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
    Reserved,
    // รหัสผ่านเดาง่ายเกินไป (อยู่ในรายการยอดนิยม / ตัวเดียวซ้ำ / ช่องว่างล้วน / เหมือนชื่อผู้ใช้หรืออีเมล)
    TooCommon
}

public sealed record FieldError(
    string Field,
    FieldErrorReason Reason);