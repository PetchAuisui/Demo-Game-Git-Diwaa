namespace GitDiwaa.Online.Accounts.Contracts;

public sealed record ApiError(
    AuthErrorCode Code,
    IReadOnlyList<FieldError> FieldErrors);