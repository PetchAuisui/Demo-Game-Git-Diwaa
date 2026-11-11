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
        builder.Services.AddSingleton<IConsentRepository, InMemoryConsentRepository>();
        builder.Services.AddSingleton<PasswordHasher>();
        builder.Services.AddSingleton<SessionTokenService>();
        builder.Services.AddSingleton(TimeProvider.System);
        // กันรหัสผ่านอ่อน: เปิดเป็นค่าเริ่มต้น ปิดเองเฉพาะตอนพัฒนา (Development) ให้ทีมใช้รหัสง่ายๆ ทดสอบในเครื่องได้
        // ตั้งเองได้ด้วย Accounts:RejectWeakPasswords (true / false) ใน appsettings หรือ command line
        bool rejectWeakPasswords = builder.Configuration.GetValue<bool?>("Accounts:RejectWeakPasswords")
            ?? !builder.Environment.IsDevelopment();
        builder.Services.AddSingleton(new AccountOptions { RejectWeakPasswords = rejectWeakPasswords });
        builder.Services.AddSingleton<AccountService>();
        builder.Services.AddSingleton<RequireSessionFilter>();

        // Rate limiting configurations
        // ค่าเริ่มต้นคิดเผื่อห้องเรียน / แล็บที่ทุกคนออกเน็ต IP เดียวกัน (ประมาณ 40 คน) ทุกค่าตั้งใหม่ได้ใน appsettings / command line
        //   AuthPermitLimit    endpoint ที่ไม่ต้องล็อกอิน (สมัคร / ตรวจซ้ำ / ล็อกอิน / ต่ออายุ) ต่อ IP ต่อนาที
        //                      วันที่ทั้งห้องสมัครพร้อมกัน ตั้งชั่วคราวราว 3 เท่าของจำนวนคน (เช่น 40 คน = 120-150)
        //   AccountPermitLimit endpoint ที่ต้องล็อกอิน (/me/*) ต่อ session ต่อนาที (คนในเน็ตเดียวกันไม่แย่งกัน)
        //   GlobalPermitLimit  ทุกคำขอรวมกันต่อ IP ต่อนาที (เพดานสุดท้าย กันการสุ่ม token มายิง)
        int authPermitLimit = builder.Configuration.GetValue("RateLimit:AuthPermitLimit", 60);
        int accountPermitLimit = builder.Configuration.GetValue("RateLimit:AccountPermitLimit", 60);
        int globalPermitLimit = builder.Configuration.GetValue("RateLimit:GlobalPermitLimit", 300);

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

            // endpoint ที่ไม่ต้องล็อกอิน (register, register/check, login, refresh): นับต่อ IP
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

            // endpoint ที่ต้องล็อกอิน (/me/*): นับต่อ session แทนต่อ IP ผู้เล่นหลายคนในเน็ตเดียวกันจึงไม่แย่งโควตากัน
            // กุญแจเป็น hash ของ token (ไม่เก็บ token จริงไว้ในตัวนับ) ไม่มี token / token รูปแบบผิด = นับรวมต่อ IP
            // คนที่สุ่ม token รูปแบบถูกมายิงจะได้ตัวนับแยก แต่ยังติดเพดานรวมต่อ IP (GlobalLimiter) ด้านบน
            rateLimiterOptions.AddPolicy("account", httpContext =>
            {
                var tokenService = httpContext.RequestServices.GetRequiredService<SessionTokenService>();
                string key = RequireSessionFilter.TryReadBearerToken(httpContext.Request, out string token) &&
                             tokenService.TryHashToken(token, out string tokenHash)
                    ? "session:" + tokenHash
                    : "ip:" + (httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown");
                return RateLimitPartition.GetFixedWindowLimiter(
                    partitionKey: key,
                    factory: _ => new FixedWindowRateLimiterOptions
                    {
                        PermitLimit = accountPermitLimit,
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