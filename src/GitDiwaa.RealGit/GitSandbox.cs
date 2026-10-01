namespace GitDiwaa.RealGit;

internal sealed record GitSandbox(
    string MissionId,
    string AttemptId,
    string AttemptRoot,
    string PlayerRepositoryPath,
    string RemotesRoot,
    string GitConfigPath,
    string HooksPath);

internal sealed record LocalRemote(string Name, string AliasUrl, string BareRepositoryPath);

