using Godot;
using GitDiwaa.Godot.ViewModels;

namespace GitDiwaa.Godot.Components;

/// <summary>Scrollable graph surface with keyboard and pointer selection.</summary>
public partial class CommitGraphCanvas : Control
{
    public event Action<CommitGraphDisplayNode>? Selected;
    private CommitGraphLayout _layout = new(Array.Empty<CommitGraphDisplayNode>());
    private int _selected = -1;
    private int _hovered = -1;
    private const float RowHeight = 104;
    private readonly Font _font = new SystemFont { FontNames = ["Noto Sans Thai", "Thonburi", "Tahoma", "Arial"] };
    private static readonly Color[] LaneColors =
    {
        new("65dfb2"), new("8ca9ff"), new("df9ffa"), new("ffb66c"), new("68d3ee")
    };

    public CommitGraphCanvas()
    {
        FocusMode = FocusModeEnum.All;
        MouseDefaultCursorShape = CursorShape.PointingHand;
        MouseExited += () => { _hovered = -1; QueueRedraw(); };
    }

    public void SetLayout(CommitGraphLayout layout)
    {
        var selectedId = _selected >= 0 && _selected < _layout.Rows.Count ? _layout.Rows[_selected].Commit.Id : null;
        _layout = layout;
        _selected = layout.Rows.ToList().FindIndex(row => row.Commit.Id == selectedId);
        _hovered = -1;
        CustomMinimumSize = new Vector2(Math.Max(420, TextX + 280), layout.Rows.Count * RowHeight + 8);
        QueueRedraw();
    }

    private float CardX => 48 + _layout.LaneCount * 36;
    private float TextX => CardX + 20;
    private static Color LaneColor(int lane) => LaneColors[lane % LaneColors.Length];
    private static Vector2 Point(int row, int lane) => new(28 + lane * 36, row * RowHeight + 46);

    public override void _Draw()
    {
        var font = _font;
        DrawStyleBox(new StyleBoxFlat
        {
            BgColor = new Color("0d1725"),
            CornerRadiusTopLeft = 12, CornerRadiusTopRight = 12,
            CornerRadiusBottomLeft = 12, CornerRadiusBottomRight = 12
        }, new Rect2(0, 0, CardX - 14, Size.Y));
        for (var index = 0; index < _layout.Rows.Count; index++)
        {
                DrawStyleBox(new StyleBoxFlat
                {
                    BgColor = index == _selected ? new Color("28394d") : index == _hovered
                        ? new Color("203047") : new Color("152235"),
                    BorderColor = index == _selected ? new Color("ffc959") : new Color("2b4058"),
                    BorderWidthLeft = index == _selected ? 4 : 1,
                    BorderWidthTop = 1, BorderWidthRight = 1, BorderWidthBottom = 1,
                    CornerRadiusTopLeft = 12, CornerRadiusTopRight = 12,
                    CornerRadiusBottomLeft = 12, CornerRadiusBottomRight = 12
                }, new Rect2(CardX, index * RowHeight + 4, Size.X - CardX - 4, RowHeight - 12));
        }
        foreach (var edge in _layout.Edges)
        {
            var from = Point(edge.FromRow, edge.FromLane);
            var to = Point(edge.ToRow, edge.ToLane);
            var midpoint = (from.Y + to.Y) / 2;
            var points = Enumerable.Range(0, 25).Select(step =>
                from.BezierInterpolate(new Vector2(from.X, midpoint), new Vector2(to.X, midpoint), to, step / 24f)).ToArray();
            DrawPolyline(points, new Color(LaneColor(edge.FromLane), 0.09f), 11, true);
            DrawPolyline(points, LaneColor(edge.FromLane), 3.5f, true);
        }
        for (var index = 0; index < _layout.Rows.Count; index++)
        {
            var row = _layout.Rows[index];
            var point = Point(index, row.Lane);
            var color = row.Commit.IsCurrentBranchHead ? new Color("ffc959") : LaneColor(row.Lane);
            DrawCircle(point, 17, new Color(color, row.Commit.IsCurrentBranchHead ? 0.22f : 0.08f));
            DrawCircle(point, 10, new Color("0c1220"));
            DrawArc(point, 9, 0, Mathf.Tau, 32, color, 3, true);
            DrawCircle(point, 4, color);
            var y = index * RowHeight;
            DrawString(font, new Vector2(TextX, y + 37), row.Commit.Subject, HorizontalAlignment.Left,
                Size.X - TextX - 20, 23, new Color("f1f5fc"));
            DrawString(font, new Vector2(TextX, y + 73), row.Commit.ShortId, HorizontalAlignment.Left,
                106, 18, new Color("b0c4dd"));
            var refs = row.Commit.IsCurrentBranchHead ? "HEAD · " : "";
            refs += string.Join(" · ", row.Commit.Branches);
            if (refs.Length > 0)
            {
                var width = Math.Max(0, Math.Min(font.GetStringSize(refs, fontSize: 17).X + 24, Size.X - TextX - 130));
                if (width > 18)
                {
                    DrawStyleBox(new StyleBoxFlat
                    {
                        BgColor = new Color(color, 0.16f),
                        CornerRadiusTopLeft = 5, CornerRadiusTopRight = 5,
                        CornerRadiusBottomLeft = 5, CornerRadiusBottomRight = 5
                    }, new Rect2(TextX + 116, y + 51, width, 30));
                    DrawString(font, new Vector2(TextX + 128, y + 73), refs,
                        HorizontalAlignment.Left, width - 24, 17, color);
                }
            }
            else
                DrawString(font, new Vector2(TextX + 116, y + 73), row.Commit.Author,
                    HorizontalAlignment.Left, Size.X - TextX - 130, 17, new Color("8199b8"));
        }
    }

    public override void _GuiInput(InputEvent input)
    {
        if (input is InputEventMouseMotion motion)
        {
            _hovered = (int)(motion.Position.Y / RowHeight);
            QueueRedraw();
        }
        if (input is InputEventMouseButton { Pressed: true, ButtonIndex: MouseButton.Left } click)
        {
            Choose((int)(click.Position.Y / RowHeight));
            GrabFocus();
            AcceptEvent();
        }
        if (input is InputEventKey { Pressed: true } key)
        {
            if (key.Keycode == Key.Down) { Choose(Math.Min(_selected + 1, _layout.Rows.Count - 1)); AcceptEvent(); }
            if (key.Keycode == Key.Up) { Choose(Math.Max(0, _selected - 1)); AcceptEvent(); }
        }
    }

    private void Choose(int index)
    {
        if (index < 0 || index >= _layout.Rows.Count) return;
        _selected = index;
        Selected?.Invoke(_layout.Rows[index].Commit);
        QueueRedraw();
    }
}
