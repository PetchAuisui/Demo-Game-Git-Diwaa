using System.Net;

namespace GitDiwaa.Server.Tests;

internal static class HealthTests
{
    public static async Task RunAsync(TestRunner runner)
    {
        await runner.RunAsync("Health_ReturnsOk", async static () =>
        {
            await using var host = await TestServerHost.StartNewAsync();
            var response = await host.Client.GetAsync("/health");

            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var content = await response.Content.ReadAsStringAsync();
            Assert.Contains(content, "ok");
            Assert.DoesNotContain(content, "version");
        });
    }
}