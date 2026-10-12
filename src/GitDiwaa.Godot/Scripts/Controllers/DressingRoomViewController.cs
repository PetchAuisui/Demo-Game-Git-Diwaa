using System;
using Godot;

namespace GitDiwaa.Godot.Controllers;

/// <summary>
/// Controller for the Dressing Room / Wardrobe View.
/// Currently left empty/open awaiting purchased items from the Shop.
/// Supports:
/// - 360-degree character rotation (Buttons & A/D, Left/Right arrow keys)
/// - Interactive Cat companion with cute hop bounce & meow SFX
/// - Smooth fade-in & fade-out screen transitions
/// - Category tabs and clean empty state
/// </summary>
public partial class DressingRoomViewController : Control
{
    private Button _backBtn = null!;
    private Button _rotateLeftBtn = null!;
    private Button _rotateRightBtn = null!;
    private TextureRect _charTexture = null!;
    private TextureRect _catSprite = null!;
    private AudioStreamPlayer _sfxClick = null!;
    private AudioStreamPlayer _sfxMeow = null!;
    private ColorRect _fadeOverlay = null!;
    private Label _counterValue = null!;
    private Control _emptyStateContainer = null!;
    private GridContainer _itemsGrid = null!;

    // Category Tabs: All, Hood, Scarf, Bag, Cat
    private Button _tabAll = null!;
    private Button _tabHood = null!;
    private Button _tabScarf = null!;
    private Button _tabBag = null!;
    private Button _tabCat = null!;

    // Facing textures: 0 = Front, 1 = Right, 2 = Back, 3 = Left
    private Texture2D[] _facingTextures = Array.Empty<Texture2D>();
    private int _facingIndex = 0;

    // Active Category Filter: 0 = All, 1 = Hood, 2 = Scarf, 3 = Bag, 4 = Cat
    private int _activeCategory = 0;

    // Tab Styles
    private StyleBoxFlat _tabActiveStyle = null!;
    private StyleBoxFlat _tabInactiveStyle = null!;

    public override void _Ready()
    {
        BindNodes();
        LoadTextures();
        InitTabStyles();
        WireEvents();
        UpdateCharacterFacing();
        UpdateCategoryFilter(0);

        // Awaiting items from shop - keep companion cat standing nicely beside Vel
        _catSprite.Visible = true;
        _emptyStateContainer.Visible = true;
        _itemsGrid.Visible = false;
        _counterValue.Text = "0 ชิ้น";

        _backBtn.GrabFocus();
        StartFadeIn();
    }

    private void BindNodes()
    {
        _backBtn = GetNode<Button>("%BackBtn");
        _rotateLeftBtn = GetNode<Button>("%RotateLeftBtn");
        _rotateRightBtn = GetNode<Button>("%RotateRightBtn");
        _charTexture = GetNode<TextureRect>("%CharacterSprite");
        _catSprite = GetNode<TextureRect>("%CatCompanionSprite");
        _sfxClick = GetNode<AudioStreamPlayer>("%SfxClick");
        _sfxMeow = GetNode<AudioStreamPlayer>("%SfxMeow");
        _fadeOverlay = GetNode<ColorRect>("%FadeOverlay");
        _counterValue = GetNode<Label>("%CounterValue");
        _emptyStateContainer = GetNode<Control>("%EmptyStateContainer");
        _itemsGrid = GetNode<GridContainer>("%ItemsGrid");

        _tabAll = GetNode<Button>("%TabAll");
        _tabHood = GetNode<Button>("%TabHood");
        _tabScarf = GetNode<Button>("%TabScarf");
        _tabBag = GetNode<Button>("%TabBag");
        _tabCat = GetNode<Button>("%TabCat");
    }

    private void LoadTextures()
    {
        _facingTextures = new Texture2D[4];
        _facingTextures[0] = GD.Load<Texture2D>("res://assets/cutscene/characters/vel/vel_Hblue_Sredyellow_idle.png");
        _facingTextures[1] = GD.Load<Texture2D>("res://assets/cutscene/characters/vel/vel_right.png");
        _facingTextures[2] = GD.Load<Texture2D>("res://assets/cutscene/characters/vel/vel_back.png");
        _facingTextures[3] = GD.Load<Texture2D>("res://assets/cutscene/characters/vel/vel_left.png");
    }

    private void InitTabStyles()
    {
        _tabActiveStyle = new StyleBoxFlat
        {
            BgColor = new Color(0.427f, 0.157f, 0.851f, 1f), // #6D28D9
            BorderWidthLeft = 2,
            BorderWidthTop = 2,
            BorderWidthRight = 2,
            BorderWidthBottom = 2,
            BorderColor = new Color(0.545f, 0.361f, 0.965f, 1f), // #8B5CF6
            CornerRadiusTopLeft = 14,
            CornerRadiusTopRight = 14,
            CornerRadiusBottomLeft = 14,
            CornerRadiusBottomRight = 14,
            ContentMarginLeft = 14,
            ContentMarginRight = 14,
            ContentMarginTop = 6,
            ContentMarginBottom = 6
        };

        _tabInactiveStyle = new StyleBoxFlat
        {
            BgColor = new Color(0.082f, 0.059f, 0.180f, 0.9f), // #150F2E
            BorderWidthLeft = 1,
            BorderWidthTop = 1,
            BorderWidthRight = 1,
            BorderWidthBottom = 1,
            BorderColor = new Color(0.180f, 0.137f, 0.333f, 1f), // #2E2355
            CornerRadiusTopLeft = 14,
            CornerRadiusTopRight = 14,
            CornerRadiusBottomLeft = 14,
            CornerRadiusBottomRight = 14,
            ContentMarginLeft = 14,
            ContentMarginRight = 14,
            ContentMarginTop = 6,
            ContentMarginBottom = 6
        };
    }

