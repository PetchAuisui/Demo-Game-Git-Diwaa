namespace GitDiwaa.RealGit;

public sealed record PolicyDecision(bool Allowed, IReadOnlyList<string> Arguments, string? Reason)
{
    public static PolicyDecision Allow(IReadOnlyList<string> args) => new(true, args, null);
    public static PolicyDecision Deny(string reason) => new(false, [], reason);
}

/// <summary>
/// Whitelist-based validation of player commands. Only the modern, lesson-relevant
/// part of git is reachable, and no argument may point outside the sandbox.
/// </summary>
public sealed class CommandPolicy
{
    public const string DefaultVirtualRemoteBase = "https://archive.diwaa/";

    private static readonly HashSet<string> AllowedSubcommands =
    [
        "config", "init", "status", "add", "commit", "log", "diff", "show",
        "restore", "reset", "branch", "switch", "merge", "clone", "remote",
        "pull", "push", "fetch", "rm", "mv", "version"
    ];

    private static readonly Dictionary<string, string> LegacyReplacements = new()
    {
        ["checkout"] = "ใช้ `git switch <branch>` เพื่อข้ามมิติ หรือ `git restore <file>` เพื่อฟื้นคืนไฟล์ (Git สมัยใหม่ ≥ 2.23)",
    };

    private static readonly string[] ForbiddenOptionPrefixes =
    [
        "--git-dir", "--work-tree", "--exec-path", "--namespace", "--upload-pack", "--receive-pack",
        "--exec", "--template", "--config", "--output", "--ext-diff", "--separate-git-dir",
        "--reference", "--shared", "--config-env", "--super-prefix", "--recurse-submodules",
        "--file", "--blob", "--system", "--worktree", "--open-files-in-pager", "--include",
        "--edit", "--interactive", "--patch",
    ];

    private static readonly HashSet<string> ForbiddenShortOptions = ["-C", "-c", "-i", "-p", "-e"];
    private static readonly HashSet<string> ShellOperators = ["|", "||", "&", "&&", ";", ">", ">>", "<", "<<", "$(", "`"];
    private static readonly HashSet<string> MessageOptions = ["-m", "--message", "--grep", "--author"];
    private static readonly HashSet<string> AllowedConfigKeys = ["user.name", "user.email"];

    public string VirtualRemoteBase { get; }

    public CommandPolicy(string virtualRemoteBase = DefaultVirtualRemoteBase)
    {
        VirtualRemoteBase = virtualRemoteBase;
    }

    public PolicyDecision Evaluate(string commandLine)
    {
        if (string.IsNullOrWhiteSpace(commandLine))
            return PolicyDecision.Deny("ยังไม่ได้ร่ายคาถาใด ๆ");

        var tokens = CommandTokenizer.Tokenize(commandLine.Trim(), out var tokenError);
        if (tokenError is not null) return PolicyDecision.Deny(tokenError);

        foreach (var t in tokens)
        {
            if (!t.WasQuoted && (ShellOperators.Contains(t.Value) || t.Value.Contains("$(") || t.Value.Contains('`')))
                return PolicyDecision.Deny("วงเวทนี้ร่ายได้ทีละคาถา — ไม่รองรับการเชื่อมคำสั่ง (|, ;, &&, >)");
        }

        if (tokens.Count == 0 || tokens[0].Value != "git")
            return PolicyDecision.Deny("คาถาในวงร่ายเวทต้องขึ้นต้นด้วย `git`");

        var args = tokens.Skip(1).Select(t => t.Value).ToList();
        if (args.Count == 0)
            return PolicyDecision.Deny("ต้องระบุคาถาต่อจาก `git` เช่น `git status`");

        if (args.Count == 1 && args[0] is "--version" or "-v")
            return PolicyDecision.Allow(["--version"]);

        var sub = args[0];
        if (sub.StartsWith('-'))
            return PolicyDecision.Deny($"ไม่อนุญาตตัวเลือกระดับบนสุด `{sub}` ในหอคอย ให้ใส่ชื่อคาถาก่อน เช่น `git status`");

        if (LegacyReplacements.TryGetValue(sub, out var replacement))
            return PolicyDecision.Deny($"`git {sub}` เป็นคาถารุ่นเก่า — {replacement}");

        if (!AllowedSubcommands.Contains(sub))
            return PolicyDecision.Deny($"`git {sub}` ยังไม่อยู่ในสมุดคาถาของหอคอย");

        var rest = args.Skip(1).ToList();
        var optionError = ValidateOptions(sub, rest);
        if (optionError is not null) return PolicyDecision.Deny(optionError);

        var specific = sub switch
        {
            "config" => ValidateConfig(rest),
            "clone" => ValidateClone(rest),
            "remote" => ValidateRemote(rest),
            _ => null,
        };
        return specific is null ? PolicyDecision.Allow(args) : PolicyDecision.Deny(specific);
    }

