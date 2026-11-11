using System.Net;
using System.Net.Http.Json;
using GitDiwaa.Online.Accounts.Contracts;
using GitDiwaa.Server.Accounts;
using GitDiwaa.Server.Persistence.InMemory;
using GitDiwaa.Server.Security;

namespace GitDiwaa.Server.Tests;

/// <summary>
/// เทสของจุดที่แก้ตามรีวิว PR: ตัวนับใส่รหัสผิดแบบ atomic และแยกต้นทาง, ช่วงผ่อนผันหลังหมุน token,
/// ForwardedHeaders, โควตาของ /logout, hash แบบจำกัดจำนวนพร้อมกัน และการบังคับส่ง consent repository
/// </summary>
internal static class LoginLockoutAndRefreshGraceTests
{
    private const string Password = "S3cret-Pass!";

    public static async Task RunAsync(TestRunner runner)
    {
        // ---------------------------------------------------------------- พักการล็อกอิน

        await runner.RunAsync("Login_ConcurrentWrongPasswords_StillLock", async static () =>
        {
            var ctx = await CreateWithUserAsync();

            // เดิม: ทุกคำขออ่านตัวนับได้ 0 แล้วเขียน 1 ทับกัน ไม่ถึง 5 สักที บัญชีจึงไม่ถูกพัก
            var attempts = new Task<AccountResult<LoginSession>>[20];
            for (int i = 0; i < attempts.Length; i++)
            {
                attempts[i] = Task.Run(() => ctx.Service.LoginAsync(new LoginRequest("mage01", "WrongPassword!", false), "10.0.0.1"));
            }
            var results = await Task.WhenAll(attempts);
            Assert.True(results.All(r => !r.Succeeded));

            var correct = await ctx.Service.LoginAsync(new LoginRequest("mage01", Password, false), "10.0.0.1");
            Assert.False(correct.Succeeded, "Parallel wrong passwords must still trigger the lockout.");
            Assert.Equal(AuthErrorCode.InvalidCredentials, correct.Error);
        });

        await runner.RunAsync("Login_Lockout_OnlyLocksTheClientThatFailed", async static () =>
        {
            var ctx = await CreateWithUserAsync();

            for (int i = 0; i < 5; i++)
            {
                await ctx.Service.LoginAsync(new LoginRequest("mage01", "WrongPassword!", false), "203.0.113.9");
            }

            // คนที่ใส่ผิดถูกพัก แม้จะใส่รหัสถูกในภายหลัง
            var attacker = await ctx.Service.LoginAsync(new LoginRequest("mage01", Password, false), "203.0.113.9");
            Assert.False(attacker.Succeeded);

            // เจ้าของบัญชีจากเน็ตอื่นยังเข้าได้ตามปกติ
            var owner = await ctx.Service.LoginAsync(new LoginRequest("mage01", Password, false), "198.51.100.7");
            Assert.True(owner.Succeeded, "Another client must not be locked out by someone else's failures.");
        });

        await runner.RunAsync("Login_FailuresAcrossManyClients_LockWholeAccount", async static () =>
        {
            var ctx = await CreateWithUserAsync();

            // 10 ต้นทาง ต้นทางละ 2 ครั้ง = 20 ครั้ง: ไม่มีต้นทางไหนถึง 5 แต่รวมทั้งบัญชีถึงเกณฑ์
            for (int client = 0; client < 10; client++)
            {
                for (int i = 0; i < 2; i++)
                {
                    await ctx.Service.LoginAsync(new LoginRequest("mage01", "WrongPassword!", false), $"203.0.113.{client}");
                }
            }

            var fresh = await ctx.Service.LoginAsync(new LoginRequest("mage01", Password, false), "198.51.100.7");
            Assert.False(fresh.Succeeded, "Guessing from many addresses must lock the whole account.");

            ctx.Time.Advance(TimeSpan.FromMinutes(15) + TimeSpan.FromSeconds(1));
            var later = await ctx.Service.LoginAsync(new LoginRequest("mage01", Password, false), "198.51.100.7");
            Assert.True(later.Succeeded);
        });

        await runner.RunAsync("Login_ClientFailures_ExpireAfterLockoutWindow", async static () =>
        {
            var ctx = await CreateWithUserAsync();

            for (int i = 0; i < 4; i++)
            {
                await ctx.Service.LoginAsync(new LoginRequest("mage01", "WrongPassword!", false), "203.0.113.9");
            }
            ctx.Time.Advance(TimeSpan.FromMinutes(16));
            // ครั้งที่ 5 ห่างจากครั้งก่อนเกินช่วงพัก: ตัวนับของต้นทางเริ่มใหม่ จึงยังไม่ถูกพัก
            await ctx.Service.LoginAsync(new LoginRequest("mage01", "WrongPassword!", false), "203.0.113.9");

            var correct = await ctx.Service.LoginAsync(new LoginRequest("mage01", Password, false), "203.0.113.9");
            Assert.True(correct.Succeeded);
        });

        // ---------------------------------------------------------------- ช่วงผ่อนผันหลังหมุน token

        await runner.RunAsync("Refresh_ReuseWithinGrace_Succeeds_AndKeepsOtherSessions", async static () =>
        {
            var ctx = await CreateWithUserAsync();
            string tokenA = (await ctx.Service.LoginAsync(new LoginRequest("mage01", Password, true))).Value!.Token;
            string tokenB = (await ctx.Service.LoginAsync(new LoginRequest("mage01", Password, false))).Value!.Token;

            string tokenA2 = (await ctx.Service.RefreshAsync(tokenA)).Value!.Token;

            // คำตอบ refresh หายกลางทาง เกมลองใหม่ด้วยใบเดิมภายใน 60 วินาที
            ctx.Time.Advance(TimeSpan.FromSeconds(30));
            var retry = await ctx.Service.RefreshAsync(tokenA);
            Assert.True(retry.Succeeded, "A quick retry with the just-rotated token must not be treated as theft.");
            Assert.False(string.Equals(retry.Value!.Token, tokenA2, StringComparison.Ordinal));

            Assert.True((await ctx.Service.ValidateSessionAsync(retry.Value.Token)).Succeeded);
            Assert.True((await ctx.Service.ValidateSessionAsync(tokenA2)).Succeeded);
            Assert.True((await ctx.Service.ValidateSessionAsync(tokenB)).Succeeded);
            // ใบเก่ายังใช้เรียก endpoint อื่นไม่ได้ (ผ่อนผันให้เฉพาะการ refresh)
            Assert.False((await ctx.Service.ValidateSessionAsync(tokenA)).Succeeded);
        });

        await runner.RunAsync("Refresh_ConcurrentSameToken_AllSucceedWithinGrace", async static () =>
        {
            var ctx = await CreateWithUserAsync();
            string token = (await ctx.Service.LoginAsync(new LoginRequest("mage01", Password, false))).Value!.Token;

            // เกม 2 หน้าต่าง (หรือมากกว่า) refresh ใบเดียวกันพร้อมกัน: ต้องไม่มีใครโดนตัดทุก session
            var tasks = new Task<AccountResult<LoginSession>>[20];
            for (int i = 0; i < tasks.Length; i++)
            {
                tasks[i] = Task.Run(() => ctx.Service.RefreshAsync(token));
            }
            var results = await Task.WhenAll(tasks);

            Assert.True(results.All(r => r.Succeeded), $"Expected every refresh to succeed, got {results.Count(r => r.Succeeded)}.");
            Assert.Equal(20, results.Select(r => r.Value!.Token).Distinct(StringComparer.Ordinal).Count());
            foreach (var result in results)
            {
                Assert.True((await ctx.Service.ValidateSessionAsync(result.Value!.Token)).Succeeded);
            }
        });

        await runner.RunAsync("Refresh_ReuseAfterLogout_HasNoGrace_RevokesAll", async static () =>
        {
            var ctx = await CreateWithUserAsync();
            string tokenA = (await ctx.Service.LoginAsync(new LoginRequest("mage01", Password, false))).Value!.Token;
            string tokenB = (await ctx.Service.LoginAsync(new LoginRequest("mage01", Password, false))).Value!.Token;

            string tokenA2 = (await ctx.Service.RefreshAsync(tokenA)).Value!.Token;
            await ctx.Service.LogoutAsync(tokenA2);

            // ผู้เล่นออกจากระบบไปแล้ว: ใบเก่าต้องใช้ไม่ได้ทันที แม้ยังอยู่ใน 60 วินาที
            var reuse = await ctx.Service.RefreshAsync(tokenA);
            Assert.False(reuse.Succeeded);
            Assert.False((await ctx.Service.ValidateSessionAsync(tokenB)).Succeeded);
        });

        await runner.RunAsync("Refresh_ReuseOfLoggedOutToken_HasNoGrace", async static () =>
        {
            var ctx = await CreateWithUserAsync();
            string token = (await ctx.Service.LoginAsync(new LoginRequest("mage01", Password, false))).Value!.Token;
            await ctx.Service.LogoutAsync(token);

            // ถูกยกเลิกด้วย logout (ไม่ใช่ถูกหมุน): ไม่มีช่วงผ่อนผัน
            var reuse = await ctx.Service.RefreshAsync(token);
            Assert.False(reuse.Succeeded);
        });

        await runner.RunAsync("Refresh_GraceDisabled_ReuseRevokesAllImmediately", async static () =>
        {
            var ctx = await CreateWithUserAsync(new AccountOptions { RefreshReuseGracePeriod = TimeSpan.Zero });
            string tokenA = (await ctx.Service.LoginAsync(new LoginRequest("mage01", Password, false))).Value!.Token;
            string tokenA2 = (await ctx.Service.RefreshAsync(tokenA)).Value!.Token;

            var reuse = await ctx.Service.RefreshAsync(tokenA);
            Assert.False(reuse.Succeeded);
            Assert.False((await ctx.Service.ValidateSessionAsync(tokenA2)).Succeeded);
        });

        // ---------------------------------------------------------------- อื่นๆ

        await runner.RunAsync("PasswordHasher_AsyncVariants_MatchSyncOnes", async static () =>
        {
            var hasher = new PasswordHasher();
            string hash = await hasher.HashAsync(Password);
            Assert.True(await hasher.VerifyAsync(Password, hash));
            Assert.False(await hasher.VerifyAsync("WrongPassword!", hash));
            Assert.True(hasher.Verify(Password, hash));

            // คำขอพร้อมกันมากกว่าจำนวน core ต้องเสร็จครบ (รอคิว ไม่ค้าง)
            var many = Enumerable.Range(0, Environment.ProcessorCount * 2 + 2).Select(_ => hasher.VerifyAsync(Password, hash));
            Assert.True((await Task.WhenAll(many)).All(ok => ok));
        });

        runner.Run("AccountService_RequiresConsentRepository", static () =>
        {
            Assert.Throws<ArgumentNullException>(() => new AccountService(
                new InMemoryUserRepository(),
                new InMemorySessionRepository(),
                new PasswordHasher(),
                new SessionTokenService(),
                new ManualTimeProvider(AccountTestContext.StartTime),
                null!));
        });

        await runner.RunAsync("Api_Logout_UsesPerSessionQuota", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync("--RateLimit:AccountPermitLimit=2", "--RateLimit:AuthPermitLimit=3");
            string mage = await RegisterAndLoginAsync(host, "mage01", "mage@example.com");  // ใช้โควตา auth ไป 2

            Assert.Equal(HttpStatusCode.NoContent, (await LogoutAsync(host, mage)).StatusCode);
            Assert.Equal(HttpStatusCode.NoContent, (await LogoutAsync(host, mage)).StatusCode);
            Assert.Equal(HttpStatusCode.TooManyRequests, (await LogoutAsync(host, mage)).StatusCode);

            // /logout ไม่กินโควตา auth (ต่อ IP): ผู้เล่นอื่นในเน็ตเดียวกันยังล็อกอิน / ตรวจชื่อได้
            var check = await host.Client.PostAsJsonAsync("/api/v1/accounts/register/check",
                new RegisterCheckRequest("hero01", "hero@example.com"));
            Assert.Equal(HttpStatusCode.NoContent, check.StatusCode);
        });

