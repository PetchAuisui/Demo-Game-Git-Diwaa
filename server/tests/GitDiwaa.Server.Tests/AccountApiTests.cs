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
        await runner.RunAsync("Api_Me_WithToken_200_WithoutToken_401", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            var reg = new RegisterRequest("mage01", "Arch Mage", "mage@example.com", "S3cret-Pass!");
            await host.Client.PostAsJsonAsync("/api/v1/accounts/register", reg);

            // Without token -> 401 with WWW-Authenticate header
            var noTokenResp = await host.Client.GetAsync("/api/v1/accounts/me");
            Assert.Equal(HttpStatusCode.Unauthorized, noTokenResp.StatusCode);
            Assert.Equal("Bearer", noTokenResp.Headers.WwwAuthenticate.ToString());

            // With valid token
            var loginResp = await host.Client.PostAsJsonAsync("/api/v1/accounts/login", new LoginRequest("mage01", "S3cret-Pass!", false));
            var loginData = await loginResp.Content.ReadFromJsonAsync<LoginResponse>();

            using var reqMsg = new HttpRequestMessage(HttpMethod.Get, "/api/v1/accounts/me");
            reqMsg.Headers.Add("Authorization", $"Bearer {loginData!.Token}");

            var authResp = await host.Client.SendAsync(reqMsg);
            Assert.Equal(HttpStatusCode.OK, authResp.StatusCode);

            var body = await authResp.Content.ReadAsStringAsync();
            Assert.Contains(body, "mage01");
            Assert.Contains(body, "Arch Mage");
        });

        await runner.RunAsync("Api_Me_RejectsTokenInQueryString", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            var reg = new RegisterRequest("mage01", "Arch Mage", "mage@example.com", "S3cret-Pass!");
            await host.Client.PostAsJsonAsync("/api/v1/accounts/register", reg);

            var loginResp = await host.Client.PostAsJsonAsync("/api/v1/accounts/login", new LoginRequest("mage01", "S3cret-Pass!", false));
            var loginData = await loginResp.Content.ReadFromJsonAsync<LoginResponse>();

            // Passing token via query string must be rejected
            var response = await host.Client.GetAsync($"/api/v1/accounts/me?token={loginData!.Token}");
            Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        });

        await runner.RunAsync("Api_Refresh_ReturnsNewToken_NoStore", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            var reg = new RegisterRequest("mage01", "Arch Mage", "mage@example.com", "S3cret-Pass!");
            await host.Client.PostAsJsonAsync("/api/v1/accounts/register", reg);

            var loginResp = await host.Client.PostAsJsonAsync("/api/v1/accounts/login", new LoginRequest("mage01", "S3cret-Pass!", false));
            var loginData = await loginResp.Content.ReadFromJsonAsync<LoginResponse>();

            using var refreshReq = new HttpRequestMessage(HttpMethod.Post, "/api/v1/accounts/refresh");
            refreshReq.Headers.Add("Authorization", $"bearer {loginData!.Token}"); // Case-insensitive bearer

            var refreshResp = await host.Client.SendAsync(refreshReq);
            Assert.Equal(HttpStatusCode.OK, refreshResp.StatusCode);
            Assert.Equal("no-store", refreshResp.Headers.CacheControl?.ToString());

            var refreshData = await refreshResp.Content.ReadFromJsonAsync<LoginResponse>();
            Assert.True(refreshData is not null);
            Assert.False(string.Equals(loginData.Token, refreshData!.Token, StringComparison.Ordinal));
            Assert.Equal(43, refreshData.Token.Length);
        });

        await runner.RunAsync("Api_Logout_Returns204_ThenMe401", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            var reg = new RegisterRequest("mage01", "Arch Mage", "mage@example.com", "S3cret-Pass!");
            await host.Client.PostAsJsonAsync("/api/v1/accounts/register", reg);

            var loginResp = await host.Client.PostAsJsonAsync("/api/v1/accounts/login", new LoginRequest("mage01", "S3cret-Pass!", false));
            var loginData = await loginResp.Content.ReadFromJsonAsync<LoginResponse>();

            using var logoutReq = new HttpRequestMessage(HttpMethod.Post, "/api/v1/accounts/logout");
            logoutReq.Headers.Add("Authorization", $"Bearer {loginData!.Token}");

            var logoutResp = await host.Client.SendAsync(logoutReq);
            Assert.Equal(HttpStatusCode.NoContent, logoutResp.StatusCode);

            // After logout, accessing /me with that token must return 401
            using var meReq = new HttpRequestMessage(HttpMethod.Get, "/api/v1/accounts/me");
            meReq.Headers.Add("Authorization", $"Bearer {loginData.Token}");

            var meResp = await host.Client.SendAsync(meReq);
            Assert.Equal(HttpStatusCode.Unauthorized, meResp.StatusCode);
        });

        await runner.RunAsync("Api_Login_RateLimited_Returns429_WithRetryAfter", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync("--RateLimit:AuthPermitLimit=3");

            var loginReq = new LoginRequest("nobody", "wrong-pass", false);

            // First 3 attempts should reach endpoint logic and return 401
            for (int i = 0; i < 3; i++)
            {
                var resp = await host.Client.PostAsJsonAsync("/api/v1/accounts/login", loginReq);
                Assert.Equal(HttpStatusCode.Unauthorized, resp.StatusCode);
            }

            // 4th attempt exceeds limit of 3 -> rejected with 429
            var rateLimitedResp = await host.Client.PostAsJsonAsync("/api/v1/accounts/login", loginReq);
            Assert.Equal(HttpStatusCode.TooManyRequests, rateLimitedResp.StatusCode);
            Assert.Equal("60", rateLimitedResp.Headers.RetryAfter?.Delta?.TotalSeconds.ToString());

            var body = await rateLimitedResp.Content.ReadAsStringAsync();
            Assert.Contains(body, "RateLimited");
        });

        await runner.RunAsync("Api_RateLimit_DoesNotBlockMe", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync("--RateLimit:AuthPermitLimit=2");
            var reg = new RegisterRequest("mage01", "Arch Mage", "mage@example.com", "S3cret-Pass!");
            await host.Client.PostAsJsonAsync("/api/v1/accounts/register", reg);

            // Exhaust auth quota (register = 1, login = 1 -> quota used = 2/2)
            var loginResp = await host.Client.PostAsJsonAsync("/api/v1/accounts/login", new LoginRequest("mage01", "S3cret-Pass!", false));
            Assert.Equal(HttpStatusCode.OK, loginResp.StatusCode, "Login should succeed within the auth quota.");
            var loginData = await loginResp.Content.ReadFromJsonAsync<LoginResponse>();

            // Subsequent login exceeds quota -> must be rate limited with 429
            var blockedLogin = await host.Client.PostAsJsonAsync("/api/v1/accounts/login", new LoginRequest("mage01", "S3cret-Pass!", false));
            Assert.Equal(HttpStatusCode.TooManyRequests, blockedLogin.StatusCode, "Second login should exceed the auth quota.");

            // But /me endpoint does not have "auth" limit applied -> should still return 200
            using var meReq = new HttpRequestMessage(HttpMethod.Get, "/api/v1/accounts/me");
            meReq.Headers.Add("Authorization", $"Bearer {loginData!.Token}");

            var meResp = await host.Client.SendAsync(meReq);
            Assert.Equal(HttpStatusCode.OK, meResp.StatusCode, "/me must not be limited by the auth policy.");
        });

        await runner.RunAsync("Api_OversizedBody_Returns413", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();

            // Create a payload larger than 16 KB (e.g. 20 KB)
            string largePadding = new('x', 20 * 1024);
            string json = $"{{\"identifier\":\"{largePadding}\",\"password\":\"pass\",\"rememberMe\":false}}";
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await host.Client.PostAsync("/api/v1/accounts/login", content);
            Assert.Equal(HttpStatusCode.RequestEntityTooLarge, response.StatusCode);

            var body = await response.Content.ReadAsStringAsync();
            Assert.DoesNotContain(body, "Exception");
        });

        await runner.RunAsync("Api_Register_DuplicateDisplayName_Returns409WithFieldError", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            var first = new RegisterRequest("mage01", "Hero", "mage1@example.com", "S3cret-Pass!");
            var second = new RegisterRequest("mage02", " hero ", "mage2@example.com", "S3cret-Pass!");

            var firstResp = await host.Client.PostAsJsonAsync("/api/v1/accounts/register", first);
            Assert.Equal(HttpStatusCode.Created, firstResp.StatusCode);

            var secondResp = await host.Client.PostAsJsonAsync("/api/v1/accounts/register", second);
            Assert.Equal(HttpStatusCode.Conflict, secondResp.StatusCode);

            var body = await secondResp.Content.ReadAsStringAsync();
            Assert.Contains(body, "\"code\":\"IdentifierTaken\"");
            Assert.Contains(body, "\"field\":\"displayName\"");
            Assert.Contains(body, "\"reason\":\"Taken\"");
        });

        await runner.RunAsync("Api_Register_DuplicateEmail_Returns409WithoutFieldErrors", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            var first = new RegisterRequest("mage01", "Hero One", "same@example.com", "S3cret-Pass!");
            var second = new RegisterRequest("mage02", "Hero Two", "SAME@example.com", "S3cret-Pass!");

            var firstResp = await host.Client.PostAsJsonAsync("/api/v1/accounts/register", first);
            Assert.Equal(HttpStatusCode.Created, firstResp.StatusCode);

            var secondResp = await host.Client.PostAsJsonAsync("/api/v1/accounts/register", second);
            Assert.Equal(HttpStatusCode.Conflict, secondResp.StatusCode);

            var body = await secondResp.Content.ReadAsStringAsync();
            Assert.Contains(body, "\"code\":\"IdentifierTaken\"");
            Assert.DoesNotContain(body, "email");
            Assert.Contains(body, "\"fieldErrors\":[]");
        });
    }
}