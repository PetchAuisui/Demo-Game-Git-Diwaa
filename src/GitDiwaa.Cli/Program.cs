using System.Text;
using GitDiwaa.Cli;
using GitDiwaa.RealGit;

Console.OutputEncoding = Encoding.UTF8;

try
{
    var options = CliOptions.Parse(args);
    if (options.ShowHelp)
    {
        Console.WriteLine(CliOptions.HelpText);
        return 0;
    }

    var factory = new RealGitGameSessionFactory(options.WorkspaceRoot);
    await using var session = await factory.CreateAsync(options.MissionId, options.AttemptId);
    var app = new TerminalApp(new SystemTerminal(), session);
    return options.Command is null
        ? await app.RunInteractiveAsync()
        : await app.RunCommandAsync(options.Command, options.PrintSnapshot);
}
catch (ArgumentException exception)
{
    Console.Error.WriteLine($"Invalid option: {exception.Message}");
    Console.Error.WriteLine("Run with --help for usage.");
    return 2;
}
catch (Exception exception) when (exception is IOException or InvalidOperationException)
{
    Console.Error.WriteLine($"Git-Diwaa could not start: {exception.Message}");
    return 1;
}

