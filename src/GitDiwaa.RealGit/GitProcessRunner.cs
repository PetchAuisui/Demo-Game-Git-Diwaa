using System.ComponentModel;
using System.Diagnostics;
using GitDiwaa.Core;

namespace GitDiwaa.RealGit;

internal sealed class GitProcessRunner
{
    private static readonly TimeSpan DefaultTimeout = TimeSpan.FromSeconds(15);

    public async Task<GitCommandResult> RunAsync(
        GitSandbox sandbox,
        string workingDirectory,
        IReadOnlyList<string> arguments,
        CancellationToken cancellationToken = default)
    {
        try
        {
            using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            timeout.CancelAfter(DefaultTimeout);
            return await RunCoreAsync(sandbox, workingDirectory, arguments, timeout.Token);
        }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            return GitCommandResult.Rejected(
                $"Git command timed out after {DefaultTimeout.TotalSeconds:0} seconds.",
                FormatCommand(arguments));
        }
        catch (Exception exception) when (exception is InvalidOperationException or Win32Exception)
        {
            return GitCommandResult.Rejected(exception.Message, FormatCommand(arguments));
        }
    }

    private static async Task<GitCommandResult> RunCoreAsync(
        GitSandbox sandbox,
        string workingDirectory,
        IReadOnlyList<string> arguments,
        CancellationToken cancellationToken)
    {
        var startInfo = new ProcessStartInfo
        {
            FileName = "git",
            WorkingDirectory = workingDirectory,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            RedirectStandardInput = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        foreach (var argument in arguments) startInfo.ArgumentList.Add(argument);
        ApplySandboxEnvironment(startInfo, sandbox);

        using var process = new Process { StartInfo = startInfo };
        process.Start();
        process.StandardInput.Close();
        var outputTask = process.StandardOutput.ReadToEndAsync(cancellationToken);
        var errorTask = process.StandardError.ReadToEndAsync(cancellationToken);

        try
        {
            await process.WaitForExitAsync(cancellationToken);
        }
        catch (OperationCanceledException)
        {
            if (!process.HasExited) process.Kill(entireProcessTree: true);
            await process.WaitForExitAsync(CancellationToken.None);
            throw;
        }

        return new(
            process.ExitCode == 0,
            process.ExitCode,
            await outputTask,
            await errorTask,
            FormatCommand(arguments));
    }

    private static void ApplySandboxEnvironment(ProcessStartInfo startInfo, GitSandbox sandbox)
    {
        startInfo.Environment["GIT_CONFIG_GLOBAL"] = sandbox.GitConfigPath;
        startInfo.Environment["GIT_CONFIG_NOSYSTEM"] = "1";
        startInfo.Environment["GIT_TERMINAL_PROMPT"] = "0";
        startInfo.Environment["GCM_INTERACTIVE"] = "Never";
        startInfo.Environment["GIT_EDITOR"] = "true";
        startInfo.Environment["GIT_SEQUENCE_EDITOR"] = "true";
        startInfo.Environment["GIT_MERGE_AUTOEDIT"] = "no";
        startInfo.Environment["LC_ALL"] = "C";
        startInfo.Environment["GIT_CONFIG_COUNT"] = "2";
        startInfo.Environment["GIT_CONFIG_KEY_0"] = "core.hooksPath";
        startInfo.Environment["GIT_CONFIG_VALUE_0"] = sandbox.HooksPath;
        startInfo.Environment["GIT_CONFIG_KEY_1"] = "protocol.file.allow";
        startInfo.Environment["GIT_CONFIG_VALUE_1"] = "always";
    }

    private static string FormatCommand(IReadOnlyList<string> arguments) =>
        $"git {string.Join(' ', arguments.Select(QuoteForDisplay))}";

    private static string QuoteForDisplay(string value) =>
        value.Any(char.IsWhiteSpace) ? $"\"{value.Replace("\"", "\\\"")}\"" : value;
}

