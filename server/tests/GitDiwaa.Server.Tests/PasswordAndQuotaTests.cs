using System.Net;
using System.Net.Http.Json;
using GitDiwaa.Online.Accounts.Contracts;
using GitDiwaa.Server.Accounts;

namespace GitDiwaa.Server.Tests;

internal static class PasswordAndQuotaTests
{
    public static async Task RunAsync(TestRunner runner)
    {
        await runner.RunAsync("Register_WeakPassword_Rejected_WhenEnabled", async static () =>
        {
            var ctx = AccountTestContext.Create(new AccountOptions { RejectWeakPasswords = true });
            var reg = await ctx.Service.RegisterAsync(new RegisterRequest("mage01", null, "mage@example.com", "12345678"));
            Assert.Equal(AuthErrorCode.ValidationFailed, reg.Error);
            Assert.Equal(AccountFields.Password, reg.FieldErrors[0].Field);
            Assert.Equal(FieldErrorReason.TooCommon, reg.FieldErrors[0].Reason);
            Assert.Equal(null, await ctx.Users.FindByUsernameAsync("mage01"));
        });

        await runner.RunAsync("Register_PasswordSameAsUsername_Rejected", async static () =>
        {
            var ctx = AccountTestContext.Create(new AccountOptions { RejectWeakPasswords = true });
            var reg = await ctx.Service.RegisterAsync(new RegisterRequest("mage0123", null, "mage@example.com", "MAGE0123"));
            Assert.Equal(FieldErrorReason.TooCommon, reg.FieldErrors[0].Reason);
        });

        await runner.RunAsync("Register_WeakPassword_Allowed_WhenDisabled", async static () =>
        {
            var ctx = AccountTestContext.Create(new AccountOptions { RejectWeakPasswords = false });
            var reg = await ctx.Service.RegisterAsync(new RegisterRequest("mage01", null, "mage@example.com", "12345678"));
            Assert.True(reg.Succeeded);
        });

        await runner.RunAsync("Api_WeakPassword_OffInDevelopment_OnWhenConfigured", async static () =>
        {
            await using (var dev = await TestServerHost.StartNewAsync())
            {
                var allowed = await dev.Client.PostAsJsonAsync("/api/v1/accounts/register",
                    new RegisterRequest("mage01", null, "mage@example.com", "12345678"));
                Assert.Equal(HttpStatusCode.Created, allowed.StatusCode);
            }

            await using var strict = await TestServerHost.StartNewAsync("--Accounts:RejectWeakPasswords=true");
            var rejected = await strict.Client.PostAsJsonAsync("/api/v1/accounts/register",
                new RegisterRequest("mage01", null, "mage@example.com", "12345678"));
            Assert.Equal(HttpStatusCode.BadRequest, rejected.StatusCode);
            var body = await rejected.Content.ReadAsStringAsync();
            Assert.Contains(body, "TooCommon");
            Assert.DoesNotContain(body, "12345678");
        });

        await runner.RunAsync("Api_AccountQuota_IsPerSession_NotSharedAcrossPlayers", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync("--RateLimit:AccountPermitLimit=2");
            string mage = await RegisterAndLoginAsync(host, "mage01", "mage@example.com");
            string hero = await RegisterAndLoginAsync(host, "hero01", "hero@example.com");

            Assert.Equal(HttpStatusCode.OK, (await GetMeAsync(host, mage)).StatusCode);
            Assert.Equal(HttpStatusCode.OK, (await GetMeAsync(host, mage)).StatusCode);
            Assert.Equal(HttpStatusCode.TooManyRequests, (await GetMeAsync(host, mage)).StatusCode);

            // ผู้เล่นอีกคนจาก IP เดียวกันยังใช้ได้ตามปกติ
            Assert.Equal(HttpStatusCode.OK, (await GetMeAsync(host, hero)).StatusCode);
        });

        await runner.RunAsync("Api_AuthQuota_NotUsedByAccountEndpoints", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync("--RateLimit:AuthPermitLimit=3");
            string mage = await RegisterAndLoginAsync(host, "mage01", "mage@example.com");  // ใช้โควตา auth ไป 2

            for (int i = 0; i < 5; i++)
            {
                Assert.Equal(HttpStatusCode.OK, (await GetMeAsync(host, mage)).StatusCode);
            }

            // /me ไม่ได้กินโควตา auth: ยังเหลือ 1 ครั้งให้ตรวจชื่อซ้ำ
            var check = await host.Client.PostAsJsonAsync("/api/v1/accounts/register/check",
                new RegisterCheckRequest("hero01", "hero@example.com"));
            Assert.Equal(HttpStatusCode.NoContent, check.StatusCode);
        });
    }

    private static async Task<string> RegisterAndLoginAsync(TestServerHost host, string username, string email)
    {
        await host.Client.PostAsJsonAsync("/api/v1/accounts/register",
            new RegisterRequest(username, null, email, "S3cret-Pass!"));
        var loginResp = await host.Client.PostAsJsonAsync("/api/v1/accounts/login",
            new LoginRequest(username, "S3cret-Pass!", false));
        var login = await loginResp.Content.ReadFromJsonAsync<LoginResponse>();
        return login!.Token;
    }

    private static async Task<HttpResponseMessage> GetMeAsync(TestServerHost host, string token)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/v1/accounts/me");
        request.Headers.Add("Authorization", $"Bearer {token}");
        return await host.Client.SendAsync(request);
    }
}
