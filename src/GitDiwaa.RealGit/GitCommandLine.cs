using System.Text;

namespace GitDiwaa.RealGit;

internal static class GitCommandLine
{
    public static IReadOnlyList<string> Tokenize(string input)
    {
        ArgumentNullException.ThrowIfNull(input);

        var tokens = new List<string>();
        var current = new StringBuilder();
        char? quote = null;

        for (var index = 0; index < input.Length; index++)
        {
            var character = input[index];
            if (quote is not null)
            {
                if (character == quote)
                {
                    quote = null;
                    continue;
                }

                if (quote == '"' && character == '\\' && index + 1 < input.Length &&
                    input[index + 1] is '"' or '\\')
                {
                    current.Append(input[++index]);
                    continue;
                }

                current.Append(character);
                continue;
            }

            if (character is '\'' or '"')
            {
                quote = character;
            }
            else if (char.IsWhiteSpace(character))
            {
                AddCurrentToken(tokens, current);
            }
            else
            {
                current.Append(character);
            }
        }

        if (quote is not null) throw new ArgumentException("Unterminated quote.", nameof(input));
        AddCurrentToken(tokens, current);
        return tokens;
    }

    private static void AddCurrentToken(List<string> tokens, StringBuilder current)
    {
        if (current.Length == 0) return;
        tokens.Add(current.ToString());
        current.Clear();
    }
}

