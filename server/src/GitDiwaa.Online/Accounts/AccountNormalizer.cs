using System.Text;

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

    public static string NormalizeDisplayNameKey(string displayName)
    {
        ArgumentNullException.ThrowIfNull(displayName);

        string normalized = displayName.Normalize(NormalizationForm.FormKC).Trim();
        if (normalized.Length == 0)
        {
            return string.Empty;
        }

        var sb = new StringBuilder(normalized.Length);
        bool previousWasSpace = false;

        foreach (char c in normalized)
        {
            if (char.IsWhiteSpace(c))
            {
                if (!previousWasSpace)
                {
                    sb.Append(' ');
                    previousWasSpace = true;
                }
            }
            else
            {
                sb.Append(c);
                previousWasSpace = false;
            }
        }

        return sb.ToString().ToLowerInvariant();
    }
}
