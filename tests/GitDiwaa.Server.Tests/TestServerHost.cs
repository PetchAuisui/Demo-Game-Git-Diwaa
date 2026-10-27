using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting.Server;
using Microsoft.AspNetCore.Hosting.Server.Features;
using Microsoft.Extensions.DependencyInjection;

namespace GitDiwaa.Server.Tests;

internal sealed class TestServerHost : IAsyncDisposable
{
    public WebApplication App { get; }
    public HttpClient Client { get; }

    private TestServerHost(WebApplication app, HttpClient client)
    {
        App = app;
        Client = client;
    }

    public static async Task<TestServerHost> StartNewAsync(params string[] extraArgs)
    {
        var argsList = new List<string> { "--Logging:LogLevel:Default=Warning" };
        argsList.AddRange(extraArgs);

        var app = ServerApp.Build(argsList.ToArray(), "Development");
        app.Urls.Add("http://127.0.0.1:0");
        await app.StartAsync();

        var serverAddresses = app.Services
            .GetRequiredService<IServer>()
            .Features
            .Get<IServerAddressesFeature>();

        var boundAddress = serverAddresses?.Addresses.FirstOrDefault() ?? app.Urls.First();
        var client = new HttpClient { BaseAddress = new Uri(boundAddress) };

        return new TestServerHost(app, client);
    }

    public async ValueTask DisposeAsync()
    {
        Client.Dispose();
        await App.StopAsync();
        await App.DisposeAsync();
    }
}