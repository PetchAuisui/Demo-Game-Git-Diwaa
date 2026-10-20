using System.Net;
using System.Security.Cryptography;
using GitDiwaa.Online.Accounts;
using GitDiwaa.Server;
using GitDiwaa.Server.Security;
using Microsoft.AspNetCore.Hosting.Server;
using Microsoft.AspNetCore.Hosting.Server.Features;
using Microsoft.Extensions.DependencyInjection;

namespace GitDiwaa.Server.Tests;

internal static class Program
{
    private static async Task<int> Main()
    {
        var runner = new TestRunner();

        await runner.RunAsync("Health_ReturnsOk", async static () =>
        {
            var app = ServerApp.Build(["--Logging:LogLevel:Default=Warning"], "Development");
            app.Urls.Add("http://127.0.0.1:0");

            try
            {
                await app.StartAsync();

                var serverAddresses = app.Services
                    .GetRequiredService<IServer>()
                    .Features
                    .Get<IServerAddressesFeature>();

                var boundAddress = serverAddresses?.Addresses.FirstOrDefault() ?? app.Urls.First();

                using var client = new HttpClient { BaseAddress = new Uri(boundAddress) };
                var response = await client.GetAsync("/health");

                Assert.Equal(HttpStatusCode.OK, response.StatusCode);

                var content = await response.Content.ReadAsStringAsync();
                Assert.Contains(content, "ok");
                Assert.DoesNotContain(content, "version");
            }
            finally
            {
                await app.StopAsync();
                await app.DisposeAsync();
            }
        });

        // --- Step 2.2: PasswordHasher Tests (12 ข้อ + Health 1 ข้อ = 13 ข้อ) ---

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

        return runner.Complete();
    }
}

internal sealed class TestRunner
{
    private int _passed;
    private int _failed;

    public void Run(string name, Action test)
    {
        try
        {
            test();
            _passed++;
            Console.WriteLine($"[PASS] {name}");
        }
        catch (Exception ex)
        {
            _failed++;
            Console.WriteLine($"[FAIL] {name}: {ex.GetType().Name}: {ex.Message}");
        }
    }

    public async Task RunAsync(string name, Func<Task> test)
    {
        try
        {
            await test();
            _passed++;
            Console.WriteLine($"[PASS] {name}");
        }
        catch (Exception ex)
        {
            _failed++;
            Console.WriteLine($"[FAIL] {name}: {ex.GetType().Name}: {ex.Message}");
        }
    }

    public int Complete()
    {
        var total = _passed + _failed;
        Console.WriteLine($"Total: {total}, Passed: {_passed}, Failed: {_failed}");
        return total > 0 && _failed == 0 ? 0 : 1;
    }
}

internal static class Assert
{
    public static void True(bool condition, string message = "Expected condition to be true.")
    {
        if (!condition)
        {
            throw new InvalidOperationException(message);
        }
    }

    public static void False(bool condition, string message = "Expected condition to be false.")
    {
        if (condition)
        {
            throw new InvalidOperationException(message);
        }
    }

    public static void Equal<T>(T expected, T actual, string? message = null)
    {
        if (!EqualityComparer<T>.Default.Equals(expected, actual))
        {
            throw new InvalidOperationException(message ?? $"Expected '{expected}', but got '{actual}'.");
        }
    }

    public static void Contains(string text, string expected)
    {
        if (!text.Contains(expected, StringComparison.Ordinal))
        {
            throw new InvalidOperationException($"Expected '{text}' to contain '{expected}'.");
        }
    }

    public static void DoesNotContain(string text, string unexpected)
    {
        if (text.Contains(unexpected, StringComparison.Ordinal))
        {
            throw new InvalidOperationException($"Expected '{text}' NOT to contain '{unexpected}'.");
        }
    }

    public static void Throws<TException>(Action action) where TException : Exception
    {
        try
        {
            action();
        }
        catch (TException)
        {
            return;
        }
        throw new InvalidOperationException($"Expected {typeof(TException).Name} but nothing (or another type) was thrown.");
    }
}