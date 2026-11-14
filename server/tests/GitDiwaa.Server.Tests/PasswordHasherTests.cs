using System.Security.Cryptography;
using GitDiwaa.Online.Accounts;
using GitDiwaa.Server.Security;

namespace GitDiwaa.Server.Tests;

internal static class PasswordHasherTests
{
    public static void Run(TestRunner runner)
    {
        runner.Run("Hash_HasExpectedFormat", static () =>
        {
            var hasher = new PasswordHasher();
            var hash = hasher.Hash("S3cret-Pass!");
            var parts = hash.Split('$');

            Assert.Equal(4, parts.Length);
            Assert.Equal(PasswordHasher.Algorithm, parts[0]);
            Assert.Equal("600000", parts[1]);

            var saltBytes = Convert.FromBase64String(parts[2]);
            Assert.Equal(PasswordHasher.SaltSize, saltBytes.Length);

            var hashBytes = Convert.FromBase64String(parts[3]);
            Assert.Equal(PasswordHasher.HashSize, hashBytes.Length);
        });

        runner.Run("Hash_DoesNotContainPassword", static () =>
        {
            var hasher = new PasswordHasher();
            var hash = hasher.Hash("S3cret-Pass!");

            Assert.DoesNotContain(hash, "S3cret-Pass!");
        });

        runner.Run("Hash_SamePasswordTwice_Differs", static () =>
        {
            var hasher = new PasswordHasher();
            var hash1 = hasher.Hash("S3cret-Pass!");
            var hash2 = hasher.Hash("S3cret-Pass!");

            Assert.False(string.Equals(hash1, hash2, StringComparison.Ordinal), "Two hashes of same password must differ due to salt.");
        });

        runner.Run("Verify_CorrectPassword_True", static () =>
        {
            var hasher = new PasswordHasher();
            var hash = hasher.Hash("MySecurePassword123!");

            Assert.True(hasher.Verify("MySecurePassword123!", hash));
        });

        runner.Run("Verify_WrongPassword_False", static () =>
        {
            var hasher = new PasswordHasher();
            var hash = hasher.Hash("MySecurePassword123!");

            Assert.False(hasher.Verify("WrongPassword456!", hash));
        });

        runner.Run("Verify_IsCaseAndWhitespaceSensitive", static () =>
        {
            var hasher = new PasswordHasher();
            var hashCase = hasher.Hash("Password1");
            Assert.False(hasher.Verify("password1", hashCase));

            var hashSpace = hasher.Hash(" pass12345 ");
            Assert.False(hasher.Verify("pass12345", hashSpace));
            Assert.True(hasher.Verify(" pass12345 ", hashSpace));
        });

        runner.Run("Verify_ThaiPassword_RoundTrips", static () =>
        {
            var hasher = new PasswordHasher();
            var hash = hasher.Hash("รหัสลับของนักเวท");

            Assert.True(hasher.Verify("รหัสลับของนักเวท", hash));
            Assert.False(hasher.Verify("รหัสลับของนักรบ", hash));
        });

        runner.Run("Verify_Malformed_ReturnsFalseWithoutThrowing", static () =>
        {
            var hasher = new PasswordHasher();
            string[] malformed =
            [
                "",
                "abc",
                "md5$600000$AAAA$AAAA",
                "pbkdf2-sha256$abc$AAAA$AAAA",
                "pbkdf2-sha256$1$AAAA$AAAA",
                "pbkdf2-sha256$999999999$AAAA$AAAA",
                "pbkdf2-sha256$600000$bad-base64!$AAAA",
                "pbkdf2-sha256$600000$AAAA$bad-base64!",
                "pbkdf2-sha256$600000$AAAA$AAAA$extra"
            ];

            foreach (var hash in malformed)
            {
                Assert.False(hasher.Verify("password", hash));
            }
        });

        runner.Run("Verify_TooLongPassword_False", static () =>
        {
            var hasher = new PasswordHasher();
            var hash = hasher.Hash("validpassword");
            var tooLongPass = new string('x', AccountRules.PasswordMaxLength + 1);

            Assert.False(hasher.Verify(tooLongPass, hash));
        });

        runner.Run("NeedsRehash_Current_False_Old_True", static () =>
        {
            var hasher = new PasswordHasher();
            var currentHash = hasher.Hash("password");
            Assert.False(hasher.NeedsRehash(currentHash));

            byte[] salt = RandomNumberGenerator.GetBytes(PasswordHasher.SaltSize);
            byte[] hashBytes = Rfc2898DeriveBytes.Pbkdf2(
                "password",
                salt,
                100_000,
                HashAlgorithmName.SHA256,
                PasswordHasher.HashSize);

            var oldHash = $"pbkdf2-sha256$100000${Convert.ToBase64String(salt)}${Convert.ToBase64String(hashBytes)}";
            Assert.True(hasher.NeedsRehash(oldHash));
            Assert.True(hasher.Verify("password", oldHash));

            Assert.True(hasher.NeedsRehash("malformed-hash"));
        });

        runner.Run("Hash_TooLongOrNullPassword_Throws", static () =>
        {
            var hasher = new PasswordHasher();
            Assert.Throws<ArgumentException>(() => hasher.Hash(new string('x', AccountRules.PasswordMaxLength + 1)));
            Assert.Throws<ArgumentNullException>(() => hasher.Hash(null!));
        });

        runner.Run("DummyHash_IsStableAndValid", static () =>
        {
            var hasher = new PasswordHasher();
            var dummy = hasher.DummyHash;
            Assert.Equal(dummy, new PasswordHasher().DummyHash);
            Assert.False(hasher.NeedsRehash(dummy));
            Assert.False(hasher.Verify("S3cret-Pass!", dummy));
        });
    }
}