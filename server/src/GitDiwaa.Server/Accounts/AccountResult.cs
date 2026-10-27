using GitDiwaa.Online.Accounts.Contracts;

namespace GitDiwaa.Server.Accounts;

public sealed record AccountResult<T>(T? Value, AuthErrorCode? Error, IReadOnlyList<FieldError> FieldErrors)
{
    public bool Succeeded => Error is null;

    public static AccountResult<T> Success(T value) => new(value, null, []);

    public static AccountResult<T> Failure(AuthErrorCode error, IReadOnlyList<FieldError>? fieldErrors = null) =>
        new(default, error, fieldErrors ?? []);
}