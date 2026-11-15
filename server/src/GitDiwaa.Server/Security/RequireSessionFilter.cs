using GitDiwaa.Online.Accounts.Contracts;
using GitDiwaa.Server.Accounts;
using Microsoft.AspNetCore.Http;

namespace GitDiwaa.Server.Security;

public sealed class RequireSessionFilter : IEndpointFilter
{
    public const string SessionItemKey = "AuthenticatedSession";
    private readonly AccountService _accountService;

    public RequireSessionFilter(AccountService accountService)
    {
        _accountService = accountService ?? throw new ArgumentNullException(nameof(accountService));
    }

    public async ValueTask<object?> InvokeAsync(EndpointFilterInvocationContext context, EndpointFilterDelegate next)
    {
        var httpContext = context.HttpContext;

        if (!TryReadBearerToken(httpContext.Request, out string token))
        {
            return UnauthorizedResponse(httpContext);
        }

        var result = await _accountService.ValidateSessionAsync(token, httpContext.RequestAborted);
        if (!result.Succeeded || result.Value is null)
        {
            return UnauthorizedResponse(httpContext);
        }

        httpContext.Items[SessionItemKey] = result.Value;
        return await next(context);
    }

    public static bool TryReadBearerToken(HttpRequest request, out string token)
    {
        token = string.Empty;

        if (!request.Headers.TryGetValue("Authorization", out var authHeaderValues))
        {
            return false;
        }

        string? headerValue = authHeaderValues.ToString();
        if (string.IsNullOrWhiteSpace(headerValue))
        {
            return false;
        }

        const string prefix = "Bearer ";
        if (!headerValue.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        string extractedToken = headerValue[prefix.Length..].Trim();
        if (string.IsNullOrEmpty(extractedToken))
        {
            return false;
        }

        token = extractedToken;
        return true;
    }

    private static IResult UnauthorizedResponse(HttpContext httpContext)
    {
        httpContext.Response.Headers.WWWAuthenticate = "Bearer";
        var error = new ApiError(AuthErrorCode.InvalidCredentials, []);
        return Results.Json(error, statusCode: StatusCodes.Status401Unauthorized);
    }
}