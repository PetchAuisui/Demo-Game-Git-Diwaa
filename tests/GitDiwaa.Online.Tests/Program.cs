using System.Globalization;
using GitDiwaa.Online.Accounts;
using GitDiwaa.Online.Accounts.Contracts;

namespace GitDiwaa.Online.Tests;

internal static class Program
{
    private static int Main()
    {
        var runner = new TestRunner();

        runner.Run("Skeleton_RunnerWorks", static () =>
        {
            Assert.True(true, "Test runner skeleton is operational.");
        });

        runner.Run("AccountRules_HasExpectedConstants", static () =>
        {
            Assert.Equal(3, AccountRules.UsernameMinLength);
            Assert.Equal(20, AccountRules.UsernameMaxLength);
            Assert.Equal(254, AccountRules.EmailMaxLength);
            Assert.Equal(64, AccountRules.EmailLocalPartMaxLength);
            Assert.Equal(1, AccountRules.DisplayNameMinLength);
            Assert.Equal(50, AccountRules.DisplayNameMaxLength);
            Assert.Equal(8, AccountRules.PasswordMinLength);
            Assert.Equal(128, AccountRules.PasswordMaxLength);
            Assert.Equal(254, AccountRules.LoginIdentifierMaxLength);
        });

        runner.Run("NormalizeUsername_TrimsAndLowercases", static () =>
        {
            Assert.Equal("abc", AccountNormalizer.NormalizeUsername(" ABC "));
        });

        runner.Run("NormalizeEmail_TrimsAndLowercases", static () =>
        {
            Assert.Equal("a@b.com", AccountNormalizer.NormalizeEmail(" A@B.COM "));
        });

        runner.Run("NormalizeUsername_WhitespaceOnly_ReturnsEmpty", static () =>
        {
            Assert.Equal("", AccountNormalizer.NormalizeUsername("   "));
        });

        runner.Run("NormalizeUsername_IsCultureInvariant", static () =>
        {
            var original = CultureInfo.CurrentCulture;
            try
            {
                CultureInfo.CurrentCulture = new CultureInfo("tr-TR");
                Assert.Equal("title", AccountNormalizer.NormalizeUsername("TITLE"));
            }
            finally
            {
                CultureInfo.CurrentCulture = original;
            }
        });

        runner.Run("NormalizeUsername_Null_Throws", static () =>
        {
            Assert.Throws<ArgumentNullException>(() => AccountNormalizer.NormalizeUsername(null!));
        });

        runner.Run("NormalizeEmail_Null_Throws", static () =>
        {
            Assert.Throws<ArgumentNullException>(() => AccountNormalizer.NormalizeEmail(null!));
        });

        runner.Run("RegisterRequest_ToString_HidesPassword", static () =>
        {
            var request = new RegisterRequest("mage01", "Arch Mage", "mage@example.com", "S3cret-Pass!");
            var text = request.ToString();

            Assert.DoesNotContain(text, "S3cret-Pass!");
            Assert.DoesNotContain(text, "mage@example.com");
            Assert.Contains(text, "***");
            Assert.Contains(text, "mage01");
        });

        runner.Run("LoginRequest_ToString_HidesPassword", static () =>
        {
            var request = new LoginRequest("mage01", "S3cret-Pass!", true);
            var text = request.ToString();

            Assert.DoesNotContain(text, "S3cret-Pass!");
            Assert.Contains(text, "***");
            Assert.Contains(text, "mage01");
        });

        runner.Run("AuthErrorCode_DefaultIsUnknown", static () =>
        {
            Assert.Equal(AuthErrorCode.Unknown, default(AuthErrorCode));
        });

        runner.Run("FieldErrorReason_DefaultIsUnknown", static () =>
        {
            Assert.Equal(FieldErrorReason.Unknown, default(FieldErrorReason));
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