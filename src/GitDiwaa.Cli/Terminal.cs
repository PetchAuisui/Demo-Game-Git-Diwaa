namespace GitDiwaa.Cli;

internal interface ITerminal
{
    string? ReadLine();
    void Write(string text);
    void WriteLine(string text = "");
    void WriteError(string text);
    void Clear();
}

internal sealed class SystemTerminal : ITerminal
{
    public string? ReadLine() => Console.ReadLine();
    public void Write(string text) => Console.Write(text);
    public void WriteLine(string text = "") => Console.WriteLine(text);
    public void WriteError(string text) => Console.Error.WriteLine(text);
    public void Clear() => Console.Clear();
}

