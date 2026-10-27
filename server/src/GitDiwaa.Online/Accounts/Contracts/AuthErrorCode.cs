namespace GitDiwaa.Online.Accounts.Contracts;

public enum AuthErrorCode
{
    Unknown,
    InvalidCredentials,
    ValidationFailed,
    IdentifierTaken,
    RateLimited,
    NetworkUnavailable,
    ServerError
}