        await runner.RunAsync("Api_ForwardedFor_Ignored_WhenNoProxyConfigured", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync("--RateLimit:AuthPermitLimit=2");

            Assert.Equal(HttpStatusCode.NoContent, (await CheckFromAsync(host, "198.51.100.1")).StatusCode);
            Assert.Equal(HttpStatusCode.NoContent, (await CheckFromAsync(host, "198.51.100.2")).StatusCode);
            // ไม่ได้ตั้ง proxy ที่เชื่อถือ: ปลอม X-Forwarded-For มาก็ยังนับเป็น IP จริงเดียวกัน
            Assert.Equal(HttpStatusCode.TooManyRequests, (await CheckFromAsync(host, "198.51.100.3")).StatusCode);
        });

        await runner.RunAsync("Api_ForwardedFor_Used_WhenProxyIsTrusted", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync(
                "--RateLimit:AuthPermitLimit=2",
                "--ForwardedHeaders:KnownProxies:0=127.0.0.1");

            Assert.Equal(HttpStatusCode.NoContent, (await CheckFromAsync(host, "198.51.100.1")).StatusCode);
            Assert.Equal(HttpStatusCode.NoContent, (await CheckFromAsync(host, "198.51.100.1")).StatusCode);
            Assert.Equal(HttpStatusCode.TooManyRequests, (await CheckFromAsync(host, "198.51.100.1")).StatusCode);
            // ผู้เล่นอีกคนหลัง proxy เดียวกันมีโควตาของตัวเอง
            Assert.Equal(HttpStatusCode.NoContent, (await CheckFromAsync(host, "198.51.100.2")).StatusCode);
        });

        await runner.RunAsync("Api_ForwardedFor_Ignored_FromUntrustedProxy", async static () =>
        {
            // เชื่อเฉพาะ 10.9.9.9 แต่คำขอมาจาก 127.0.0.1: ต้องไม่เชื่อ header
            await using var host = await TestServerHost.StartNewAsync(
                "--RateLimit:AuthPermitLimit=2",
                "--ForwardedHeaders:KnownProxies:0=10.9.9.9");

            Assert.Equal(HttpStatusCode.NoContent, (await CheckFromAsync(host, "198.51.100.1")).StatusCode);
            Assert.Equal(HttpStatusCode.NoContent, (await CheckFromAsync(host, "198.51.100.2")).StatusCode);
            Assert.Equal(HttpStatusCode.TooManyRequests, (await CheckFromAsync(host, "198.51.100.3")).StatusCode);
        });

        await runner.RunAsync("Api_Login_LockoutCountsPerForwardedClient", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync("--ForwardedHeaders:KnownProxies:0=127.0.0.1");
            await host.Client.PostAsJsonAsync("/api/v1/accounts/register",
                new RegisterRequest("mage01", null, "mage@example.com", Password));

            for (int i = 0; i < 5; i++)
            {
                await LoginFromAsync(host, "203.0.113.9", "WrongPassword!");
            }

            Assert.Equal(HttpStatusCode.Unauthorized, (await LoginFromAsync(host, "203.0.113.9", Password)).StatusCode);
            Assert.Equal(HttpStatusCode.OK, (await LoginFromAsync(host, "198.51.100.7", Password)).StatusCode);
        });
    }

    private static async Task<AccountTestContext> CreateWithUserAsync(AccountOptions? options = null)
    {
        var ctx = AccountTestContext.Create(options);
        var reg = await ctx.Service.RegisterAsync(new RegisterRequest("mage01", "Mage", "mage@example.com", Password));
        Assert.True(reg.Succeeded);
        return ctx;
    }

    private static async Task<string> RegisterAndLoginAsync(TestServerHost host, string username, string email)
    {
        await host.Client.PostAsJsonAsync("/api/v1/accounts/register",
            new RegisterRequest(username, null, email, Password));
        var loginResp = await host.Client.PostAsJsonAsync("/api/v1/accounts/login",
            new LoginRequest(username, Password, false));
        var login = await loginResp.Content.ReadFromJsonAsync<LoginResponse>();
        return login!.Token;
    }

    private static async Task<HttpResponseMessage> LogoutAsync(TestServerHost host, string token)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, "/api/v1/accounts/logout");
        request.Headers.Add("Authorization", $"Bearer {token}");
        return await host.Client.SendAsync(request);
    }

    private static async Task<HttpResponseMessage> CheckFromAsync(TestServerHost host, string forwardedFor)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, "/api/v1/accounts/register/check")
        {
            Content = JsonContent.Create(new RegisterCheckRequest("hero01", "hero@example.com"))
        };
        request.Headers.Add("X-Forwarded-For", forwardedFor);
        return await host.Client.SendAsync(request);
    }

    private static async Task<HttpResponseMessage> LoginFromAsync(TestServerHost host, string forwardedFor, string password)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, "/api/v1/accounts/login")
        {
            Content = JsonContent.Create(new LoginRequest("mage01", password, false))
        };
        request.Headers.Add("X-Forwarded-For", forwardedFor);
        return await host.Client.SendAsync(request);
    }
}
