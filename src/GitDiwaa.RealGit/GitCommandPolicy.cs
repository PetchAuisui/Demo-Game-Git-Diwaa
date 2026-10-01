namespace GitDiwaa.RealGit;

internal sealed class GitCommandPolicy
{
    private static readonly HashSet<string> AllowedCommands = new(StringComparer.Ordinal)
    {
        "init", "status", "add", "commit", "log", "diff", "restore", "reset",
        "branch", "switch", "merge", "clone", "remote", "fetch", "pull", "push"
    };

    private readonly GitSandbox _sandbox;
    private readonly LocalRemote _remote;

    public GitCommandPolicy(GitSandbox sandbox, LocalRemote remote)
    {
        _sandbox = sandbox;
        _remote = remote;
    }

    public string? Validate(IReadOnlyList<string> arguments)
    {
        if (arguments.Count == 0) return "Missing Git command.";
        if (arguments.Count == 1 && arguments[0] == "--version") return null;
        if (arguments[0] == "config") return ValidateConfig(arguments);
        if (!AllowedCommands.Contains(arguments[0]))
            return $"Command 'git {arguments[0]}' is not enabled in Git-Diwaa.";

        if (arguments.Any(IsProcessEscapeOption))
            return "Changing Git's executable, config, hooks, or working directory is not allowed.";

        return arguments[0] switch
        {
            "init" => arguments.Count == 1 ? null : "Use: git init",
            "status" => arguments.Count == 1 ? null : "Use: git status",
            "add" => ValidatePathCommand(arguments, ["-A", "--all"]),
            "commit" => ValidateCommit(arguments),
            "log" => ValidateLog(arguments),
            "diff" => ValidateDiff(arguments),
            "restore" => ValidatePathCommand(arguments, ["--staged"]),
            "reset" => ValidateReset(arguments),
            "branch" => ValidateBranch(arguments),
            "switch" => ValidateSwitch(arguments),
            "merge" => ValidateMerge(arguments),
            "clone" => ValidateClone(arguments),
            "remote" => ValidateRemote(arguments),
            "fetch" => ValidateFetch(arguments),
            "pull" => ValidatePull(arguments),
            "push" => ValidatePush(arguments),
            _ => "Unsupported command."
        };
    }

    private static string? ValidateConfig(IReadOnlyList<string> arguments)
    {
        if (arguments.Count is < 3 or > 4 || arguments[1] != "--global")
            return "Only sandboxed global user.name and user.email settings are allowed.";
        return arguments[2] is "user.name" or "user.email"
            ? null
            : "Only user.name and user.email may be configured.";
    }

    private static string? ValidateCommit(IReadOnlyList<string> arguments)
    {
        var index = 1;
        while (index < arguments.Count)
        {
            if (arguments[index] is "-a" or "--amend")
            {
                index++;
                continue;
            }

            if (arguments[index] == "-m" && index + 1 < arguments.Count &&
                !string.IsNullOrWhiteSpace(arguments[index + 1]))
            {
                index += 2;
                continue;
            }

            return "Git-Diwaa supports commit with -a, -m and --amend only.";
        }

        return null;
    }

    private static string? ValidateLog(IReadOnlyList<string> arguments)
    {
        for (var index = 1; index < arguments.Count; index++)
        {
            var value = arguments[index];
            if (value is "--oneline" or "--graph" or "--all" or "--decorate") continue;
            if (value == "-n" && index + 1 < arguments.Count &&
                int.TryParse(arguments[++index], out var count) && count > 0) continue;
            if (value.StartsWith("-n", StringComparison.Ordinal) &&
                int.TryParse(value[2..], out count) && count > 0) continue;
            return "Git-Diwaa supports log with --oneline, --graph, --all, --decorate and -n only.";
        }

        return null;
    }

    private static string? ValidateDiff(IReadOnlyList<string> arguments) =>
        arguments.Skip(1).All(value => value == "--staged")
            ? null
            : "Use: git diff [--staged]";

    private static string? ValidateReset(IReadOnlyList<string> arguments)
    {
        if (arguments.Count > 3) return "Use one reset mode and one revision.";
        if (arguments.Skip(1).Any(value => value.StartsWith('-') &&
            value is not ("--soft" or "--mixed" or "--hard")))
            return "Reset mode must be --soft, --mixed or --hard.";
        if (arguments.Skip(1).Any(value => !value.StartsWith('-') && !IsSafeRevision(value)))
            return "Invalid reset revision.";
        return null;
    }

    private static string? ValidateBranch(IReadOnlyList<string> arguments)
    {
        if (arguments.Count == 1) return null;
        if (arguments.Count == 2 && arguments[1] is "-a" or "--all") return null;
        if (arguments.Count == 2 && IsSafeRef(arguments[1])) return null;
        if (arguments.Count == 3 && arguments[1] == "-d" && IsSafeRef(arguments[2])) return null;
        return "Use: git branch, git branch --all, git branch <name>, or git branch -d <name>.";
    }

    private static string? ValidateSwitch(IReadOnlyList<string> arguments)
    {
        if (arguments.Count == 2 && IsSafeRef(arguments[1])) return null;
        if (arguments.Count == 3 && arguments[1] == "-c" && IsSafeRef(arguments[2])) return null;
        return "Use: git switch <branch> or git switch -c <branch>.";
    }

