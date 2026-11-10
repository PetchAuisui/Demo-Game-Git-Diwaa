using System.Text;
using GitDiwaa.Online.Accounts;

namespace GitDiwaa.Server.Persistence;

public enum UserStatus
{
    Unknown = 0,
    Active = 1,
    Disabled = 2
}

public sealed record UserRecord(
    Guid Id,
    string Username,
    string Email,
    string EmailNormalized,
    string DisplayName,
    string DisplayNameKey,
    string PasswordHash,
    DateTimeOffset? EmailVerifiedAt,
    int FailedLoginCount,
    DateTimeOffset? LockoutUntil,
    UserStatus Status,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    DateTimeOffset? LastLoginAt,
    DateTimeOffset? DisplayNameChangedAt = null,
    bool LeaderboardOptIn = false,
    int DisplayNameChangeCredits = AccountRules.InitialDisplayNameChanges)
{
    /// <summary>
    /// ตอนนี้เปลี่ยนชื่อที่แสดงได้กี่ครั้ง: ยังมีสิทธิ์เหลือก็ใช้ได้เลย
    /// ใช้หมดแล้ว ได้คืน 1 ครั้งเมื่อครบ cooldown นับจากการเปลี่ยนครั้งล่าสุด (คืนทีละ 1 ไม่สะสม)
    /// </summary>
    public int AvailableDisplayNameChanges(DateTimeOffset now, TimeSpan cooldown)
    {
        if (DisplayNameChangeCredits > 0)
        {
            return DisplayNameChangeCredits;
        }

        return DisplayNameChangedAt is not { } lastChange || lastChange.Add(cooldown) <= now ? 1 : 0;
    }

    public DateTimeOffset NextDisplayNameChangeAt(DateTimeOffset now, TimeSpan cooldown) =>
        AvailableDisplayNameChanges(now, cooldown) > 0 || DisplayNameChangedAt is not { } lastChange
            ? now
            : lastChange.Add(cooldown);

    private bool PrintMembers(StringBuilder builder)
    {
        builder.Append("Id = ").Append(Id)
               .Append(", Username = ").Append(Username)
               .Append(", Email = ***, EmailNormalized = ***")
               .Append(", DisplayName = ").Append(DisplayName)
               .Append(", DisplayNameKey = ").Append(DisplayNameKey)
               .Append(", PasswordHash = ***")
               .Append(", EmailVerifiedAt = ").Append(EmailVerifiedAt)
               .Append(", FailedLoginCount = ").Append(FailedLoginCount)
               .Append(", LockoutUntil = ").Append(LockoutUntil)
               .Append(", Status = ").Append(Status)
               .Append(", CreatedAt = ").Append(CreatedAt)
               .Append(", UpdatedAt = ").Append(UpdatedAt)
               .Append(", LastLoginAt = ").Append(LastLoginAt)
               .Append(", DisplayNameChangedAt = ").Append(DisplayNameChangedAt)
               .Append(", LeaderboardOptIn = ").Append(LeaderboardOptIn)
               .Append(", DisplayNameChangeCredits = ").Append(DisplayNameChangeCredits);
        return true;
    }
}