using GitDiwaa.Server.Security;

namespace GitDiwaa.Server.Tests;

internal static class SessionTokenTests
{
    public static void Run(TestRunner runner)
    {
        runner.Run("CreateToken_IsBase64UrlOf32Bytes", static () =>
        {
            var service = new SessionTokenService();
            var issued = service.CreateToken();

            Assert.Equal(SessionTokenService.TokenTextLength, issued.Token.Length);
            Assert.DoesNotContain(issued.Token, "+");
            Assert.DoesNotContain(issued.Token, "/");
            Assert.DoesNotContain(issued.Token, "=");
        });

        runner.Run("CreateToken_HashIs64LowercaseHex", static () =>
        {
            var service = new SessionTokenService();
            var issued = service.CreateToken();

            Assert.Equal(64, issued.TokenHash.Length);
            foreach (char c in issued.TokenHash)
            {
                bool isLowerHex = c is (>= '0' and <= '9') or (>= 'a' and <= 'f');
                Assert.True(isLowerHex, $"Expected lowercase hex character but got '{c}'.");
            }
        });

        runner.Run("CreateToken_TwoTokensDiffer", static () =>
        {
            var service = new SessionTokenService();
            var token1 = service.CreateToken();
            var token2 = service.CreateToken();

            Assert.False(string.Equals(token1.Token, token2.Token, StringComparison.Ordinal));
            Assert.False(string.Equals(token1.TokenHash, token2.TokenHash, StringComparison.Ordinal));
        });

        runner.Run("CreateToken_HashDoesNotContainToken", static () =>
        {
            var service = new SessionTokenService();
            var issued = service.CreateToken();

            Assert.DoesNotContain(issued.TokenHash, issued.Token);
        });

        runner.Run("TryHashToken_MatchesIssuedHash", static () =>
        {
            var service = new SessionTokenService();
            var issued = service.CreateToken();

            var success = service.TryHashToken(issued.Token, out string computedHash);
            Assert.True(success);
            Assert.Equal(issued.TokenHash, computedHash);
        });

        runner.Run("TryHashToken_RejectsMalformed", static () =>
        {
            var service = new SessionTokenService();

            string[] malformed =
            [
                null!,
                "",
                "short",
                new string('a', 42),
                new string('a', 44),
                new string('a', 42) + "+",
                new string('a', 42) + "=",
                new string('a', 42) + "ก",
                new string('a', 10_000)
            ];

            foreach (var token in malformed)
            {
                var success = service.TryHashToken(token, out string tokenHash);
                Assert.False(success, $"Token '{token}' should have been rejected.");
                Assert.Equal(string.Empty, tokenHash);
            }
        });

        runner.Run("IssuedToken_ToString_HidesToken", static () =>
        {
            var issued = new SessionTokenService().CreateToken();
            var text = issued.ToString();
            Assert.DoesNotContain(text, issued.Token);
            Assert.Contains(text, "***");
            Assert.Contains(text, issued.TokenHash);
        });
    }
}