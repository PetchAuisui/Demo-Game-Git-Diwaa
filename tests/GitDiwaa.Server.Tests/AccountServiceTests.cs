using System.Security.Cryptography;
using GitDiwaa.Online.Accounts.Contracts;
using GitDiwaa.Server.Accounts;
using GitDiwaa.Server.Persistence;
using GitDiwaa.Server.Security;

namespace GitDiwaa.Server.Tests;

internal static class AccountServiceTests
{
    public static async Task RunAsync(TestRunner runner)
    {
        // --- Registration Tests (4 ข้อ) ---

        await runner.RunAsync("Register_Valid_StoresNormalizedUser", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var request = new RegisterRequest(" Mage01 ", " Arch Mage ", " Mage@Example.COM ", "S3cret-Pass!");
            var result = await ctx.Service.RegisterAsync(request);

            Assert.True(result.Succeeded);
            Assert.Equal(null, result.Error);
            Assert.Equal("mage01", result.Value?.Username);
            Assert.Equal("Arch Mage", result.Value?.DisplayName);

            var storedUser = await ctx.Users.FindByIdAsync(result.Value!.Id);
            Assert.Equal("mage01", storedUser?.Username);
            Assert.Equal("Mage@Example.COM", storedUser?.Email);
            Assert.Equal("mage@example.com", storedUser?.EmailNormalized);
            Assert.Equal("Arch Mage", storedUser?.DisplayName);
            Assert.True(ctx.Hasher.Verify("S3cret-Pass!", storedUser?.PasswordHash));
        });

