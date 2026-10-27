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
        AccountOptions options)
    {
        _userRepository = userRepository;
        _sessionRepository = sessionRepository;
        _passwordHasher = passwordHasher;
        _sessionTokenService = sessionTokenService;
        _timeProvider = timeProvider;
        _options = options;
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

        string normalizedIdentifier = AccountNormalizer.NormalizeIdentifier(request.Identifier);
        bool isEmail = AccountNormalizer.IsEmailIdentifier(request.Identifier);

        UserRecord? user = isEmail
            ? await _userRepository.FindByEmailAsync(normalizedIdentifier, ct)
            : await _userRepository.FindByUsernameAsync(normalizedIdentifier, ct);

        DateTimeOffset now = _timeProvider.GetUtcNow();

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

        bool isPasswordValid = _passwordHasher.Verify(request.Password, user.PasswordHash);
        if (!isPasswordValid)
        {
            int failedAttempts = user.FailedLoginCount + 1;
            DateTimeOffset? lockoutUntil = user.LockoutUntil;

            if (failedAttempts >= _options.MaxFailedLoginAttempts)
            {
                lockoutUntil = now + _options.LockoutDuration;
                failedAttempts = 0;
            }

            var updatedUserOnFailure = user with
            {
                FailedLoginCount = failedAttempts,
                LockoutUntil = lockoutUntil,
                UpdatedAt = now
            };

            await _userRepository.UpdateAsync(updatedUserOnFailure, ct);
            return AccountResult<LoginSession>.Failure(AuthErrorCode.InvalidCredentials);
        }

        // Login successful: reset lockout & failed counter
        string updatedPasswordHash = user.PasswordHash;
        if (_passwordHasher.NeedsRehash(user.PasswordHash))
        {
            updatedPasswordHash = _passwordHasher.Hash(request.Password);
        }

        var updatedUserOnSuccess = user with
        {
            FailedLoginCount = 0,
            LockoutUntil = null,
            PasswordHash = updatedPasswordHash,
            LastLoginAt = now,
            UpdatedAt = now
        };

        await _userRepository.UpdateAsync(updatedUserOnSuccess, ct);

        IssuedToken issuedToken = _sessionTokenService.CreateToken();
        TimeSpan lifetime = request.RememberMe ? _options.PersistentSessionLifetime : _options.ShortSessionLifetime;
        DateTimeOffset expiresAt = now + lifetime;

        var session = new SessionRecord(
            Id: Guid.NewGuid(),
            UserId: user.Id,
            TokenHash: issuedToken.TokenHash,
            IsPersistent: request.RememberMe,
            CreatedAt: now,
            ExpiresAt: expiresAt,
            LastUsedAt: now,
            RevokedAt: null);

        await _sessionRepository.AddAsync(session, ct);

        var profile = new PlayerProfile(user.Id, user.Username, user.DisplayName);
        var loginSession = new LoginSession(profile, issuedToken.Token, expiresAt);

        return AccountResult<LoginSession>.Success(loginSession);
    }
}