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
            if (index == _selected || index == _hovered)
                DrawStyleBox(new StyleBoxFlat
                {
                    BgColor = index == _selected ? new Color("26344e") : new Color("171f33"),
                    CornerRadiusTopLeft = 8, CornerRadiusTopRight = 8,
                    CornerRadiusBottomLeft = 8, CornerRadiusBottomRight = 8
                }, new Rect2(0, index * RowHeight + 2, Size.X, RowHeight - 4));
        }
        foreach (var edge in _layout.Edges)
        {
            var from = Point(edge.FromRow, edge.FromLane);
            var to = Point(edge.ToRow, edge.ToLane);
            var bendY = to.Y - RowHeight / 2;
            DrawPolyline(new[] { from, new Vector2(from.X, bendY), new Vector2(to.X, to.Y - 12), to },
                LaneColor(edge.FromLane).Darkened(0.25f), 2.5f, true);
        }
        for (var index = 0; index < _layout.Rows.Count; index++)
        {
            var row = _layout.Rows[index];
            var point = Point(index, row.Lane);
            var color = row.Commit.IsCurrentBranchHead ? new Color("ffc959") : LaneColor(row.Lane);
            if (row.Commit.IsCurrentBranchHead) DrawCircle(point, 12, new Color(color, 0.18f));
            DrawCircle(point, 7, color);
            DrawCircle(point, 3, new Color("111827"));
            var y = index * RowHeight;
            DrawString(font, new Vector2(TextX, y + 26), row.Commit.Subject, HorizontalAlignment.Left,
                Size.X - TextX - 12, 18, new Color("e7edf7"));
            var refs = row.Commit.IsCurrentBranchHead ? "HEAD · " : "";
            refs += string.Join(" · ", row.Commit.Branches);
            var metadata = row.Commit.ShortId + (refs.Length > 0 ? "   " + refs : "   " + row.Commit.Author);
            DrawString(font, new Vector2(TextX, y + 50), metadata, HorizontalAlignment.Left,
                Size.X - TextX - 12, 14, refs.Length > 0 ? color : new Color("94a3bb"));
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
