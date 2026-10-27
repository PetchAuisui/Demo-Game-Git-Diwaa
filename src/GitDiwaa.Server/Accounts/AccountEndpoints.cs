using GitDiwaa.Online.Accounts.Contracts;
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
        });

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
        });
    }
}