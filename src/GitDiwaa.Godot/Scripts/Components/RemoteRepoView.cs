using GitDiwaa.Core;
using GitDiwaa.Godot.Common;
using Godot;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// หน้า Remote Repository จำลอง GitHub (ธีม dark): Code (เปิดโฟลเดอร์/ไฟล์ได้), Commits, Branches,
/// Pull requests (สร้าง/ดู diff/review/merge/ปิด) อ่านและสั่งงานผ่าน <see cref="IGitRemoteHost"/> เท่านั้น
/// </summary>
public partial class RemoteRepoView : Control
{
    [Signal] public delegate void BackRequestedEventHandler();

    private enum Page { Code, Blob, Commits, Branches, Pulls, NewPull, PullDetail }

    private enum PullTab { Conversation, Commits, Files }

    // ใช้เป็นตัวบอกว่าปุ่มนี้เป็นปุ่มหลัก (สีเขียว) ในโค้ดหน้าเดิมที่ยังไม่ได้ปรับ
    private static readonly Color Green = GitHubTheme.SuccessEmphasis;
    private static readonly Color Purple = GitHubTheme.Done;

    private IGitRemoteHost? _host;
    private RemoteRepositoryInfo? _repo;
    private Page _page = Page.Code;
    private string _branch = "main";
    private string _path = "";
    private int _pullNumber;
    private PullTab _pullTab = PullTab.Conversation;
    private bool _showClosed;
    private string _newPullSource = "";
    private string _status = "";
    private bool _statusIsError;

    private Label _ownerLabel = null!;
    private Label _repoLabel = null!;
    private Label _addressPath = null!;
    private Control _avatarSlot = null!;
    private HBoxContainer _tabs = null!;
    private ScrollContainer _scroll = null!;
    private VBoxContainer _content = null!;

    public override void _Ready()
    {
        Theme = GitHubTheme.Create();
        SetAnchorsAndOffsetsPreset(LayoutPreset.FullRect);
        MouseFilter = MouseFilterEnum.Stop;

        var dim = new ColorRect { Color = new Color(0.004f, 0.016f, 0.035f, 0.9f) };
        dim.SetAnchorsAndOffsetsPreset(LayoutPreset.FullRect);
        AddChild(dim);

        var margin = new MarginContainer();
        margin.SetAnchorsAndOffsetsPreset(LayoutPreset.FullRect);
        margin.AddThemeConstantOverride("margin_left", 56);
        margin.AddThemeConstantOverride("margin_right", 56);
        margin.AddThemeConstantOverride("margin_top", 84);
        margin.AddThemeConstantOverride("margin_bottom", 36);
        AddChild(margin);

        var window = new PanelContainer { ClipContents = true };
        window.AddThemeStyleboxOverride("panel", GitHubTheme.Box(GitHubTheme.Canvas, GitHubTheme.Border, 8, 1));
        margin.AddChild(window);

        var column = new VBoxContainer();
        column.AddThemeConstantOverride("separation", 0);
        window.AddChild(column);
        column.AddChild(BuildTopBar());
        column.AddChild(BuildRepoHeader());
        column.AddChild(BuildBody());
    }

    public override void _UnhandledInput(InputEvent @event)
    {
        if (@event.IsActionPressed("ui_cancel"))
        {
            GetViewport().SetInputAsHandled();
            EmitSignal(SignalName.BackRequested);
        }
    }

