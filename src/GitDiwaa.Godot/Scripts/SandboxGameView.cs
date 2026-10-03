using Godot;
using GitDiwaa.Core;
using GitDiwaa.Godot.Components;
using GitDiwaa.Godot.Services;

namespace GitDiwaa.Godot;

/// <summary>
/// Root Orchestrator for the Git-Diwaa Sandbox Game.
/// Follows OOP Mediator / Controller pattern to decouple UI Panels from the Git Sandbox Service.
/// </summary>
public partial class SandboxGameView : Control
{
    private TopBarPanel _topBar = null!;
    private FilesPanel _filesPanel = null!;
    private GitGraphPanel _gitGraphPanel = null!;
    private TerminalPanel _terminalPanel = null!;

    private IGitSandboxService _sandboxService = null!;
    private bool _isInitialized;

    public override void _Ready()
    {
        BindNodes();
        WireEvents();
        _ = InitializeSandboxAsync();
    }

    private void BindNodes()
    {
        _topBar = GetNode<TopBarPanel>("%TopBar");
        _filesPanel = GetNode<FilesPanel>("%FilesPanel");
        _gitGraphPanel = GetNode<GitGraphPanel>("%GitGraphPanel");
        _terminalPanel = GetNode<TerminalPanel>("%TerminalPanel");
    }

    private void WireEvents()
    {
        _terminalPanel.CommandSubmitted += OnCommandSubmitted;
        _filesPanel.FileSelected += OnFileSelected;
        _filesPanel.CreateFileRequested += OnCreateFileRequested;
        _gitGraphPanel.CommitSelected += OnCommitSelected;
        _topBar.ResetRequested += OnResetRequested;
    }

    /// <summary>
    /// Injects or creates the sandbox service. Allows OOP dependency injection.
    /// </summary>
    public void SetSandboxService(IGitSandboxService service)
    {
        _sandboxService = service;
    }

    private async Task InitializeSandboxAsync()
    {
        _terminalPanel.SetExecuting(true);
        _terminalPanel.AppendInfo("Initializing isolated Git workspace...");

        if (_sandboxService == null)
        {
            try
            {
                // Try initializing real Git sandbox
                var realService = new RealGitSandboxService();
                await realService.InitializeAsync("checkpoint-01");
                _sandboxService = realService;
            }
            catch (Exception ex)
            {
                // Fallback to Mock service if Git CLI or filesystem permissions are restricted
                GD.PrintErr($"Real Git initialization failed ({ex.Message}), falling back to Mock service.");
                var mockService = new MockGitSandboxService();
                await mockService.InitializeAsync();
                _sandboxService = mockService;
            }
        }

        _isInitialized = true;
        _terminalPanel.SetExecuting(false);

        if (_sandboxService.Info != null)
        {
            _terminalPanel.SetWindowTitle($"TERMINAL — learner@diwaa:~/{_sandboxService.Info.MissionId}");
            _terminalPanel.AppendInfo($"Sandbox workspace: {_sandboxService.Info.RepositoryPath}");
        }

        await RefreshStateAsync();
    }

    private async void OnCommandSubmitted(string command)
    {
        if (!_isInitialized) return;

        var trimmed = command.Trim();

        // Built-in help handler
        if (trimmed.Equals("help", StringComparison.OrdinalIgnoreCase))
        {
            ShowHelp();
            return;
        }

        // Commit shorthand check
        if (trimmed.Equals("git commit", StringComparison.OrdinalIgnoreCase))
        {
            _terminalPanel.AppendError("Commit message required: use git commit -m \"message\"");
            return;
        }

        // Helper host file commands
        if (trimmed.StartsWith("write ", StringComparison.OrdinalIgnoreCase))
        {
            await HandleWriteCommandAsync(trimmed);
            return;
        }

        if (trimmed.StartsWith("cat ", StringComparison.OrdinalIgnoreCase))
        {
            await HandleCatCommandAsync(trimmed);
            return;
        }

        if (trimmed.StartsWith("delete ", StringComparison.OrdinalIgnoreCase))
        {
            await HandleDeleteCommandAsync(trimmed);
            return;
        }

        // Execute via Git sandbox service
        _terminalPanel.SetExecuting(true);
        try
        {
            var result = await _sandboxService.ExecuteAsync(trimmed);

            if (result.Success)
            {
                if (!string.IsNullOrWhiteSpace(result.StandardOutput))
                {
                    _terminalPanel.AppendOutput(result.StandardOutput.TrimEnd());
                }
                else
                {
                    _terminalPanel.AppendInfo("Command completed successfully.");
                }
            }
            else
            {
                var errMsg = !string.IsNullOrWhiteSpace(result.StandardError)
                    ? result.StandardError.TrimEnd()
                    : $"Command failed (exit code {result.ExitCode})";
                _terminalPanel.AppendError(errMsg);
            }
        }
        catch (Exception ex)
        {
            _terminalPanel.AppendError($"Execution error: {ex.Message}");
        }
        finally
        {
            _terminalPanel.SetExecuting(false);
            await RefreshStateAsync();
        }
    }

    private async Task HandleWriteCommandAsync(string command)
    {
        var parts = command.Split(' ', 3, StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length < 3)
        {
            _terminalPanel.AppendError("Usage: write <filepath> <content>");
            return;
        }

        try
        {
            await _sandboxService.WriteFileAsync(parts[1], parts[2]);
            _terminalPanel.AppendInfo($"Wrote file '{parts[1]}'");
            await RefreshStateAsync();
        }
        catch (Exception ex)
        {
            _terminalPanel.AppendError($"Failed to write file: {ex.Message}");
        }
    }

