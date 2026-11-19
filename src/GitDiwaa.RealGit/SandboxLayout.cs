namespace GitDiwaa.RealGit;

/// <summary>
/// Physical layout of one sandbox:
/// <code>
/// root/
///   home/.gitconfig   ← the only config git is allowed to see
///   hooks/            ← empty; core.hooksPath points here
///   workspace/        ← everything the player can touch
///   remotes/*.git     ← bare repositories served as https://archive.diwaa/*
///   npc/*             ← other mages' clones used by floor scripts
/// </code>
/// </summary>
public sealed class SandboxLayout
{
    public string Root { get; }
    public string Home => Path.Combine(Root, "home");
    public string GlobalConfig => Path.Combine(Home, ".gitconfig");
    public string Hooks => Path.Combine(Root, "hooks");
    public string Workspace => Path.Combine(Root, "workspace");
    public string Remotes => Path.Combine(Root, "remotes");
    public string Npc => Path.Combine(Root, "npc");

    public SandboxLayout(string root)
    {
        // Resolve symlinks (macOS /var → /private/var) so ceiling directories and jail checks match.
        Directory.CreateDirectory(root);
        Root = ResolveRealPath(root);
    }

    public void Create()
    {
        foreach (var dir in new[] { Home, Hooks, Workspace, Remotes, Npc })
            Directory.CreateDirectory(dir);
        if (!File.Exists(GlobalConfig))
            File.WriteAllText(GlobalConfig, string.Empty);
    }

    public string RemotesUrlPrefix => new Uri(Remotes + Path.DirectorySeparatorChar).AbsoluteUri;

    /// <summary>Maps a workspace-relative path to an absolute path, or null if it escapes the jail.</summary>
    public string? ResolveInWorkspace(string relativeTo, string path)
    {
        if (CommandPolicy.IsUnsafePath(path) && !path.StartsWith('.')) return null;
        var full = Path.GetFullPath(Path.Combine(relativeTo, path));
        return IsInside(Workspace, full) ? full : null;
    }

    public static bool IsInside(string parent, string candidate)
    {
        var p = Path.GetFullPath(parent).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
        var c = Path.GetFullPath(candidate).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
        return c.StartsWith(p, StringComparison.Ordinal);
    }

    private static string ResolveRealPath(string path)
    {
        var full = Path.GetFullPath(path);
        var info = new DirectoryInfo(full);
        var segments = new Stack<string>();
        while (info is not null)
        {
            if (info.LinkTarget is not null)
            {
                var target = info.ResolveLinkTarget(true)!.FullName;
                var rebuilt = segments.Aggregate(target, Path.Combine);
                return ResolveRealPath(rebuilt);
            }
            segments.Push(info.Name);
            info = info.Parent;
        }
        return full;
    }
}
