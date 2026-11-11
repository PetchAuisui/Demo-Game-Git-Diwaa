using System.Globalization;
using System.Security.Cryptography;
using GitDiwaa.Online.Accounts;

namespace GitDiwaa.Server.Security;

public sealed class PasswordHasher
{
    public const string Algorithm = "pbkdf2-sha256";
    public const int Iterations = 600_000;
    public const int SaltSize = 16;
    public const int HashSize = 32;

    public const int MinIterations = 100_000;
    public const int MaxIterations = 10_000_000;

    private static readonly Lazy<string> LazyDummyHash = new(static () =>
    {
        var hasher = new PasswordHasher();
        return hasher.Hash(Convert.ToHexString(RandomNumberGenerator.GetBytes(16)));
    });

    public string DummyHash => LazyDummyHash.Value;

    // PBKDF2 600,000 รอบกิน CPU หลายร้อย ms ต่อครั้ง: จำกัดจำนวนที่คำนวณพร้อมกันไว้เท่าจำนวน core
    // คำขอที่เกินจะรอคิวแบบไม่กิน thread (await) ทั้งห้องสมัครพร้อมกันจึงไม่แย่ง thread ของ /health และ /me จนตอบไม่ทัน
    private static readonly SemaphoreSlim HashSlots = new(Math.Max(1, Environment.ProcessorCount));

    public async Task<string> HashAsync(string password, CancellationToken ct = default)
    {
        await HashSlots.WaitAsync(ct);
        try
        {
            return await Task.Run(() => Hash(password), ct);
        }
        finally
        {
            HashSlots.Release();
        }
    }

    public async Task<bool> VerifyAsync(string? password, string? storedHash, CancellationToken ct = default)
    {
        await HashSlots.WaitAsync(ct);
        try
        {
            return await Task.Run(() => Verify(password, storedHash), ct);
        }
        finally
        {
            HashSlots.Release();
        }
    }

    public string Hash(string password)
    {
        ArgumentNullException.ThrowIfNull(password);

        if (password.Length > AccountRules.PasswordMaxLength)
        {
            throw new ArgumentException(
                $"Password exceeds maximum allowed length of {AccountRules.PasswordMaxLength}.",
                nameof(password));
        }

        byte[] salt = RandomNumberGenerator.GetBytes(SaltSize);
        byte[] hash = Rfc2898DeriveBytes.Pbkdf2(
            password,
            salt,
            Iterations,
            HashAlgorithmName.SHA256,
            HashSize);

        return string.Create(
            CultureInfo.InvariantCulture,
            $"{Algorithm}${Iterations}${Convert.ToBase64String(salt)}${Convert.ToBase64String(hash)}");
    }

    public bool Verify(string? password, string? storedHash)
    {
        if (string.IsNullOrEmpty(password) || string.IsNullOrEmpty(storedHash))
        {
            return false;
        }

        if (password.Length > AccountRules.PasswordMaxLength)
        {
            return false;
        }

        string[] parts = storedHash.Split('$');
        if (parts.Length != 4)
        {
            return false;
        }

        if (!string.Equals(parts[0], Algorithm, StringComparison.Ordinal))
        {
            return false;
        }

        if (!int.TryParse(parts[1], NumberStyles.None, CultureInfo.InvariantCulture, out int iterations))
        {
            return false;
        }

        if (iterations < MinIterations || iterations > MaxIterations)
        {
            return false;
        }

        Span<byte> salt = stackalloc byte[SaltSize];
        if (!Convert.TryFromBase64String(parts[2], salt, out int saltBytesWritten) || saltBytesWritten != SaltSize)
        {
            return false;
        }

        Span<byte> expectedHash = stackalloc byte[HashSize];
        if (!Convert.TryFromBase64String(parts[3], expectedHash, out int hashBytesWritten) || hashBytesWritten != HashSize)
        {
            return false;
        }

        byte[] actualHash = Rfc2898DeriveBytes.Pbkdf2(
            password,
            salt,
            iterations,
            HashAlgorithmName.SHA256,
            HashSize);

        return CryptographicOperations.FixedTimeEquals(actualHash, expectedHash);
    }

    public bool NeedsRehash(string? storedHash)
    {
        if (string.IsNullOrEmpty(storedHash))
        {
            return true;
        }

        string[] parts = storedHash.Split('$');
        if (parts.Length != 4)
        {
            return true;
        }

        if (!string.Equals(parts[0], Algorithm, StringComparison.Ordinal))
        {
            return true;
        }

        if (!int.TryParse(parts[1], NumberStyles.None, CultureInfo.InvariantCulture, out int iterations))
        {
            return true;
        }

        return iterations < Iterations;
    }
}