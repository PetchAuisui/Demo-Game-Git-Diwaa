using GitDiwaa.Core;

namespace GitDiwaa.RealGit;

public sealed class RealGitGameSessionFactory : IGitGameSessionFactory
{
    private readonly GitWorkspaceManager _workspaceManager;
    private readonly GitProcessRunner _processRunner = new();
    private readonly string _playerName;

    /// <param name="workspaceRoot">โฟลเดอร์เก็บ attempt ทั้งหมด</param>
    /// <param name="playerName">ชื่อผู้เล่น ใช้เป็นเจ้าของ (host) ของ repo บน GitHub จำลอง</param>
    public RealGitGameSessionFactory(string workspaceRoot, string playerName = RemoteSeed.DefaultOwner)
    {
        ValidateName(playerName, nameof(playerName));
        _workspaceManager = new(workspaceRoot);
        _playerName = playerName;
    }

    /// <summary>สร้าง session ที่มี GitHub จำลองเป็น repo ว่างของผู้เล่น</summary>
    public Task<IGitGameSession> CreateAsync(
        string missionId,
        string attemptId,
        CancellationToken cancellationToken = default) =>
        CreateAsync(missionId, attemptId, RemoteSeed.Empty(_playerName), cancellationToken);

    /// <summary>สร้าง session ที่ GitHub จำลองเริ่มต้นตาม <paramref name="seed"/> (เช่น มีประวัติอยู่แล้ว)</summary>
    public async Task<IGitGameSession> CreateAsync(
        string missionId,
        string attemptId,
        RemoteSeed seed,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(seed);
        ValidateName(seed.Owner, nameof(seed.Owner));
        ValidateName(seed.Name, nameof(seed.Name));

        var sandbox = _workspaceManager.CreateAttempt(missionId, attemptId);
        var remote = await _workspaceManager.CreateBareRemoteAsync(
            sandbox,
            _processRunner,
            "origin",
            seed.CloneUrl,
            cancellationToken);
        await RemoteSeeder.SeedAsync(sandbox, remote, _processRunner, seed, cancellationToken);
        return new RealGitGameSession(sandbox, remote, _processRunner, seed);
    }

    private static void ValidateName(string value, string parameterName)
    {
        if (string.IsNullOrWhiteSpace(value) ||
            value.Any(character => !(char.IsAsciiLetterOrDigit(character) || character is '-' or '_')))
            throw new ArgumentException("Use only ASCII letters, numbers, '-' and '_'.", parameterName);
    }
}
