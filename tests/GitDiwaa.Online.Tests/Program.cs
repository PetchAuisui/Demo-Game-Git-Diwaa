using System.Globalization;
using GitDiwaa.Online.Accounts;
using GitDiwaa.Online.Accounts.Contracts;

namespace GitDiwaa.Online.Tests;

internal static class Program
{
    private static readonly RegisterRequest Valid = new("mage01", "นักเวท", "mage@example.com", "S3cret-Pass!");

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

        // --- Step 1.4: ValidateRegister Tests ---

        runner.Run("ValidateRegister_NullRequest_Throws", static () =>
        {
            Assert.Throws<ArgumentNullException>(() => AccountInputValidator.ValidateRegister(null!));
        });

        runner.Run("ValidateRegister_BaselineValid_Passes", static () =>
        {
            AssertValid(AccountInputValidator.ValidateRegister(Valid));
        });

        runner.Run("ValidateRegister_Username_RequiredAndLength", static () =>
        {
            AssertFieldError(
                AccountInputValidator.ValidateRegister(Valid with { Username = null! }),
                AccountFields.Username,
                FieldErrorReason.Required);

            AssertFieldError(
                AccountInputValidator.ValidateRegister(Valid with { Username = "ab" }),
                AccountFields.Username,
                FieldErrorReason.TooShort);

            AssertFieldError(
                AccountInputValidator.ValidateRegister(Valid with { Username = new string('a', 21) }),
                AccountFields.Username,
                FieldErrorReason.TooLong);
        });

        runner.Run("ValidateRegister_Username_InvalidFormat", static () =>
        {
            AssertFieldError(
                AccountInputValidator.ValidateRegister(Valid with { Username = "-abc" }),
                AccountFields.Username,
                FieldErrorReason.InvalidFormat);

            AssertFieldError(
                AccountInputValidator.ValidateRegister(Valid with { Username = "abc-" }),
                AccountFields.Username,
                FieldErrorReason.InvalidFormat);
        });

        runner.Run("ValidateRegister_Username_InvalidCharacters", static () =>
        {
            string[] invalidCharUsernames =
            [
                "../x",
                "a b",
                "ab\nc",
                "\u0430bc", // Cyrillic small letter 'a' (U+0430)
                "\u212Aing" // Kelvin sign K (U+212A)
            ];

            foreach (var username in invalidCharUsernames)
            {
                AssertFieldError(
                    AccountInputValidator.ValidateRegister(Valid with { Username = username }),
                    AccountFields.Username,
                    FieldErrorReason.InvalidCharacters);
            }
        });

        runner.Run("ValidateRegister_Username_ValidCases", static () =>
        {
            string[] validUsernames =
            [
                " ABC ",
                "a-b-c",
                new string('a', 20),
                "abc\n" // trailing newline is trimmed; stored value "abc" has no newline
            ];

            foreach (var username in validUsernames)
            {
                AssertValid(AccountInputValidator.ValidateRegister(Valid with { Username = username }));
            }
        });

        runner.Run("ValidateRegister_Email_RequiredAndTooLong", static () =>
        {
            AssertFieldError(
                AccountInputValidator.ValidateRegister(Valid with { Email = null! }),
                AccountFields.Email,
                FieldErrorReason.Required);

            var email255 = new string('a', 64) + "@" + new string('b', 186) + ".com";
            Assert.Equal(255, email255.Length);
            AssertFieldError(
                AccountInputValidator.ValidateRegister(Valid with { Email = email255 }),
                AccountFields.Email,
                FieldErrorReason.TooLong);
        });

        runner.Run("ValidateRegister_Email_InvalidCharacters", static () =>
        {
            AssertFieldError(
                AccountInputValidator.ValidateRegister(Valid with { Email = "มาย@b.com" }),
                AccountFields.Email,
                FieldErrorReason.InvalidCharacters);

            AssertFieldError(
                AccountInputValidator.ValidateRegister(Valid with { Email = "Name <a@b.com>" }),
                AccountFields.Email,
                FieldErrorReason.InvalidCharacters);
        });

