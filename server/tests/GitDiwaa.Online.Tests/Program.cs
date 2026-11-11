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

        runner.Run("LoginRequest_ToString_HidesEmailIdentifier", static () =>
        {
            var text = new LoginRequest("mage@example.com", "S3cret-Pass!", false).ToString();

            Assert.DoesNotContain(text, "mage@example.com");
            Assert.DoesNotContain(text, "S3cret-Pass!");
        });

        runner.Run("AuthErrorCode_DefaultIsUnknown", static () =>
        {
            Assert.Equal(AuthErrorCode.Unknown, default(AuthErrorCode));
        });

        runner.Run("FieldErrorReason_DefaultIsUnknown", static () =>
        {
            Assert.Equal(FieldErrorReason.Unknown, default(FieldErrorReason));
        });

        runner.Run("FieldErrorReason_HasTaken", static () =>
        {
            Assert.Equal("Taken", FieldErrorReason.Taken.ToString());
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
            // ไม่ใส่ชื่อที่แสดงได้ (server ตั้งให้)
            AssertValid(AccountInputValidator.ValidateRegister(Valid with { DisplayName = "   " }));
            AssertValid(AccountInputValidator.ValidateRegister(Valid with { DisplayName = null }));

            // ชื่อรูปแบบที่ระบบสงวนไว้
            foreach (var reserved in new[] { "player-12", "PLAYER-7", "Ｐｌａｙｅｒ-５", " player-1 " })
            {
                AssertFieldError(
                    AccountInputValidator.ValidateRegister(Valid with { DisplayName = reserved }),
                    AccountFields.DisplayName,
                    FieldErrorReason.Reserved);
            }

            AssertValid(AccountInputValidator.ValidateRegister(Valid with { DisplayName = "player" }));
            AssertValid(AccountInputValidator.ValidateRegister(Valid with { DisplayName = "player-" }));
            AssertValid(AccountInputValidator.ValidateRegister(Valid with { DisplayName = "player-one" }));

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

        runner.Run("ValidatePasswordStrength_Cases", static () =>
        {
            static FieldErrorReason? Reason(string password, string username = "mage01", string email = "mage@example.com") =>
                AccountInputValidator.ValidatePasswordStrength(password, username, email)?.Reason;

            Assert.Equal<FieldErrorReason?>(FieldErrorReason.TooCommon, Reason("12345678"));
            Assert.Equal<FieldErrorReason?>(FieldErrorReason.TooCommon, Reason("PassWord123"));
            Assert.Equal<FieldErrorReason?>(FieldErrorReason.TooCommon, Reason("  password  "));
            Assert.Equal<FieldErrorReason?>(FieldErrorReason.TooCommon, Reason("        "));
            Assert.Equal<FieldErrorReason?>(FieldErrorReason.TooCommon, Reason("zzzzzzzzzz"));
            Assert.Equal<FieldErrorReason?>(FieldErrorReason.TooCommon, Reason("MAGE0123", username: "mage0123"));
            Assert.Equal<FieldErrorReason?>(FieldErrorReason.TooCommon, Reason("someone1", email: "someone1@example.com"));
            Assert.Equal<FieldErrorReason?>(FieldErrorReason.TooCommon, Reason("someone1@example.com", email: "someone1@example.com"));
            Assert.Equal<FieldErrorReason?>(null, Reason("S3cret-Pass!"));
            Assert.Equal<FieldErrorReason?>(null, Reason("correct horse battery"));
        });

        runner.Run("ValidateRegister_AllEmpty_ReturnsThreeRequiredErrors", static () =>
        {
            // ชื่อที่แสดงไม่บังคับแล้ว (server ตั้งให้) จึงเหลือ 3 ช่องที่บังคับ
            var errors = AccountInputValidator.ValidateRegister(new RegisterRequest("", "", "", ""));
            Assert.Equal(3, errors.Count);
            AssertFieldError(errors, AccountFields.Username, FieldErrorReason.Required);
            AssertFieldError(errors, AccountFields.Email, FieldErrorReason.Required);
            AssertFieldError(errors, AccountFields.Password, FieldErrorReason.Required);
        });

        // --- Step 1.5: ValidateLogin & Identifier Tests ---

        runner.Run("ValidateLogin_NullRequest_Throws", static () =>
        {
            Assert.Throws<ArgumentNullException>(() => AccountInputValidator.ValidateLogin(null!));
        });

        runner.Run("ValidateLogin_Valid_Passes", static () =>
        {
            AssertValid(AccountInputValidator.ValidateLogin(new LoginRequest("validuser", "validpass", false)));
        });

        runner.Run("ValidateLogin_DoesNotRevealRegisterRules", static () =>
        {
            string[] identifiers = ["ab", "\u0430bc", "-x-", "a b"];
            foreach (var identifier in identifiers)
            {
                AssertValid(AccountInputValidator.ValidateLogin(new LoginRequest(identifier, "S3cret-Pass!", false)));
            }

            AssertValid(AccountInputValidator.ValidateLogin(new LoginRequest("mage01", "short", false)));
            AssertValid(AccountInputValidator.ValidateLogin(new LoginRequest("ab", "p", true)));
        });

        runner.Run("ValidateLogin_RequiredAndTooLong_Errors", static () =>
        {
            var emptyErrors = AccountInputValidator.ValidateLogin(new LoginRequest("   ", "", false));
            Assert.Equal(2, emptyErrors.Count);
            AssertFieldError(emptyErrors, AccountFields.Identifier, FieldErrorReason.Required);
            AssertFieldError(emptyErrors, AccountFields.Password, FieldErrorReason.Required);

            var tooLongIdentifier = new string('x', 255);
            var tooLongPassword = new string('y', 129);
            var longErrors = AccountInputValidator.ValidateLogin(new LoginRequest(tooLongIdentifier, tooLongPassword, false));
            Assert.Equal(2, longErrors.Count);
            AssertFieldError(longErrors, AccountFields.Identifier, FieldErrorReason.TooLong);
            AssertFieldError(longErrors, AccountFields.Password, FieldErrorReason.TooLong);
        });

        runner.Run("AccountNormalizer_IsEmailIdentifier_And_NormalizeIdentifier", static () =>
        {
            Assert.Throws<ArgumentNullException>(() => AccountNormalizer.IsEmailIdentifier(null!));
            Assert.True(AccountNormalizer.IsEmailIdentifier("user@example.com"));
            Assert.True(AccountNormalizer.IsEmailIdentifier("@"));
            Assert.False(AccountNormalizer.IsEmailIdentifier("username"));

            Assert.Equal("user@example.com", AccountNormalizer.NormalizeIdentifier(" USER@EXAMPLE.COM "));
            Assert.Equal("username", AccountNormalizer.NormalizeIdentifier(" USERNAME "));
        });

        // --- Commit S1: NormalizeDisplayNameKey Tests ---

        runner.Run("NormalizeDisplayNameKey_CaseInsensitive_ProducesSameKey", static () =>
        {
            string key1 = AccountNormalizer.NormalizeDisplayNameKey("Hero");
            string key2 = AccountNormalizer.NormalizeDisplayNameKey("hero");

            Assert.Equal(key1, key2);
            Assert.Equal("hero", key1);
        });

        runner.Run("NormalizeDisplayNameKey_CollapsesExtraWhitespaceAndTrims", static () =>
        {
            string key = AccountNormalizer.NormalizeDisplayNameKey("  ผู้กล้า   01 ");
            Assert.Equal("ผู้กล้า 01", key);
        });

        runner.Run("NormalizeDisplayNameKey_NormalizesThaiSaraAmEquivalents", static () =>
        {
            // \u0E33 (Sara Am) vs \u0E4D\u0E32 (Nikhahit + Sara Aa)
            string key1 = AccountNormalizer.NormalizeDisplayNameKey("\u0E33");
            string key2 = AccountNormalizer.NormalizeDisplayNameKey("\u0E4D\u0E32");

            Assert.Equal(key1, key2);
        });

        runner.Run("NormalizeDisplayNameKey_ConvertsFullWidthToStandardAscii", static () =>
        {
            // Full-width "Ｈｅｒｏ" -> "hero"
            string key = AccountNormalizer.NormalizeDisplayNameKey("Ｈｅｒｏ");
            Assert.Equal("hero", key);
        });

        runner.Run("NormalizeDisplayNameKey_DifferentNamesProduceDifferentKeys", static () =>
        {
            string key1 = AccountNormalizer.NormalizeDisplayNameKey("ผู้กล้า");
            string key2 = AccountNormalizer.NormalizeDisplayNameKey("ผู้กล้า1");

            Assert.False(key1 == key2, "Expected different keys for different display names.");
        });

        runner.Run("NormalizeDisplayNameKey_Null_Throws", static () =>
        {
            Assert.Throws<ArgumentNullException>(() => AccountNormalizer.NormalizeDisplayNameKey(null!));
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