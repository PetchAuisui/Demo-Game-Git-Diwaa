using System.Net;
using System.Net.Http.Json;
using GitDiwaa.Online.Accounts;
using GitDiwaa.Online.Accounts.Contracts;
using GitDiwaa.Server.Accounts;

namespace GitDiwaa.Server.Tests;

internal static class DisplayNameTests
{
    private static readonly TimeSpan Cooldown = TimeSpan.FromDays(14);

    public static async Task RunAsync(TestRunner runner)
    {
        // --- AccountService ---

        await runner.RunAsync("Rename_Succeeds_AndFreesOldName", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var hero = await ctx.Service.RegisterAsync(new RegisterRequest("hero01", "Old Name", "hero@example.com", "S3cret-Pass!"));

            var rename = await ctx.Service.ChangeDisplayNameAsync(hero.Value!.Id, new ChangeDisplayNameRequest(" New Name "));
            Assert.True(rename.Succeeded);
            Assert.Equal("New Name", rename.Value?.Profile.DisplayName);
            // ยังเหลือสิทธิ์อีก 1 ครั้ง จึงเปลี่ยนได้ทันที
            Assert.Equal(1, rename.Value?.ChangesAvailable);
            Assert.Equal(AccountTestContext.StartTime, rename.Value?.NextChangeAllowedAt);

            var stored = await ctx.Users.FindByIdAsync(hero.Value.Id);
            Assert.Equal("New Name", stored?.DisplayName);

            // ชื่อเก่าว่างแล้ว คนอื่นสมัครด้วยชื่อนี้ได้
            var other = await ctx.Service.RegisterAsync(new RegisterRequest("other01", "Old Name", "other@example.com", "S3cret-Pass!"));
            Assert.True(other.Succeeded);
        });

