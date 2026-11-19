using System.Text;

namespace GitDiwaa.RealGit;

/// <summary>
/// Splits a command line into arguments the way a POSIX shell would for quotes,
/// but never interprets operators — the result goes straight to the git process.
/// </summary>
public static class CommandTokenizer
{
    public sealed record Token(string Value, bool WasQuoted);

    public static IReadOnlyList<Token> Tokenize(string commandLine, out string? error)
    {
        error = null;
        var tokens = new List<Token>();
        var current = new StringBuilder();
        var inToken = false;
        var quoted = false;
        char? quote = null;

        for (var i = 0; i < commandLine.Length; i++)
        {
            var ch = commandLine[i];
            if (quote is not null)
            {
                if (ch == quote) { quote = null; continue; }
                if (ch == '\\' && quote == '"' && i + 1 < commandLine.Length && commandLine[i + 1] is '"' or '\\')
                {
                    current.Append(commandLine[++i]);
                    continue;
                }
                current.Append(ch);
                continue;
            }

            switch (ch)
            {
                case '"' or '\'':
                    quote = ch;
                    inToken = true;
                    quoted = true;
                    break;
                case ' ' or '\t':
                    if (inToken) Flush();
                    break;
                default:
                    // Normalise "smart quotes" that phones and Thai keyboards like to insert.
                    if (ch is '“' or '”') { quote = '"'; inToken = true; quoted = true; break; }
                    current.Append(ch);
                    inToken = true;
                    break;
            }
        }

        if (quote is not null)
        {
            error = "เครื่องหมายคำพูดไม่ครบคู่ (unterminated quote)";
            return [];
        }

        if (inToken) Flush();
        return tokens;

        void Flush()
        {
            tokens.Add(new Token(current.ToString(), quoted));
            current.Clear();
            inToken = false;
            quoted = false;
        }
    }
}
