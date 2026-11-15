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

        // ตรวจก่อนสมัคร (เกมเรียกก่อนเปิดหน้านโยบาย) 204 = ใช้ได้ / 409 = มีคนใช้แล้ว (ไม่บอกว่าช่องไหน) / 400 = รูปแบบผิด
        // ใช้ POST ไม่ใช่ GET เพื่อไม่ให้อีเมลไปอยู่ใน URL และ access log
        group.MapPost("/register/check", async (RegisterCheckRequest? request, AccountService accountService, CancellationToken ct) =>
        {
            if (request is null)
            {
                return Results.Json(new ApiError(AuthErrorCode.ValidationFailed, []), statusCode: StatusCodes.Status400BadRequest);
            }

            var result = await accountService.CheckRegistrationAsync(request, ct);
            if (result.Succeeded)
            {
                return Results.NoContent();
            }

            int statusCode = result.Error == AuthErrorCode.IdentifierTaken
                ? StatusCodes.Status409Conflict
                : StatusCodes.Status400BadRequest;
            return Results.Json(new ApiError(result.Error ?? AuthErrorCode.Unknown, result.FieldErrors), statusCode: statusCode);
        }).RequireRateLimiting("auth");

        group.MapPost("/login", async (LoginRequest? request, AccountService accountService, HttpContext httpContext, CancellationToken ct) =>
        {
            var response = httpContext.Response;
            response.Headers.CacheControl = "no-store";

            if (request is null)
            {
                var emptyError = new ApiError(AuthErrorCode.ValidationFailed, []);
                return Results.Json(emptyError, statusCode: StatusCodes.Status400BadRequest);
            }

            // ต้นทางของคำขอ ใช้นับการใส่รหัสผิดแยกตาม IP (อยู่หลัง proxy ต้องตั้ง ForwardedHeaders ไม่งั้นทุกคนเป็น IP เดียวกัน)
            string clientKey = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
            var result = await accountService.LoginAsync(request, clientKey, ct);
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
        }).AddEndpointFilter<RequireSessionFilter>().RequireRateLimiting("account");

        // สถานะชื่อที่แสดง (เปลี่ยนได้อีกกี่ครั้ง / เมื่อไหร่) ให้หน้าบัญชีแสดงก่อนผู้เล่นกดเปลี่ยน
        group.MapGet("/me/display-name", async (
            HttpContext httpContext,
            AccountService accountService,
            CancellationToken ct) =>
        {
            httpContext.Response.Headers.CacheControl = "no-store";

            var session = (AuthenticatedSession)httpContext.Items[RequireSessionFilter.SessionItemKey]!;
            var result = await accountService.GetDisplayNameStatusAsync(session.Profile.Id, ct);
            if (result.Succeeded && result.Value is not null)
            {
                return Results.Json(result.Value, statusCode: StatusCodes.Status200OK);
            }

            var apiError = new ApiError(result.Error ?? AuthErrorCode.Unknown, result.FieldErrors);
            return Results.Json(apiError, statusCode: StatusCodes.Status401Unauthorized);
        }).AddEndpointFilter<RequireSessionFilter>().RequireRateLimiting("account");

        // อีเมลของเจ้าของ token เท่านั้น (เมนูบัญชีในเกมแสดงแบบปิดบัง) ผู้ใช้มาจาก session จึงขอของคนอื่นไม่ได้
        // ไม่ให้แคช และจำกัดจำนวนครั้งเหมือน login: ถ้า token หลุด คนที่ได้ token ไปจะดึงข้อมูลได้ช้าลง
        group.MapGet("/me/email", async (
            HttpContext httpContext,
            AccountService accountService,
            CancellationToken ct) =>
        {
            httpContext.Response.Headers.CacheControl = "no-store";

            var session = (AuthenticatedSession)httpContext.Items[RequireSessionFilter.SessionItemKey]!;
            var result = await accountService.GetEmailAsync(session.Profile.Id, ct);
            if (result.Succeeded && result.Value is not null)
            {
                return Results.Json(result.Value, statusCode: StatusCodes.Status200OK);
            }

            var apiError = new ApiError(result.Error ?? AuthErrorCode.Unknown, result.FieldErrors);
            return Results.Json(apiError, statusCode: StatusCodes.Status401Unauthorized);
        }).AddEndpointFilter<RequireSessionFilter>().RequireRateLimiting("account");

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
        }).AddEndpointFilter<RequireSessionFilter>().RequireRateLimiting("account");

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
        }).AddEndpointFilter<RequireSessionFilter>().RequireRateLimiting("account");

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
        }).AddEndpointFilter<RequireSessionFilter>().RequireRateLimiting("account");

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
        // เดิม /logout มีแค่เพดานรวมต่อ IP (ไม่เคยกินโควตาล็อกอินของใคร) เพิ่มโควตาเฉพาะตามรีวิว
        // เลือก policy "account" (ต่อ session) ไม่ใช่ "auth" (ต่อ IP): ถ้าใช้ "auth" การออกจากระบบจะเริ่มกินโควตาล็อกอิน / สมัคร
        // ของคนอื่นในเน็ตเดียวกัน ส่วน "account" นับแยกตาม token คนที่ไม่มี token ใบนั้นใช้โควตานี้ไม่ได้
        }).RequireRateLimiting("account");
    }
}