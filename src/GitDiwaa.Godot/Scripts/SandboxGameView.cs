using Godot;
using GitDiwaa.Core;
using GitDiwaa.Godot.Components;
using GitDiwaa.Godot.Services;
using GitDiwaa.Godot.ViewModels;

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
        _topBar.RepoPressed += OnRepoPressed;
        _terminalPanel.CommandSubmitted += OnCommandSubmitted;
        _filesPanel.OpenFileRequested += OnOpenFileRequested;
        _filesPanel.SaveFileRequested += OnSaveFileRequested;
        _filesPanel.CreateFileRequested += OnCreateFileRequested;
        _filesPanel.CreateFolderRequested += OnCreateFolderRequested;
        _filesPanel.RenameEntryRequested += OnRenameEntryRequested;
        _filesPanel.DeleteEntryRequested += OnDeleteEntryRequested;
        _gitGraphPanel.CommitSelected += OnCommitSelected;
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
        _terminalPanel.AppendInfo("Git-Diwaa Terminal กำลังสร้างพื้นที่ทดลอง...");

        if (_sandboxService == null)
        {
            try
            {
                var realService = new RealGitSandboxService();
                await realService.InitializeAsync("checkpoint-01");
                _sandboxService = realService;
            }
            catch (Exception ex)
            {
                GD.PrintErr($"Real Git initialization failed ({ex.Message}), falling back to Mock service.");
                var mockService = new MockGitSandboxService();
                await mockService.InitializeAsync();
                _sandboxService = mockService;
            }
        }

        _isInitialized = true;
        _topBar.SetRepoButtonEnabled(_sandboxService.RemoteHost != null);
        _terminalPanel.SetExecuting(false);

        if (_sandboxService.Info != null)
        {
            _terminalPanel.SetWindowTitle($"●  ●  ●    TERMINAL — learner@diwaa:~/{_sandboxService.Info.MissionId}");
            _terminalPanel.AppendInfo("พร้อมใช้งาน — พิมพ์ help หรือเริ่มด้วย git --version\n");
        }

        await RefreshStateAsync();
    }

    private void OnRepoPressed()
    {
        if (_sandboxService?.RemoteHost is not { } host)
        {
            _terminalPanel.AppendError("หน้า repo ใช้ได้เฉพาะเมื่อเปิดโหมด Real Git");
            return;
        }

        var view = new RemoteRepoView();
        view.BackRequested += () => view.QueueFree();
        AddChild(view);
        view.Open(host);
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

        if (trimmed.Equals("sandbox-reset", StringComparison.OrdinalIgnoreCase))
        {
            OnResetRequested();
            return;
        }

        if (trimmed.Equals("files", StringComparison.OrdinalIgnoreCase))
        {
            await HandleFilesCommandAsync();
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
                    _terminalPanel.AppendInfo("✓ สำเร็จ");
                }
            }
            else
            {
                var errMsg = !string.IsNullOrWhiteSpace(result.StandardError)
                    ? result.StandardError.TrimEnd()
                    : $"✗ คำสั่งล้มเหลว (exit {result.ExitCode})";
                _terminalPanel.AppendError(errMsg);
            }
        }
        catch (Exception ex)
        {
            _terminalPanel.AppendError($"เกิดข้อผิดพลาด: {ex.Message}");
        }
        finally
        {
            _terminalPanel.SetExecuting(false);
            await RefreshStateAsync();
        }
    }

    private async Task HandleFilesCommandAsync()
    {
        var files = await _sandboxService.GetFilesAsync();
        if (files.Count == 0)
        {
            _terminalPanel.AppendInfo("working directory ว่าง");
        }
        else
        {
            _terminalPanel.AppendOutput(string.Join("\n", files.Select(f => f.Path)));
        }
    }

    private async Task HandleWriteCommandAsync(string command)
    {
        var parts = command.Split(' ', 3, StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length < 3)
        {
            _terminalPanel.AppendError("วิธีใช้: write <path> <content>");
            return;
        }

        try
        {
            await _sandboxService.WriteFileAsync(parts[1], parts[2]);
            _terminalPanel.AppendInfo($"✓ เขียนไฟล์ '{parts[1]}' แล้ว");
            await RefreshStateAsync();
        }
        catch (Exception ex)
        {
            _terminalPanel.AppendError($"เขียนไฟล์ไม่สำเร็จ: {ex.Message}");
        }
    }

    private async Task HandleCatCommandAsync(string command)
    {
        var parts = command.Split(' ', 2, StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length < 2)
        {
            _terminalPanel.AppendError("วิธีใช้: cat <path>");
            return;
        }

        try
        {
            var content = await _sandboxService.ReadFileAsync(parts[1]);
            if (content == null)
            {
                _terminalPanel.AppendError($"ไม่พบไฟล์ '{parts[1]}'");
            }
            else
            {
                _terminalPanel.AppendOutput(content);
            }
        }
        catch (Exception ex)
        {
            _terminalPanel.AppendError($"อ่านไฟล์ไม่สำเร็จ: {ex.Message}");
        }
    }

    private async Task HandleDeleteCommandAsync(string command)
    {
        var parts = command.Split(' ', 2, StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length < 2)
        {
            _terminalPanel.AppendError("วิธีใช้: delete <path>");
            return;
        }

        try
        {
            var ok = _sandboxService.DeleteFile(parts[1]);
            if (ok)
            {
                _terminalPanel.AppendInfo($"✓ ลบ '{parts[1]}' แล้ว");
                await RefreshStateAsync();
            }
            else
            {
                _terminalPanel.AppendError($"ไม่พบไฟล์ '{parts[1]}'");
            }
        }
        catch (Exception ex)
        {
            _terminalPanel.AppendError($"ลบไฟล์ไม่สำเร็จ: {ex.Message}");
        }
    }

    private async void OnOpenFileRequested(string filePath)
    {
        _filesPanel.SetBusy(true);
        try
        {
            var content = await _sandboxService.ReadFileAsync(filePath);
            if (content == null)
            {
                _filesPanel.ShowFeedback($"ไม่พบไฟล์ '{filePath}'", true);
                return;
            }

            _filesPanel.ShowFile(filePath, content);
            _filesPanel.ShowFeedback($"เปิด {filePath} แล้ว");
        }
        catch (Exception ex)
        {
            _filesPanel.ShowFeedback($"เปิดไฟล์ไม่สำเร็จ: {ex.Message}", true);
        }
        finally
        {
            _filesPanel.SetBusy(false);
        }
    }

    private async void OnSaveFileRequested(string filePath, string content)
    {
        _filesPanel.SetBusy(true);
        try
        {
            await _sandboxService.WriteFileAsync(filePath, content);
            _filesPanel.MarkSaved(filePath);
            _filesPanel.ShowFeedback($"บันทึก {filePath} แล้ว — Git status อัปเดตแล้ว");
            _terminalPanel.AppendInfo($"✓ บันทึกไฟล์ '{filePath}' แล้ว");
            await RefreshStateAsync();
        }
        catch (Exception ex)
        {
            _filesPanel.ShowFeedback($"บันทึกไม่สำเร็จ: {ex.Message}", true);
            _terminalPanel.AppendError($"บันทึกไฟล์ไม่สำเร็จ: {ex.Message}");
        }
        finally
        {
            _filesPanel.SetBusy(false);
        }
    }

    private async void OnCreateFileRequested(string filePath, string content)
    {
        _filesPanel.SetBusy(true);
        try
        {
            if (await _sandboxService.ReadFileAsync(filePath) != null)
                throw new IOException($"มีไฟล์ '{filePath}' อยู่แล้ว");
            await _sandboxService.WriteFileAsync(filePath, content);
            _filesPanel.ShowFile(filePath, content);
            _filesPanel.ShowFeedback($"สร้าง {filePath} แล้ว");
            _terminalPanel.AppendInfo($"✓ สร้างไฟล์ใหม่แล้ว: {filePath}");
            await RefreshStateAsync();
        }
        catch (Exception ex)
        {
            _filesPanel.ShowFeedback($"สร้างไฟล์ไม่สำเร็จ: {ex.Message}", true);
            _terminalPanel.AppendError($"สร้างไฟล์ไม่สำเร็จ: {ex.Message}");
        }
        finally
        {
            _filesPanel.SetBusy(false);
        }
    }

    private async void OnCreateFolderRequested(string folderPath)
    {
        _filesPanel.SetBusy(true);
        try
        {
            await _sandboxService.CreateDirectoryAsync(folderPath);
            _filesPanel.ShowFeedback($"สร้างโฟลเดอร์ {folderPath} แล้ว");
            _terminalPanel.AppendInfo($"✓ สร้างโฟลเดอร์ใหม่แล้ว: {folderPath}");
            await RefreshStateAsync();
        }
        catch (Exception ex)
        {
            _filesPanel.ShowFeedback($"สร้างโฟลเดอร์ไม่สำเร็จ: {ex.Message}", true);
            _terminalPanel.AppendError($"สร้างโฟลเดอร์ไม่สำเร็จ: {ex.Message}");
        }
        finally
        {
            _filesPanel.SetBusy(false);
        }
    }

    private async void OnRenameEntryRequested(string sourcePath, string destinationPath)
    {
        _filesPanel.SetBusy(true);
        try
        {
            await _sandboxService.RenameEntryAsync(sourcePath, destinationPath);
            _filesPanel.NotifyEntryRenamed(sourcePath, destinationPath);
            _filesPanel.ShowFeedback($"เปลี่ยนชื่อเป็น {destinationPath} แล้ว");
            _terminalPanel.AppendInfo($"✓ เปลี่ยนชื่อ '{sourcePath}' → '{destinationPath}'");
            await RefreshStateAsync();
        }
        catch (Exception ex)
        {
            _filesPanel.ShowFeedback($"เปลี่ยนชื่อไม่สำเร็จ: {ex.Message}", true);
            _terminalPanel.AppendError($"เปลี่ยนชื่อไม่สำเร็จ: {ex.Message}");
        }
        finally
        {
            _filesPanel.SetBusy(false);
        }
    }

    private async void OnDeleteEntryRequested(string entryPath, bool isDirectory)
    {
        _filesPanel.SetBusy(true);
        try
        {
            if (!_sandboxService.DeleteEntry(entryPath, isDirectory))
                throw new FileNotFoundException($"ไม่พบ '{entryPath}'");
            _filesPanel.NotifyEntryDeleted(entryPath);
            _filesPanel.ShowFeedback($"ลบ {entryPath} แล้ว — ตรวจสอบได้ด้วย git status");
            _terminalPanel.AppendInfo($"✓ ลบ '{entryPath}' แล้ว");
            await RefreshStateAsync();
        }
        catch (Exception ex)
        {
            _filesPanel.ShowFeedback($"ลบไม่สำเร็จ: {ex.Message}", true);
            _terminalPanel.AppendError($"ลบไม่สำเร็จ: {ex.Message}");
        }
        finally
        {
            _filesPanel.SetBusy(false);
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
            _terminalPanel.AppendError($"เกิดข้อผิดพลาดในการแสดง commit: {ex.Message}");
        }
    }

    private async void OnResetRequested()
    {
        _terminalPanel.SetExecuting(true);
        _terminalPanel.AppendInfo("กำลังรีเซ็ตพื้นที่ sandbox...");
        try
        {
            await _sandboxService.ResetAsync();
            _terminalPanel.AppendInfo("✓ รีเซ็ต sandbox เรียบร้อย");
            await RefreshStateAsync();
        }
        catch (Exception ex)
        {
            _terminalPanel.AppendError($"รีเซ็ตไม่สำเร็จ: {ex.Message}");
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
            var snapshot = await _sandboxService.InspectAsync();
            
            // Always show files, even if git is not initialized
            var entries = await _sandboxService.GetWorkspaceEntriesAsync();
            _filesPanel.SetEntries(entries);

            if (snapshot.IsInitialized)
            {
                _gitGraphPanel.SetSnapshot(snapshot);
            }
            else
            {
                _gitGraphPanel.SetEmptyState();
            }
        }
        catch (Exception ex)
        {
            GD.PrintErr($"Failed to refresh sandbox state: {ex.Message}");
        }
    }

    private void ShowHelp()
    {
        _terminalPanel.AppendInfo("""
คำสั่ง Git: git --version, config, init, status, add, commit, log, diff,
            restore, reset, branch, switch, merge, clone, remote, pull, push

คำสั่ง UI: write <path> <content>, cat <path>, delete <path>, files,
           sandbox-reset, clear, help
""");
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