        await runner.RunAsync("Register_Invalid_ReturnsFieldErrors_StoresNothing", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var request = new RegisterRequest("ab", "Valid Name", "valid@example.com", "pass");
            var result = await ctx.Service.RegisterAsync(request);

            Assert.False(result.Succeeded);
            Assert.Equal(AuthErrorCode.ValidationFailed, result.Error);
            Assert.True(result.FieldErrors.Count >= 2);

            Assert.Equal(null, await ctx.Users.FindByUsernameAsync("ab"));
        });

        await runner.RunAsync("Register_DuplicateUsername_IdentifierTaken", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var req1 = new RegisterRequest("mage01", "Name One", "user1@example.com", "S3cret-Pass!");
            var result1 = await ctx.Service.RegisterAsync(req1);
            Assert.True(result1.Succeeded);

            var req2 = new RegisterRequest("mage01", "Name Two", "user2@example.com", "S3cret-Pass!");
            var result2 = await ctx.Service.RegisterAsync(req2);
            Assert.False(result2.Succeeded);
            Assert.Equal(AuthErrorCode.IdentifierTaken, result2.Error);
        });

        await runner.RunAsync("Register_DuplicateEmailDifferentCase_IdentifierTaken", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var req1 = new RegisterRequest("mage01", "Name One", "A@X.com", "S3cret-Pass!");
            var result1 = await ctx.Service.RegisterAsync(req1);
            Assert.True(result1.Succeeded);

            var req2 = new RegisterRequest("mage02", "Name Two", "a@x.com", "S3cret-Pass!");
            var result2 = await ctx.Service.RegisterAsync(req2);
            Assert.False(result2.Succeeded);
            Assert.Equal(AuthErrorCode.IdentifierTaken, result2.Error);
        });

        // --- Login Tests (10 ข้อ) ---

        await runner.RunAsync("Login_ByUsername_ShortSession12h", async static () =>
        {
            var ctx = AccountTestContext.Create();
            await ctx.Service.RegisterAsync(new RegisterRequest("mage01", "Mage", "mage@example.com", "S3cret-Pass!"));

            var loginResult = await ctx.Service.LoginAsync(new LoginRequest("mage01", "S3cret-Pass!", RememberMe: false));
            Assert.True(loginResult.Succeeded);
            Assert.Equal(AccountTestContext.StartTime.AddHours(12), loginResult.Value?.ExpiresAt);
            Assert.Equal("mage01", loginResult.Value?.Profile.Username);
        });

        await runner.RunAsync("Login_ByEmailCaseInsensitive_Succeeds", async static () =>
        {
            var ctx = AccountTestContext.Create();
            await ctx.Service.RegisterAsync(new RegisterRequest("mage01", "Mage", "mage@example.com", "S3cret-Pass!"));

            var loginResult = await ctx.Service.LoginAsync(new LoginRequest("MAGE@Example.com", "S3cret-Pass!", false));
            Assert.True(loginResult.Succeeded);
            Assert.Equal("mage01", loginResult.Value?.Profile.Username);
        });

        await runner.RunAsync("Login_RememberMe_Session30Days", async static () =>
        {
            var ctx = AccountTestContext.Create();
            await ctx.Service.RegisterAsync(new RegisterRequest("mage01", "Mage", "mage@example.com", "S3cret-Pass!"));

            var loginResult = await ctx.Service.LoginAsync(new LoginRequest("mage01", "S3cret-Pass!", RememberMe: true));
            Assert.True(loginResult.Succeeded);
            Assert.Equal(AccountTestContext.StartTime.AddDays(30), loginResult.Value?.ExpiresAt);
        });

        await runner.RunAsync("Login_StoresOnlyTokenHash", async static () =>
        {
            var ctx = AccountTestContext.Create();
            await ctx.Service.RegisterAsync(new RegisterRequest("mage01", "Mage", "mage@example.com", "S3cret-Pass!"));

            var loginResult = await ctx.Service.LoginAsync(new LoginRequest("mage01", "S3cret-Pass!", false));
            string rawToken = loginResult.Value!.Token;

            Assert.True(ctx.TokenService.TryHashToken(rawToken, out string tokenHash));

            var foundByHash = await ctx.Sessions.FindByTokenHashAsync(tokenHash);
            Assert.True(foundByHash is not null);

            var foundByRaw = await ctx.Sessions.FindByTokenHashAsync(rawToken);
            Assert.Equal(null, foundByRaw);
        });

        await runner.RunAsync("Login_WrongPassword_And_UnknownUser_SameError", async static () =>
        {
            var ctx = AccountTestContext.Create();
            await ctx.Service.RegisterAsync(new RegisterRequest("mage01", "Mage", "mage@example.com", "S3cret-Pass!"));

            var wrongPassResult = await ctx.Service.LoginAsync(new LoginRequest("mage01", "WrongPassword999!", false));
            Assert.False(wrongPassResult.Succeeded);
            Assert.Equal(AuthErrorCode.InvalidCredentials, wrongPassResult.Error);

            var unknownUserResult = await ctx.Service.LoginAsync(new LoginRequest("non_existent_mage", "S3cret-Pass!", false));
            Assert.False(unknownUserResult.Succeeded);
            Assert.Equal(AuthErrorCode.InvalidCredentials, unknownUserResult.Error);
        });

        await runner.RunAsync("Login_LocksAfterFiveFailures", async static () =>
        {
            var ctx = AccountTestContext.Create();
            await ctx.Service.RegisterAsync(new RegisterRequest("mage01", "Mage", "mage@example.com", "S3cret-Pass!"));

            for (int i = 0; i < 5; i++)
            {
                var fail = await ctx.Service.LoginAsync(new LoginRequest("mage01", "WrongPassword!", false));
                Assert.False(fail.Succeeded);
                Assert.Equal(AuthErrorCode.InvalidCredentials, fail.Error);
            }

            var attemptDuringLockout = await ctx.Service.LoginAsync(new LoginRequest("mage01", "S3cret-Pass!", false));
            Assert.False(attemptDuringLockout.Succeeded);
            Assert.Equal(AuthErrorCode.InvalidCredentials, attemptDuringLockout.Error);

            ctx.Time.Advance(TimeSpan.FromMinutes(15) + TimeSpan.FromSeconds(1));

            var successResult = await ctx.Service.LoginAsync(new LoginRequest("mage01", "S3cret-Pass!", false));
            Assert.True(successResult.Succeeded);

            var storedUser = await ctx.Users.FindByUsernameAsync("mage01");
            Assert.Equal(0, storedUser?.FailedLoginCount);
            Assert.Equal(null, storedUser?.LockoutUntil);
        });

        await runner.RunAsync("Login_DisabledUser_InvalidCredentials", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var reg = await ctx.Service.RegisterAsync(new RegisterRequest("mage01", "Mage", "mage@example.com", "S3cret-Pass!"));

            var user = await ctx.Users.FindByIdAsync(reg.Value!.Id);
            await ctx.Users.UpdateAsync(user! with { Status = UserStatus.Disabled });

            var loginResult = await ctx.Service.LoginAsync(new LoginRequest("mage01", "S3cret-Pass!", false));
            Assert.False(loginResult.Succeeded);
            Assert.Equal(AuthErrorCode.InvalidCredentials, loginResult.Error);
        });

        await runner.RunAsync("Login_EmptyInput_ValidationFailed", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var loginResult = await ctx.Service.LoginAsync(new LoginRequest("", "", false));

            Assert.False(loginResult.Succeeded);
            Assert.Equal(AuthErrorCode.ValidationFailed, loginResult.Error);
            Assert.True(loginResult.FieldErrors.Count >= 2);
        });

        await runner.RunAsync("Login_UpgradesOldHash", async static () =>
        {
            var ctx = AccountTestContext.Create();

            byte[] salt = RandomNumberGenerator.GetBytes(PasswordHasher.SaltSize);
            byte[] hashBytes = Rfc2898DeriveBytes.Pbkdf2(
                "S3cret-Pass!",
                salt,
                100_000,
                HashAlgorithmName.SHA256,
                PasswordHasher.HashSize);

            string oldHash = $"pbkdf2-sha256$100000${Convert.ToBase64String(salt)}${Convert.ToBase64String(hashBytes)}";

            var legacyUser = TestData.NewUser("legacy_mage", "legacy@example.com") with
            {
                PasswordHash = oldHash
            };
            await ctx.Users.TryAddAsync(legacyUser);

            var loginResult = await ctx.Service.LoginAsync(new LoginRequest("legacy_mage", "S3cret-Pass!", false));
            Assert.True(loginResult.Succeeded);

            var updatedUser = await ctx.Users.FindByUsernameAsync("legacy_mage");
            Assert.True(updatedUser is not null, "User should still exist after login.");
            Assert.True(updatedUser!.PasswordHash.StartsWith("pbkdf2-sha256$600000$", StringComparison.Ordinal));
            Assert.True(ctx.Hasher.Verify("S3cret-Pass!", updatedUser.PasswordHash));
        });

        runner.Run("LoginSession_ToString_HidesToken", static () =>
        {
            var profile = new PlayerProfile(Guid.NewGuid(), "mage01", "Arch Mage");
            var session = new LoginSession(profile, "RawSecretToken43CharactersLengthHere!!__--", DateTimeOffset.UtcNow);

            var text = session.ToString();
            Assert.DoesNotContain(text, "RawSecretToken43CharactersLengthHere!!__--");
            Assert.Contains(text, "***");
            Assert.Contains(text, "mage01");
        });
    }
}