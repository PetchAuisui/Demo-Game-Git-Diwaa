using System.Globalization;
using System.Text.RegularExpressions;
using GitDiwaa.Online.Accounts.Contracts;

namespace GitDiwaa.Online.Accounts;

public static partial class AccountInputValidator
{
    [GeneratedRegex(@"^[a-z0-9](?:[a-z0-9-]{1,18})[a-z0-9]\z")]
    private static partial Regex UsernameRegex();

    public static IReadOnlyList<FieldError> ValidateRegister(RegisterRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);

        var errors = new List<FieldError>(4);

        if (ValidateUsername(request.Username) is { } usernameError)
        {
            errors.Add(usernameError);
        }

        // ไม่ใส่ชื่อที่แสดงตอนสมัครได้: server จะตั้งให้เป็น player-<เลขลำดับ>
        if (!string.IsNullOrWhiteSpace(request.DisplayName) &&
            ValidateDisplayName(request.DisplayName) is { } displayNameError)
        {
            errors.Add(displayNameError);
        }

        if (ValidateEmail(request.Email) is { } emailError)
        {
            errors.Add(emailError);
        }

        if (ValidateRegisterPassword(request.Password) is { } passwordError)
        {
            errors.Add(passwordError);
        }

        // ยินยอมแสดงชื่อบนตารางอันดับตอนสมัคร: ต้องบอกว่าเห็นนโยบายเวอร์ชันไหน
        if (ValidatePolicyVersion(request.PolicyVersion, required: request.LeaderboardOptIn) is { } policyError)
        {
            errors.Add(policyError);
        }

