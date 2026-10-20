namespace GitDiwaa.Online.Accounts;

public static class AccountNormalizer
{
    public static string NormalizeUsername(string username)
    {
        ArgumentNullException.ThrowIfNull(username);
        return username.Trim().ToLowerInvariant();
    }

    public static string NormalizeEmail(string email)
    {
        ArgumentNullException.ThrowIfNull(email);
        return email.Trim().ToLowerInvariant();
    }

    public static bool IsEmailIdentifier(string identifier)
    {
        ArgumentNullException.ThrowIfNull(identifier);
        return identifier.Contains('@', StringComparison.Ordinal);
    }

    public static string NormalizeIdentifier(string identifier) =>
        IsEmailIdentifier(identifier)
            ? NormalizeEmail(identifier)
            : NormalizeUsername(identifier);
}