        runner.Run("ValidateRegister_Email_InvalidFormat", static () =>
        {
            string[] invalidFormatEmails =
            [
                "mage.example.com",
                "a@@b.com",
                "a@b",
                "a@.b.com",
                "a@b..com",
                ".a@b.com",
                "a.@b.com"
            ];

            foreach (var email in invalidFormatEmails)
            {
                AssertFieldError(
                    AccountInputValidator.ValidateRegister(Valid with { Email = email }),
                    AccountFields.Email,
                    FieldErrorReason.InvalidFormat);
            }
        });

        runner.Run("ValidateRegister_DisplayName_Cases", static () =>
        {
            AssertFieldError(
                AccountInputValidator.ValidateRegister(Valid with { DisplayName = "   " }),
                AccountFields.DisplayName,
                FieldErrorReason.Required);

            AssertFieldError(
                AccountInputValidator.ValidateRegister(Valid with { DisplayName = new string('ก', 51) }),
                AccountFields.DisplayName,
                FieldErrorReason.TooLong);

            string[] invalidCharNames =
            [
                "mage\u202E",
                "mage\u200B",
                "mage\nname"
            ];

            foreach (var name in invalidCharNames)
            {
                AssertFieldError(
                    AccountInputValidator.ValidateRegister(Valid with { DisplayName = name }),
                    AccountFields.DisplayName,
                    FieldErrorReason.InvalidCharacters);
            }

            AssertValid(AccountInputValidator.ValidateRegister(Valid with { DisplayName = "นักเวท" }));
        });

        runner.Run("ValidateRegister_Password_Cases", static () =>
        {
            AssertFieldError(
                AccountInputValidator.ValidateRegister(Valid with { Password = "" }),
                AccountFields.Password,
                FieldErrorReason.Required);

            AssertFieldError(
                AccountInputValidator.ValidateRegister(Valid with { Password = new string('p', 7) }),
                AccountFields.Password,
                FieldErrorReason.TooShort);

            AssertValid(AccountInputValidator.ValidateRegister(Valid with { Password = new string('p', 8) }));
            AssertValid(AccountInputValidator.ValidateRegister(Valid with { Password = new string('p', 128) }));

            AssertFieldError(
                AccountInputValidator.ValidateRegister(Valid with { Password = new string('p', 129) }),
                AccountFields.Password,
                FieldErrorReason.TooLong);

            AssertValid(AccountInputValidator.ValidateRegister(Valid with { Password = " abc12345 " }));
        });

        runner.Run("ValidateRegister_AllEmpty_ReturnsFourRequiredErrors", static () =>
        {
            var errors = AccountInputValidator.ValidateRegister(new RegisterRequest("", "", "", ""));
            Assert.Equal(4, errors.Count);
            AssertFieldError(errors, AccountFields.Username, FieldErrorReason.Required);
            AssertFieldError(errors, AccountFields.DisplayName, FieldErrorReason.Required);
            AssertFieldError(errors, AccountFields.Email, FieldErrorReason.Required);
            AssertFieldError(errors, AccountFields.Password, FieldErrorReason.Required);
        });

        return runner.Complete();
    }

    private static void AssertValid(IReadOnlyList<FieldError> errors)
    {
        Assert.Equal(0, errors.Count, $"Expected 0 errors, but got {errors.Count}: {string.Join(", ", errors)}");
    }

    private static void AssertFieldError(IReadOnlyList<FieldError> errors, string field, FieldErrorReason reason)
    {
        foreach (var error in errors)
        {
            if (error.Field == field && error.Reason == reason)
            {
                return;
            }
        }

        throw new InvalidOperationException(
            $"Expected FieldError({field}, {reason}), but got: [{string.Join(", ", errors)}]");
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