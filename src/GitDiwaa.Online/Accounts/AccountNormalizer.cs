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
}