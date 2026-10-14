namespace GitDiwaa.RealGit;

/// <summary>remote ทั้งหมดของ session (repo จาก seed ถ้ามี กับ repo ที่ผู้เล่นสร้างเพิ่ม) ใช้ร่วมกันระหว่าง policy, session และบัญชี</summary>
internal sealed class RemoteRegistry
{
    private readonly List<LocalRemote> _remotes = [];

    public RemoteRegistry(LocalRemote? primary = null)
    {
        if (primary is not null) _remotes.Add(primary);
    }

    public IReadOnlyList<LocalRemote> Remotes => _remotes;

    public void Add(LocalRemote remote) => _remotes.Add(remote);
}