        await runner.RunAsync("Rename_ToTakenName_ReturnsTakenFieldError", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var hero = await ctx.Service.RegisterAsync(new RegisterRequest("hero01", "Hero", "hero@example.com", "S3cret-Pass!"));
            await ctx.Service.RegisterAsync(new RegisterRequest("other01", "Taken Name", "other@example.com", "S3cret-Pass!"));

            var rename = await ctx.Service.ChangeDisplayNameAsync(hero.Value!.Id, new ChangeDisplayNameRequest("taken name"));
            Assert.Equal(AuthErrorCode.IdentifierTaken, rename.Error);
            Assert.Equal(1, rename.FieldErrors.Count);
            Assert.Equal(FieldErrorReason.Taken, rename.FieldErrors[0].Reason);

            var stored = await ctx.Users.FindByIdAsync(hero.Value.Id);
            Assert.Equal("Hero", stored?.DisplayName);
        });

        await runner.RunAsync("Rename_TwoFreeChanges_ThenBlockedUntilCooldownEnds", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var hero = await ctx.Service.RegisterAsync(new RegisterRequest("hero01", "Hero", "hero@example.com", "S3cret-Pass!"));
            Guid id = hero.Value!.Id;

            Assert.True((await ctx.Service.ChangeDisplayNameAsync(id, new ChangeDisplayNameRequest("Second"))).Succeeded);
            var lastFree = await ctx.Service.ChangeDisplayNameAsync(id, new ChangeDisplayNameRequest("Second B"));
            Assert.True(lastFree.Succeeded);
            Assert.Equal(0, lastFree.Value?.ChangesAvailable);
            Assert.Equal(AccountTestContext.StartTime.Add(Cooldown), lastFree.Value?.NextChangeAllowedAt);

            ctx.Time.Advance(Cooldown - TimeSpan.FromSeconds(1));
            var tooSoon = await ctx.Service.ChangeDisplayNameAsync(id, new ChangeDisplayNameRequest("Third"));
            Assert.Equal(AuthErrorCode.DisplayNameChangeCooldown, tooSoon.Error);
            Assert.Equal(AccountTestContext.StartTime.Add(Cooldown), tooSoon.Value?.NextChangeAllowedAt);
            Assert.Equal("Second B", (await ctx.Users.FindByIdAsync(id))?.DisplayName);

            ctx.Time.Advance(TimeSpan.FromSeconds(1));
            Assert.True((await ctx.Service.ChangeDisplayNameAsync(id, new ChangeDisplayNameRequest("Third"))).Succeeded);

            // ได้คืนทีละ 1 เท่านั้น: เปลี่ยนต่อทันทีไม่ได้
            var again = await ctx.Service.ChangeDisplayNameAsync(id, new ChangeDisplayNameRequest("Fourth"));
            Assert.Equal(AuthErrorCode.DisplayNameChangeCooldown, again.Error);
        });

        await runner.RunAsync("Rename_UnusedCreditIsKept", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var hero = await ctx.Service.RegisterAsync(new RegisterRequest("hero01", "Hero", "hero@example.com", "S3cret-Pass!"));
            Guid id = hero.Value!.Id;

            Assert.True((await ctx.Service.ChangeDisplayNameAsync(id, new ChangeDisplayNameRequest("Second"))).Succeeded);
            ctx.Time.Advance(TimeSpan.FromDays(100));
            var status = await ctx.Service.GetDisplayNameStatusAsync(id);
            Assert.Equal(1, status.Value?.ChangesAvailable);
        });

        await runner.RunAsync("Register_WithoutDisplayName_GetsSequentialPlayerNames", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var first = await ctx.Service.RegisterAsync(new RegisterRequest("hero01", null, "hero1@example.com", "S3cret-Pass!"));
            var second = await ctx.Service.RegisterAsync(new RegisterRequest("hero02", "  ", "hero2@example.com", "S3cret-Pass!"));
            Assert.Equal("player-10001", first.Value?.DisplayName);
            Assert.Equal("player-10002", second.Value?.DisplayName);

            var status = await ctx.Service.GetDisplayNameStatusAsync(first.Value!.Id);
            Assert.Equal(AccountRules.InitialDisplayNameChanges, status.Value?.ChangesAvailable);
            Assert.Equal(AccountTestContext.StartTime, status.Value?.NextChangeAllowedAt);
        });

        await runner.RunAsync("Register_ReservedDisplayName_Rejected", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var reg = await ctx.Service.RegisterAsync(new RegisterRequest("hero01", "Player-99", "hero@example.com", "S3cret-Pass!"));
            Assert.Equal(AuthErrorCode.ValidationFailed, reg.Error);
            Assert.Equal(FieldErrorReason.Reserved, reg.FieldErrors[0].Reason);
        });

        await runner.RunAsync("Rename_ToReservedName_Rejected", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var hero = await ctx.Service.RegisterAsync(new RegisterRequest("hero01", null, "hero@example.com", "S3cret-Pass!"));
            var rename = await ctx.Service.ChangeDisplayNameAsync(hero.Value!.Id, new ChangeDisplayNameRequest("player-2"));
            Assert.Equal(AuthErrorCode.ValidationFailed, rename.Error);
            Assert.Equal(FieldErrorReason.Reserved, rename.FieldErrors[0].Reason);

            // ชื่อเดิมยังอยู่ และสิทธิ์ไม่ถูกใช้
            var status = await ctx.Service.GetDisplayNameStatusAsync(hero.Value.Id);
            Assert.Equal("player-10001", status.Value?.Profile.DisplayName);
            Assert.Equal(2, status.Value?.ChangesAvailable);
        });

        await runner.RunAsync("Rename_SameName_DoesNotStartCooldown", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var hero = await ctx.Service.RegisterAsync(new RegisterRequest("hero01", "Hero", "hero@example.com", "S3cret-Pass!"));
            Guid id = hero.Value!.Id;

            var same = await ctx.Service.ChangeDisplayNameAsync(id, new ChangeDisplayNameRequest("Hero"));
            Assert.True(same.Succeeded);
            Assert.Equal(null, (await ctx.Users.FindByIdAsync(id))?.DisplayNameChangedAt);

            Assert.True((await ctx.Service.ChangeDisplayNameAsync(id, new ChangeDisplayNameRequest("Other"))).Succeeded);
        });

        await runner.RunAsync("Rename_CaseOnlyChange_Allowed", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var hero = await ctx.Service.RegisterAsync(new RegisterRequest("hero01", "hero", "hero@example.com", "S3cret-Pass!"));

            var rename = await ctx.Service.ChangeDisplayNameAsync(hero.Value!.Id, new ChangeDisplayNameRequest("HERO"));
            Assert.True(rename.Succeeded);
            Assert.Equal("HERO", rename.Value?.Profile.DisplayName);
        });

        await runner.RunAsync("Rename_Invalid_ReturnsValidationFailed", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var hero = await ctx.Service.RegisterAsync(new RegisterRequest("hero01", "Hero", "hero@example.com", "S3cret-Pass!"));

            var empty = await ctx.Service.ChangeDisplayNameAsync(hero.Value!.Id, new ChangeDisplayNameRequest("   "));
            Assert.Equal(AuthErrorCode.ValidationFailed, empty.Error);

            var tooLong = await ctx.Service.ChangeDisplayNameAsync(hero.Value.Id, new ChangeDisplayNameRequest(new string('a', 51)));
            Assert.Equal(AuthErrorCode.ValidationFailed, tooLong.Error);

            var control = await ctx.Service.ChangeDisplayNameAsync(hero.Value.Id, new ChangeDisplayNameRequest("Bad\u200BName"));
            Assert.Equal(AuthErrorCode.ValidationFailed, control.Error);
        });

        await runner.RunAsync("Rename_UnknownUser_ReturnsInvalidCredentials", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var result = await ctx.Service.ChangeDisplayNameAsync(Guid.NewGuid(), new ChangeDisplayNameRequest("Ghost"));
            Assert.Equal(AuthErrorCode.InvalidCredentials, result.Error);
        });

        await runner.RunAsync("Rename_ConcurrentRequests_OnlyOneSucceeds", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var hero = await ctx.Service.RegisterAsync(new RegisterRequest("hero01", "Hero", "hero@example.com", "S3cret-Pass!"));
            Guid id = hero.Value!.Id;

            var tasks = new Task<AccountResult<ChangeDisplayNameResponse>>[20];
            for (int i = 0; i < tasks.Length; i++)
            {
                string name = $"Name {i}";
                tasks[i] = Task.Run(() => ctx.Service.ChangeDisplayNameAsync(id, new ChangeDisplayNameRequest(name)));
            }

            var results = await Task.WhenAll(tasks);
            Assert.Equal(AccountRules.InitialDisplayNameChanges, results.Count(r => r.Succeeded));
        });

        await runner.RunAsync("Rename_TwoUsersSameNewName_OnlyOneWins", async static () =>
        {
            var ctx = AccountTestContext.Create();
            var ids = new Guid[10];
            for (int i = 0; i < ids.Length; i++)
            {
                var reg = await ctx.Service.RegisterAsync(new RegisterRequest($"hero{i:00}", $"Hero {i}", $"hero{i}@example.com", "S3cret-Pass!"));
                ids[i] = reg.Value!.Id;
            }

            var tasks = ids
                .Select(id => Task.Run(() => ctx.Service.ChangeDisplayNameAsync(id, new ChangeDisplayNameRequest("Champion"))))
                .ToArray();

            var results = await Task.WhenAll(tasks);
            Assert.Equal(1, results.Count(r => r.Succeeded));
        });

        // --- API ---

        await runner.RunAsync("Api_ChangeDisplayName_200_ThenCooldown409WithRetryAfter", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            await host.Client.PostAsJsonAsync("/api/v1/accounts/register",
                new RegisterRequest("mage01", "Arch Mage", "mage@example.com", "S3cret-Pass!"));
            var loginResp = await host.Client.PostAsJsonAsync("/api/v1/accounts/login",
                new LoginRequest("mage01", "S3cret-Pass!", false));
            var login = await loginResp.Content.ReadFromJsonAsync<LoginResponse>();
            string token = login!.Token;

            var first = await SendRenameAsync(host, token, "Grand Mage");
            Assert.Equal(HttpStatusCode.OK, first.StatusCode);
            Assert.Equal("no-store", first.Headers.CacheControl?.ToString());
            var firstBody = await first.Content.ReadAsStringAsync();
            Assert.Contains(firstBody, "Grand Mage");
            Assert.Contains(firstBody, "nextChangeAllowedAt");
            Assert.DoesNotContain(firstBody, "mage@example.com");

            using var meReq = new HttpRequestMessage(HttpMethod.Get, "/api/v1/accounts/me");
            meReq.Headers.Add("Authorization", $"Bearer {token}");
            var me = await host.Client.SendAsync(meReq);
            Assert.Contains(await me.Content.ReadAsStringAsync(), "Grand Mage");

            var second = await SendRenameAsync(host, token, "Other Mage");
            Assert.Equal(HttpStatusCode.OK, second.StatusCode);

            using var statusReq = new HttpRequestMessage(HttpMethod.Get, "/api/v1/accounts/me/display-name");
            statusReq.Headers.Add("Authorization", $"Bearer {token}");
            var status = await host.Client.SendAsync(statusReq);
            Assert.Equal(HttpStatusCode.OK, status.StatusCode);
            Assert.Contains(await status.Content.ReadAsStringAsync(), "\"changesAvailable\":0");

            var third = await SendRenameAsync(host, token, "Third Mage");
            Assert.Equal(HttpStatusCode.Conflict, third.StatusCode);
            Assert.Contains(await third.Content.ReadAsStringAsync(), "DisplayNameChangeCooldown");
            Assert.True(third.Headers.RetryAfter?.Delta is { } wait && wait > TimeSpan.FromDays(13),
                "Expected Retry-After close to 14 days.");
        });

        await runner.RunAsync("Api_ChangeDisplayName_WithoutToken_401", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            var response = await host.Client.PatchAsJsonAsync("/api/v1/accounts/me/display-name",
                new ChangeDisplayNameRequest("Sneaky"));
            Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        });

        await runner.RunAsync("Api_ChangeDisplayName_TakenName_409WithFieldError", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            await host.Client.PostAsJsonAsync("/api/v1/accounts/register",
                new RegisterRequest("mage01", "Arch Mage", "mage@example.com", "S3cret-Pass!"));
            await host.Client.PostAsJsonAsync("/api/v1/accounts/register",
                new RegisterRequest("rogue01", "Shadow", "rogue@example.com", "S3cret-Pass!"));
            var loginResp = await host.Client.PostAsJsonAsync("/api/v1/accounts/login",
                new LoginRequest("mage01", "S3cret-Pass!", false));
            var login = await loginResp.Content.ReadFromJsonAsync<LoginResponse>();

            var response = await SendRenameAsync(host, login!.Token, "SHADOW");
            Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
            var body = await response.Content.ReadAsStringAsync();
            Assert.Contains(body, "IdentifierTaken");
            Assert.Contains(body, "displayName");
            Assert.Contains(body, "Taken");
        });
    }

    private static async Task<HttpResponseMessage> SendRenameAsync(TestServerHost host, string token, string displayName)
    {
        using var request = new HttpRequestMessage(HttpMethod.Patch, "/api/v1/accounts/me/display-name")
        {
            Content = JsonContent.Create(new ChangeDisplayNameRequest(displayName))
        };
        request.Headers.Add("Authorization", $"Bearer {token}");
        return await host.Client.SendAsync(request);
    }
}
