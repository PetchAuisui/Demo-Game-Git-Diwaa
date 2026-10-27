using System.Text.Json.Serialization;
using System.Threading.RateLimiting;
using GitDiwaa.Online.Accounts.Contracts;
using GitDiwaa.Server.Accounts;
using GitDiwaa.Server.Persistence;
using GitDiwaa.Server.Persistence.InMemory;
using GitDiwaa.Server.Security;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
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

        // Limit maximum request body size to 16 KB (protect against memory exhaustion)
        builder.WebHost.ConfigureKestrel(o => o.Limits.MaxRequestBodySize = 16 * 1024);

        // Ensure consistent throwing of BadHttpRequestException across all environments
        builder.Services.Configure<RouteHandlerOptions>(o => o.ThrowOnBadRequest = true);

        // Silence the built-in exception handler logger for bad requests
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
        builder.Services.AddSingleton<RequireSessionFilter>();

        // Rate limiting configurations
        int authPermitLimit = builder.Configuration.GetValue("RateLimit:AuthPermitLimit", 10);
        int globalPermitLimit = builder.Configuration.GetValue("RateLimit:GlobalPermitLimit", 120);

        builder.Services.AddRateLimiter(rateLimiterOptions =>
        {
            rateLimiterOptions.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
            rateLimiterOptions.OnRejected = async (context, token) =>
            {
                context.HttpContext.Response.Headers.RetryAfter = "60";
                var error = new ApiError(AuthErrorCode.RateLimited, []);
                await context.HttpContext.Response.WriteAsJsonAsync(error, cancellationToken: token);
            };

            // Global per-IP rate limiter
            rateLimiterOptions.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
            {
                string ip = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
                return RateLimitPartition.GetFixedWindowLimiter(
                    partitionKey: ip,
                    factory: _ => new FixedWindowRateLimiterOptions
                    {
                        PermitLimit = globalPermitLimit,
                        Window = TimeSpan.FromMinutes(1),
                        QueueLimit = 0
                    });
            });

            // Dedicated policy for sensitive endpoints (register, login, refresh)
            rateLimiterOptions.AddPolicy("auth", httpContext =>
            {
                string ip = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
                return RateLimitPartition.GetFixedWindowLimiter(
                    partitionKey: ip,
                    factory: _ => new FixedWindowRateLimiterOptions
                    {
                        PermitLimit = authPermitLimit,
                        Window = TimeSpan.FromMinutes(1),
                        QueueLimit = 0
                    });
            });
        });

        var app = builder.Build();

        // Centralized error handler
        app.UseExceptionHandler(exceptionHandlerApp =>
        {
            exceptionHandlerApp.Run(async context =>
            {
                var error = context.Features.Get<IExceptionHandlerFeature>()?.Error;

                if (error is BadHttpRequestException badRequest)
                {
                    context.Response.StatusCode = badRequest.StatusCode;
                    await context.Response.WriteAsJsonAsync(new ApiError(AuthErrorCode.ValidationFailed, []));
                    return;
                }

                var logger = context.RequestServices.GetRequiredService<ILoggerFactory>().CreateLogger("GitDiwaa.Server");
                logger.LogError(error, "Unhandled server error on {Path}", context.Request.Path);

                context.Response.StatusCode = StatusCodes.Status500InternalServerError;
                await context.Response.WriteAsJsonAsync(new ApiError(AuthErrorCode.ServerError, []));
            });
        });

        app.UseRateLimiter();

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