        return errors;
    }

    public static IReadOnlyList<FieldError> ValidateLogin(LoginRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);

        var errors = new List<FieldError>(2);

        if (string.IsNullOrWhiteSpace(request.Identifier))
        {
            errors.Add(new FieldError(AccountFields.Identifier, FieldErrorReason.Required));
        }
        else if (request.Identifier.Trim().Length > AccountRules.LoginIdentifierMaxLength)
        {
            errors.Add(new FieldError(AccountFields.Identifier, FieldErrorReason.TooLong));
        }

        if (string.IsNullOrEmpty(request.Password))
        {
            errors.Add(new FieldError(AccountFields.Password, FieldErrorReason.Required));
        }
        else if (request.Password.Length > AccountRules.PasswordMaxLength)
        {
            errors.Add(new FieldError(AccountFields.Password, FieldErrorReason.TooLong));
        }

        return errors;
    }

    public static IReadOnlyList<FieldError> ValidateChangeDisplayName(ChangeDisplayNameRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);

        var errors = new List<FieldError>(1);
        if (ValidateDisplayName(request.DisplayName) is { } displayNameError)
        {
            errors.Add(displayNameError);
        }

        return errors;
    }

    public static IReadOnlyList<FieldError> ValidateLeaderboardConsent(LeaderboardConsentRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);

        var errors = new List<FieldError>(1);
        if (ValidatePolicyVersion(request.PolicyVersion, required: true) is { } policyError)
        {
            errors.Add(policyError);
        }

        return errors;
    }

    // ต้องเป็นเวอร์ชันปัจจุบันเท่านั้น: ไม่บันทึกการยินยอมกับนโยบายที่ผู้เล่นไม่ได้เห็นจริง
    private static FieldError? ValidatePolicyVersion(string? policyVersion, bool required)
    {
        if (string.IsNullOrEmpty(policyVersion))
        {
            return required ? new FieldError(AccountFields.PolicyVersion, FieldErrorReason.Required) : null;
        }

        if (!string.Equals(policyVersion, PrivacyPolicy.CurrentVersion, StringComparison.Ordinal))
        {
            return new FieldError(AccountFields.PolicyVersion, FieldErrorReason.InvalidFormat);
        }

        return null;
    }

    private static FieldError? ValidateUsername(string? rawUsername)
    {
        if (string.IsNullOrWhiteSpace(rawUsername))
        {
            return new FieldError(AccountFields.Username, FieldErrorReason.Required);
        }

        var trimmed = rawUsername.Trim();
        foreach (var c in trimmed)
        {
            if (!IsAllowedUsernameChar(c))
            {
                return new FieldError(AccountFields.Username, FieldErrorReason.InvalidCharacters);
            }
        }

        var normalized = AccountNormalizer.NormalizeUsername(rawUsername);
        if (normalized.Length < AccountRules.UsernameMinLength)
        {
            return new FieldError(AccountFields.Username, FieldErrorReason.TooShort);
        }

        if (normalized.Length > AccountRules.UsernameMaxLength)
        {
            return new FieldError(AccountFields.Username, FieldErrorReason.TooLong);
        }

        if (!UsernameRegex().IsMatch(normalized))
        {
            return new FieldError(AccountFields.Username, FieldErrorReason.InvalidFormat);
        }

        return null;
    }

    private static FieldError? ValidateEmail(string? rawEmail)
    {
        if (string.IsNullOrWhiteSpace(rawEmail))
        {
            return new FieldError(AccountFields.Email, FieldErrorReason.Required);
        }

        var trimmed = rawEmail.Trim();
        if (trimmed.Length > AccountRules.EmailMaxLength)
        {
            return new FieldError(AccountFields.Email, FieldErrorReason.TooLong);
        }

        foreach (var c in trimmed)
        {
            if (!IsAllowedEmailChar(c))
            {
                return new FieldError(AccountFields.Email, FieldErrorReason.InvalidCharacters);
            }
        }

        var normalized = AccountNormalizer.NormalizeEmail(rawEmail);

        var atIndex = normalized.IndexOf('@');
        if (atIndex <= 0 || atIndex != normalized.LastIndexOf('@'))
        {
            return new FieldError(AccountFields.Email, FieldErrorReason.InvalidFormat);
        }

        var localPart = normalized[..atIndex];
        var domainPart = normalized[(atIndex + 1)..];

        if (localPart.Length == 0 ||
            localPart.Length > AccountRules.EmailLocalPartMaxLength ||
            localPart.StartsWith('.') ||
            localPart.EndsWith('.'))
        {
            return new FieldError(AccountFields.Email, FieldErrorReason.InvalidFormat);
        }

        if (domainPart.Length == 0 ||
            !domainPart.Contains('.', StringComparison.Ordinal) ||
            domainPart.StartsWith('.') ||
            domainPart.EndsWith('.') ||
            normalized.Contains("..", StringComparison.Ordinal))
        {
            return new FieldError(AccountFields.Email, FieldErrorReason.InvalidFormat);
        }

        return null;
    }

    private static FieldError? ValidateDisplayName(string? rawDisplayName)
    {
        if (string.IsNullOrWhiteSpace(rawDisplayName))
        {
            return new FieldError(AccountFields.DisplayName, FieldErrorReason.Required);
        }

        var trimmed = rawDisplayName.Trim();
        if (trimmed.Length > AccountRules.DisplayNameMaxLength)
        {
            return new FieldError(AccountFields.DisplayName, FieldErrorReason.TooLong);
        }

        foreach (var c in trimmed)
        {
            var category = char.GetUnicodeCategory(c);
            if (category is UnicodeCategory.Control
                or UnicodeCategory.Format
                or UnicodeCategory.LineSeparator
                or UnicodeCategory.ParagraphSeparator
                or UnicodeCategory.Surrogate)
            {
                return new FieldError(AccountFields.DisplayName, FieldErrorReason.InvalidCharacters);
            }
        }

        if (AccountRules.IsReservedDisplayName(trimmed))
        {
            return new FieldError(AccountFields.DisplayName, FieldErrorReason.Reserved);
        }

        return null;
    }

    private static FieldError? ValidateRegisterPassword(string? password)
    {
        if (string.IsNullOrEmpty(password))
        {
            return new FieldError(AccountFields.Password, FieldErrorReason.Required);
        }

        if (password.Length < AccountRules.PasswordMinLength)
        {
            return new FieldError(AccountFields.Password, FieldErrorReason.TooShort);
        }

        if (password.Length > AccountRules.PasswordMaxLength)
        {
            return new FieldError(AccountFields.Password, FieldErrorReason.TooLong);
        }

        return null;
    }

    private static bool IsAllowedUsernameChar(char c) =>
        c is (>= 'a' and <= 'z') or (>= 'A' and <= 'Z') or (>= '0' and <= '9') or '-';

    private static bool IsAllowedEmailChar(char c) =>
        c is (>= 'a' and <= 'z')
            or (>= 'A' and <= 'Z')
            or (>= '0' and <= '9')
            or '.'
            or '_'
            or '%'
            or '+'
            or '-'
            or '@';
}