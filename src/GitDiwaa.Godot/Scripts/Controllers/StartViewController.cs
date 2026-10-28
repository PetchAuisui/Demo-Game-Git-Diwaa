using System;
using Godot;

namespace GitDiwaa.Godot.Controllers;

/// <summary>
/// Controller for the Start Screen View.
/// Orchestrates start screen navigation, audio effects, live terminal simulation,
/// real-time system clock, and transition to Sandbox gameplay.
/// </summary>
public partial class StartViewController : Control
{
    private Button _startCareerBtn = null!;
    private Button _resumeWorkBtn = null!;
    private Button _dressingRoomBtn = null!;
    private Button _shopBtn = null!;
    private Button _tutorialBtn = null!;
    private Label _clockLabel = null!;
    private RichTextLabel _outputLog = null!;
    private LineEdit _commandInput = null!;
    private Label _cursorBlock = null!;
    private AudioStreamPlayer _bgmAudio = null!;
    private AudioStreamPlayer _sfxClick = null!;
    private AudioStreamPlayer _sfxCommand = null!;
    private TextureRect _scenePreviewRect = null!;
    private Texture2D[] _previewFrames = Array.Empty<Texture2D>();

    private double _cursorBlinkTimer;
    private double _clockUpdateTimer;
    private double _previewAnimTimer;
    private int _previewFrameIndex;
    private const double PreviewFps = 6.67;
    private bool _cursorVisible = true;

    public override void _Ready()
    {
        BindNodes();
        WireEvents();
        UpdateClock();
        LoadPreviewAnimation();
        _startCareerBtn.GrabFocus();
    }

    private void BindNodes()
    {
        _startCareerBtn = GetNode<Button>("%StartCareerBtn");
        _resumeWorkBtn = GetNode<Button>("%ResumeWorkBtn");
        _dressingRoomBtn = GetNode<Button>("%DressingRoomBtn");
        _shopBtn = GetNode<Button>("%ShopBtn");
        _tutorialBtn = GetNode<Button>("%TutorialBtn");
        _clockLabel = GetNode<Label>("%ClockLabel");
        _outputLog = GetNode<RichTextLabel>("%OutputLog");
        _commandInput = GetNode<LineEdit>("%CommandInput");
        _cursorBlock = GetNode<Label>("%CursorBlock");
        _bgmAudio = GetNode<AudioStreamPlayer>("%BgmAudio");
        _sfxClick = GetNode<AudioStreamPlayer>("%SfxClick");
        _sfxCommand = GetNode<AudioStreamPlayer>("%SfxCommand");
        _scenePreviewRect = GetNode<TextureRect>("%ScenePreviewRect");
    }

    private void WireEvents()
    {
        _startCareerBtn.Pressed += OnStartCareerPressed;
        _resumeWorkBtn.Pressed += OnResumeWorkPressed;
        _dressingRoomBtn.Pressed += OnDressingRoomPressed;
        _shopBtn.Pressed += OnShopPressed;
        _tutorialBtn.Pressed += OnTutorialPressed;

        _startCareerBtn.FocusEntered += OnButtonFocusEntered;
        _resumeWorkBtn.FocusEntered += OnButtonFocusEntered;
        _dressingRoomBtn.FocusEntered += OnButtonFocusEntered;
        _shopBtn.FocusEntered += OnButtonFocusEntered;
        _tutorialBtn.FocusEntered += OnButtonFocusEntered;

        _commandInput.TextSubmitted += OnTerminalCommandSubmitted;
    }

    private void LoadPreviewAnimation()
    {
        SpriteFrames? framesResource = null;
        if (ResourceLoader.Exists("res://Scenes/tower_preview_frames.tres"))
        {
            framesResource = GD.Load<SpriteFrames>("res://Scenes/tower_preview_frames.tres");
        }
        else if (ResourceLoader.Exists("res://assets/art/start_screen/tower_preview_frames.tres"))
        {
            framesResource = GD.Load<SpriteFrames>("res://assets/art/start_screen/tower_preview_frames.tres");
        }

        if (framesResource != null && framesResource.HasAnimation("default"))
        {
            int count = framesResource.GetFrameCount("default");
            _previewFrames = new Texture2D[count];
            for (int i = 0; i < count; i++)
            {
                _previewFrames[i] = framesResource.GetFrameTexture("default", i);
            }
        }
    }

    public override void _Process(double delta)
    {
        // Blinking cursor
        _cursorBlinkTimer += delta;
        if (_cursorBlinkTimer >= 0.5)
        {
            _cursorBlinkTimer = 0.0;
            _cursorVisible = !_cursorVisible;
            _cursorBlock.Visible = _cursorVisible;
        }

        // Live clock
        _clockUpdateTimer += delta;
        if (_clockUpdateTimer >= 1.0)
        {
            _clockUpdateTimer = 0.0;
            UpdateClock();
        }

        // Tower preview animation (6.67 FPS, 0-65 looping)
        if (_previewFrames.Length > 0 && _scenePreviewRect != null)
        {
            _previewAnimTimer += delta;
            if (_previewAnimTimer >= (1.0 / PreviewFps))
            {
                _previewAnimTimer -= (1.0 / PreviewFps);
                _previewFrameIndex = (_previewFrameIndex + 1) % _previewFrames.Length;
                _scenePreviewRect.Texture = _previewFrames[_previewFrameIndex];
            }
        }
    }

