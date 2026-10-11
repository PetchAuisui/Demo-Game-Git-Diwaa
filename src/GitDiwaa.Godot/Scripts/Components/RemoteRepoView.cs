using GitDiwaa.Core;
using GitDiwaa.Godot.Common;
using Godot;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// หน้า Remote Repository จำลอง GitHub: Code (เปิดโฟลเดอร์/ไฟล์ได้), Commits, Branches,
/// Pull requests (สร้าง/ดู diff/review/merge/ปิด) อ่านและสั่งงานผ่าน <see cref="IGitRemoteHost"/> เท่านั้น
/// </summary>
public partial class RemoteRepoView : Control
{
    [Signal] public delegate void BackRequestedEventHandler();

    private enum Page { Code, Blob, Commits, Branches, Pulls, NewPull, PullDetail }

    private static readonly Color Green = new(0.18f, 0.55f, 0.27f);
    private static readonly Color Purple = new(0.64f, 0.45f, 0.95f);

    private IGitRemoteHost? _host;
    private RemoteRepositoryInfo? _repo;
    private Page _page = Page.Code;
    private string _branch = "main";
    private string _path = "";
    private int _pullNumber;
    private bool _showClosed;
    private string _newPullSource = "";
    private string _status = "";
    private bool _statusIsError;
    private bool _cloneOpen;

    private Label _titleLabel = null!;
    private Button _codeTab = null!;
    private Button _pullTab = null!;
    private VBoxContainer _content = null!;

    public override void _Ready()
    {
        SetAnchorsAndOffsetsPreset(LayoutPreset.FullRect);
        MouseFilter = MouseFilterEnum.Stop;

        var backdrop = new ColorRect { Color = new Color(0.02f, 0.03f, 0.06f, 0.94f) };
        backdrop.SetAnchorsAndOffsetsPreset(LayoutPreset.FullRect);
        AddChild(backdrop);

        var margin = new MarginContainer();
        margin.SetAnchorsAndOffsetsPreset(LayoutPreset.FullRect);
        margin.AddThemeConstantOverride("margin_left", 60);
        margin.AddThemeConstantOverride("margin_right", 60);
        margin.AddThemeConstantOverride("margin_top", 84);
        margin.AddThemeConstantOverride("margin_bottom", 40);
        AddChild(margin);

        var card = new PanelContainer();
        card.AddThemeStyleboxOverride("panel", Panel(SandboxThemeTokens.CardBg, SandboxThemeTokens.CardBorder, 12, 22));
        margin.AddChild(card);

        var root = new VBoxContainer();
        root.AddThemeConstantOverride("separation", 10);
        card.AddChild(root);

        var header = new HBoxContainer();
        header.AddThemeConstantOverride("separation", 14);
        header.AddChild(Btn("← กลับ Sandbox", () => EmitSignal(SignalName.BackRequested)));
        _titleLabel = Lbl("", SandboxThemeTokens.GoldTitle, 24);
        _titleLabel.SizeFlagsHorizontal = SizeFlags.ExpandFill;
        header.AddChild(_titleLabel);
        header.AddChild(Lbl("Public", SandboxThemeTokens.TextSecondary, 14));
        root.AddChild(header);

        var tabs = new HBoxContainer();
        _codeTab = Btn("</> Code", () => Go(Page.Code), toggle: true);
        _pullTab = Btn("⑂ Pull requests", () => Go(Page.Pulls), toggle: true);
        tabs.AddChild(_codeTab);
        tabs.AddChild(_pullTab);
        root.AddChild(tabs);
        root.AddChild(new HSeparator());

        var scroll = new ScrollContainer
        {
            SizeFlagsVertical = SizeFlags.ExpandFill,
            HorizontalScrollMode = ScrollContainer.ScrollMode.Disabled
        };
        _content = new VBoxContainer { SizeFlagsHorizontal = SizeFlags.ExpandFill };
        _content.AddThemeConstantOverride("separation", 10);
        scroll.AddChild(_content);
        root.AddChild(scroll);
    }

    public void Open(IGitRemoteHost host)
    {
        _host = host;
        Go(Page.Code);
    }

    private async void Go(Page page, string? message = null, bool error = false)
    {
        if (page != Page.Code && page != Page.Blob) _cloneOpen = false;
        _page = page;
        if (message is not null) { _status = message; _statusIsError = error; }
        await RefreshAsync();
    }