    private string? ValidateOptions(string sub, List<string> rest)
    {
        for (var i = 0; i < rest.Count; i++)
        {
            var arg = rest[i];

            if (MessageOptions.Contains(arg))
            {
                i++; // free text value, never a path
                continue;
            }

            if (arg.StartsWith("--message=") || arg.StartsWith("--grep=") || arg.StartsWith("--author=") ||
                (arg.StartsWith("-m") && arg.Length > 2 && sub == "commit"))
                continue;

            if (arg.StartsWith("--"))
            {
                var name = arg.Split('=', 2)[0];
                if (ForbiddenOptionPrefixes.Any(f => name == f || name.StartsWith(f + "-")))
                    return $"ตัวเลือก `{name}` ถูกผนึกไว้ในหอคอยเพื่อความปลอดภัย";
                if (arg.Contains('=') && IsUnsafePath(arg.Split('=', 2)[1]))
                    return $"ห้ามอ้างถึงที่อยู่นอกพื้นที่ของตน: `{arg}`";
                continue;
            }

            if (arg.StartsWith('-') && arg.Length > 1)
            {
                if (IsForbiddenShortOption(sub, arg))
                    return $"ตัวเลือก `{arg}` ใช้กับ `git {sub}` ในหอคอยไม่ได้";

                // Bundled flags such as `git commit -am "msg"`: the next token is the message.
                if (sub == "commit" && !arg.StartsWith("--") && arg.EndsWith('m'))
                    i++;
                continue;
            }

            if (IsRemoteUrl(arg))
                continue;

            if (IsUnsafePath(arg))
                return $"ห้ามอ้างถึงที่อยู่นอกพื้นที่ของตน: `{arg}`";
        }

        return null;
    }

    private static bool IsForbiddenShortOption(string sub, string arg)
    {
        if (!ForbiddenShortOptions.Contains(arg)) return false;
        return (sub, arg) switch
        {
            ("switch", "-c" or "-C") => false,          // create + switch branch
            ("log" or "show" or "diff", "-p") => false, // patch output, not interactive
            _ => true,
        };
    }

    private string? ValidateConfig(List<string> rest)
    {
        var scopeless = rest.Where(a => a is not ("--global" or "--local")).ToList();
        if (scopeless.Count == 1 && scopeless[0] is "--list" or "-l")
            return null;

        if (scopeless.Count >= 1 && scopeless[0] == "--get")
            scopeless.RemoveAt(0);

        if (scopeless.Count is < 1 or > 2)
            return "รูปแบบ: git config --global user.name \"ชื่อ\"";

        var key = scopeless[0];
        if (!AllowedConfigKeys.Contains(key))
            return $"หอคอยอนุญาตให้ตั้งค่าเฉพาะ user.name และ user.email เท่านั้น (ไม่ใช่ `{key}`)";

        return null;
    }

    private string? ValidateClone(List<string> rest)
    {
        var positional = rest.Where(a => !a.StartsWith('-')).ToList();
        if (positional.Count == 0)
            return "ต้องบอกที่อยู่ของคัมภีร์ในคลังเวท เช่น git clone https://archive.diwaa/<name>.git";
        if (!IsRemoteUrl(positional[0]))
            return $"คัดลอกได้เฉพาะคัมภีร์จากคลังเวทกลาง ({VirtualRemoteBase}...)";
        return null;
    }

    private string? ValidateRemote(List<string> rest)
    {
        var positional = rest.Where(a => !a.StartsWith('-')).ToList();
        if (positional.Count == 0) return null;

        var action = positional[0];
        if (action is "add" or "set-url")
        {
            if (positional.Count < 3)
                return $"รูปแบบ: git remote {action} <ชื่อ> <ที่อยู่>";
            if (!IsRemoteUrl(positional[2]))
                return $"สายเชื่อมต้องชี้ไปยังคลังเวทกลาง ({VirtualRemoteBase}...)";
        }
        else if (action is not ("remove" or "rm" or "rename" or "show" or "get-url" or "-v"))
        {
            return $"`git remote {action}` ยังไม่อยู่ในสมุดคาถาของหอคอย";
        }
        return null;
    }


    public bool IsRemoteUrl(string value) =>
        value.StartsWith(VirtualRemoteBase, StringComparison.OrdinalIgnoreCase) &&
        !value[VirtualRemoteBase.Length..].Contains("..") &&
        !value.Contains('\\');

    public static bool IsUnsafePath(string value)
    {
        if (string.IsNullOrEmpty(value)) return false;
        if (value.StartsWith('/') || value.StartsWith('~') || value.StartsWith('\\')) return true;
        if (value.Length >= 2 && char.IsLetter(value[0]) && value[1] == ':') return true;
        if (value.Contains("://") || value.StartsWith("file:") || value.StartsWith("ext::") || value.Contains('@') && value.Contains(':'))
            return true;
        var segments = value.Replace('\\', '/').Split('/');
        return segments.Any(s => s == "..") || segments.Any(s => s == ".git");
    }
}
