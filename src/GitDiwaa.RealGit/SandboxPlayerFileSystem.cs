using GitDiwaa.Core;

namespace GitDiwaa.RealGit;

internal sealed class SandboxPlayerFileSystem : IPlayerFileSystem
{
    private readonly string _root;
    private readonly string _rootWithSeparator;
    private readonly StringComparison _pathComparison = OperatingSystem.IsWindows()
        ? StringComparison.OrdinalIgnoreCase
        : StringComparison.Ordinal;

    public SandboxPlayerFileSystem(GitSandbox sandbox)
    {
        _root = Path.GetFullPath(sandbox.PlayerRepositoryPath);
        _rootWithSeparator = _root.TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
    }

    public async Task WriteAllTextAsync(
        string relativePath,
        string content,
        CancellationToken cancellationToken = default)
    {
        var path = Resolve(relativePath);
        EnsureNoSymbolicLinks(path);
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        await File.WriteAllTextAsync(path, content, cancellationToken);
    }

    public async Task<string?> ReadAllTextAsync(
        string relativePath,
        CancellationToken cancellationToken = default)
    {
        var path = Resolve(relativePath);
        EnsureNoSymbolicLinks(path);
        return File.Exists(path) ? await File.ReadAllTextAsync(path, cancellationToken) : null;
    }

    public bool Delete(string relativePath)
    {
        var path = Resolve(relativePath);
        EnsureNoSymbolicLinks(path);
        if (!File.Exists(path)) return false;
        File.Delete(path);
        return true;
    }

    public IReadOnlyList<string> ListFiles() => Directory
        .EnumerateFiles(_root, "*", new EnumerationOptions
        {
            RecurseSubdirectories = true,
            IgnoreInaccessible = true,
            AttributesToSkip = FileAttributes.ReparsePoint
        })
        .Where(path => !IsGitMetadata(path))
        .Select(path => Path.GetRelativePath(_root, path))
        .OrderBy(path => path, StringComparer.Ordinal)
        .ToArray();

    private string Resolve(string relativePath)
    {
        if (string.IsNullOrWhiteSpace(relativePath) || Path.IsPathRooted(relativePath))
            throw new ArgumentException("Use a repository-relative file path.", nameof(relativePath));

        var fullPath = Path.GetFullPath(Path.Combine(_root, relativePath));
        if (!fullPath.StartsWith(_rootWithSeparator, _pathComparison) || IsGitMetadata(fullPath))
            throw new InvalidOperationException("File path must stay inside the repository and outside .git.");
        return fullPath;
    }

    private void EnsureNoSymbolicLinks(string path)
    {
        var relative = Path.GetRelativePath(_root, path);
        var current = _root;
        foreach (var segment in relative.Split(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar))
        {
            current = Path.Combine(current, segment);
            if (!File.Exists(current) && !Directory.Exists(current)) continue;
            if ((File.GetAttributes(current) & FileAttributes.ReparsePoint) != 0)
                throw new InvalidOperationException("Symbolic links are not supported in player file operations.");
        }
    }

    private bool IsGitMetadata(string path)
    {
        var gitPath = Path.Combine(_root, ".git");
        return path.Equals(gitPath, _pathComparison) ||
               path.StartsWith(gitPath + Path.DirectorySeparatorChar, _pathComparison);
    }
}
