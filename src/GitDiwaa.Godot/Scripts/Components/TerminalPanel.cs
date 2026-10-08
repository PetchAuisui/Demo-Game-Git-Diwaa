using Godot;
using GitDiwaa.Godot.Common;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// Reusable OOP Terminal Component for Godot.
/// Matches the authentic Git-Diwaa Checkpoint-01 visual style and behaviors.
/// </summary>
public partial class TerminalPanel : PanelContainer
{
    [Signal]
    public delegate void CommandSubmittedEventHandler(string command);

    [Export]
    public string WindowTitle { get; set; } = "●  ●  ●    TERMINAL — learner@diwaa:~/checkpoint-01";

    [Export]
    public string PromptPrefix { get; set; } = "learner@diwaa:~ $";

    private Label _titleLabel = null!;
    private Label _hintLabel = null!;
    private RichTextLabel _outputLog = null!;
    private Label _promptLabel = null!;
    private LineEdit _inputEdit = null!;
    private Button _enterButton = null!;
    private ConfirmationDialog _commitDialog = null!;
    private LineEdit _commitInput = null!;

    private readonly List<string> _commandHistory = new();
    private int _historyIndex;
    private bool _isExecuting;

    public override void _Ready()
    {
        BindNodes();

        _titleLabel.Text = WindowTitle;
        _promptLabel.Text = PromptPrefix;

        _inputEdit.TextSubmitted += _ => SubmitFromInput();
        _enterButton.Pressed += SubmitFromInput;
        _inputEdit.GuiInput += OnInputGuiInput;

        DialogStyle.Apply(_commitDialog, DialogStyle.Success, "✓", "Commit message", false, _commitInput);
        _commitDialog.Size = new Vector2I(780, 100);
        _commitInput.PlaceholderText = "กรอกข้อความอธิบาย Commit เช่น add player profile";
        _commitDialog.Confirmed += OnCommitDialogConfirmed;
        _commitDialog.AboutToPopup += () => _commitInput.CallDeferred(Control.MethodName.GrabFocus);

        _inputEdit.GrabFocus();
    }

    private void BindNodes()
    {
        _titleLabel = GetNode<Label>("%TitleLabel");
        _hintLabel = GetNode<Label>("%HintLabel");
        _outputLog = GetNode<RichTextLabel>("%OutputLog");
        _promptLabel = GetNode<Label>("%PromptLabel");
        _inputEdit = GetNode<LineEdit>("%InputEdit");
        _enterButton = GetNode<Button>("%EnterButton");
        _commitDialog = GetNode<ConfirmationDialog>("%CommitDialog");
        _commitInput = GetNode<LineEdit>("%CommitInput");
    }

    private void SubmitFromInput()
    {
        if (_isExecuting) return;

        var command = _inputEdit.Text.Trim();
        if (string.IsNullOrEmpty(command)) return;

        _inputEdit.Clear();

        if (_commandHistory.Count == 0 || _commandHistory[^1] != command)
        {
            _commandHistory.Add(command);
        }
        _historyIndex = _commandHistory.Count;

        if (command == "git commit")
        {
            _commitInput.Clear();
            _commitDialog.PopupCentered();
            return;
        }

        SubmitCommand(command);
    }

    private void OnCommitDialogConfirmed()
    {
        var message = _commitInput.Text.Trim();
        if (string.IsNullOrEmpty(message))
        {
            AppendError("Commit message cannot be empty.");
            return;
        }
        var fullCommand = $"git commit -m \"{message.Replace("\"", "\\\"")}\"";
        SubmitCommand(fullCommand);
    }

    public void SubmitCommand(string command)
    {
        AppendCommand(command);

        if (command.Equals("clear", StringComparison.OrdinalIgnoreCase))
        {
            ClearOutput();
            return;
        }

        EmitSignal(SignalName.CommandSubmitted, command);
    }

    private void OnInputGuiInput(InputEvent @event)
    {
        if (@event is InputEventKey { Pressed: true } keyEvent && _commandHistory.Count > 0)
        {
            if (keyEvent.Keycode == Key.Up)
            {
                _historyIndex = Math.Clamp(_historyIndex - 1, 0, _commandHistory.Count);
                _inputEdit.Text = _historyIndex < _commandHistory.Count ? _commandHistory[_historyIndex] : string.Empty;
                _inputEdit.CaretColumn = _inputEdit.Text.Length;
                GetViewport().SetInputAsHandled();
            }
            else if (keyEvent.Keycode == Key.Down)
            {
                _historyIndex = Math.Clamp(_historyIndex + 1, 0, _commandHistory.Count);
                _inputEdit.Text = _historyIndex < _commandHistory.Count ? _commandHistory[_historyIndex] : string.Empty;
                _inputEdit.CaretColumn = _inputEdit.Text.Length;
                GetViewport().SetInputAsHandled();
            }
        }
    }

    public void AppendCommand(string command)
    {
        _outputLog.AddText($"\n{PromptPrefix} {command}\n");
        ScrollToBottom();
    }

    public void AppendOutput(string text)
    {
        if (string.IsNullOrWhiteSpace(text)) return;
        _outputLog.AddText($"{text.TrimEnd()}\n");
        ScrollToBottom();
    }

    public void AppendError(string error)
    {
        if (string.IsNullOrWhiteSpace(error)) return;
        _outputLog.AddText($"[Error] {error.TrimEnd()}\n");
        ScrollToBottom();
    }

    public void AppendInfo(string info)
    {
        if (string.IsNullOrWhiteSpace(info)) return;
        _outputLog.AddText($"{info.TrimEnd()}\n");
        ScrollToBottom();
    }

    public void ClearOutput()
    {
        _outputLog.Clear();
    }

    private void ScrollToBottom()
    {
        _outputLog.ScrollToLine(Math.Max(0, _outputLog.GetLineCount() - 1));
    }

    public void SetExecuting(bool isExecuting)
    {
        _isExecuting = isExecuting;
        _inputEdit.Editable = !isExecuting;
        _enterButton.Disabled = isExecuting;
        if (!isExecuting)
        {
            _inputEdit.GrabFocus();
        }
    }

    public void SetWindowTitle(string title)
    {
        WindowTitle = title;
        if (_titleLabel != null) _titleLabel.Text = title;
    }

    public void SetPromptPrefix(string prefix)
    {
        PromptPrefix = prefix;
        if (_promptLabel != null) _promptLabel.Text = prefix;
    }
}