    private async Task RefreshAsync()
    {
        if (_host is null) return;
        foreach (var child in _content.GetChildren())
        {
            _content.RemoveChild(child);
            child.QueueFree();
        }

        try
        {
            _repo = await _host.GetRepositoryAsync();
            _titleLabel.Text = $"{_repo.Owner} / {_repo.Name}";
            var pulls = _host.ListPullRequests();
            _codeTab.ButtonPressed = _page is Page.Code or Page.Blob or Page.Commits or Page.Branches;
            _pullTab.ButtonPressed = !_codeTab.ButtonPressed;
            _pullTab.Text = $"⑂ Pull requests ({pulls.Count(p => p.State == PullRequestState.Open)})";
            if (!(await _host.ListBranchesAsync()).Any(b => b.Name == _branch)) _branch = _repo.DefaultBranch;

            if (_status.Length > 0)
            {
                _content.AddChild(Lbl(_status, _statusIsError ? SandboxThemeTokens.ErrorText : SandboxThemeTokens.PromptGreen, wrap: true));
                _status = "";
            }

            switch (_page)
            {
                case Page.Code: await BuildCodeAsync(); break;
                case Page.Blob: await BuildBlobAsync(); break;
                case Page.Commits: await BuildCommitsAsync(); break;
                case Page.Branches: await BuildBranchesAsync(); break;
                case Page.Pulls: BuildPulls(pulls); break;
                case Page.NewPull: await BuildNewPullAsync(); break;
                case Page.PullDetail: await BuildPullDetailAsync(); break;
            }
        }
        catch (Exception ex)
        {
            _content.AddChild(Lbl($"โหลดข้อมูล repository ไม่สำเร็จ: {ex.Message}", SandboxThemeTokens.ErrorText));
        }
    }

    // ───────────── UI helpers ─────────────

    private static string StateIcon(PullRequestState state) => state switch
    {
        PullRequestState.Open => "🟢",
        PullRequestState.Merged => "🟣",
        _ => "🔴"
    };

    private static string VerdictText(ReviewVerdict verdict) => verdict switch
    {
        ReviewVerdict.Approved => "✓ Approved",
        ReviewVerdict.ChangesRequested => "✗ Changes requested",
        _ => "💬 Commented"
    };

    private static string Count(int number, string singular, string plural) =>
        $"{number} {(number == 1 ? singular : plural)}";

    private static string ParentPath(string path)
    {
        var index = path.LastIndexOf('/');
        return index < 0 ? "" : path[..index];
    }

    private OptionButton BranchPicker(IReadOnlyList<RemoteBranchInfo> branches, Action<string> onSelected, string? selected = null)
    {
        selected ??= _branch;
        var picker = new OptionButton();
        for (var index = 0; index < branches.Count; index++)
        {
            picker.AddItem($"⑂ {branches[index].Name}", index);
            if (branches[index].Name == selected) picker.Selected = index;
        }

        picker.ItemSelected += index => onSelected(branches[(int)index].Name);
        return picker;
    }

    private static Label Lbl(string text, Color color, int size = 16, bool wrap = false)
    {
        var label = new Label { Text = text };
        if (wrap)
        {
            label.AutowrapMode = TextServer.AutowrapMode.WordSmart;
            label.SizeFlagsHorizontal = SizeFlags.ExpandFill;
        }

        label.AddThemeColorOverride("font_color", color);
        label.AddThemeFontSizeOverride("font_size", size);
        return label;
    }

    private static Button Btn(string text, Action onPressed, bool flat = false, bool toggle = false, Color? color = null)
    {
        var button = new Button { Text = text, Flat = flat, ToggleMode = toggle, FocusMode = FocusModeEnum.None };
        if (color is { } fill)
        {
            var style = Panel(fill, fill.Lightened(0.25f), 6, 12);
            button.AddThemeStyleboxOverride("normal", style);
            button.AddThemeStyleboxOverride("hover", Panel(fill.Lightened(0.12f), fill.Lightened(0.35f), 6, 12));
            button.AddThemeStyleboxOverride("pressed", style);
            button.AddThemeColorOverride("font_color", Colors.White);
        }

        button.Pressed += onPressed;
        return button;
    }

    private static PanelContainer Card()
    {
        var card = new PanelContainer { SizeFlagsHorizontal = SizeFlags.ExpandFill };
        card.AddThemeStyleboxOverride("panel", Panel(SandboxThemeTokens.InputBg, SandboxThemeTokens.CardBorder, 8, 14));
        return card;
    }

    private static StyleBoxFlat Panel(Color fill, Color border, int radius, int margin) => new()
    {
        BgColor = fill,
        BorderColor = border,
        BorderWidthLeft = 2, BorderWidthRight = 2, BorderWidthTop = 2, BorderWidthBottom = 2,
        CornerRadiusTopLeft = radius, CornerRadiusTopRight = radius,
        CornerRadiusBottomLeft = radius, CornerRadiusBottomRight = radius,
        ContentMarginLeft = margin, ContentMarginRight = margin,
        ContentMarginTop = margin * 0.6f, ContentMarginBottom = margin * 0.6f
    };

    private static SystemFont Mono() => new() { FontNames = ["Menlo", "Consolas", "monospace"] };

    private static string Ago(DateTimeOffset when)
    {
        var span = DateTimeOffset.Now - when;
        if (span.TotalDays >= 1) return $"{(int)span.TotalDays} day{((int)span.TotalDays == 1 ? "" : "s")} ago";
        if (span.TotalHours >= 1) return $"{(int)span.TotalHours} hour{((int)span.TotalHours == 1 ? "" : "s")} ago";
        if (span.TotalMinutes >= 1) return $"{(int)span.TotalMinutes} min ago";
        return "just now";
    }
}
