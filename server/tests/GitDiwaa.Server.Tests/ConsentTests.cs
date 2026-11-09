using System.Net;
using System.Net.Http.Json;
using GitDiwaa.Online.Accounts;
using GitDiwaa.Online.Accounts.Contracts;
using GitDiwaa.Server.Accounts;
using GitDiwaa.Server.Persistence;
using GitDiwaa.Server.Persistence.InMemory;
using GitDiwaa.Server.Security;

namespace GitDiwaa.Server.Tests;

internal static class ConsentTests
{
    private sealed record Ctx(InMemoryUserRepository Users, InMemoryConsentRepository Consents, AccountService Service);

    private static Ctx Create()
    {
        var users = new InMemoryUserRepository();
        var consents = new InMemoryConsentRepository();
        var service = new AccountService(
            users,
            new InMemorySessionRepository(),
            new PasswordHasher(),
            new SessionTokenService(),
            new ManualTimeProvider(AccountTestContext.StartTime),
            new AccountOptions(),
            consents);
        return new Ctx(users, consents, service);
    }

    public static async Task RunAsync(TestRunner runner)
    {
        await runner.RunAsync("Consent_RegisterWithOptIn_StoresFlagAndGrantedRecord", async static () =>
        {
            var ctx = Create();
            var reg = await ctx.Service.RegisterAsync(new RegisterRequest(
                "hero01", "Hero", "hero@example.com", "S3cret-Pass!", PrivacyPolicy.CurrentVersion, true));
            Assert.True(reg.Succeeded);

            var user = await ctx.Users.FindByIdAsync(reg.Value!.Id);
            Assert.True(user!.LeaderboardOptIn);

            var records = await ctx.Consents.ListForUserAsync(user.Id);
            Assert.Equal(1, records.Count);
            Assert.Equal(ConsentPurposes.LeaderboardDisplay, records[0].Purpose);
            Assert.Equal(PrivacyPolicy.CurrentVersion, records[0].PolicyVersion);
            Assert.True(records[0].Granted);
            Assert.Equal(AccountTestContext.StartTime, records[0].RecordedAt);
        });

        await runner.RunAsync("Consent_RegisterDefault_HiddenAndRecordsNotGranted", async static () =>
        {
            var ctx = Create();
            var reg = await ctx.Service.RegisterAsync(new RegisterRequest("hero01", "Hero", "hero@example.com", "S3cret-Pass!"));
            Assert.True(reg.Succeeded);

            var user = await ctx.Users.FindByIdAsync(reg.Value!.Id);
            Assert.False(user!.LeaderboardOptIn);

            var records = await ctx.Consents.ListForUserAsync(user.Id);
            Assert.Equal(1, records.Count);
            Assert.False(records[0].Granted);
        });

        await runner.RunAsync("Consent_RegisterOptInWithoutPolicy_ValidationFailed_StoresNothing", async static () =>
        {
            var ctx = Create();
            var reg = await ctx.Service.RegisterAsync(new RegisterRequest(
                "hero01", "Hero", "hero@example.com", "S3cret-Pass!", null, true));
            Assert.Equal(AuthErrorCode.ValidationFailed, reg.Error);
            Assert.Equal(AccountFields.PolicyVersion, reg.FieldErrors[0].Field);
            Assert.Equal(FieldErrorReason.Required, reg.FieldErrors[0].Reason);
            Assert.Equal(null, await ctx.Users.FindByUsernameAsync("hero01"));
        });

        await runner.RunAsync("Consent_RegisterWrongPolicyVersion_ValidationFailed", async static () =>
        {
            var ctx = Create();
            var reg = await ctx.Service.RegisterAsync(new RegisterRequest(
                "hero01", "Hero", "hero@example.com", "S3cret-Pass!", "1999-01-01", false));
            Assert.Equal(AuthErrorCode.ValidationFailed, reg.Error);
            Assert.Equal(FieldErrorReason.InvalidFormat, reg.FieldErrors[0].Reason);
        });

        await runner.RunAsync("Consent_GrantThenWithdraw_RecordsEveryChange", async static () =>
        {
            var ctx = Create();
            var reg = await ctx.Service.RegisterAsync(new RegisterRequest("hero01", "Hero", "hero@example.com", "S3cret-Pass!"));
            Guid id = reg.Value!.Id;

            var grant = await ctx.Service.SetLeaderboardConsentAsync(id, new LeaderboardConsentRequest(true, PrivacyPolicy.CurrentVersion));
            Assert.True(grant.Value!.LeaderboardOptIn);

            var withdraw = await ctx.Service.SetLeaderboardConsentAsync(id, new LeaderboardConsentRequest(false, PrivacyPolicy.CurrentVersion));
            Assert.False(withdraw.Value!.LeaderboardOptIn);
            Assert.False((await ctx.Users.FindByIdAsync(id))!.LeaderboardOptIn);

            var records = await ctx.Consents.ListForUserAsync(id);
            Assert.Equal(3, records.Count);
            Assert.False(records[0].Granted);
            Assert.True(records[1].Granted);
            Assert.False(records[2].Granted);
        });

        await runner.RunAsync("Consent_SetWithoutPolicyVersion_ValidationFailed", async static () =>
        {
            var ctx = Create();
            var reg = await ctx.Service.RegisterAsync(new RegisterRequest("hero01", "Hero", "hero@example.com", "S3cret-Pass!"));
            var result = await ctx.Service.SetLeaderboardConsentAsync(reg.Value!.Id, new LeaderboardConsentRequest(true, null));
            Assert.Equal(AuthErrorCode.ValidationFailed, result.Error);
            Assert.False((await ctx.Users.FindByIdAsync(reg.Value.Id))!.LeaderboardOptIn);
        });

        await runner.RunAsync("Consent_StaleUpdate_DoesNotOverwriteChoice", async static () =>
        {
            var ctx = Create();
            var reg = await ctx.Service.RegisterAsync(new RegisterRequest("hero01", "Hero", "hero@example.com", "S3cret-Pass!"));
            Guid id = reg.Value!.Id;

            // อ่านข้อมูลไว้ก่อน (เหมือนตอน login) แล้วผู้เล่นกดยินยอมระหว่างนั้น
            var stale = await ctx.Users.FindByIdAsync(id);
            await ctx.Service.SetLeaderboardConsentAsync(id, new LeaderboardConsentRequest(true, PrivacyPolicy.CurrentVersion));
            await ctx.Users.UpdateAsync(stale! with { FailedLoginCount = 1 });

            var current = await ctx.Users.FindByIdAsync(id);
            Assert.True(current!.LeaderboardOptIn);
            Assert.Equal(1, current.FailedLoginCount);
        });

        await runner.RunAsync("Consent_UnknownUser_InvalidCredentials", async static () =>
        {
            var ctx = Create();
            var result = await ctx.Service.SetLeaderboardConsentAsync(
                Guid.NewGuid(), new LeaderboardConsentRequest(true, PrivacyPolicy.CurrentVersion));
            Assert.Equal(AuthErrorCode.InvalidCredentials, result.Error);
        });

        await runner.RunAsync("Api_LeaderboardConsent_GetPut_AndRequiresToken", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            await host.Client.PostAsJsonAsync("/api/v1/accounts/register",
                new RegisterRequest("mage01", "Arch Mage", "mage@example.com", "S3cret-Pass!"));
            var loginResp = await host.Client.PostAsJsonAsync("/api/v1/accounts/login",
                new LoginRequest("mage01", "S3cret-Pass!", false));
            var login = await loginResp.Content.ReadFromJsonAsync<LoginResponse>();
            string token = login!.Token;

            var noToken = await host.Client.GetAsync("/api/v1/accounts/me/leaderboard-consent");
            Assert.Equal(HttpStatusCode.Unauthorized, noToken.StatusCode);

            var before = await SendAsync(host, HttpMethod.Get, token, null);
            Assert.Equal(HttpStatusCode.OK, before.StatusCode);
            Assert.Contains(await before.Content.ReadAsStringAsync(), "\"leaderboardOptIn\":false");

            var grant = await SendAsync(host, HttpMethod.Put, token, new LeaderboardConsentRequest(true, PrivacyPolicy.CurrentVersion));
            Assert.Equal(HttpStatusCode.OK, grant.StatusCode);
            Assert.Equal("no-store", grant.Headers.CacheControl?.ToString());
            Assert.Contains(await grant.Content.ReadAsStringAsync(), "\"leaderboardOptIn\":true");

            var after = await SendAsync(host, HttpMethod.Get, token, null);
            Assert.Contains(await after.Content.ReadAsStringAsync(), "\"leaderboardOptIn\":true");

            var wrongVersion = await SendAsync(host, HttpMethod.Put, token, new LeaderboardConsentRequest(false, "old"));
            Assert.Equal(HttpStatusCode.BadRequest, wrongVersion.StatusCode);
            Assert.Contains(await wrongVersion.Content.ReadAsStringAsync(), "policyVersion");
        });
    }

    private static async Task<HttpResponseMessage> SendAsync(
        TestServerHost host,
        HttpMethod method,
        string token,
        LeaderboardConsentRequest? body)
    {
        using var request = new HttpRequestMessage(method, "/api/v1/accounts/me/leaderboard-consent");
        if (body is not null)
        {
            request.Content = JsonContent.Create(body);
        }
        request.Headers.Add("Authorization", $"Bearer {token}");
        return await host.Client.SendAsync(request);
    }
}
