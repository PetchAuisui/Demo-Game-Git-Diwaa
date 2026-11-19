namespace GitDiwaa.Tests;

/// <summary>Minimal dependency-free test runner (the repo has no NuGet sources configured).</summary>
public static class TestRunner
{
    private static readonly List<(string Name, Func<Task> Body)> Tests = [];

    public static void Test(string name, Func<Task> body) => Tests.Add((name, body));
    public static void Test(string name, Action body) => Tests.Add((name, () => { body(); return Task.CompletedTask; }));

    public static async Task<int> RunAllAsync(string? filter)
    {
        var failed = 0;
        var run = 0;
        foreach (var (name, body) in Tests)
        {
            if (filter is not null && !name.Contains(filter, StringComparison.OrdinalIgnoreCase)) continue;
            run++;
            try
            {
                await body();
                Console.WriteLine($"  \u001b[32m✔\u001b[0m {name}");
            }
            catch (Exception ex)
            {
                failed++;
                Console.WriteLine($"  \u001b[31m✘ {name}\u001b[0m\n      {ex.Message.Replace("\n", "\n      ")}");
            }
        }
        Console.WriteLine(failed == 0 ? $"\nAll {run} tests passed." : $"\n{failed}/{run} tests FAILED.");
        return failed == 0 ? 0 : 1;
    }
}

public static class Assert
{
    public static void True(bool condition, string message)
    {
        if (!condition) throw new Exception(message);
    }

    public static void Equal<T>(T expected, T actual, string? context = null)
    {
        if (!EqualityComparer<T>.Default.Equals(expected, actual))
            throw new Exception($"{context}: expected <{expected}> but was <{actual}>");
    }
}
