using System.Diagnostics;
using System.Text;
using GitDiwaa.Core;

namespace GitDiwaa.RealGit;

/// <summary>
/// Runs the real git executable directly (no shell) with an environment that only
/// knows about the sandbox: private HOME and config, no hooks, no prompts, no pager.
/// </summary>
public sealed class GitProcessRunner
{
    private readonly SandboxLayout _layout;
    private readonly string _virtualRemoteBase;
    private readonly TimeSpan _timeout;

    public GitProcessRunner(SandboxLayout layout, string virtualRemoteBase, TimeSpan? timeout = null)
    {
        _layout = layout;
        _virtualRemoteBase = virtualRemoteBase;
        _timeout = timeout ?? TimeSpan.FromSeconds(15);
    }

    public async Task<GitCommandResult> RunAsync(
        IReadOnlyList<string> arguments,
        string workingDirectory,
        bool forPlayer,
        CancellationToken cancellationToken = default)
    {
        var display = "git " + string.Join(' ', arguments.Select(QuoteForDisplay));
        if (!SandboxLayout.IsInside(_layout.Root, workingDirectory))
            return GitCommandResult.Rejected("working directory escaped the sandbox", display);

        var psi = new ProcessStartInfo("git")
        {
            WorkingDirectory = workingDirectory,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            RedirectStandardInput = true,
            UseShellExecute = false,
            CreateNoWindow = true,
            StandardOutputEncoding = Encoding.UTF8,
            StandardErrorEncoding = Encoding.UTF8,
        };

        foreach (var key in psi.Environment.Keys.Where(k => k.StartsWith("GIT_", StringComparison.OrdinalIgnoreCase)).ToList())
            psi.Environment.Remove(key);

        psi.Environment["HOME"] = _layout.Home;
        psi.Environment["USERPROFILE"] = _layout.Home;
        psi.Environment["XDG_CONFIG_HOME"] = Path.Combine(_layout.Home, ".config");
        psi.Environment["GIT_CONFIG_NOSYSTEM"] = "1";
        psi.Environment["GIT_CONFIG_GLOBAL"] = _layout.GlobalConfig;
        psi.Environment["GIT_CEILING_DIRECTORIES"] = _layout.Root;
        psi.Environment["GIT_TERMINAL_PROMPT"] = "0";
        psi.Environment["GIT_ASKPASS"] = "";
        psi.Environment["SSH_ASKPASS"] = "";
        psi.Environment["GIT_EDITOR"] = "true";
        psi.Environment["GIT_SEQUENCE_EDITOR"] = "true";
        psi.Environment["GIT_PAGER"] = "cat";
        psi.Environment["PAGER"] = "cat";
        psi.Environment["GIT_OPTIONAL_LOCKS"] = "0";
        psi.Environment["LC_ALL"] = "C.UTF-8";

        // Safety + world settings injected on every call (players cannot pass -c themselves).
        string[] injected =
        [
            "-c", $"core.hooksPath={_layout.Hooks}",
            "-c", "core.quotePath=false",
            "-c", "core.autocrlf=false",
            "-c", "init.defaultBranch=main",
            "-c", "advice.detachedHead=false",
            "-c", "pull.rebase=false",
            "-c", "protocol.allow=never",
            "-c", "protocol.file.allow=always",
            "-c", $"url.{_layout.RemotesUrlPrefix}.insteadOf={_virtualRemoteBase}",
            "-c", $"color.ui={(forPlayer ? "always" : "never")}",
        ];
        foreach (var a in injected) psi.ArgumentList.Add(a);
        foreach (var a in arguments) psi.ArgumentList.Add(a);

        using var process = new Process { StartInfo = psi };
        try
        {
            process.Start();
        }
        catch (Exception ex)
        {
            return GitCommandResult.Rejected($"ไม่พบพลัง Git ในเครื่องนี้ ({ex.Message})", display);
        }

        process.StandardInput.Close();
        var stdoutTask = process.StandardOutput.ReadToEndAsync(cancellationToken);
        var stderrTask = process.StandardError.ReadToEndAsync(cancellationToken);

        using var timeoutCts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeoutCts.CancelAfter(_timeout);
        try
        {
            await process.WaitForExitAsync(timeoutCts.Token);
        }
        catch (OperationCanceledException)
        {
            try { process.Kill(entireProcessTree: true); } catch { /* already gone */ }
            return GitCommandResult.Rejected("คาถาใช้เวลานานเกินไปและถูกยกเลิก", display);
        }

        var stdout = Sanitize(await stdoutTask);
        var stderr = Sanitize(await stderrTask);
        return new GitCommandResult(process.ExitCode == 0, process.ExitCode, stdout, stderr, display);
    }

    /// <summary>Hides physical sandbox paths so the player only sees in-world addresses.</summary>
    public string Sanitize(string text)
    {
        if (string.IsNullOrEmpty(text)) return text;
        var remotesPrefix = _layout.RemotesUrlPrefix;
        return text
            .Replace(remotesPrefix, _virtualRemoteBase)
            .Replace(_layout.Remotes + Path.DirectorySeparatorChar, _virtualRemoteBase)
            .Replace(_layout.Workspace + Path.DirectorySeparatorChar, string.Empty)
            .Replace(_layout.Workspace, ".")
            .Replace(_layout.Root, "~");
    }

    private static string QuoteForDisplay(string arg) =>
        arg.Length == 0 || arg.Any(char.IsWhiteSpace) ? $"\"{arg}\"" : arg;
}
