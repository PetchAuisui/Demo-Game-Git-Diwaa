using System.Net;
using System.Net.Http.Json;
using System.Text;
using GitDiwaa.Online.Accounts.Contracts;

namespace GitDiwaa.Server.Tests;

internal static class AccountApiTests
{
    public static async Task RunAsync(TestRunner runner)
    {
        await runner.RunAsync("Api_Register_Returns201_WithoutEmailOrHash", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            var req = new RegisterRequest("mage01", "Arch Mage", "mage@example.com", "S3cret-Pass!");

            var response = await host.Client.PostAsJsonAsync("/api/v1/accounts/register", req);
            Assert.Equal(HttpStatusCode.Created, response.StatusCode);

            var body = await response.Content.ReadAsStringAsync();
            Assert.DoesNotContain(body, "mage@example.com");
            Assert.DoesNotContain(body, "pbkdf2");
            Assert.Contains(body, "mage01");
            Assert.Contains(body, "Arch Mage");
        });

        await runner.RunAsync("Api_Register_EmptyJson_Returns400_Required", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            var emptyContent = new StringContent("{}", Encoding.UTF8, "application/json");

            var response = await host.Client.PostAsync("/api/v1/accounts/register", emptyContent);
            Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

            var body = await response.Content.ReadAsStringAsync();
            Assert.Contains(body, "ValidationFailed");
            Assert.Contains(body, "Required");
        });

        await runner.RunAsync("Api_Register_Duplicate_Returns409", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            var req = new RegisterRequest("mage01", "Arch Mage", "mage@example.com", "S3cret-Pass!");

            var first = await host.Client.PostAsJsonAsync("/api/v1/accounts/register", req);
            Assert.Equal(HttpStatusCode.Created, first.StatusCode);

            var duplicate = await host.Client.PostAsJsonAsync("/api/v1/accounts/register", req);
            Assert.Equal(HttpStatusCode.Conflict, duplicate.StatusCode);

            var body = await duplicate.Content.ReadAsStringAsync();
            Assert.Contains(body, "IdentifierTaken");
        });

        await runner.RunAsync("Api_Login_Returns200_WithToken_AndNoStore", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            var reg = new RegisterRequest("mage01", "Arch Mage", "mage@example.com", "S3cret-Pass!");
            await host.Client.PostAsJsonAsync("/api/v1/accounts/register", reg);

            var loginReq = new LoginRequest("mage01", "S3cret-Pass!", false);
            var response = await host.Client.PostAsJsonAsync("/api/v1/accounts/login", loginReq);

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            Assert.Equal("no-store", response.Headers.CacheControl?.ToString());

            var loginData = await response.Content.ReadFromJsonAsync<LoginResponse>();
            Assert.True(loginData is not null);
            Assert.Equal(43, loginData!.Token.Length);
            Assert.Equal("mage01", loginData.Profile.Username);
        });

        await runner.RunAsync("Api_Login_WrongPassword_And_UnknownUser_IdenticalBody", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            var reg = new RegisterRequest("mage01", "Arch Mage", "mage@example.com", "S3cret-Pass!");
            await host.Client.PostAsJsonAsync("/api/v1/accounts/register", reg);

            var wrongPassReq = new LoginRequest("mage01", "WrongPassword123!", false);
            var wrongPassResp = await host.Client.PostAsJsonAsync("/api/v1/accounts/login", wrongPassReq);

            var unknownUserReq = new LoginRequest("nobody_mage", "S3cret-Pass!", false);
            var unknownUserResp = await host.Client.PostAsJsonAsync("/api/v1/accounts/login", unknownUserReq);

            Assert.Equal(HttpStatusCode.Unauthorized, wrongPassResp.StatusCode);
            Assert.Equal(HttpStatusCode.Unauthorized, unknownUserResp.StatusCode);

            var wrongPassBody = await wrongPassResp.Content.ReadAsStringAsync();
            var unknownUserBody = await unknownUserResp.Content.ReadAsStringAsync();

            Assert.Equal(wrongPassBody, unknownUserBody, "Responses for wrong password and unknown user must be byte-for-byte identical.");
        });

        await runner.RunAsync("Api_MalformedJson_Returns400_WithoutInternals", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            var malformed = new StringContent("{bad json", Encoding.UTF8, "application/json");

            var response = await host.Client.PostAsync("/api/v1/accounts/login", malformed);
            Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

            var body = await response.Content.ReadAsStringAsync();
            Assert.DoesNotContain(body, "Exception");
            Assert.DoesNotContain(body, "   at ");
            Assert.DoesNotContain(body, "System.");
            Assert.Contains(body, "ValidationFailed");
        });

        await runner.RunAsync("Api_EnumsAreStrings", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            var loginReq = new LoginRequest("unknown_user", "pass", false);
            var response = await host.Client.PostAsJsonAsync("/api/v1/accounts/login", loginReq);

            Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
            var body = await response.Content.ReadAsStringAsync();

            Assert.Contains(body, "\"code\":\"InvalidCredentials\"");
        });
    }
}