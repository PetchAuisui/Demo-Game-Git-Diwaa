namespace GitDiwaa.Online.Accounts;

public static class AccountRules
{
    public const int UsernameMinLength = 3;
    public const int UsernameMaxLength = 20;

    public const int EmailMaxLength = 254;
    public const int EmailLocalPartMaxLength = 64;

    public const int DisplayNameMinLength = 1;
    public const int DisplayNameMaxLength = 50;

    public const int PasswordMinLength = 8;
    public const int PasswordMaxLength = 128;

    public const int LoginIdentifierMaxLength = 254;
}