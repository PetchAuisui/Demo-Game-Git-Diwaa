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
    // Color & Theme Tokens for Dressing Room
    private static readonly Color TabActiveBg = new(0.427f, 0.157f, 0.851f, 1f);     // #6D28D9
    private static readonly Color TabActiveBorder = new(0.545f, 0.361f, 0.965f, 1f); // #8B5CF6
    private static readonly Color TabInactiveBg = new(0.082f, 0.059f, 0.180f, 0.9f); // #150F2E
    private static readonly Color TabInactiveBorder = new(0.180f, 0.137f, 0.333f, 1f); // #2E2355
    private static readonly Color TabActiveText = new(1.0f, 1.0f, 1.0f, 1.0f);
    private static readonly Color TabInactiveText = new(0.65f, 0.60f, 0.80f, 1.0f);

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

    // Category Tabs: 0 = All, 1 = Hood, 2 = Scarf, 3 = Bag, 4 = Cat
    private Button[] _tabButtons = Array.Empty<Button>();

    // Facing textures: 0 = Front, 1 = Right, 2 = Back, 3 = Left
    private Texture2D[] _facingTextures = Array.Empty<Texture2D>();
    private int _facingIndex = 0;

    // Active Category Filter: 0 = All, 1 = Hood, 2 = Scarf, 3 = Bag, 4 = Cat
    // TODO: Connect with Shop / Inventory purchased items filter once the Shop system is integrated.
    private int _activeCategory = 0;

    // Animation & Transition Guards
    private float _catInitialOffsetTop = 35.0f;
    private bool _isCatHopping = false;
    private bool _isLeaving = false;

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

        // Store ground reference position for cat hop animation
        _catInitialOffsetTop = _catSprite.OffsetTop;

        // Awaiting items from shop - keep companion cat standing nicely beside Vel
        _catSprite.Visible = true;
        _emptyStateContainer.Visible = true;
        _itemsGrid.Visible = false;
        _counterValue.Text = "0 ชิ้น";

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

        _tabButtons = new[]
        {
            GetNode<Button>("%TabAll"),
            GetNode<Button>("%TabHood"),
            GetNode<Button>("%TabScarf"),
            GetNode<Button>("%TabBag"),
            GetNode<Button>("%TabCat")
        };
    }

    private void LoadTextures()
    {
        string[] paths =
        {
            "res://assets/cutscene/characters/vel/vel_Hblue_Sredyellow_idle.png",
            "res://assets/cutscene/characters/vel/vel_right.png",
            "res://assets/cutscene/characters/vel/vel_back.png",
            "res://assets/cutscene/characters/vel/vel_left.png"
        };

        _facingTextures = new Texture2D[paths.Length];
        for (int i = 0; i < paths.Length; i++)
        {
            var texture = GD.Load<Texture2D>(paths[i]);
            if (texture == null)
            {
                GD.PushError($"[DressingRoom] Failed to load character texture from '{paths[i]}'");
            }
            _facingTextures[i] = texture!;
        }
    }

    private void InitTabStyles()
    {
        _tabActiveStyle = new StyleBoxFlat
        {
            BgColor = TabActiveBg,
            BorderWidthLeft = 2,
            BorderWidthTop = 2,
            BorderWidthRight = 2,
            BorderWidthBottom = 2,
            BorderColor = TabActiveBorder,
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
            BgColor = TabInactiveBg,
            BorderWidthLeft = 1,
            BorderWidthTop = 1,
            BorderWidthRight = 1,
            BorderWidthBottom = 1,
            BorderColor = TabInactiveBorder,
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

        for (int i = 0; i < _tabButtons.Length; i++)
        {
            int categoryIndex = i;
            _tabButtons[i].Pressed += () =>
            {
                PlaySfx();
                UpdateCategoryFilter(categoryIndex);
            };
        }

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
        if (_isCatHopping) return;
        _isCatHopping = true;

        if (_sfxMeow != null && _sfxMeow.Stream != null)
        {
            _sfxMeow.Play();
        }

        float initialTop = _catInitialOffsetTop;
        float initialBottom = _catInitialOffsetTop + 140.0f;

        // Cute hop animation anchored to initial OffsetTop & OffsetBottom on the pedestal
        var tween = CreateTween();
        tween.TweenProperty(_catSprite, "offset_top", initialTop - 14.0f, 0.12f)
             .SetTrans(Tween.TransitionType.Quad)
             .SetEase(Tween.EaseType.Out);
        tween.Parallel().TweenProperty(_catSprite, "offset_bottom", initialBottom - 14.0f, 0.12f)
             .SetTrans(Tween.TransitionType.Quad)
             .SetEase(Tween.EaseType.Out);

        tween.TweenProperty(_catSprite, "offset_top", initialTop, 0.14f)
             .SetTrans(Tween.TransitionType.Bounce)
             .SetEase(Tween.EaseType.Out);
        tween.Parallel().TweenProperty(_catSprite, "offset_bottom", initialBottom, 0.14f)
             .SetTrans(Tween.TransitionType.Bounce)
             .SetEase(Tween.EaseType.Out);

        tween.TweenCallback(Callable.From(() =>
        {
            _catSprite.OffsetTop = initialTop;
            _catSprite.OffsetBottom = initialBottom;
            _isCatHopping = false;
        }));
    }

    public override void _Input(InputEvent @event)
    {
        if (@event.IsActionPressed("ui_cancel"))
        {
            OnBackPressed();
            GetViewport().SetInputAsHandled();
        }
        else if (@event is InputEventKey keyEvent && keyEvent.Pressed && !keyEvent.Echo)
        {
            if (keyEvent.Keycode is Key.A or Key.Left)
            {
                OnRotateLeft();
                GetViewport().SetInputAsHandled();
            }
            else if (keyEvent.Keycode is Key.D or Key.Right)
            {
                OnRotateRight();
                GetViewport().SetInputAsHandled();
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
        _activeCategory = categoryIndex;

        // Apply Tab styles across all tabs
        for (int i = 0; i < _tabButtons.Length; i++)
        {
            ApplyTabStyle(_tabButtons[i], i == categoryIndex);
        }
    }

    private void ApplyTabStyle(Button btn, bool isActive)
    {
        btn.AddThemeStyleboxOverride("normal", isActive ? _tabActiveStyle : _tabInactiveStyle);
        btn.AddThemeStyleboxOverride("hover", isActive ? _tabActiveStyle : _tabInactiveStyle);
        btn.AddThemeStyleboxOverride("pressed", isActive ? _tabActiveStyle : _tabInactiveStyle);
        btn.AddThemeColorOverride("font_color", isActive ? TabActiveText : TabInactiveText);
    }

    private void OnBackPressed()
    {
        if (_isLeaving) return;
        _isLeaving = true;

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
