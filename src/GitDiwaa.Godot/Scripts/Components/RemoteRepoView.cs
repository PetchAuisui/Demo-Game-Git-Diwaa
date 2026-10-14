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

    private enum Page { Repos, NewRepo, Code, Blob, Commits, Branches, Pulls, NewPull, PullDetail }

    private enum PullTab { Conversation, Commits, Files }

    private IGitRemoteAccount? _account;
    private IGitRemoteHost? _host;
    private Button _backButton = null!;
    private int? _restoreScroll;
    private RemoteRepositoryInfo? _repo;
    private Page _page = Page.Repos;
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
    private PanelContainer _window = null!;
    private Control _repoHeader = null!;
    private TextureRect _roomBackdrop = null!;
    private MarginContainer _topMargin = null!;
    private MarginContainer _headerMargin = null!;
    private MarginContainer _bodyMargin = null!;

    /// <summary>ความกว้างสูงสุดของเนื้อหา (หัว repo และตัวหน้าจัดกึ่งกลางให้ตรงกัน) จอกว้างขึ้นก็ไม่ยืดตาม</summary>
    private static int ContentMaxWidth => S(1320);

    public override void _Ready()
    {
        Theme = GitHubTheme.Create();
        SetAnchorsAndOffsetsPreset(LayoutPreset.FullRect);
        MouseFilter = MouseFilterEnum.Stop;
        GetViewport().GuiReleaseFocus(); // ไม่ให้ช่องพิมพ์ของ terminal ด้านหลังรับคีย์บอร์ดต่อ

        var dim = new ColorRect { Color = GitHubTheme.Backdrop };
        dim.SetAnchorsAndOffsetsPreset(LayoutPreset.FullRect);
        AddChild(dim);

        var margin = new MarginContainer();
        margin.SetAnchorsAndOffsetsPreset(LayoutPreset.FullRect);
        margin.AddThemeConstantOverride("margin_left", 28);
        margin.AddThemeConstantOverride("margin_right", 28);
        margin.AddThemeConstantOverride("margin_top", 84);
        margin.AddThemeConstantOverride("margin_bottom", 28);
        AddChild(margin);

        var window = new PanelContainer { ClipContents = true };
        _window = window;
        window.AddThemeStyleboxOverride("panel", GitHubTheme.Box(GitHubTheme.Canvas, GitHubTheme.Border, 10, 1));
        margin.AddChild(window);

        _roomBackdrop = BuildRoomBackdrop();
        window.AddChild(_roomBackdrop);

        var column = new VBoxContainer();
        column.AddThemeConstantOverride("separation", S(0));
        window.AddChild(column);
        column.AddChild(BuildTopBar());
        _repoHeader = BuildRepoHeader();
        column.AddChild(_repoHeader);
        column.AddChild(BuildBody());

        _window.Resized += UpdateGutters;
        Callable.From(UpdateGutters).CallDeferred();
    }

    /// <summary>
    /// กด Esc เพื่อกลับ Sandbox ดักใน _Input (ก่อน GUI) เพราะโฟกัสอาจค้างที่ช่องพิมพ์ของ terminal
    /// ยกเว้นขณะพิมพ์ในช่องของหน้านี้เอง (ให้ Esc ใช้เลิกพิมพ์ก่อน)
    /// </summary>
    public override void _Input(InputEvent @event)
    {
        if (!@event.IsActionPressed("ui_cancel")) return;
        var focus = GetViewport().GuiGetFocusOwner();
        if (focus is LineEdit or TextEdit && IsAncestorOf(focus))
        {
            focus.ReleaseFocus();
            GetViewport().SetInputAsHandled();
            return;
        }

        GetViewport().SetInputAsHandled();
        EmitSignal(SignalName.BackRequested);
    }

    /// <summary>แถบบนสุด: ปุ่มย้อนกลับ ช่อง URL ตรงกลางเหมือนเบราว์เซอร์ และปุ่มปิด (แสดงที่อยู่ของหน้าปัจจุบัน)</summary>
    private Control BuildTopBar()
    {
        var bar = new PanelContainer { MouseFilter = MouseFilterEnum.Pass };
        var style = GitHubTheme.Underlined(GitHubTheme.Inset, GitHubTheme.Border, 1, 0, 10);
        style.CornerRadiusTopLeft = 9;
        style.CornerRadiusTopRight = 9;
        bar.AddThemeStyleboxOverride("panel", style);

        _topMargin = new MarginContainer();
        _topMargin.AddThemeConstantOverride("margin_left", S(16));
        _topMargin.AddThemeConstantOverride("margin_right", S(16));
        // สามช่อง: ซ้าย/ขวาขยายเท่ากัน ช่อง URL ตรงกลางจึงอยู่กลางแถบพอดี
        var row = new HBoxContainer();
        row.AddThemeConstantOverride("separation", S(12));

        var left = new HBoxContainer { SizeFlagsHorizontal = SizeFlags.ExpandFill, SizeFlagsStretchRatio = 1 };
        left.AddThemeConstantOverride("separation", S(12));
        _backButton = GitHubUi.Btn("ย้อนกลับ", () => Go(Page.Repos), icon: GhIcon.ArrowLeft);
        _backButton.TooltipText = "กลับไปรายการ repository";
        _backButton.Visible = false;
        left.AddChild(_backButton);

        var simulated = GitHubUi.Pill("Magic Vault", GitHubTheme.Attention, new Color(GitHubTheme.Attention, 0.55f), size: 13);
        simulated.SizeFlagsVertical = SizeFlags.ShrinkCenter;
        left.AddChild(simulated);
        row.AddChild(left);

        var address = new PanelContainer
        {
            MouseFilter = MouseFilterEnum.Pass,
            CustomMinimumSize = new Vector2(S(560), 0),
            SizeFlagsHorizontal = SizeFlags.ShrinkCenter
        };
        address.AddThemeStyleboxOverride("panel", GitHubTheme.Box(GitHubTheme.Surface, GitHubTheme.Border, 16, 1, 14, 4));
        var addressRow = new HBoxContainer { MouseFilter = MouseFilterEnum.Ignore };
        addressRow.AddThemeConstantOverride("separation", S(8));
        addressRow.AddChild(GitHubUi.Icon(GhIcon.Lock, GitHubTheme.FgMuted, 14));
        addressRow.AddChild(GitHubUi.Text("magic-vault.com", GitHubTheme.FgMuted, 14));
        _addressPath = GitHubUi.Text(string.Empty, GitHubTheme.Fg, 14);
        addressRow.AddChild(_addressPath);
        address.AddChild(addressRow);
        row.AddChild(address);

        var right = new HBoxContainer
        {
            SizeFlagsHorizontal = SizeFlags.ExpandFill,
            SizeFlagsStretchRatio = 1,
            Alignment = BoxContainer.AlignmentMode.End
        };
        right.AddThemeConstantOverride("separation", S(12));
        var refresh = GitHubUi.Btn(string.Empty, () => Go(_page), GhButtonKind.Ghost, GhIcon.Refresh);
        refresh.TooltipText = "รีเฟรชหน้านี้";
        right.AddChild(refresh);
        _avatarSlot = new Control { MouseFilter = MouseFilterEnum.Ignore, CustomMinimumSize = new Vector2(S(28), S(28)) };
        right.AddChild(_avatarSlot);
        right.AddChild(GitHubUi.KeyHint("Esc"));
        right.AddChild(GitHubUi.Btn("ปิด", () => EmitSignal(SignalName.BackRequested), icon: GhIcon.X));
        row.AddChild(right);

        _topMargin.AddChild(row);
        bar.AddChild(_topMargin);
        return bar;
    }

    /// <summary>ส่วนหัว repo: ไอคอน เจ้าของ / ชื่อ repo ป้าย Public และแท็บ Code / Pull requests</summary>
    private Control BuildRepoHeader()
    {
        var header = new PanelContainer { MouseFilter = MouseFilterEnum.Pass };
        header.AddThemeStyleboxOverride("panel", GitHubTheme.Underlined(GitHubTheme.Surface, GitHubTheme.Border, 1, 0, 16, 0));

        _headerMargin = new MarginContainer();
        _headerMargin.AddThemeConstantOverride("margin_left", S(24));
        _headerMargin.AddThemeConstantOverride("margin_right", S(24));
        var column = new VBoxContainer();
        column.AddThemeConstantOverride("separation", S(12));

        var title = new HBoxContainer();
        title.AddThemeConstantOverride("separation", S(8));
        title.AddChild(GitHubUi.Icon(GhIcon.Repo, GitHubTheme.FgMuted, 18));
        _ownerLabel = GitHubUi.Text(string.Empty, GitHubTheme.Accent, 20);
        _ownerLabel.TooltipText = "กลับไปรายการ repository";
        _ownerLabel.MouseFilter = MouseFilterEnum.Stop;
        _ownerLabel.MouseDefaultCursorShape = CursorShape.PointingHand;
        _ownerLabel.GuiInput += input =>
        {
            if (input is InputEventMouseButton { Pressed: true, ButtonIndex: MouseButton.Left }) Go(Page.Repos);
        };
        title.AddChild(_ownerLabel);
        title.AddChild(GitHubUi.Text("/", GitHubTheme.FgMuted, 20));
        _repoLabel = GitHubUi.Text(string.Empty, GitHubTheme.Accent, 20, bold: true);
        title.AddChild(_repoLabel);
        title.AddChild(GitHubUi.Pill("Public", GitHubTheme.FgMuted, GitHubTheme.Border));
        column.AddChild(title);

        _tabs = new HBoxContainer();
        _tabs.AddThemeConstantOverride("separation", S(4));
        column.AddChild(_tabs);

        _headerMargin.AddChild(column);
        header.AddChild(_headerMargin);
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
        margin.AddThemeConstantOverride("margin_left", S(24));
        margin.AddThemeConstantOverride("margin_right", S(24));
        margin.AddThemeConstantOverride("margin_top", S(20));
        margin.AddThemeConstantOverride("margin_bottom", S(40));
        _bodyMargin = margin;
        _scroll.GetVScrollBar().VisibilityChanged += UpdateGutters;
        _content = new VBoxContainer { SizeFlagsHorizontal = SizeFlags.ExpandFill };
        _content.AddThemeConstantOverride("separation", S(16));
        margin.AddChild(_content);
        _scroll.AddChild(margin);
        return _scroll;
    }

    /// <summary>
    /// จัดเนื้อหาให้อยู่กึ่งกลางกว้างไม่เกิน <see cref="ContentMaxWidth"/> ทั้งแถบบน หัว repo และตัวหน้า
    /// ขอบซ้าย/ขวาตรงกัน โดยหักความกว้างแถบเลื่อนฝั่งตัวหน้าออกจากขอบขวา
    /// </summary>
    private void UpdateGutters()
    {
        // อาจถูกเรียกแบบ deferred หลังหน้าถูกปิด (กด Esc) จึงเช็กว่าโหนดยังอยู่
        if (!IsInstanceValid(_window) || !IsInstanceValid(_topMargin) || !IsInstanceValid(_headerMargin)
            || !IsInstanceValid(_bodyMargin) || !IsInstanceValid(_scroll)) return;

        var gutter = Math.Max(S(20), (int)((_window.Size.X - ContentMaxWidth) / 2f));
        var scrollbar = _scroll.GetVScrollBar();
        var scrollbarWidth = scrollbar.Visible ? (int)scrollbar.GetCombinedMinimumSize().X : 0;

        foreach (var margin in new[] { _topMargin, _headerMargin })
        {
            margin.AddThemeConstantOverride("margin_left", gutter);
            margin.AddThemeConstantOverride("margin_right", gutter);
        }

        _bodyMargin.AddThemeConstantOverride("margin_left", gutter);
        _bodyMargin.AddThemeConstantOverride("margin_right", Math.Max(S(12), gutter - scrollbarWidth));
    }

    public void Open(IGitRemoteAccount account)
    {
        _account = account;
        _host = null;
        Go(Page.Repos);
    }

    /// <summary>เปิด repo ที่เลือกจากรายการ (เริ่มที่หน้า Code ของ repo นั้น)</summary>
    private void OpenRepo(string name)
    {
        var host = _account?.OpenRepository(name);
        if (host is null) return;
        _host = host;
        _branch = "main";
        _path = string.Empty;
        _pullNumber = 0;
        _showClosed = false;
        _newPullSource = string.Empty;
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

    private bool _refreshing;
    private bool _refreshQueued;

    /// <summary>
    /// รีเฟรชทีละรอบ: ถ้ากดเปลี่ยนหน้าซ้อนระหว่างรอข้อมูล รอบที่สองจะรอรอบแรกจบแล้วค่อยวาดใหม่
    /// ไม่งั้นสองรอบจะเติมเนื้อหาลง _content พร้อมกันจนซ้ำ
    /// </summary>
    private async Task RefreshAsync()
    {
        if (_refreshing)
        {
            _refreshQueued = true;
            return;
        }

        _refreshing = true;
        try
        {
            do
            {
                _refreshQueued = false;
                await RefreshOnceAsync();
            } while (_refreshQueued && IsAlive);
        }
        finally
        {
            _refreshing = false;
        }
    }

    private async Task RefreshOnceAsync()
    {
        if (_account is null) return;
        foreach (var child in _content.GetChildren())
        {
            _content.RemoveChild(child);
            child.QueueFree();
        }

        try
        {
            if (_page is Page.Repos or Page.NewRepo)
                await RefreshAccountPageAsync();
            else if (_host is not null)
                await RefreshRepoPageAsync(_host);
        }
        catch (Exception ex)
        {
            if (!IsAlive) return; // ปิดหน้าไปแล้วระหว่างรอข้อมูล ไม่ต้องแจ้งอะไร
            _content.AddChild(GitHubUi.Flash($"โหลดข้อมูล repository ไม่สำเร็จ: {ex.Message}", true));
        }

        if (!IsAlive) return;
        Callable.From(UpdateGutters).CallDeferred();
        var scroll = _restoreScroll ?? 0;
        _restoreScroll = null;
        if (scroll == 0) _scroll.SetDeferred(ScrollContainer.PropertyName.ScrollVertical, 0);
        else RestoreScrollAsync(scroll);
    }

    /// <summary>กลับไปตำแหน่งเลื่อนเดิมหลังโหลดหน้าใหม่ (เช่น หลังส่งความเห็นกลาง diff) ต้องรอให้เลย์เอาต์ยาวพอก่อน</summary>
    private async void RestoreScrollAsync(int value)
    {
        for (var frame = 0; frame < 3; frame++)
        {
            await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);
            if (!IsAlive) return;
            _scroll.ScrollVertical = value;
        }
    }

    /// <summary>หน้าระดับบัญชี: รายการ repo และฟอร์มสร้าง repo ใหม่ (ยังไม่ได้อยู่ใน repo ใด)</summary>
    private async Task RefreshAccountPageAsync()
    {
        var repos = await _account!.ListRepositoriesAsync();
        if (!IsAlive) return;
        ShowAccountHeader(_account.Owner);
        ShowStatus();
        if (_page == Page.Repos) BuildRepos(repos);
        else BuildNewRepo();
    }

    private async Task RefreshRepoPageAsync(IGitRemoteHost host)
    {
        _repo = await host.GetRepositoryAsync();
        if (!IsAlive) return;
        ShowRepoHeader(_repo, host.ListPullRequests().Count(p => p.State == PullRequestState.Open));
        var branches = await host.ListBranchesAsync();
        if (!IsAlive) return;
        if (!branches.Any(b => b.Name == _branch)) _branch = _repo.DefaultBranch;

        ShowStatus();

        switch (_page)
        {
            case Page.Code: await BuildCodeAsync(); break;
            case Page.Blob: await BuildBlobAsync(); break;
            case Page.Commits: await BuildCommitsAsync(); break;
            case Page.Branches: await BuildBranchesAsync(); break;
            case Page.Pulls: BuildPulls(host.ListPullRequests()); break;
            case Page.NewPull: await BuildNewPullAsync(); break;
            case Page.PullDetail: await BuildPullDetailAsync(); break;
        }
    }

    private void ShowStatus()
    {
        if (_status.Length == 0) return;
        _content.AddChild(GitHubUi.Flash(_status, _statusIsError));
        _status = string.Empty;
    }

    private void SetAvatar(string owner)
    {
        foreach (var child in _avatarSlot.GetChildren())
        {
            _avatarSlot.RemoveChild(child);
            child.QueueFree();
        }

        _avatarSlot.AddChild(GitHubUi.Avatar(owner, 28));
    }

    private void ShowAccountHeader(string owner)
    {
        _repoHeader.Visible = false;
        _backButton.Visible = _page == Page.NewRepo;
        _roomBackdrop.Visible = true;
        _addressPath.Text = _page == Page.NewRepo ? "/new" : $"/{owner}?tab=repositories";
        SetAvatar(owner);
    }

    private void ShowRepoHeader(RemoteRepositoryInfo repo, int openPulls)
    {
        _repoHeader.Visible = true;
        _backButton.Visible = true;
        _roomBackdrop.Visible = false;
        _ownerLabel.Text = repo.Owner;
        _repoLabel.Text = repo.Name;
        _addressPath.Text = AddressPath(repo);
        SetAvatar(repo.Owner);

        foreach (var child in _tabs.GetChildren())
        {
            _tabs.RemoveChild(child);
            child.QueueFree();
        }

        var codeActive = _page is Page.Code or Page.Blob or Page.Commits or Page.Branches;
        _tabs.AddChild(GitHubUi.Tab("Code", codeActive, () => { _path = string.Empty; Go(Page.Code); }, GhIcon.Code));
        _tabs.AddChild(GitHubUi.Tab("Pull requests", !codeActive, () => Go(Page.Pulls), GhIcon.PullOpen, openPulls));
    }

    /// <summary>ส่วนหลัง magic-vault.com ของที่อยู่หน้าปัจจุบัน</summary>
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

    // ───────────── ตัวช่วย ─────────────

    private static int S(int pixels) => GitHubTheme.S(pixels);

    /// <summary>ผู้เล่นอาจกด Esc ปิดหน้าระหว่างรอข้อมูลจาก Git จึงต้องเช็กก่อนแตะโหนดหลังทุก await</summary>
    private bool IsAlive => IsInstanceValid(this) && !IsQueuedForDeletion();

    private static string ParentPath(string path)
    {
        var index = path.LastIndexOf('/');
        return index < 0 ? "" : path[..index];
    }

    private OptionButton BranchPicker(IReadOnlyList<RemoteBranchInfo> branches, Action<string> onSelected, string? selected = null)
    {
        selected ??= _branch;
        var picker = new OptionButton { MouseFilter = MouseFilterEnum.Pass };
        var icon = GitHubIcons.Get(GhIcon.Branch, GitHubTheme.FgMuted, S(16));
        for (var index = 0; index < branches.Count; index++)
        {
            picker.AddIconItem(icon, branches[index].Name, index);
            if (branches[index].Name == selected) picker.Selected = index;
        }

        picker.ItemSelected += index => onSelected(branches[(int)index].Name);
        return picker;
    }
}