    private void UpdateClock()
    {
        _clockLabel.Text = $"MT: {DateTime.Now:HH:mm:ss}";
    }

    private void OnButtonFocusEntered()
    {
        PlaySfx(_sfxClick);
    }

    private void OnStartCareerPressed()
    {
        PlaySfx(_sfxClick);
        AppendTerminalText("> Executing START NEW CAREER...");
        AppendTerminalText("> Initializing Magic Tower apprentice session...");
        
        // Delay slightly for audio feedback before switching scene
        var timer = GetTree().CreateTimer(0.35);
        timer.Timeout += () =>
        {
            GetTree().ChangeSceneToFile("res://scenes/cutscene/cut_scence_normal.tscn");
        };
    }

    private void OnResumeWorkPressed()
    {
        PlaySfx(_sfxClick);
        AppendTerminalText("> Resuming active repository session...");
        
        var timer = GetTree().CreateTimer(0.35);
        timer.Timeout += () =>
        {
            GetTree().ChangeSceneToFile("res://Scenes/SandboxGameView.tscn");
        };
    }

    private void OnDressingRoomPressed()
    {
        PlaySfx(_sfxClick);
        AppendTerminalText("> Accessing Royal Wardrobe & Dressing Room...");

        var timer = GetTree().CreateTimer(0.35);
        timer.Timeout += () =>
        {
            if (ResourceLoader.Exists("res://Scenes/DressingRoomView.tscn"))
            {
                GetTree().ChangeSceneToFile("res://Scenes/DressingRoomView.tscn");
            }
            else
            {
                AppendTerminalText("> Wardrobe module initialized.");
            }
        };
    }

    private void OnShopPressed()
    {
        PlaySfx(_sfxClick);
        AppendTerminalText("> Accessing Royal Magic Bazaar & Shop...");

        var timer = GetTree().CreateTimer(0.35);
        timer.Timeout += () =>
        {
            if (ResourceLoader.Exists("res://Scenes/ShopView.tscn"))
            {
                GetTree().ChangeSceneToFile("res://Scenes/ShopView.tscn");
            }
            else
            {
                AppendTerminalText("> Magic Bazaar module initialized.");
            }
        };
    }

    private void OnTutorialPressed()
    {
        PlaySfx(_sfxClick);
        AppendTerminalText("\n--- [ TUTORIAL & DOCUMENTATION ] ---");
        AppendTerminalText("ยินดีต้อนรับสู่ Git-Diwaa! คุณจะได้เรียนรู้ Git ผ่านโลกเวทมนตร์");
        AppendTerminalText("คำสั่งพื้นฐาน: git init, git status, git add ., git commit -m \"...\"");
        AppendTerminalText("กด [START NEW CAREER] เพื่อเข้าสู่ด่านหอคอยเวทมนตร์!\n");
    }

    private void OnTerminalCommandSubmitted(string input)
    {
        var cmd = input.Trim();
        if (string.IsNullOrEmpty(cmd)) return;

        PlaySfx(_sfxCommand);
        _commandInput.Clear();
        AppendTerminalText($"> {cmd}");

        var lower = cmd.ToLowerInvariant();
        if (lower is "clear" or "cls")
        {
            _outputLog.Text = "";
            return;
        }

        if (lower is "start" or "play" or "run")
        {
            OnStartCareerPressed();
            return;
        }

        if (lower is "dressing" or "dress" or "wardrobe")
        {
            OnDressingRoomPressed();
            return;
        }

        if (lower is "shop" or "bazaar" or "store" or "market")
        {
            OnShopPressed();
            return;
        }

        if (lower == "git init")
        {
            AppendTerminalText("Initialized empty Git repository in /magictower/spells/.git/");
        }
        else if (lower == "git status")
        {
            AppendTerminalText("On branch main\nNo commits yet\nUntracked files: new_spell.magic");
        }
        else if (lower is "git add ." or "git add new_spell.magic")
        {
            AppendTerminalText("Changes to be committed: new_spell.magic");
        }
        else if (lower.StartsWith("git commit"))
        {
            AppendTerminalText("[main (root-commit) 8f3a1b2] Recorded spell in ancient repository");
        }
        else if (lower == "git branch")
        {
            AppendTerminalText("* main\n  fireball");
        }
        else if (lower == "help")
        {
            AppendTerminalText("Commands: git init, git status, git add, git commit, git branch, start, wardrobe, shop, clear, help");
        }
        else
        {
            AppendTerminalText($"git: '{cmd}' executed in sandbox preview.");
        }
    }

    private void AppendTerminalText(string text)
    {
        if (string.IsNullOrEmpty(_outputLog.Text))
        {
            _outputLog.Text = text;
        }
        else
        {
            _outputLog.Text += $"\n{text}";
        }
    }

    private void PlaySfx(AudioStreamPlayer? player)
    {
        if (player != null && player.Stream != null)
        {
            player.Play();
        }
    }
}