    /// <summary>แถบบนสุด: ปุ่มกลับ Sandbox และช่อง URL เหมือนเบราว์เซอร์ (แสดงที่อยู่ของหน้าปัจจุบัน)</summary>
    private Control BuildTopBar()
    {
        var bar = new PanelContainer { MouseFilter = MouseFilterEnum.Pass };
        var style = GitHubTheme.Underlined(GitHubTheme.CanvasSubtle, GitHubTheme.Border, 1, 16, 10);
        style.CornerRadiusTopLeft = 7;
        style.CornerRadiusTopRight = 7;
        bar.AddThemeStyleboxOverride("panel", style);

        var row = new HBoxContainer();
        row.AddThemeConstantOverride("separation", 12);
        row.AddChild(GitHubUi.Btn("กลับ Sandbox", () => EmitSignal(SignalName.BackRequested), icon: GhIcon.ArrowLeft));

        var address = new PanelContainer
        {
            MouseFilter = MouseFilterEnum.Pass,
            CustomMinimumSize = new Vector2(560, 0),
            SizeFlagsHorizontal = SizeFlags.ShrinkBegin
        };
        address.AddThemeStyleboxOverride("panel", GitHubTheme.Box(GitHubTheme.Canvas, GitHubTheme.Border, 16, 1, 14, 4));
        var addressRow = new HBoxContainer { MouseFilter = MouseFilterEnum.Ignore };
        addressRow.AddThemeConstantOverride("separation", 8);
        addressRow.AddChild(GitHubUi.Icon(GhIcon.Lock, GitHubTheme.FgMuted, 14));
        addressRow.AddChild(GitHubUi.Text("github.com", GitHubTheme.FgMuted, 14));
        _addressPath = GitHubUi.Text(string.Empty, GitHubTheme.Fg, 14);
        addressRow.AddChild(_addressPath);
        address.AddChild(addressRow);
        row.AddChild(address);

        row.AddChild(GitHubUi.Spacer());
        _avatarSlot = new Control { MouseFilter = MouseFilterEnum.Ignore, CustomMinimumSize = new Vector2(28, 28) };
        row.AddChild(_avatarSlot);

        bar.AddChild(row);
        return bar;
    }

    /// <summary>ส่วนหัว repo: ไอคอน เจ้าของ / ชื่อ repo ป้าย Public และแท็บ Code / Pull requests</summary>
    private Control BuildRepoHeader()
    {
        var header = new PanelContainer { MouseFilter = MouseFilterEnum.Pass };
        header.AddThemeStyleboxOverride("panel", GitHubTheme.Underlined(GitHubTheme.CanvasSubtle, GitHubTheme.Border, 1, 24, 16, 0));

        var column = new VBoxContainer();
        column.AddThemeConstantOverride("separation", 12);

        var title = new HBoxContainer();
        title.AddThemeConstantOverride("separation", 8);
        title.AddChild(GitHubUi.Icon(GhIcon.Repo, GitHubTheme.FgMuted, 18));
        _ownerLabel = GitHubUi.Text(string.Empty, GitHubTheme.Accent, 20);
        title.AddChild(_ownerLabel);
        title.AddChild(GitHubUi.Text("/", GitHubTheme.FgMuted, 20));
        _repoLabel = GitHubUi.Text(string.Empty, GitHubTheme.Accent, 20, bold: true);
        title.AddChild(_repoLabel);
        title.AddChild(GitHubUi.Pill("Public", GitHubTheme.FgMuted, GitHubTheme.Border));
        column.AddChild(title);

        _tabs = new HBoxContainer();
        _tabs.AddThemeConstantOverride("separation", 4);
        column.AddChild(_tabs);

        header.AddChild(column);
        return header;
    }

    private Control BuildBody()
    {
        _scroll = new ScrollContainer
        {
            SizeFlagsVertical = SizeFlags.ExpandFill,
            HorizontalScrollMode = ScrollContainer.ScrollMode.Disabled
        };
        var margin = new MarginContainer { SizeFlagsHorizontal = SizeFlags.ExpandFill };
        margin.AddThemeConstantOverride("margin_left", 24);
        margin.AddThemeConstantOverride("margin_right", 24);
        margin.AddThemeConstantOverride("margin_top", 20);
        margin.AddThemeConstantOverride("margin_bottom", 40);
        _content = new VBoxContainer { SizeFlagsHorizontal = SizeFlags.ExpandFill };
        _content.AddThemeConstantOverride("separation", 16);
        margin.AddChild(_content);
        _scroll.AddChild(margin);
        return _scroll;
    }

    public void Open(IGitRemoteHost host)
    {
        _host = host;
        Go(Page.Code);
    }