    private async Task HandleCatCommandAsync(string command)
    {
        var parts = command.Split(' ', 2, StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length < 2)
        {
            _terminalPanel.AppendError("Usage: cat <filepath>");
            return;
        }

        try
        {
            var content = await _sandboxService.ReadFileAsync(parts[1]);
            if (content == null)
            {
                _terminalPanel.AppendError($"File '{parts[1]}' not found");
            }
            else
            {
                _terminalPanel.AppendOutput(content);
            }
        }
        catch (Exception ex)
        {
            _terminalPanel.AppendError($"Failed to read file: {ex.Message}");
        }
    }

    private async Task HandleDeleteCommandAsync(string command)
    {
        var parts = command.Split(' ', 2, StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length < 2)
        {
            _terminalPanel.AppendError("Usage: delete <filepath>");
            return;
        }

        try
        {
            var ok = _sandboxService.DeleteFile(parts[1]);
            if (ok)
            {
                _terminalPanel.AppendInfo($"Deleted '{parts[1]}'");
                await RefreshStateAsync();
            }
            else
            {
                _terminalPanel.AppendError($"File '{parts[1]}' not found");
            }
        }
        catch (Exception ex)
        {
            _terminalPanel.AppendError($"Failed to delete file: {ex.Message}");
        }
    }

    private async void OnFileSelected(string filePath)
    {
        try
        {
            var content = await _sandboxService.ReadFileAsync(filePath);
            _terminalPanel.AppendInfo($"Inspecting file: {filePath}");
            if (!string.IsNullOrEmpty(content))
            {
                _terminalPanel.AppendOutput(content);
            }
        }
        catch (Exception ex)
        {
            _terminalPanel.AppendError($"Could not read file {filePath}: {ex.Message}");
        }
    }

    private async void OnCreateFileRequested(string filePath, string content)
    {
        try
        {
            await _sandboxService.WriteFileAsync(filePath, content);
            _terminalPanel.AppendInfo($"Created new workspace file: {filePath}");
            await RefreshStateAsync();
        }
        catch (Exception ex)
        {
            _terminalPanel.AppendError($"Error creating file: {ex.Message}");
        }
    }

    private async void OnCommitSelected(string commitId)
    {
        _terminalPanel.AppendCommand($"git show {commitId[..7]} --stat");
        try
        {
            var result = await _sandboxService.ExecuteAsync($"git show {commitId} --stat");
            if (!string.IsNullOrWhiteSpace(result.StandardOutput))
            {
                _terminalPanel.AppendOutput(result.StandardOutput.TrimEnd());
            }
        }
        catch (Exception ex)
        {
            _terminalPanel.AppendError($"Error inspecting commit: {ex.Message}");
        }
    }

    private async void OnResetRequested()
    {
        _terminalPanel.SetExecuting(true);
        _terminalPanel.AppendInfo("Resetting sandbox attempt...");
        try
        {
            await _sandboxService.ResetAsync();
            _terminalPanel.AppendInfo("Sandbox reset complete.");
            await RefreshStateAsync();
        }
        catch (Exception ex)
        {
            _terminalPanel.AppendError($"Reset failed: {ex.Message}");
        }
        finally
        {
            _terminalPanel.SetExecuting(false);
        }
    }

    private async Task RefreshStateAsync()
    {
        try
        {
            var files = await _sandboxService.GetFilesAsync();
            _filesPanel.SetFiles(files);

            var commits = await _sandboxService.GetCommitGraphAsync();
            _gitGraphPanel.SetCommits(commits);

            _topBar.SetCurrentBranch(_sandboxService.CurrentBranch);
        }
        catch (Exception ex)
        {
            GD.PrintErr($"Failed to refresh sandbox state: {ex.Message}");
        }
    }

    private void ShowHelp()
    {
        _terminalPanel.AppendInfo("=== Git-Diwaa Sandbox Commands ===");
        _terminalPanel.AppendInfo("Git Commands:");
        _terminalPanel.AppendInfo("  git init                  - Initialize git repository");
        _terminalPanel.AppendInfo("  git status                - Show repository status");
        _terminalPanel.AppendInfo("  git add <file>            - Stage file(s) for commit");
        _terminalPanel.AppendInfo("  git commit -m \"msg\"       - Create commit");
        _terminalPanel.AppendInfo("  git branch <name>         - Create branch");
        _terminalPanel.AppendInfo("  git checkout -b <name>    - Create and switch branch");
        _terminalPanel.AppendInfo("  git merge <branch>        - Merge branch");
        _terminalPanel.AppendInfo("  git log --oneline         - View commit logs");
        _terminalPanel.AppendInfo("Helper Commands:");
        _terminalPanel.AppendInfo("  write <path> <text>       - Create or modify file");
        _terminalPanel.AppendInfo("  cat <path>                - Read file content");
        _terminalPanel.AppendInfo("  delete <path>             - Delete file");
        _terminalPanel.AppendInfo("  clear                     - Clear terminal log\n");
    }

    public override void _ExitTree()
    {
        if (_sandboxService != null)
        {
            _ = _sandboxService.DisposeAsync();
        }
        base._ExitTree();
    }
}
