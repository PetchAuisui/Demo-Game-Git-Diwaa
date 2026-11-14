using System.Net;
using System.Net.Http.Json;
using GitDiwaa.Online.Accounts.Contracts;

namespace GitDiwaa.Server.Tests;

internal static class RegisterCheckTests
{
    private const string CheckPath = "/api/v1/accounts/register/check";

    public static async Task RunAsync(TestRunner runner)
    {
        await runner.RunAsync("Check_Available_Succeeds_AndCreatesNothing", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var result = await ctx.Service.CheckRegistrationAsync(new RegisterCheckRequest("mage01", "mage@example.com"));
            Assert.True(result.Succeeded);
            Assert.Equal(null, await ctx.Users.FindByUsernameAsync("mage01"));
            Assert.Equal(null, await ctx.Users.FindByEmailAsync("mage@example.com"));
        });

        await runner.RunAsync("Check_UsernameTaken_IdentifierTaken_WithoutFieldHint", async static () =>
        {
            var ctx = AccountTestContext.Create();
            await ctx.Service.RegisterAsync(new RegisterRequest("mage01", null, "mage@example.com", "S3cret-Pass!"));

            var result = await ctx.Service.CheckRegistrationAsync(new RegisterCheckRequest("MAGE01", "other@example.com"));
            Assert.Equal(AuthErrorCode.IdentifierTaken, result.Error);
            Assert.Equal(0, result.FieldErrors.Count);
        });

        await runner.RunAsync("Check_EmailTaken_IdentifierTaken_WithoutFieldHint", async static () =>
        {
            var ctx = AccountTestContext.Create();
            await ctx.Service.RegisterAsync(new RegisterRequest("mage01", null, "mage@example.com", "S3cret-Pass!"));

            var result = await ctx.Service.CheckRegistrationAsync(new RegisterCheckRequest("other01", " Mage@Example.com "));
            Assert.Equal(AuthErrorCode.IdentifierTaken, result.Error);
            Assert.Equal(0, result.FieldErrors.Count);
        });

        await runner.RunAsync("Check_InvalidInput_ValidationFailed_PerField", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var result = await ctx.Service.CheckRegistrationAsync(new RegisterCheckRequest("", "not-an-email"));
            Assert.Equal(AuthErrorCode.ValidationFailed, result.Error);
            Assert.Equal(2, result.FieldErrors.Count);
            Assert.Equal(AccountFields.Username, result.FieldErrors[0].Field);
            Assert.Equal(AccountFields.Email, result.FieldErrors[1].Field);
        });

        await runner.RunAsync("Api_Check_Available_Returns204", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            var response = await host.Client.PostAsJsonAsync(CheckPath, new RegisterCheckRequest("mage01", "mage@example.com"));
            Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        });

        await runner.RunAsync("Api_Check_Taken_Returns409_WithoutFieldErrors", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            await host.Client.PostAsJsonAsync("/api/v1/accounts/register",
                new RegisterRequest("mage01", null, "mage@example.com", "S3cret-Pass!"));

            var response = await host.Client.PostAsJsonAsync(CheckPath, new RegisterCheckRequest("other01", "mage@example.com"));
            Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);

            var body = await response.Content.ReadAsStringAsync();
            Assert.Contains(body, "IdentifierTaken");
            Assert.Contains(body, "\"fieldErrors\":[]");
            Assert.DoesNotContain(body, "mage@example.com");
        });

        await runner.RunAsync("Api_Check_IsRateLimited", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync("--RateLimit:AuthPermitLimit=2");
            var req = new RegisterCheckRequest("mage01", "mage@example.com");

            Assert.Equal(HttpStatusCode.NoContent, (await host.Client.PostAsJsonAsync(CheckPath, req)).StatusCode);
            Assert.Equal(HttpStatusCode.NoContent, (await host.Client.PostAsJsonAsync(CheckPath, req)).StatusCode);
            Assert.Equal(HttpStatusCode.TooManyRequests, (await host.Client.PostAsJsonAsync(CheckPath, req)).StatusCode);
        });
    }
}