    private void WireEvents()
    {
        _backBtn.Pressed += OnBackPressed;
        _rotateLeftBtn.Pressed += OnRotateLeft;
        _rotateRightBtn.Pressed += OnRotateRight;

        _tabAll.Pressed += () => UpdateCategoryFilter(0);
        _tabHood.Pressed += () => UpdateCategoryFilter(1);
        _tabScarf.Pressed += () => UpdateCategoryFilter(2);
        _tabBag.Pressed += () => UpdateCategoryFilter(3);
        _tabCat.Pressed += () => UpdateCategoryFilter(4);

        // Interactive cat on pedestal
        _catSprite.GuiInput += OnCatGuiInput;
    }

    private void StartFadeIn()
    {
        if (_fadeOverlay == null) return;
        _fadeOverlay.Modulate = new Color(1, 1, 1, 1);
        var tween = CreateTween();
        tween.TweenProperty(_fadeOverlay, "modulate:a", 0.0f, 0.35f)
             .SetTrans(Tween.TransitionType.Quad)
             .SetEase(Tween.EaseType.Out);
    }

    private void OnCatGuiInput(InputEvent @event)
    {
        if (@event is InputEventMouseButton mb && mb.Pressed && mb.ButtonIndex == MouseButton.Left)
        {
            OnCatClicked();
        }
    }

    private void OnCatClicked()
    {
        if (_sfxMeow != null && _sfxMeow.Stream != null)
        {
            _sfxMeow.Play();
        }

        // Cute hop animation
        var tween = CreateTween();
        float currentY = _catSprite.Position.Y;
        tween.TweenProperty(_catSprite, "position:y", currentY - 14.0f, 0.12f)
             .SetTrans(Tween.TransitionType.Quad)
             .SetEase(Tween.EaseType.Out);
        tween.TweenProperty(_catSprite, "position:y", currentY, 0.14f)
             .SetTrans(Tween.TransitionType.Bounce)
             .SetEase(Tween.EaseType.Out);
    }

    public override void _UnhandledInput(InputEvent @event)
    {
        if (@event.IsActionPressed("ui_cancel"))
        {
            OnBackPressed();
        }
        else if (@event is InputEventKey keyEvent && keyEvent.Pressed && !keyEvent.Echo)
        {
            if (keyEvent.Keycode == Key.A || keyEvent.Keycode == Key.Left)
            {
                OnRotateLeft();
            }
            else if (keyEvent.Keycode == Key.D || keyEvent.Keycode == Key.Right)
            {
                OnRotateRight();
            }
        }
    }

    private void OnRotateLeft()
    {
        PlaySfx();
        _facingIndex = (_facingIndex + 3) % 4;
        UpdateCharacterFacing();
    }

    private void OnRotateRight()
    {
        PlaySfx();
        _facingIndex = (_facingIndex + 1) % 4;
        UpdateCharacterFacing();
    }

    private void UpdateCharacterFacing()
    {
        if (_facingTextures.Length > _facingIndex && _facingTextures[_facingIndex] != null)
        {
            _charTexture.Texture = _facingTextures[_facingIndex];
        }
    }

    private void UpdateCategoryFilter(int categoryIndex)
    {
        PlaySfx();
        _activeCategory = categoryIndex;

        // Apply Tab styles
        ApplyTabStyle(_tabAll, categoryIndex == 0);
        ApplyTabStyle(_tabHood, categoryIndex == 1);
        ApplyTabStyle(_tabScarf, categoryIndex == 2);
        ApplyTabStyle(_tabBag, categoryIndex == 3);
        ApplyTabStyle(_tabCat, categoryIndex == 4);
    }

    private void ApplyTabStyle(Button btn, bool isActive)
    {
        btn.AddThemeStyleboxOverride("normal", isActive ? _tabActiveStyle : _tabInactiveStyle);
        btn.AddThemeStyleboxOverride("hover", isActive ? _tabActiveStyle : _tabInactiveStyle);
        btn.AddThemeStyleboxOverride("pressed", isActive ? _tabActiveStyle : _tabInactiveStyle);
        btn.AddThemeColorOverride("font_color", isActive ? new Color(1, 1, 1, 1) : new Color(0.65f, 0.60f, 0.80f, 1));
    }

    private void OnBackPressed()
    {
        PlaySfx();
        if (_fadeOverlay != null)
        {
            var tween = CreateTween();
            tween.TweenProperty(_fadeOverlay, "modulate:a", 1.0f, 0.22f)
                 .SetTrans(Tween.TransitionType.Quad)
                 .SetEase(Tween.EaseType.In);
            tween.TweenCallback(Callable.From(() =>
            {
                GetTree().ChangeSceneToFile("res://Scenes/StartView.tscn");
            }));
        }
        else
        {
            GetTree().ChangeSceneToFile("res://Scenes/StartView.tscn");
        }
    }

    private void PlaySfx()
    {
        if (_sfxClick != null && _sfxClick.Stream != null)
        {
            _sfxClick.Play();
        }
    }
}
