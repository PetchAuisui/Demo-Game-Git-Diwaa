using System.Buffers.Text;
using System.Security.Cryptography;
using System.Text;

namespace GitDiwaa.Server.Security;

public sealed record IssuedToken(string Token, string TokenHash)
{
    private bool PrintMembers(StringBuilder builder)
    {
        builder.Append("Token = ***, TokenHash = ").Append(TokenHash);
        return true;
    }
}

public sealed class SessionTokenService
{
    public const int TokenByteLength = 32;
    public const int TokenTextLength = 43;

    public IssuedToken CreateToken()
    {
        byte[] tokenBytes = RandomNumberGenerator.GetBytes(TokenByteLength);
        string token = Base64Url.EncodeToString(tokenBytes);
        string tokenHash = HashTokenString(token);

        return new IssuedToken(token, tokenHash);
    }

    public bool TryHashToken(string? token, out string tokenHash)
    {
        tokenHash = string.Empty;

        if (token is null || token.Length != TokenTextLength)
        {
            return false;
        }

        foreach (char c in token)
        {
            if (!IsBase64UrlChar(c))
            {
                return false;
            }
        }

        tokenHash = HashTokenString(token);
        return true;
    }

    private static string HashTokenString(string token)
    {
        byte[] utf8Bytes = Encoding.UTF8.GetBytes(token);
        byte[] hashBytes = SHA256.HashData(utf8Bytes);
        return Convert.ToHexStringLower(hashBytes);
    }

    private static bool IsBase64UrlChar(char c) =>
        c is (>= 'a' and <= 'z')
            or (>= 'A' and <= 'Z')
            or (>= '0' and <= '9')
            or '-'
            or '_';
}