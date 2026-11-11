using System.Globalization;
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
    private readonly IConsentRepository _consentRepository;

    // ลองออกชื่อ player-<เลข> ได้กี่ครั้งถ้าบังเอิญชน (ปกติไม่ชน เพราะผู้เล่นตั้งชื่อรูปแบบนี้เองไม่ได้)
    private const int MaxGeneratedNameAttempts = 5;

    public AccountService(
        IUserRepository userRepository,
        ISessionRepository sessionRepository,
        PasswordHasher passwordHasher,
        SessionTokenService sessionTokenService,
        TimeProvider timeProvider,
        IConsentRepository consentRepository,
        AccountOptions? options = null)
    {
        _userRepository = userRepository ?? throw new ArgumentNullException(nameof(userRepository));
        _sessionRepository = sessionRepository ?? throw new ArgumentNullException(nameof(sessionRepository));
        _passwordHasher = passwordHasher ?? throw new ArgumentNullException(nameof(passwordHasher));
        _sessionTokenService = sessionTokenService ?? throw new ArgumentNullException(nameof(sessionTokenService));
        _timeProvider = timeProvider ?? throw new ArgumentNullException(nameof(timeProvider));
        _options = options ?? new AccountOptions();
        // บังคับส่งเสมอ: ถ้าปล่อยให้สร้างตัวในหน่วยความจำเองได้ วันที่ลืมลงทะเบียนตัวฐานข้อมูลจริง
        // หลักฐานความยินยอมจะหายตอน restart โดยไม่มี error บอก
        _consentRepository = consentRepository ?? throw new ArgumentNullException(nameof(consentRepository));
    }

    public async Task<AccountResult<PlayerProfile>> RegisterAsync(RegisterRequest request, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var validationErrors = AccountInputValidator.ValidateRegister(request);
        if (validationErrors.Count > 0)
        {
            return AccountResult<PlayerProfile>.Failure(AuthErrorCode.ValidationFailed, validationErrors);
        }

        if (_options.RejectWeakPasswords &&
            AccountInputValidator.ValidatePasswordStrength(request.Password, request.Username, request.Email) is { } weakPassword)
        {
            return AccountResult<PlayerProfile>.Failure(AuthErrorCode.ValidationFailed, [weakPassword]);
        }

        string normalizedUsername = AccountNormalizer.NormalizeUsername(request.Username);
        string trimmedEmail = request.Email.Trim();
        string normalizedEmail = AccountNormalizer.NormalizeEmail(request.Email);
        bool generateDisplayName = string.IsNullOrWhiteSpace(request.DisplayName);

        string passwordHash = await _passwordHasher.HashAsync(request.Password, ct);
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

    /// <summary>
    /// clientKey = ต้นทางของคำขอ (IP) ใช้นับการใส่รหัสผิดแยกตามต้นทาง ไม่ส่ง = นับรวมเป็นต้นทางเดียว
    /// </summary>
    public async Task<AccountResult<LoginSession>> LoginAsync(LoginRequest request, string? clientKey = null, CancellationToken ct = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var validationErrors = AccountInputValidator.ValidateLogin(request);
        if (validationErrors.Count > 0)
        {
            return AccountResult<LoginSession>.Failure(AuthErrorCode.ValidationFailed, validationErrors);
        }

        DateTimeOffset now = _timeProvider.GetUtcNow();
        string client = clientKey ?? string.Empty;

        string normalizedIdentifier = AccountNormalizer.NormalizeIdentifier(request.Identifier);
        UserRecord? user = AccountNormalizer.IsEmailIdentifier(request.Identifier)
            ? await _userRepository.FindByEmailAsync(normalizedIdentifier, ct)
            : await _userRepository.FindByUsernameAsync(normalizedIdentifier, ct);

        // ไม่มีบัญชี / บัญชีถูกปิด / ถูกพักอยู่: ตอบเหมือนรหัสผิดทุกกรณี และยังคำนวณ hash หลอกให้ใช้เวลาเท่ากัน
        if (user is null ||
            user.Status != UserStatus.Active ||
            await _userRepository.IsLoginLockedAsync(user.Id, client, now, ct))
        {
            await _passwordHasher.VerifyAsync(request.Password, _passwordHasher.DummyHash, ct);
            return AccountResult<LoginSession>.Failure(AuthErrorCode.InvalidCredentials);
        }

        bool passwordMatches = await _passwordHasher.VerifyAsync(request.Password, user.PasswordHash, ct);
        if (!passwordMatches)
        {
            // นับใน repository แบบ atomic: ถ้าอ่านค่ามาบวกเองตรงนี้ คำขอที่ยิงพร้อมกันจะอ่านได้ค่าเดียวกันแล้วเขียนทับกัน
            // (ตรวจรหัสใช้เวลาหลายร้อย ms) ตัวนับไม่ถึงเกณฑ์สักที บัญชีเลยไม่ถูกพัก
            var rules = new LoginLockoutRules(
                _options.MaxFailedLoginAttempts,
                _options.MaxFailedLoginAttemptsPerAccount,
                _options.LockoutDuration);
            await _userRepository.RecordFailedLoginAsync(user.Id, client, now, rules, ct);
            return AccountResult<LoginSession>.Failure(AuthErrorCode.InvalidCredentials);
        }

        // ระหว่างตรวจรหัส มีคำขออื่นทำให้ถูกพักไปแล้ว: รหัสถูกก็ยังไม่ให้เข้า (ไม่อย่างนั้นยิงพร้อมกันจะเดาได้เกินโควตา)
        if (await _userRepository.IsLoginLockedAsync(user.Id, client, now, ct))
        {
            return AccountResult<LoginSession>.Failure(AuthErrorCode.InvalidCredentials);
        }

        string? upgradedPasswordHash = _passwordHasher.NeedsRehash(user.PasswordHash)
            ? await _passwordHasher.HashAsync(request.Password, ct)
            : null;
        await _userRepository.RecordSuccessfulLoginAsync(user.Id, client, upgradedPasswordHash, now, ct);
        var successfulUser = user;

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

        // token ใบนี้ถูกยกเลิกไปแล้ว: ถ้าเพิ่งถูกหมุนและยังอยู่ในช่วงผ่อนผัน ถือเป็นการลองใหม่ตามปกติ
        // นอกนั้นถือว่า token ถูกขโมย ตัดทุก session ของบัญชี
        bool alreadyRotated = session.RevokedAt is not null;
        if (alreadyRotated && !await IsWithinRotationGraceAsync(session, now, ct))
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

        // เพิ่ม session ใหม่ก่อน แล้วค่อยหมุนใบเก่า: คำขอที่เข้ามาพร้อมกันจะหา session ที่มาแทนเจอเสมอตอนตรวจช่วงผ่อนผัน
        await _sessionRepository.AddAsync(newSessionRecord, ct);

        if (!alreadyRotated &&
            !await _sessionRepository.TryRotateAsync(session.Id, newSessionRecord.Id, now, ct))
        {
            // แพ้คำขออื่นที่หมุนใบเดียวกันไปก่อน (atomic: ชนะได้คำขอเดียว) หรือถูกยกเลิกไประหว่างนี้
            var latest = await _sessionRepository.FindByIdAsync(session.Id, ct);
            if (latest is null || !await IsWithinRotationGraceAsync(latest, now, ct))
            {
                await _sessionRepository.RevokeAllForUserAsync(session.UserId, now, ct);
                return AccountResult<LoginSession>.Failure(AuthErrorCode.InvalidCredentials);
            }
            // อยู่ในช่วงผ่อนผัน (เช่น เกม 2 หน้าต่าง refresh พร้อมกัน): ใช้ session ใหม่ที่เพิ่มไว้แล้วได้เลย
        }

        var profile = new PlayerProfile(user.Id, user.Username, user.DisplayName);
        var loginSession = new LoginSession(profile, newIssuedToken.Token, newExpiresAt);

        return AccountResult<LoginSession>.Success(loginSession);
    }

    /// <summary>
    /// token ใบเก่าที่ถูกหมุนไปแล้ว ยังอยู่ในช่วงผ่อนผันไหม ต้องครบทุกข้อ:
    /// 1. ถูกยกเลิกเพราะ refresh (ไม่ใช่ logout / ถูกตัดทั้งบัญชี)
    /// 2. เพิ่งถูกหมุนไม่เกิน RefreshReuseGracePeriod
    /// 3. session ที่มาแทนยังใช้ได้อยู่: ถ้าผู้เล่น logout ไปแล้ว หรือบัญชีถูกตัดทุก session ใบเก่าต้องใช้ไม่ได้ทันที
    /// กรณีปกติที่เข้าช่วงนี้: คำตอบ refresh หายกลางทางแล้วเกมลองใหม่ / เปิดเกม 2 หน้าต่างที่ใช้ไฟล์จดจำเดียวกัน
    /// </summary>
    private async Task<bool> IsWithinRotationGraceAsync(SessionRecord session, DateTimeOffset now, CancellationToken ct)
    {
        if (_options.RefreshReuseGracePeriod <= TimeSpan.Zero ||
            session.RotatedAt is not { } rotatedAt ||
            session.ReplacedBySessionId is not { } replacedBy ||
            now - rotatedAt > _options.RefreshReuseGracePeriod)
        {
            return false;
        }

        var successor = await _sessionRepository.FindByIdAsync(replacedBy, ct);
        return successor is not null && successor.RevokedAt is null;
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

    /// <summary>
    /// อีเมลของผู้ใช้คนนี้ (userId มาจาก session เท่านั้น ขอของคนอื่นไม่ได้)
    /// </summary>
    public async Task<AccountResult<MyEmailResponse>> GetEmailAsync(Guid userId, CancellationToken ct = default)
    {
        var user = await _userRepository.FindByIdAsync(userId, ct);
        if (user is null || user.Status != UserStatus.Active)
        {
            return AccountResult<MyEmailResponse>.Failure(AuthErrorCode.InvalidCredentials);
        }

        return AccountResult<MyEmailResponse>.Success(new MyEmailResponse(user.Email));
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