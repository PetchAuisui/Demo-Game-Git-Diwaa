using System.Net;
using Microsoft.AspNetCore.Hosting.Server;
using Microsoft.AspNetCore.Hosting.Server.Features;
using Microsoft.Extensions.DependencyInjection;

namespace GitDiwaa.Server.Tests;

internal static class HealthTests
{
    public static async Task RunAsync(TestRunner runner)
    {
        await runner.RunAsync("Health_ReturnsOk", async static () =>
        {
            var app = ServerApp.Build(["--Logging:LogLevel:Default=Warning"], "Development");
            app.Urls.Add("http://127.0.0.1:0");

            try
            {
                await app.StartAsync();

                var serverAddresses = app.Services
                    .GetRequiredService<IServer>()
                    .Features
                    .Get<IServerAddressesFeature>();

                var boundAddress = serverAddresses?.Addresses.FirstOrDefault() ?? app.Urls.First();

                using var client = new HttpClient { BaseAddress = new Uri(boundAddress) };
                var response = await client.GetAsync("/health");

                Assert.Equal(HttpStatusCode.OK, response.StatusCode);

                var content = await response.Content.ReadAsStringAsync();
                Assert.Contains(content, "ok");
                Assert.DoesNotContain(content, "version");
            }
            finally
            {
                await app.StopAsync();
                await app.DisposeAsync();
            }
        });
    }
}