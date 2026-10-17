using GitDiwaa.Core;
using GitDiwaa.Godot.Common;
using Godot;

namespace GitDiwaa.Godot.Components;

public partial class RemoteRepoView
{
    private static readonly PackedScene RepoListPageScene = GD.Load<PackedScene>("res://Scenes/RepoListPage.tscn");

    /// <summary>หน้ารายการ repo ก่อนเข้า repo: โครงอยู่ใน Scenes/RepoListPage.tscn</summary>
    private void BuildRepos(IReadOnlyList<RemoteRepositoryInfo> repos)
    {
        var page = RepoListPageScene.Instantiate<RepoListPage>();
        _content.AddChild(page);
        page.Setup(_account!.Owner, repos, OpenRepo, () => Go(Page.NewRepo));
    }

    private static readonly PackedScene NewRepoPageScene = GD.Load<PackedScene>("res://Scenes/NewRepoPage.tscn");

    /// <summary>ฟอร์มสร้าง repository ใหม่ (ว่าง) เหมือนหน้า New repository ของ GitHub: โครงอยู่ใน Scenes/NewRepoPage.tscn</summary>
    private void BuildNewRepo()
    {
        var account = _account!;
        var page = NewRepoPageScene.Instantiate<NewRepoPage>();
        _content.AddChild(page);
        page.Setup(account.Owner, async (name, description) =>
        {
            var repo = await account.CreateRepositoryAsync(name, description);
            if (!IsAlive) return;
            _status = $"สร้าง repository {repo.Name} แล้ว";
            _statusIsError = false;
            OpenRepo(repo.Name);
        }, () => Go(Page.Repos));
    }
}