    private static string? ValidateMerge(IReadOnlyList<string> arguments)
    {
        if (arguments.Count == 2 && (arguments[1] == "--abort" || IsSafeRef(arguments[1]))) return null;
        if (arguments.Count == 3 && arguments[1] == "--no-ff" && IsSafeRef(arguments[2])) return null;
        return "Use: git merge <branch>, git merge --no-ff <branch>, or git merge --abort.";
    }

    private string? ValidateClone(IReadOnlyList<string> arguments)
    {
        if (arguments.Count != 2) return "Use: git clone <game-remote-url>.";
        if (Directory.EnumerateFileSystemEntries(_sandbox.PlayerRepositoryPath).Any())
            return "The player repository must be empty before clone.";
        return ValidateRemoteUrl(arguments[1]);
    }

    private string? ValidateRemote(IReadOnlyList<string> arguments)
    {
        if (arguments.Count == 2 && arguments[1] == "-v") return null;
        if (arguments.Count == 4 && arguments[1] == "add" && IsSafeRef(arguments[2]))
            return ValidateRemoteUrl(arguments[3]);
        if (arguments.Count == 4 && arguments[1] == "set-url" && IsSafeRef(arguments[2]))
            return ValidateRemoteUrl(arguments[3]);
        if (arguments.Count == 3 && arguments[1] == "remove" && IsSafeRef(arguments[2])) return null;
        return "Git-Diwaa supports remote -v, add, set-url and remove.";
    }

    private static string? ValidateFetch(IReadOnlyList<string> arguments) =>
        arguments.Count <= 2 && (arguments.Count == 1 || IsSafeRef(arguments[1]))
            ? null
            : "Use: git fetch [remote].";

    private static string? ValidatePull(IReadOnlyList<string> arguments)
    {
        var remaining = arguments.Skip(1).ToList();
        remaining.RemoveAll(value => value == "--rebase");
        return remaining.Count <= 2 && remaining.All(IsSafeRef)
            ? null
            : "Use: git pull [--rebase] [remote] [branch].";
    }

    private static string? ValidatePush(IReadOnlyList<string> arguments)
    {
        var remaining = arguments.Skip(1).ToList();
        remaining.RemoveAll(value => value is "-u" or "--set-upstream" or "-f" or "--force");
        return remaining.Count <= 2 && remaining.All(IsSafeRef)
            ? null
            : "Use: git push [-u] [--force] [remote] [branch].";
    }

    private static string? ValidatePathCommand(
        IReadOnlyList<string> arguments,
        IReadOnlyCollection<string> allowedOptions)
    {
        if (arguments.Count < 2) return $"git {arguments[0]} requires a file path.";
        foreach (var value in arguments.Skip(1))
        {
            if (value.StartsWith('-') && !allowedOptions.Contains(value))
                return $"Option '{value}' is not enabled.";
            if (!value.StartsWith('-') && value != "." && !IsSafeRelativePath(value))
                return "File path escapes the repository or targets Git metadata.";
        }

        return null;
    }

    private string? ValidateRemoteUrl(string url)
    {
        if (url.Equals(_remote.AliasUrl, StringComparison.Ordinal)) return null;
        if (Path.IsPathRooted(url) &&
            Path.GetFullPath(url).Equals(
                Path.GetFullPath(_remote.BareRepositoryPath),
                OperatingSystem.IsWindows() ? StringComparison.OrdinalIgnoreCase : StringComparison.Ordinal))
            return null;
        return "Only the local remote registered for this Git-Diwaa session is allowed.";
    }

    private static bool IsProcessEscapeOption(string value) =>
        value is "-C" or "--exec-path" or "--git-dir" or "--work-tree" or "--config-env" ||
        value.StartsWith("--exec-path=", StringComparison.Ordinal) ||
        value.StartsWith("--git-dir=", StringComparison.Ordinal) ||
        value.StartsWith("--work-tree=", StringComparison.Ordinal) ||
        value.StartsWith("--config-env=", StringComparison.Ordinal) ||
        value.StartsWith("--upload-pack=", StringComparison.Ordinal) ||
        value.StartsWith("--receive-pack=", StringComparison.Ordinal);

    private static bool IsSafeRelativePath(string value) =>
        !Path.IsPathRooted(value) &&
        !value.Split(['/', '\\'], StringSplitOptions.RemoveEmptyEntries)
            .Contains("..", StringComparer.Ordinal) &&
        !value.Split(['/', '\\'], StringSplitOptions.RemoveEmptyEntries)
            .Contains(".git", StringComparer.OrdinalIgnoreCase);

    private static bool IsSafeRevision(string value) =>
        !string.IsNullOrWhiteSpace(value) &&
        !value.StartsWith('-') &&
        value.All(character => char.IsAsciiLetterOrDigit(character) || character is '-' or '_' or '/' or '.' or '~' or '^');

    private static bool IsSafeRef(string value) =>
        !string.IsNullOrWhiteSpace(value) &&
        !value.StartsWith('-') &&
        !value.Contains("..", StringComparison.Ordinal) &&
        !value.EndsWith(".", StringComparison.Ordinal) &&
        value.All(character => char.IsAsciiLetterOrDigit(character) || character is '-' or '_' or '/' or '.');
}
