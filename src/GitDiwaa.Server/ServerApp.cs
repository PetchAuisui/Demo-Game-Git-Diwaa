using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Hosting;

namespace GitDiwaa.Server;

public static class ServerApp
{
    public static WebApplication Build(string[] args, string? environmentName = null)
    {
        var options = new WebApplicationOptions
        {
            Args = args,
            EnvironmentName = environmentName
        };

        var builder = WebApplication.CreateBuilder(options);
        var app = builder.Build();

        if (!app.Environment.IsDevelopment())
        {
            app.UseHsts();
            app.UseHttpsRedirection();
        }

        app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

        return app;
    }
}