using GitDiwaa.Core;
using GitDiwaa.Godot.Common;
using Godot;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// ฟอร์มสร้าง repository ใหม่ (ว่าง) เหมือนหน้า New repository ของ GitHub (Scenes/NewRepoPage.tscn)
/// โครงฟอร์มอยู่ใน scene โค้ดนี้ผูกปุ่ม สร้าง repo และแสดงข้อผิดพลาด
/// </summary>
public partial class NewRepoPage : PanelContainer
{
    private Label _error = null!;
    private LineEdit _name = null!;

    public override void _Ready()
    {
        _error = GetNode<Label>("%Error");
        _name = GetNode<LineEdit>("%NameEdit");

        foreach (var label in new[] { "%Title", "%NameLabel", "%OwnerLabel", "%DescriptionLabel" })
            GetNode<Label>(label).AddThemeFontOverride("font", GitHubTheme.BoldFont);
        GetNode<Button>("%CreateButton").Icon = GitHubIcons.Get(GhIcon.Repo, Colors.White, GitHubTheme.S(16));
    }

    /// <param name="create">สร้าง repo จากชื่อและคำอธิบาย (โยนข้อผิดพลาดได้ จะแสดงใต้ช่องกรอก)</param>
    /// <param name="cancel">กดยกเลิก</param>
    public void Setup(string owner, Func<string, string, Task> create, Action cancel)
    {
        GetNode<Label>("%OwnerLabel").Text = owner;
        var description = GetNode<LineEdit>("%DescriptionEdit");

        var busy = false;
        async void Create()
        {
            if (busy) return; // กดซ้ำ (Enter แล้วคลิก) ระหว่างรอ ไม่ให้สร้างสองรอบ
            busy = true;
            _error.Visible = false;
            try
            {
                await create(_name.Text, description.Text);
            }
            catch (Exception ex)
            {
                // ข้อผิดพลาดอื่น (เช่นสร้างโฟลเดอร์ไม่ได้) ต้องไม่หลุดออกจาก async void จนเกมค้าง
                // กดสร้างซ้ำเร็วๆ: ครั้งแรกสำเร็จแล้วหน้าถูกสร้างใหม่ ฟอร์มเดิมถูกลบไปแล้ว
                if (!IsInstanceValid(this) || IsQueuedForDeletion()) return;
                _error.Text = ex.Message;
                _error.Visible = true;
            }
            finally
            {
                busy = false;
            }
        }

        _name.TextSubmitted += _ => Create();
        GetNode<Button>("%CreateButton").Pressed += Create;
        GetNode<Button>("%CancelButton").Pressed += cancel;
        Callable.From(() => { if (IsInstanceValid(_name)) _name.GrabFocus(); }).CallDeferred();
    }
}
