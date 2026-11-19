using GitDiwaa.Core;

namespace GitDiwaa.RealGit;

/// <summary>File access for the player, jailed to the workspace and relative to the current directory.</summary>
public sealed class SandboxFileSystem : IPlayerFileSystem
{
    private readonly SandboxLayout _layout;
    private readonly Func<string> _currentDirectory;

    public SandboxFileSystem(SandboxLayout layout, Func<string> currentDirectory)
    {
        _layout = layout;
        _currentDirectory = currentDirectory;
    }

    public async Task WriteAllTextAsync(string relativePath, string content, CancellationToken cancellationToken = default)
    {
        var full = Resolve(relativePath) ?? throw new UnauthorizedAccessException($"'{relativePath}' อยู่นอกพื้นที่ของผู้เล่น");
        Directory.CreateDirectory(Path.GetDirectoryName(full)!);
        await File.WriteAllTextAsync(full, content, cancellationToken);
    }

    public async Task<string?> ReadAllTextAsync(string relativePath, CancellationToken cancellationToken = default)
    {
        var full = Resolve(relativePath);
        return full is not null && File.Exists(full) ? await File.ReadAllTextAsync(full, cancellationToken) : null;
    }

    public bool Delete(string relativePath)
    {
        var full = Resolve(relativePath);
        if (full is null || !File.Exists(full)) return false;
        File.Delete(full);
        return true;
    }

    /// <summary>Files under the current directory (relative to it), excluding .git internals.</summary>
    public IReadOnlyList<string> ListFiles()
    {
        var root = _currentDirectory();
        if (!Directory.Exists(root)) return [];
        return Directory.EnumerateFiles(root, "*", SearchOption.AllDirectories)
            .Select(f => Path.GetRelativePath(root, f).Replace('\\', '/'))
            .Where(f => !f.StartsWith(".git/") && f != ".git")
            .Where(f => !f.Split('/').Contains(".git"))
            .Order(StringComparer.Ordinal)
            .ToList();
    }

    private string? Resolve(string relativePath)
    {
        if (string.IsNullOrWhiteSpace(relativePath)) return null;
        var full = _layout.ResolveInWorkspace(_currentDirectory(), relativePath);
        if (full is null) return null;
        // Never let the player read or write git internals directly.
        var rel = Path.GetRelativePath(_layout.Workspace, full).Replace('\\', '/');
        return rel.Split('/').Contains(".git") ? null : full;
    }
}
