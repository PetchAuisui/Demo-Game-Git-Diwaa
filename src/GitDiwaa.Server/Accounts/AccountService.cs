using GitDiwaa.Online.Accounts;
using GitDiwaa.Online.Accounts.Contracts;
using GitDiwaa.Server.Persistence;
using GitDiwaa.Server.Security;

namespace GitDiwaa.Server.Accounts;

public sealed class AccountService
{
    private readonly IUserRepository _userRepository;
    private readonly ISessionRepository _sessionRepository;
    private readonly PasswordHasher _passwordHasher;
    private readonly SessionTokenService _sessionTokenService;
    private readonly TimeProvider _timeProvider;
    private readonly AccountOptions _options;

    public AccountService(
        IUserRepository userRepository,
        ISessionRepository sessionRepository,
        PasswordHasher passwordHasher,
        SessionTokenService sessionTokenService,
        TimeProvider timeProvider,
        AccountOptions? options = null)
    {
        _userRepository = userRepository ?? throw new ArgumentNullException(nameof(userRepository));
        _sessionRepository = sessionRepository ?? throw new ArgumentNullException(nameof(sessionRepository));
        _passwordHasher = passwordHasher ?? throw new ArgumentNullException(nameof(passwordHasher));
        _sessionTokenService = sessionTokenService ?? throw new ArgumentNullException(nameof(sessionTokenService));
        _timeProvider = timeProvider ?? throw new ArgumentNullException(nameof(timeProvider));
        _options = options ?? new AccountOptions();
    }

    public async Task<AccountResult<PlayerProfile>> RegisterAsync(RegisterRequest request, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var validationErrors = AccountInputValidator.ValidateRegister(request);
        if (validationErrors.Count > 0)
        {
            return AccountResult<PlayerProfile>.Failure(AuthErrorCode.ValidationFailed, validationErrors);
        }

        string normalizedUsername = AccountNormalizer.NormalizeUsername(request.Username);
        string trimmedEmail = request.Email.Trim();
        string normalizedEmail = AccountNormalizer.NormalizeEmail(request.Email);
        string trimmedDisplayName = request.DisplayName.Trim();

        string passwordHash = _passwordHasher.Hash(request.Password);
        DateTimeOffset now = _timeProvider.GetUtcNow();

        var user = new UserRecord(
            Id: Guid.NewGuid(),
            Username: normalizedUsername,
            Email: trimmedEmail,
            EmailNormalized: normalizedEmail,
            DisplayName: trimmedDisplayName,
            PasswordHash: passwordHash,
            EmailVerifiedAt: null,
            FailedLoginCount: 0,
            LockoutUntil: null,
            Status: UserStatus.Active,
            CreatedAt: now,
            UpdatedAt: now,
            LastLoginAt: null);

        bool added = await _userRepository.TryAddAsync(user, ct);
        if (!added)
        {
            return AccountResult<PlayerProfile>.Failure(AuthErrorCode.IdentifierTaken);
        }

        var profile = new PlayerProfile(user.Id, user.Username, user.DisplayName);
        return AccountResult<PlayerProfile>.Success(profile);
    }

    public async Task<AccountResult<LoginSession>> LoginAsync(LoginRequest request, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var validationErrors = AccountInputValidator.ValidateLogin(request);
        if (validationErrors.Count > 0)
        {
            return AccountResult<LoginSession>.Failure(AuthErrorCode.ValidationFailed, validationErrors);
        }

        DateTimeOffset now = _timeProvider.GetUtcNow();

        string normalizedIdentifier = AccountNormalizer.NormalizeIdentifier(request.Identifier);
        UserRecord? user = AccountNormalizer.IsEmailIdentifier(request.Identifier)
            ? await _userRepository.FindByEmailAsync(normalizedIdentifier, ct)
            : await _userRepository.FindByUsernameAsync(normalizedIdentifier, ct);

        if (user is null)
        {
            _passwordHasher.Verify(request.Password, _passwordHasher.DummyHash);
            return AccountResult<LoginSession>.Failure(AuthErrorCode.InvalidCredentials);
        }

        if (user.Status != UserStatus.Active)
        {
            _passwordHasher.Verify(request.Password, _passwordHasher.DummyHash);
            return AccountResult<LoginSession>.Failure(AuthErrorCode.InvalidCredentials);
        }

        if (user.LockoutUntil.HasValue && user.LockoutUntil.Value > now)
        {
            _passwordHasher.Verify(request.Password, _passwordHasher.DummyHash);
            return AccountResult<LoginSession>.Failure(AuthErrorCode.InvalidCredentials);
        }

        bool passwordMatches = _passwordHasher.Verify(request.Password, user.PasswordHash);
        if (!passwordMatches)
        {
            int failedAttempts = user.FailedLoginCount + 1;
            DateTimeOffset? lockoutUntil = user.LockoutUntil;

            if (failedAttempts >= _options.MaxFailedLoginAttempts)
            {
                lockoutUntil = now.Add(_options.LockoutDuration);
                failedAttempts = 0;
            }

            var updatedUser = user with
            {
                FailedLoginCount = failedAttempts,
                LockoutUntil = lockoutUntil,
                UpdatedAt = now
            };

            await _userRepository.UpdateAsync(updatedUser, ct);
            return AccountResult<LoginSession>.Failure(AuthErrorCode.InvalidCredentials);
        }

        string currentPasswordHash = user.PasswordHash;
        if (_passwordHasher.NeedsRehash(currentPasswordHash))
        {
            currentPasswordHash = _passwordHasher.Hash(request.Password);
        }

        var successfulUser = user with
        {
            PasswordHash = currentPasswordHash,
            FailedLoginCount = 0,
            LockoutUntil = null,
            LastLoginAt = now,
            UpdatedAt = now
        };
        await _userRepository.UpdateAsync(successfulUser, ct);

        TimeSpan sessionLifetime = request.RememberMe
            ? _options.PersistentSessionLifetime
            : _options.ShortSessionLifetime;

        DateTimeOffset expiresAt = now.Add(sessionLifetime);
        IssuedToken issuedToken = _sessionTokenService.CreateToken();

        var sessionRecord = new SessionRecord(
            Id: Guid.NewGuid(),
            UserId: successfulUser.Id,
            TokenHash: issuedToken.TokenHash,
            IsPersistent: request.RememberMe,
            CreatedAt: now,
            ExpiresAt: expiresAt,
            LastUsedAt: now,
            RevokedAt: null);

        await _sessionRepository.AddAsync(sessionRecord, ct);

        var profile = new PlayerProfile(successfulUser.Id, successfulUser.Username, successfulUser.DisplayName);
        var loginSession = new LoginSession(profile, issuedToken.Token, expiresAt);

        return AccountResult<LoginSession>.Success(loginSession);
    }

