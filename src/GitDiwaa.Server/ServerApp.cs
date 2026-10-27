using System.Text.Json.Serialization;
using GitDiwaa.Online.Accounts.Contracts;
using GitDiwaa.Server.Accounts;
using GitDiwaa.Server.Persistence;
using GitDiwaa.Server.Persistence.InMemory;
using GitDiwaa.Server.Security;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

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

        // Ensure consistent throwing of BadHttpRequestException across all environments
        builder.Services.Configure<RouteHandlerOptions>(o => o.ThrowOnBadRequest = true);

        // Our exception handler logs real 500s itself; silence the built-in duplicate that also logs every malformed request
        builder.Logging.AddFilter("Microsoft.AspNetCore.Diagnostics.ExceptionHandlerMiddleware", LogLevel.None);

        // Enums serialized as string names across all responses
        builder.Services.ConfigureHttpJsonOptions(o =>
        {
            o.SerializerOptions.Converters.Add(new JsonStringEnumConverter());
        });

        // Register repositories and core services as Singletons
        builder.Services.AddSingleton<IUserRepository, InMemoryUserRepository>();
        builder.Services.AddSingleton<ISessionRepository, InMemorySessionRepository>();
        builder.Services.AddSingleton<PasswordHasher>();
        builder.Services.AddSingleton<SessionTokenService>();
        builder.Services.AddSingleton(TimeProvider.System);
        builder.Services.AddSingleton(new AccountOptions());
        builder.Services.AddSingleton<AccountService>();

        var app = builder.Build();

        // Centralized error handler
        app.UseExceptionHandler(exceptionHandlerApp =>
        {
            exceptionHandlerApp.Run(async context =>
            {
                var error = context.Features.Get<IExceptionHandlerFeature>()?.Error;

                if (error is BadHttpRequestException)
                {
                    context.Response.StatusCode = StatusCodes.Status400BadRequest;
                    await context.Response.WriteAsJsonAsync(new ApiError(AuthErrorCode.ValidationFailed, []));
                    return;
                }

                var logger = context.RequestServices.GetRequiredService<ILoggerFactory>().CreateLogger("GitDiwaa.Server");
                logger.LogError(error, "Unhandled server error on {Path}", context.Request.Path);

                context.Response.StatusCode = StatusCodes.Status500InternalServerError;
                await context.Response.WriteAsJsonAsync(new ApiError(AuthErrorCode.ServerError, []));
            });
        });

        if (!app.Environment.IsDevelopment())
        {
            app.UseHsts();
            app.UseHttpsRedirection();
        }

        app.MapGet("/health", () => Results.Ok(new { status = "ok" }));
        app.MapAccountEndpoints();

        return app;
    }
}