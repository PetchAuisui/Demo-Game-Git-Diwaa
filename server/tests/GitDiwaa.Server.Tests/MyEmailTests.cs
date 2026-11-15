using System.Net;
using System.Net.Http.Json;
using GitDiwaa.Online.Accounts.Contracts;

namespace GitDiwaa.Server.Tests;

internal static class MyEmailTests
{
    private const string EmailPath = "/api/v1/accounts/me/email";

    public static async Task RunAsync(TestRunner runner)
    {
        await runner.RunAsync("Service_GetEmail_UnknownUser_InvalidCredentials", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var result = await ctx.Service.GetEmailAsync(Guid.NewGuid());
            Assert.Equal(AuthErrorCode.InvalidCredentials, result.Error);
        });

        await runner.RunAsync("Api_MyEmail_WithoutToken_401", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            var response = await host.Client.GetAsync(EmailPath);
            Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
            Assert.DoesNotContain(await response.Content.ReadAsStringAsync(), "@");
        });

        await runner.RunAsync("Api_MyEmail_ReturnsOnlyOwnEmail_NoStore", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            await host.Client.PostAsJsonAsync("/api/v1/accounts/register",
                new RegisterRequest("mage01", null, "mage@example.com", "S3cret-Pass!"));
            await host.Client.PostAsJsonAsync("/api/v1/accounts/register",
                new RegisterRequest("hero01", null, "Hero@Example.com", "S3cret-Pass!"));

            var loginResp = await host.Client.PostAsJsonAsync("/api/v1/accounts/login",
                new LoginRequest("hero01", "S3cret-Pass!", false));
            var login = await loginResp.Content.ReadFromJsonAsync<LoginResponse>();

            using var request = new HttpRequestMessage(HttpMethod.Get, EmailPath);
            request.Headers.Add("Authorization", $"Bearer {login!.Token}");
            var response = await host.Client.SendAsync(request);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            Assert.Equal("no-store", response.Headers.CacheControl?.ToString());

            var body = await response.Content.ReadAsStringAsync();
            Assert.Contains(body, "Hero@Example.com");
            Assert.DoesNotContain(body, "mage@example.com");
        });
    }
}
