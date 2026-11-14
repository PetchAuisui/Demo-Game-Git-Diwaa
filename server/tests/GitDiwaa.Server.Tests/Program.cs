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
        await AccountServiceTests.RunAsync(runner);
        await AccountApiTests.RunAsync(runner);
        await DisplayNameTests.RunAsync(runner);
        await ConsentTests.RunAsync(runner);
        await RegisterCheckTests.RunAsync(runner);
        await MyEmailTests.RunAsync(runner);
        await PasswordAndQuotaTests.RunAsync(runner);
        await LoginLockoutAndRefreshGraceTests.RunAsync(runner);

        return runner.Complete();
    }
}