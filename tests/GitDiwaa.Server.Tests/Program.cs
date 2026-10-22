namespace GitDiwaa.Server.Tests;

internal static class Program
{
    private static async Task<int> Main()
    {
        var runner = new TestRunner();

        await HealthTests.RunAsync(runner);
        PasswordHasherTests.Run(runner);
        SessionTokenTests.Run(runner);
        await RepositoryTests.RunAsync(runner);

        return runner.Complete();
    }
}