    private async void Go(Page page, string? message = null, bool error = false)
    {
        _page = page;
        if (message is not null)
        {
            _status = message;
            _statusIsError = error;
        }

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
            ShowRepoHeader(_repo, _host.ListPullRequests().Count(p => p.State == PullRequestState.Open));
            if (!(await _host.ListBranchesAsync()).Any(b => b.Name == _branch)) _branch = _repo.DefaultBranch;

            if (_status.Length > 0)
            {
                _content.AddChild(GitHubUi.Flash(_status, _statusIsError));
                _status = string.Empty;
            }

            switch (_page)
            {
                case Page.Code: await BuildCodeAsync(); break;
                case Page.Blob: await BuildBlobAsync(); break;
                case Page.Commits: await BuildCommitsAsync(); break;
                case Page.Branches: await BuildBranchesAsync(); break;
                case Page.Pulls: BuildPulls(_host.ListPullRequests()); break;
                case Page.NewPull: await BuildNewPullAsync(); break;
                case Page.PullDetail: await BuildPullDetailAsync(); break;
            }
        }
        catch (Exception ex)
        {
            _content.AddChild(GitHubUi.Flash($"โหลดข้อมูล repository ไม่สำเร็จ: {ex.Message}", true));
        }

        _scroll.SetDeferred(ScrollContainer.PropertyName.ScrollVertical, 0);
    }

    private void ShowRepoHeader(RemoteRepositoryInfo repo, int openPulls)
    {
        _ownerLabel.Text = repo.Owner;
        _repoLabel.Text = repo.Name;
        _addressPath.Text = AddressPath(repo);

        foreach (var child in _avatarSlot.GetChildren())
        {
            _avatarSlot.RemoveChild(child);
            child.QueueFree();
        }

        _avatarSlot.AddChild(GitHubUi.Avatar(repo.Owner, 28));

        foreach (var child in _tabs.GetChildren())
        {
            _tabs.RemoveChild(child);
            child.QueueFree();
        }

        var codeActive = _page is Page.Code or Page.Blob or Page.Commits or Page.Branches;
        _tabs.AddChild(GitHubUi.Tab("Code", codeActive, () => { _path = string.Empty; Go(Page.Code); }, GhIcon.Code));
        _tabs.AddChild(GitHubUi.Tab("Pull requests", !codeActive, () => Go(Page.Pulls), GhIcon.PullOpen, openPulls));
    }

    /// <summary>ส่วนหลัง github.com ของที่อยู่หน้าปัจจุบัน เหมือน URL จริงของ GitHub</summary>
    private string AddressPath(RemoteRepositoryInfo repo)
    {
        var root = $"/{repo.Owner}/{repo.Name}";
        return _page switch
        {
            Page.Code => _path.Length == 0 ? root : $"{root}/tree/{_branch}/{_path}",
            Page.Blob => $"{root}/blob/{_branch}/{_path}",
            Page.Commits => $"{root}/commits/{_branch}",
            Page.Branches => $"{root}/branches",
            Page.Pulls => $"{root}/pulls",
            Page.NewPull => $"{root}/compare",
            Page.PullDetail => $"{root}/pull/{_pullNumber}",
            _ => root
        };
    }

    // ───────────── ตัวช่วยของหน้าเดิม (ทยอยย้ายไป GitHubUi ทีละหน้า) ─────────────

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
        var picker = new OptionButton { MouseFilter = MouseFilterEnum.Pass };
        var icon = GitHubIcons.Get(GhIcon.Branch, GitHubTheme.FgMuted);
        for (var index = 0; index < branches.Count; index++)
        {
            picker.AddIconItem(icon, branches[index].Name, index);
            if (branches[index].Name == selected) picker.Selected = index;
        }

        picker.ItemSelected += index => onSelected(branches[(int)index].Name);
        return picker;
    }

    private static Label Lbl(string text, Color color, int size = 16, bool wrap = false) =>
        GitHubUi.Text(text, color, size, wrap: wrap);

    private static Button Btn(string text, Action onPressed, bool flat = false, bool toggle = false, Color? color = null) =>
        GitHubUi.Btn(text, onPressed,
            color is not null ? GhButtonKind.Primary : flat ? GhButtonKind.Link : GhButtonKind.Default,
            toggle: toggle);

    private static PanelContainer Card() => GitHubUi.Card();

    private static string Ago(DateTimeOffset when) => GitHubUi.TimeAgo(when);
}
