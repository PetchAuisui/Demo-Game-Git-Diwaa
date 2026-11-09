using System.Globalization;
using GitDiwaa.Online.Accounts.Contracts;
using GitDiwaa.Server.Security;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;

namespace GitDiwaa.Server.Accounts;

public static class AccountEndpoints
{
    public static void MapAccountEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/accounts");

        group.MapPost("/register", async (RegisterRequest? request, AccountService accountService, CancellationToken ct) =>
        {
            if (request is null)
            {
                var emptyError = new ApiError(AuthErrorCode.ValidationFailed, []);
                return Results.Json(emptyError, statusCode: StatusCodes.Status400BadRequest);
            }

            var result = await accountService.RegisterAsync(request, ct);
            if (result.Succeeded)
            {
                return Results.Json(result.Value, statusCode: StatusCodes.Status201Created);
            }

            int statusCode = result.Error switch
            {
                AuthErrorCode.ValidationFailed => StatusCodes.Status400BadRequest,
                AuthErrorCode.IdentifierTaken => StatusCodes.Status409Conflict,
                _ => StatusCodes.Status400BadRequest
            };

            var apiError = new ApiError(result.Error ?? AuthErrorCode.Unknown, result.FieldErrors);
            return Results.Json(apiError, statusCode: statusCode);
        }).RequireRateLimiting("auth");

        group.MapPost("/login", async (LoginRequest? request, AccountService accountService, HttpResponse response, CancellationToken ct) =>
        {
            response.Headers.CacheControl = "no-store";

            if (request is null)
            {
                var emptyError = new ApiError(AuthErrorCode.ValidationFailed, []);
                return Results.Json(emptyError, statusCode: StatusCodes.Status400BadRequest);
            }

            var result = await accountService.LoginAsync(request, ct);
            if (result.Succeeded && result.Value is not null)
            {
                var loginResponse = new LoginResponse(
                    result.Value.Profile,
                    result.Value.Token,
                    result.Value.ExpiresAt);

                return Results.Json(loginResponse, statusCode: StatusCodes.Status200OK);
            }

            int statusCode = result.Error switch
            {
                AuthErrorCode.ValidationFailed => StatusCodes.Status400BadRequest,
                AuthErrorCode.InvalidCredentials => StatusCodes.Status401Unauthorized,
                _ => StatusCodes.Status401Unauthorized
            };

            var apiError = new ApiError(result.Error ?? AuthErrorCode.Unknown, result.FieldErrors);
            return Results.Json(apiError, statusCode: statusCode);
        }).RequireRateLimiting("auth");

        group.MapGet("/me", (HttpContext httpContext) =>
        {
            var session = (AuthenticatedSession)httpContext.Items[RequireSessionFilter.SessionItemKey]!;
            return Results.Json(session.Profile, statusCode: StatusCodes.Status200OK);
        }).AddEndpointFilter<RequireSessionFilter>();

        // เปลี่ยนชื่อที่แสดง: ต้อง login (token ใน Authorization header) และใช้ rate limit แบบเดียวกับ login
        // ผู้ใช้ที่จะถูกเปลี่ยนชื่อมาจาก session เท่านั้น เปลี่ยนชื่อของคนอื่นไม่ได้
        group.MapPatch("/me/display-name", async (
            ChangeDisplayNameRequest? request,
            HttpContext httpContext,
            AccountService accountService,
            TimeProvider timeProvider,
            CancellationToken ct) =>
        {
            httpContext.Response.Headers.CacheControl = "no-store";

            if (request is null)
            {
                var emptyError = new ApiError(AuthErrorCode.ValidationFailed, []);
                return Results.Json(emptyError, statusCode: StatusCodes.Status400BadRequest);
            }

            var session = (AuthenticatedSession)httpContext.Items[RequireSessionFilter.SessionItemKey]!;
            var result = await accountService.ChangeDisplayNameAsync(session.Profile.Id, request, ct);
            if (result.Succeeded && result.Value is not null)
            {
                return Results.Json(result.Value, statusCode: StatusCodes.Status200OK);
            }

            if (result.Error == AuthErrorCode.DisplayNameChangeCooldown && result.Value is not null)
            {
                // บอก client ว่าต้องรออีกกี่วินาทีถึงจะเปลี่ยนชื่อได้
                double waitSeconds = (result.Value.NextChangeAllowedAt - timeProvider.GetUtcNow()).TotalSeconds;
                long retryAfter = Math.Max(1, (long)Math.Ceiling(waitSeconds));
                httpContext.Response.Headers.RetryAfter = retryAfter.ToString(CultureInfo.InvariantCulture);
            }

            int statusCode = result.Error switch
            {
                AuthErrorCode.ValidationFailed => StatusCodes.Status400BadRequest,
                AuthErrorCode.IdentifierTaken => StatusCodes.Status409Conflict,
                AuthErrorCode.DisplayNameChangeCooldown => StatusCodes.Status409Conflict,
                AuthErrorCode.InvalidCredentials => StatusCodes.Status401Unauthorized,
                _ => StatusCodes.Status400BadRequest
            };

            var apiError = new ApiError(result.Error ?? AuthErrorCode.Unknown, result.FieldErrors);
            return Results.Json(apiError, statusCode: statusCode);
        }).AddEndpointFilter<RequireSessionFilter>().RequireRateLimiting("auth");

