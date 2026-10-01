namespace GitDiwaa.Core;

public sealed record GitCommandResult(
    bool Success,
    int ExitCode,
    string StandardOutput,
    string StandardError,
    string DisplayCommand)
{
    public string Output => string.IsNullOrWhiteSpace(StandardError)
        ? StandardOutput.TrimEnd()
        : string.IsNullOrWhiteSpace(StandardOutput)
            ? StandardError.TrimEnd()
            : $"{StandardOutput.TrimEnd()}\n{StandardError.TrimEnd()}";

    public static GitCommandResult Rejected(string message, string command) =>
        new(false, -1, string.Empty, message, command);
}

