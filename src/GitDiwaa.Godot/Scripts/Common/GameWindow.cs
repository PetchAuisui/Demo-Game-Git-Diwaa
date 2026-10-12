using Godot;

namespace GitDiwaa.Godot.Common;

/// <summary>
/// Shared window controls for scaling and F11 fullscreen toggle.
/// Adapted from Git-Diwaa-Desktop for pixel-perfect 1080p display.
/// </summary>
public partial class GameWindow : Node
{
    public override void _Input(InputEvent inputEvent)
    {
        if (inputEvent is not InputEventKey { Pressed: true, Echo: false, Keycode: Key.F11 })
            return;

        var window = GetWindow();
        if (window.Mode is Window.ModeEnum.Fullscreen or Window.ModeEnum.ExclusiveFullscreen)
        {
            window.Mode = Window.ModeEnum.Windowed;
            var screen = DisplayServer.ScreenGetUsableRect(window.CurrentScreen);
            var width = Math.Min(1920, (int)(screen.Size.X * 0.85));
            var height = Math.Min(1080, (int)(screen.Size.Y * 0.85));
            var scale = Math.Min(width / 1920.0, height / 1080.0);
            window.Size = new Vector2I((int)(1920 * scale), (int)(1080 * scale));
            window.Position = screen.Position + (screen.Size - window.Size) / 2;
        }
        else
        {
            window.Mode = Window.ModeEnum.Fullscreen;
        }

        GetViewport().SetInputAsHandled();
    }
}
