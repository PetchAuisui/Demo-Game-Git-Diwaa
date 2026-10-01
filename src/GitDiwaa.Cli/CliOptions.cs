namespace GitDiwaa.Cli;

internal sealed record CliOptions(
    string WorkspaceRoot,
    string MissionId,
    string AttemptId,
    string? Command,
    bool PrintSnapshot,
    bool ShowHelp)
{
    public const string HelpText = """
Git-Diwaa Real Git Lab

Usage:
  dotnet run --project src/GitDiwaa.Cli -- [options]

Options:
  --workspace <path>  Root for isolated game repositories
  --mission <id>      Mission identifier (default: terminal-lab)
  --attempt <id>      Attempt identifier (default: timestamp)
  --command <text>    Run one Git command and exit
  --snapshot          Print repository state after --command
  --help              Show this help

Interactive commands:
  Any allowed git command, for example: git init
  write <path> <text> | cat <path> | delete <path> | files
  snapshot | graph | where | remote-url | help | clear | exit
""";

    public static CliOptions Parse(IReadOnlyList<string> arguments)
    {
        var workspaceRoot = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "GitDiwaa",
            "workspaces");
        var missionId = "terminal-lab";
        var attemptId = $"attempt-{DateTimeOffset.Now:yyyyMMdd-HHmmss-fff}";
        string? command = null;
        var printSnapshot = false;
        var showHelp = false;

        for (var index = 0; index < arguments.Count; index++)
        {
            switch (arguments[index])
            {
                case "--workspace":
                    workspaceRoot = Path.GetFullPath(ReadValue(arguments, ref index));
                    break;
                case "--mission":
                    missionId = ReadValue(arguments, ref index);
                    break;
                case "--attempt":
                    attemptId = ReadValue(arguments, ref index);
                    break;
                case "--command":
                    command = ReadValue(arguments, ref index);
                    break;
                case "--snapshot":
                    printSnapshot = true;
                    break;
                case "--help" or "-h":
                    showHelp = true;
                    break;
                default:
                    throw new ArgumentException($"Unknown option '{arguments[index]}'.");
            }
        }

        if (printSnapshot && command is null)
            throw new ArgumentException("--snapshot requires --command.");

        return new(workspaceRoot, missionId, attemptId, command, printSnapshot, showHelp);
    }

    private static string ReadValue(IReadOnlyList<string> arguments, ref int index)
    {
        if (++index >= arguments.Count || string.IsNullOrWhiteSpace(arguments[index]))
            throw new ArgumentException($"Option '{arguments[index - 1]}' requires a value.");
        return arguments[index];
    }
}

