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
    private const float RowHeight = 72;
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

    private float TextX => 32 + _layout.LaneCount * 24;
    private static Color LaneColor(int lane) => LaneColors[lane % LaneColors.Length];
    private static Vector2 Point(int row, int lane) => new(24 + lane * 24, row * RowHeight + 27);

    public override void _Draw()
    {
        var font = ThemeDB.FallbackFont;
        for (var index = 0; index < _layout.Rows.Count; index++)
        {
                DrawStyleBox(new StyleBoxFlat
                {
                    BgColor = index == _selected ? new Color("26344e") : index == _hovered
                        ? new Color("171f33") : new Color("101625"),
                    CornerRadiusTopLeft = 8, CornerRadiusTopRight = 8,
                    CornerRadiusBottomLeft = 8, CornerRadiusBottomRight = 8
                }, new Rect2(0, index * RowHeight + 3, Size.X, RowHeight - 6));
        }
        foreach (var edge in _layout.Edges)
        {
            var from = Point(edge.FromRow, edge.FromLane);
            var to = Point(edge.ToRow, edge.ToLane);
            var midpoint = (from.Y + to.Y) / 2;
            var points = Enumerable.Range(0, 25).Select(step =>
                from.BezierInterpolate(new Vector2(from.X, midpoint), new Vector2(to.X, midpoint), to, step / 24f)).ToArray();
            DrawPolyline(points, LaneColor(edge.FromLane).Darkened(0.15f), 3, true);
        }
        for (var index = 0; index < _layout.Rows.Count; index++)
        {
            var row = _layout.Rows[index];
            var point = Point(index, row.Lane);
            var color = row.Commit.IsCurrentBranchHead ? new Color("ffc959") : LaneColor(row.Lane);
            if (row.Commit.IsCurrentBranchHead) DrawCircle(point, 12, new Color(color, 0.18f));
            DrawCircle(point, 8, new Color("0c1220"));
            DrawArc(point, 7, 0, Mathf.Tau, 32, color, 2.5f, true);
            DrawCircle(point, 3, new Color("111827"));
            var y = index * RowHeight;
            DrawString(font, new Vector2(TextX, y + 26), row.Commit.Subject, HorizontalAlignment.Left,
                Size.X - TextX - 12, 18, new Color("e7edf7"));
            DrawString(font, new Vector2(TextX, y + 52), row.Commit.ShortId, HorizontalAlignment.Left,
                90, 15, new Color("9eacc3"));
            var refs = row.Commit.IsCurrentBranchHead ? "HEAD · " : "";
            refs += string.Join(" · ", row.Commit.Branches);
            if (refs.Length > 0)
            {
                var width = Math.Max(0, Math.Min(font.GetStringSize(refs, fontSize: 14).X + 18, Size.X - TextX - 106));
                if (width > 18)
                {
                    DrawStyleBox(new StyleBoxFlat
                    {
                        BgColor = new Color(color, 0.12f),
                        CornerRadiusTopLeft = 5, CornerRadiusTopRight = 5,
                        CornerRadiusBottomLeft = 5, CornerRadiusBottomRight = 5
                    }, new Rect2(TextX + 94, y + 35, width, 24));
                    DrawString(font, new Vector2(TextX + 103, y + 52), refs,
                        HorizontalAlignment.Left, width - 18, 14, color);
                }
            }
            else
                DrawString(font, new Vector2(TextX + 94, y + 52), row.Commit.Author,
                    HorizontalAlignment.Left, Size.X - TextX - 106, 14, new Color("7d8da8"));
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