        // ความยินยอมแสดงชื่อบนตารางอันดับ: ดูได้ และให้ / ถอนได้ตลอดเวลา (ต้อง login)
        group.MapGet("/me/leaderboard-consent", async (
            HttpContext httpContext,
            AccountService accountService,
            CancellationToken ct) =>
        {
            httpContext.Response.Headers.CacheControl = "no-store";

            var session = (AuthenticatedSession)httpContext.Items[RequireSessionFilter.SessionItemKey]!;
            var result = await accountService.GetLeaderboardConsentAsync(session.Profile.Id, ct);
            if (result.Succeeded && result.Value is not null)
            {
                return Results.Json(result.Value, statusCode: StatusCodes.Status200OK);
            }

            var apiError = new ApiError(result.Error ?? AuthErrorCode.Unknown, result.FieldErrors);
            return Results.Json(apiError, statusCode: StatusCodes.Status401Unauthorized);
        }).AddEndpointFilter<RequireSessionFilter>();

        group.MapPut("/me/leaderboard-consent", async (
            LeaderboardConsentRequest? request,
            HttpContext httpContext,
            AccountService accountService,
            CancellationToken ct) =>
        {
            httpContext.Response.Headers.CacheControl = "no-store";

            if (request is null)
            {
                var emptyError = new ApiError(AuthErrorCode.ValidationFailed, []);
                return Results.Json(emptyError, statusCode: StatusCodes.Status400BadRequest);
            }

            var session = (AuthenticatedSession)httpContext.Items[RequireSessionFilter.SessionItemKey]!;
            var result = await accountService.SetLeaderboardConsentAsync(session.Profile.Id, request, ct);
            if (result.Succeeded && result.Value is not null)
            {
                return Results.Json(result.Value, statusCode: StatusCodes.Status200OK);
            }

            int statusCode = result.Error switch
            {
                AuthErrorCode.ValidationFailed => StatusCodes.Status400BadRequest,
                AuthErrorCode.InvalidCredentials => StatusCodes.Status401Unauthorized,
                _ => StatusCodes.Status400BadRequest
            };

            var apiError = new ApiError(result.Error ?? AuthErrorCode.Unknown, result.FieldErrors);
            return Results.Json(apiError, statusCode: statusCode);
        }).AddEndpointFilter<RequireSessionFilter>().RequireRateLimiting("auth");

        group.MapPost("/refresh", async (HttpRequest request, HttpResponse response, AccountService accountService, CancellationToken ct) =>
        {
            response.Headers.CacheControl = "no-store";

            if (!RequireSessionFilter.TryReadBearerToken(request, out string token))
            {
                response.Headers.WWWAuthenticate = "Bearer";
                var error = new ApiError(AuthErrorCode.InvalidCredentials, []);
                return Results.Json(error, statusCode: StatusCodes.Status401Unauthorized);
            }

            var result = await accountService.RefreshAsync(token, ct);
            if (result.Succeeded && result.Value is not null)
            {
                var loginResponse = new LoginResponse(
                    result.Value.Profile,
                    result.Value.Token,
                    result.Value.ExpiresAt);

                return Results.Json(loginResponse, statusCode: StatusCodes.Status200OK);
            }

            response.Headers.WWWAuthenticate = "Bearer";
            var apiError = new ApiError(AuthErrorCode.InvalidCredentials, []);
            return Results.Json(apiError, statusCode: StatusCodes.Status401Unauthorized);
        }).RequireRateLimiting("auth");

        group.MapPost("/logout", async (HttpRequest request, AccountService accountService, CancellationToken ct) =>
        {
            if (RequireSessionFilter.TryReadBearerToken(request, out string token))
            {
                await accountService.LogoutAsync(token, ct);
            }

            return Results.NoContent();
        });
    }
}