using Godot;
using GitDiwaa.Godot.Common;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// Reusable OOP Terminal Component for Godot.
/// Provides rich output log, command prompt line, history navigation, and signals.
/// </summary>
public partial class TerminalPanel : PanelContainer
{
    [Signal]
    public delegate void CommandSubmittedEventHandler(string command);

    [Export]
    public string WindowTitle { get; set; } = "TERMINAL — learner@diwaa:~/checkpoint-01";

    [Export]
    public string PromptPrefix { get; set; } = "learner@diwaa:~ $";

    private Label _titleLabel = null!;
    private Label _subHelpLabel = null!;
    private RichTextLabel _outputLog = null!;
    private Label _promptLabel = null!;
    private LineEdit _inputEdit = null!;
    private Button _enterButton = null!;

    private readonly List<string> _commandHistory = new();
    private int _historyIndex = -1;
    private string _currentBuffer = string.Empty;
    private bool _isExecuting;

    public override void _Ready()
    {
        ApplyStyles();
        BindNodes();

        _titleLabel.Text = WindowTitle;
        _promptLabel.Text = PromptPrefix;

        _inputEdit.TextSubmitted += OnTextSubmitted;
        _enterButton.Pressed += OnEnterPressed;
        _inputEdit.GuiInput += OnInputGuiInput;

        ShowWelcomeBanner();
        _inputEdit.GrabFocus();
    }

    private void BindNodes()
    {
        _titleLabel = GetNode<Label>("%TitleLabel");
        _subHelpLabel = GetNode<Label>("%SubHelpLabel");
        _outputLog = GetNode<RichTextLabel>("%OutputLog");
        _promptLabel = GetNode<Label>("%PromptLabel");
        _inputEdit = GetNode<LineEdit>("%InputEdit");
        _enterButton = GetNode<Button>("%EnterButton");
    }

    private void ApplyStyles()
    {
        // Terminal Window Border and Background
        var windowStyle = SandboxThemeTokens.CreatePanelStyle(
            bgColor: SandboxThemeTokens.TerminalBackground,
            borderColor: SandboxThemeTokens.BorderGold,
            borderWidth: 2,
            cornerRadius: 6,
            contentMargin: 10
        );
        AddThemeStyleboxOverride("panel", windowStyle);
    }

    private void ShowWelcomeBanner()
    {
        AppendInfo("Git-Diwaa terminal / isolated Git workspace");
        AppendInfo("Type [color=#f5c454]help[/color] for commands or type git commands directly.\n");
    }

    private void OnTextSubmitted(string text)
    {
        SubmitCommand(text);
    }

    private void OnEnterPressed()
    {
        SubmitCommand(_inputEdit.Text);
    }

    private void SubmitCommand(string command)
    {
        if (_isExecuting) return;

        var trimmed = command.Trim();
        if (string.IsNullOrEmpty(trimmed)) return;

        _commandHistory.Add(trimmed);
        _historyIndex = _commandHistory.Count;
        _currentBuffer = string.Empty;

        // Echo prompt command
        AppendCommand(trimmed);

        _inputEdit.Text = string.Empty;

        // Built-in terminal command handling
        if (trimmed.Equals("clear", StringComparison.OrdinalIgnoreCase))
        {
            ClearOutput();
            return;
        }

        EmitSignal(SignalName.CommandSubmitted, trimmed);
    }

    private void OnInputGuiInput(InputEvent @event)
    {
        if (@event is InputEventKey keyEvent && keyEvent.Pressed)
        {
            if (keyEvent.Keycode == Key.Up)
            {
                NavigateHistory(-1);
                GetViewport().SetInputAsHandled();
            }
            else if (keyEvent.Keycode == Key.Down)
            {
                NavigateHistory(1);
                GetViewport().SetInputAsHandled();
            }
        }
    }

    private void NavigateHistory(int direction)
    {
        if (_commandHistory.Count == 0) return;

        if (_historyIndex == _commandHistory.Count)
        {
            _currentBuffer = _inputEdit.Text;
        }

        _historyIndex = Mathf.Clamp(_historyIndex + direction, 0, _commandHistory.Count);

        if (_historyIndex == _commandHistory.Count)
        {
            _inputEdit.Text = _currentBuffer;
        }
        else
        {
            _inputEdit.Text = _commandHistory[_historyIndex];
        }

        _inputEdit.CaretColumn = _inputEdit.Text.Length;
    }

    public void AppendCommand(string command)
    {
        _outputLog.AppendText($"[color=#4ade80]{PromptPrefix}[/color] [color=#ffffff]{command}[/color]\n");
    }

    public void AppendOutput(string text)
    {
        if (string.IsNullOrWhiteSpace(text)) return;
        _outputLog.AppendText($"[color=#e2e8f0]{text}[/color]\n");
    }

    public void AppendError(string error)
    {
        if (string.IsNullOrWhiteSpace(error)) return;
        _outputLog.AppendText($"[color=#f87171][b]Error:[/b] {error}[/color]\n");
    }

    public void AppendInfo(string info)
    {
        if (string.IsNullOrWhiteSpace(info)) return;
        _outputLog.AppendText($"[color=#94a3b8]{info}[/color]\n");
    }

    public void ClearOutput()
    {
        _outputLog.Clear();
    }

    public void FocusInput()
    {
        _inputEdit.GrabFocus();
    }

    public void SetExecuting(bool isExecuting)
    {
        _isExecuting = isExecuting;
        _inputEdit.Editable = !isExecuting;
        _enterButton.Disabled = isExecuting;
        _enterButton.Text = isExecuting ? "..." : "Enter ↵";
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