    public async Task<AccountResult<AuthenticatedSession>> ValidateSessionAsync(string? token, CancellationToken ct = default)
    {
        DateTimeOffset now = _timeProvider.GetUtcNow();

        if (!_sessionTokenService.TryHashToken(token, out string tokenHash))
        {
            return AccountResult<AuthenticatedSession>.Failure(AuthErrorCode.InvalidCredentials);
        }

        var session = await _sessionRepository.FindByTokenHashAsync(tokenHash, ct);
        if (session is null)
        {
            return AccountResult<AuthenticatedSession>.Failure(AuthErrorCode.InvalidCredentials);
        }

        if (session.RevokedAt is not null)
        {
            return AccountResult<AuthenticatedSession>.Failure(AuthErrorCode.InvalidCredentials);
        }

        if (session.ExpiresAt <= now)
        {
            return AccountResult<AuthenticatedSession>.Failure(AuthErrorCode.InvalidCredentials);
        }

        var user = await _userRepository.FindByIdAsync(session.UserId, ct);
        if (user is null || user.Status != UserStatus.Active)
        {
            return AccountResult<AuthenticatedSession>.Failure(AuthErrorCode.InvalidCredentials);
        }

        await _sessionRepository.UpdateAsync(session with { LastUsedAt = now }, ct);

        var profile = new PlayerProfile(user.Id, user.Username, user.DisplayName);
        return AccountResult<AuthenticatedSession>.Success(new AuthenticatedSession(session.Id, profile));
    }

    public async Task<AccountResult<LoginSession>> RefreshAsync(string? token, CancellationToken ct = default)
    {
        DateTimeOffset now = _timeProvider.GetUtcNow();

        if (!_sessionTokenService.TryHashToken(token, out string tokenHash))
        {
            return AccountResult<LoginSession>.Failure(AuthErrorCode.InvalidCredentials);
        }

        var session = await _sessionRepository.FindByTokenHashAsync(tokenHash, ct);
        if (session is null)
        {
            return AccountResult<LoginSession>.Failure(AuthErrorCode.InvalidCredentials);
        }

        // Token reuse detection: if rotated/revoked token is used again, revoke all sessions for this user
        if (session.RevokedAt is not null)
        {
            await _sessionRepository.RevokeAllForUserAsync(session.UserId, now, ct);
            return AccountResult<LoginSession>.Failure(AuthErrorCode.InvalidCredentials);
        }

        if (session.ExpiresAt <= now)
        {
            return AccountResult<LoginSession>.Failure(AuthErrorCode.InvalidCredentials);
        }

        var user = await _userRepository.FindByIdAsync(session.UserId, ct);
        if (user is null || user.Status != UserStatus.Active)
        {
            return AccountResult<LoginSession>.Failure(AuthErrorCode.InvalidCredentials);
        }

        // Revoke current session
        await _sessionRepository.UpdateAsync(session with { RevokedAt = now }, ct);

        // Issue new rotated session
        TimeSpan sessionLifetime = session.IsPersistent
            ? _options.PersistentSessionLifetime
            : _options.ShortSessionLifetime;

        DateTimeOffset newExpiresAt = now.Add(sessionLifetime);
        IssuedToken newIssuedToken = _sessionTokenService.CreateToken();

        var newSessionRecord = new SessionRecord(
            Id: Guid.NewGuid(),
            UserId: user.Id,
            TokenHash: newIssuedToken.TokenHash,
            IsPersistent: session.IsPersistent,
            CreatedAt: now,
            ExpiresAt: newExpiresAt,
            LastUsedAt: now,
            RevokedAt: null);

        await _sessionRepository.AddAsync(newSessionRecord, ct);

        var profile = new PlayerProfile(user.Id, user.Username, user.DisplayName);
        var loginSession = new LoginSession(profile, newIssuedToken.Token, newExpiresAt);

        return AccountResult<LoginSession>.Success(loginSession);
    }

    public async Task LogoutAsync(string? token, CancellationToken ct = default)
    {
        DateTimeOffset now = _timeProvider.GetUtcNow();

        if (!_sessionTokenService.TryHashToken(token, out string tokenHash))
        {
            return;
        }

        var session = await _sessionRepository.FindByTokenHashAsync(tokenHash, ct);
        if (session is null || session.RevokedAt is not null)
        {
            return;
        }

        await _sessionRepository.UpdateAsync(session with { RevokedAt = now }, ct);
    }
}