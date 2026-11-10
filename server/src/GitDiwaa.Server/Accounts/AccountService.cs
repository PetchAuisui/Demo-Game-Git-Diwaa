using System.Globalization;
using GitDiwaa.Online.Accounts;
using GitDiwaa.Online.Accounts.Contracts;
using GitDiwaa.Server.Persistence;
using GitDiwaa.Server.Persistence.InMemory;
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
    private readonly IConsentRepository _consentRepository;

    // ลองออกชื่อ player-<เลข> ได้กี่ครั้งถ้าบังเอิญชน (ปกติไม่ชน เพราะผู้เล่นตั้งชื่อรูปแบบนี้เองไม่ได้)
    private const int MaxGeneratedNameAttempts = 5;

    public AccountService(
        IUserRepository userRepository,
        ISessionRepository sessionRepository,
        PasswordHasher passwordHasher,
        SessionTokenService sessionTokenService,
        TimeProvider timeProvider,
        AccountOptions? options = null,
        IConsentRepository? consentRepository = null)
    {
        _userRepository = userRepository ?? throw new ArgumentNullException(nameof(userRepository));
        _sessionRepository = sessionRepository ?? throw new ArgumentNullException(nameof(sessionRepository));
        _passwordHasher = passwordHasher ?? throw new ArgumentNullException(nameof(passwordHasher));
        _sessionTokenService = sessionTokenService ?? throw new ArgumentNullException(nameof(sessionTokenService));
        _timeProvider = timeProvider ?? throw new ArgumentNullException(nameof(timeProvider));
        _options = options ?? new AccountOptions();
        // server จริงได้ตัวที่ลงทะเบียนใน ServerApp เสมอ ตัว in-memory นี้มีไว้ให้เทสเก่าที่ไม่ได้ส่งมาใช้ได้
        _consentRepository = consentRepository ?? new InMemoryConsentRepository();
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
        bool generateDisplayName = string.IsNullOrWhiteSpace(request.DisplayName);

        string passwordHash = _passwordHasher.Hash(request.Password);
        DateTimeOffset now = _timeProvider.GetUtcNow();

        UserRecord user;
        UserAddResult addResult;
        int attempt = 0;
        do
        {
            // ไม่ได้ตั้งชื่อ: ใช้ player-<เลขลำดับ> ถ้าบังเอิญชน (เช่น ข้อมูลเก่า) ข้ามไปเลขถัดไป
            string displayName = generateDisplayName
                ? AccountRules.GeneratedDisplayNamePrefix +
                  (await _userRepository.NextPlayerNumberAsync(ct)).ToString(CultureInfo.InvariantCulture)
                : request.DisplayName!.Trim();

            user = new UserRecord(
                Id: Guid.NewGuid(),
                Username: normalizedUsername,
                Email: trimmedEmail,
                EmailNormalized: normalizedEmail,
                DisplayName: displayName,
                DisplayNameKey: AccountNormalizer.NormalizeDisplayNameKey(displayName),
                PasswordHash: passwordHash,
                EmailVerifiedAt: null,
                FailedLoginCount: 0,
                LockoutUntil: null,
                Status: UserStatus.Active,
                CreatedAt: now,
                UpdatedAt: now,
                LastLoginAt: null,
                LeaderboardOptIn: request.LeaderboardOptIn,
                DisplayNameChangeCredits: AccountRules.InitialDisplayNameChanges);

            addResult = await _userRepository.TryAddAsync(user, ct);
            attempt++;
        }
        while (generateDisplayName && addResult == UserAddResult.DisplayNameTaken && attempt < MaxGeneratedNameAttempts);

        if (addResult == UserAddResult.Added)
        {
            // บันทึกการตัดสินใจตอนสมัครเสมอ ทั้งยินยอมและไม่ยินยอม
            await _consentRepository.AddAsync(
                NewLeaderboardConsent(user.Id, request.LeaderboardOptIn, request.PolicyVersion, now), ct);
        }
        return addResult switch
        {
            UserAddResult.Added => AccountResult<PlayerProfile>.Success(new PlayerProfile(user.Id, user.Username, user.DisplayName)),
            UserAddResult.IdentifierTaken => AccountResult<PlayerProfile>.Failure(AuthErrorCode.IdentifierTaken),
            UserAddResult.DisplayNameTaken => AccountResult<PlayerProfile>.Failure(
                AuthErrorCode.IdentifierTaken,
                [new FieldError(AccountFields.DisplayName, FieldErrorReason.Taken)]),
            _ => throw new InvalidOperationException($"Unexpected UserAddResult: {addResult}")
        };
    }

    /// <summary>
    /// ตรวจก่อนสมัครว่าใช้ชื่อผู้ใช้และอีเมลนี้ได้ไหม ไม่สร้างบัญชีและไม่บันทึกอะไร
    /// ความปลอดภัย:
    /// 1. ถ้ามีคนใช้แล้ว ตอบแค่ IdentifierTaken ไม่บอกว่าช่องไหน (เหมือนตอนสมัครจริง) ไม่ให้ใช้ไล่เช็คได้ง่ายว่าอีเมลไหนมีบัญชี
    ///    และ endpoint นี้ถูกจำกัดจำนวนครั้งรวมกับ register / login
    /// 2. ผลนี้ไม่ใช่การจอง ตอนสมัครจริง (RegisterAsync) ตรวจซ้ำเสมอ เพราะคนอื่นอาจสมัครตัดหน้าไประหว่างนั้น
    /// </summary>
    public async Task<AccountResult<bool>> CheckRegistrationAsync(RegisterCheckRequest request, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var validationErrors = AccountInputValidator.ValidateRegisterCheck(request);
        if (validationErrors.Count > 0)
        {
            return AccountResult<bool>.Failure(AuthErrorCode.ValidationFailed, validationErrors);
        }

        // ค้นทั้งสองอย่างทุกครั้ง (ไม่หยุดที่อันแรก) เวลาที่ใช้ตอบจะได้ไม่บอกใบ้ว่าช่องไหนซ้ำ
        var byUsername = await _userRepository.FindByUsernameAsync(AccountNormalizer.NormalizeUsername(request.Username), ct);
        var byEmail = await _userRepository.FindByEmailAsync(AccountNormalizer.NormalizeEmail(request.Email), ct);
        if (byUsername is not null || byEmail is not null)
        {
            return AccountResult<bool>.Failure(AuthErrorCode.IdentifierTaken);
        }

        return AccountResult<bool>.Success(true);
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

        // Atomic touch: does not overwrite RevokedAt
        await _sessionRepository.TouchAsync(session.Id, now, ct);

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

        // Atomic revocation race check: only one concurrent refresh request can win
        if (!await _sessionRepository.TryRevokeAsync(session.Id, now, ct))
        {
            await _sessionRepository.RevokeAllForUserAsync(session.UserId, now, ct);
            return AccountResult<LoginSession>.Failure(AuthErrorCode.InvalidCredentials);
        }

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

    /// <summary>
    /// เปลี่ยนชื่อที่แสดงของผู้ใช้ที่ login อยู่ (userId ต้องมาจาก session ที่ตรวจแล้วเท่านั้น ห้ามรับจาก request)
    /// สำเร็จ: Value คือโปรไฟล์ใหม่ + เวลาที่เปลี่ยนได้อีกครั้ง
    /// ยังไม่ครบกำหนด: Error = DisplayNameChangeCooldown และ Value บอกเวลาที่เปลี่ยนได้อีกครั้ง
    /// </summary>
    public async Task<AccountResult<ChangeDisplayNameResponse>> ChangeDisplayNameAsync(
        Guid userId,
        ChangeDisplayNameRequest request,
        CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var validationErrors = AccountInputValidator.ValidateChangeDisplayName(request);
        if (validationErrors.Count > 0)
        {
            return AccountResult<ChangeDisplayNameResponse>.Failure(AuthErrorCode.ValidationFailed, validationErrors);
        }

        DateTimeOffset now = _timeProvider.GetUtcNow();
        string trimmedDisplayName = request.DisplayName.Trim();
        string displayNameKey = AccountNormalizer.NormalizeDisplayNameKey(request.DisplayName);

        var user = await _userRepository.FindByIdAsync(userId, ct);
        if (user is null || user.Status != UserStatus.Active)
        {
            return AccountResult<ChangeDisplayNameResponse>.Failure(AuthErrorCode.InvalidCredentials);
        }

        // ชื่อเดิมทุกตัวอักษร: ไม่ต้องเปลี่ยน และไม่นับเป็นการใช้สิทธิ์เปลี่ยนชื่อ
        if (string.Equals(user.DisplayName, trimmedDisplayName, StringComparison.Ordinal))
        {
            return AccountResult<ChangeDisplayNameResponse>.Success(ToChangeResponse(user, now));
        }

        var outcome = await _userRepository.TryChangeDisplayNameAsync(
            userId,
            trimmedDisplayName,
            displayNameKey,
            now,
            _options.DisplayNameChangeCooldown,
            ct);

        return outcome.Result switch
        {
            DisplayNameChangeResult.Changed when outcome.User is not null =>
                AccountResult<ChangeDisplayNameResponse>.Success(ToChangeResponse(outcome.User, now)),
            DisplayNameChangeResult.CooldownActive when outcome.User is not null =>
                new AccountResult<ChangeDisplayNameResponse>(
                    ToChangeResponse(outcome.User, now),
                    AuthErrorCode.DisplayNameChangeCooldown,
                    []),
            DisplayNameChangeResult.DisplayNameTaken =>
                AccountResult<ChangeDisplayNameResponse>.Failure(
                    AuthErrorCode.IdentifierTaken,
                    [new FieldError(AccountFields.DisplayName, FieldErrorReason.Taken)]),
            DisplayNameChangeResult.UserNotFound =>
                AccountResult<ChangeDisplayNameResponse>.Failure(AuthErrorCode.InvalidCredentials),
            _ => throw new InvalidOperationException($"Unexpected DisplayNameChangeResult: {outcome.Result}")
        };
    }

    /// <summary>
    /// สถานะชื่อที่แสดงตอนนี้ (ชื่อ, เปลี่ยนได้อีกกี่ครั้ง, เปลี่ยนได้อีกเมื่อไหร่) สำหรับหน้าบัญชี
    /// </summary>
    public async Task<AccountResult<ChangeDisplayNameResponse>> GetDisplayNameStatusAsync(
        Guid userId,
        CancellationToken ct = default)
    {
        var user = await _userRepository.FindByIdAsync(userId, ct);
        if (user is null || user.Status != UserStatus.Active)
        {
            return AccountResult<ChangeDisplayNameResponse>.Failure(AuthErrorCode.InvalidCredentials);
        }

        return AccountResult<ChangeDisplayNameResponse>.Success(ToChangeResponse(user, _timeProvider.GetUtcNow()));
    }

    private ChangeDisplayNameResponse ToChangeResponse(UserRecord user, DateTimeOffset now)
    {
        TimeSpan cooldown = _options.DisplayNameChangeCooldown;
        var profile = new PlayerProfile(user.Id, user.Username, user.DisplayName);
        return new ChangeDisplayNameResponse(
            profile,
            user.NextDisplayNameChangeAt(now, cooldown),
            user.AvailableDisplayNameChanges(now, cooldown));
    }

    public async Task<AccountResult<LeaderboardConsentResponse>> GetLeaderboardConsentAsync(
        Guid userId,
        CancellationToken ct = default)
    {
        var user = await _userRepository.FindByIdAsync(userId, ct);
        if (user is null || user.Status != UserStatus.Active)
        {
            return AccountResult<LeaderboardConsentResponse>.Failure(AuthErrorCode.InvalidCredentials);
        }

        return AccountResult<LeaderboardConsentResponse>.Success(new LeaderboardConsentResponse(user.LeaderboardOptIn));
    }

    /// <summary>
    /// ให้หรือถอนความยินยอมแสดงชื่อบนตารางอันดับ (ถอนได้ง่ายเท่ากับให้ ตาม PDPA) และบันทึกหลักฐานทุกครั้ง
    /// userId ต้องมาจาก session ที่ตรวจแล้วเท่านั้น
    /// </summary>
    public async Task<AccountResult<LeaderboardConsentResponse>> SetLeaderboardConsentAsync(
        Guid userId,
        LeaderboardConsentRequest request,
        CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var validationErrors = AccountInputValidator.ValidateLeaderboardConsent(request);
        if (validationErrors.Count > 0)
        {
            return AccountResult<LeaderboardConsentResponse>.Failure(AuthErrorCode.ValidationFailed, validationErrors);
        }

        var existing = await _userRepository.FindByIdAsync(userId, ct);
        if (existing is null || existing.Status != UserStatus.Active)
        {
            return AccountResult<LeaderboardConsentResponse>.Failure(AuthErrorCode.InvalidCredentials);
        }

        DateTimeOffset now = _timeProvider.GetUtcNow();
        var updated = await _userRepository.TrySetLeaderboardOptInAsync(userId, request.Granted, now, ct);
        if (updated is null)
        {
            return AccountResult<LeaderboardConsentResponse>.Failure(AuthErrorCode.InvalidCredentials);
        }

        await _consentRepository.AddAsync(NewLeaderboardConsent(userId, request.Granted, request.PolicyVersion, now), ct);
        return AccountResult<LeaderboardConsentResponse>.Success(new LeaderboardConsentResponse(updated.LeaderboardOptIn));
    }

    private static ConsentRecord NewLeaderboardConsent(Guid userId, bool granted, string? policyVersion, DateTimeOffset now) =>
        new(
            Id: Guid.NewGuid(),
            UserId: userId,
            Purpose: ConsentPurposes.LeaderboardDisplay,
            PolicyVersion: policyVersion ?? "unspecified",
            Granted: granted,
            RecordedAt: now);

    public async Task LogoutAsync(string? token, CancellationToken ct = default)
    {
        DateTimeOffset now = _timeProvider.GetUtcNow();

        if (!_sessionTokenService.TryHashToken(token, out string tokenHash))
        {
            return;
        }

        var session = await _sessionRepository.FindByTokenHashAsync(tokenHash, ct);
        if (session is null)
        {
            return;
        }

        await _sessionRepository.TryRevokeAsync(session.Id, now, ct);
    }
}