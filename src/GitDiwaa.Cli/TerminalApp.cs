using System.Text.Json;
using System.Text.Json.Serialization;
using GitDiwaa.Core;

namespace GitDiwaa.Cli;

internal sealed class TerminalApp
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = true,
        Converters = { new JsonStringEnumConverter() }
    };

    private readonly ITerminal _terminal;
    private readonly IGitGameSession _session;

    public TerminalApp(ITerminal terminal, IGitGameSession session)
    {
        _terminal = terminal;
        _session = session;
    }

    public async Task<int> RunCommandAsync(string command, bool printSnapshot)
    {
        var result = await _session.ExecuteAsync(command);
        PrintResult(result);
        if (printSnapshot) await PrintSnapshotAsync();
        return result.Success ? 0 : 1;
    }

    public async Task<int> RunInteractiveAsync()
    {
        ShowHeader();
        while (true)
        {
            _terminal.Write("git-diwaa> ");
            var input = _terminal.ReadLine();
            if (input is null || input.Trim().Equals("exit", StringComparison.OrdinalIgnoreCase)) return 0;

            var command = input.Trim();
            if (command.Length == 0) continue;

            try
            {
                if (await RunHostCommandAsync(command)) continue;
                if (command.Equals("git commit", StringComparison.Ordinal))
                {
                    _terminal.Write("Commit message: ");
                    var message = _terminal.ReadLine();
                    if (string.IsNullOrWhiteSpace(message))
                    {
                        _terminal.WriteError("Commit message cannot be empty.");
                        continue;
                    }

                    command = $"git commit -m \"{message.Replace("\"", "\\\"")}\"";
                }

                PrintResult(await _session.ExecuteAsync(command));
            }
            catch (Exception exception) when (exception is ArgumentException or InvalidOperationException or IOException)
            {
                _terminal.WriteError($"Operation failed: {exception.Message}");
            }
        }
    }

    private async Task<bool> RunHostCommandAsync(string command)
    {
        var parts = command.Split(' ', 3, StringSplitOptions.RemoveEmptyEntries);
        switch (parts[0].ToLowerInvariant())
        {
            case "help":
                _terminal.WriteLine(CliOptions.HelpText);
                return true;
            case "clear":
                _terminal.Clear();
                return true;
            case "where":
                _terminal.WriteLine(_session.Info.RepositoryPath);
                return true;
            case "remote-url":
                _terminal.WriteLine(_session.Info.RemoteUrl);
                return true;
            case "files":
                var files = _session.Files.ListFiles();
                _terminal.WriteLine(files.Count == 0 ? "Working tree is empty." : string.Join('\n', files));
                return true;
            case "write":
                if (parts.Length < 3) _terminal.WriteError("Usage: write <path> <text>");
                else
                {
                    await _session.Files.WriteAllTextAsync(parts[1], parts[2]);
                    _terminal.WriteLine($"Wrote '{parts[1]}'.");
                }
                return true;
            case "cat":
                if (parts.Length != 2) _terminal.WriteError("Usage: cat <path>");
                else _terminal.WriteLine(await _session.Files.ReadAllTextAsync(parts[1]) ?? $"File '{parts[1]}' not found.");
                return true;
            case "delete":
                if (parts.Length != 2) _terminal.WriteError("Usage: delete <path>");
                else _terminal.WriteLine(_session.Files.Delete(parts[1]) ? $"Deleted '{parts[1]}'." : $"File '{parts[1]}' not found.");
                return true;
            case "snapshot":
                await PrintSnapshotAsync();
                return true;
            case "graph":
                PrintResult(await _session.ExecuteAsync("git log --graph --all --oneline --decorate"));
                return true;
            default:
                return false;
        }
    }

    private async Task PrintSnapshotAsync()
    {
        var snapshot = await _session.InspectAsync();
        _terminal.WriteLine(JsonSerializer.Serialize(snapshot, JsonOptions));
    }

    private void PrintResult(GitCommandResult result)
    {
        if (!string.IsNullOrWhiteSpace(result.Output))
        {
            if (result.Success) _terminal.WriteLine(result.Output);
            else _terminal.WriteError(result.Output);
            return;
        }

        _terminal.WriteLine(result.Success ? "Command completed." : $"Command failed (exit {result.ExitCode}).");
    }

    private void ShowHeader()
    {
        _terminal.WriteLine("========================================");
        _terminal.WriteLine("       Git-Diwaa — Real Git Lab");
        _terminal.WriteLine("========================================");
        _terminal.WriteLine($"Sandbox: {_session.Info.RepositoryPath}");
        _terminal.WriteLine($"Game remote: {_session.Info.RemoteUrl}");
        _terminal.WriteLine("Commands only affect this isolated game session.");
        _terminal.WriteLine("Type help for available commands or exit to quit.\n");
    }
}
