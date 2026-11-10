namespace GitDiwaa.Online.Accounts.Contracts;

public enum FieldErrorReason
{
    Unknown,
    Required,
    TooShort,
    TooLong,
    InvalidCharacters,
    InvalidFormat,
    Taken,
    Reserved
}

public sealed record FieldError(
    string Field,
    FieldErrorReason Reason);