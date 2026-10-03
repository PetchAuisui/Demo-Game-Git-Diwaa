using Godot;
using GitDiwaa.Godot.ViewModels;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// Reusable OOP Files Component for Godot.
/// Uses the authentic ItemList presentation matching Checkpoint-01.
/// </summary>
public partial class FilesPanel : PanelContainer
{
    [Signal]
    public delegate void FileSelectedEventHandler(string filePath);

    [Signal]
    public delegate void CreateFileRequestedEventHandler(string filePath, string content);

    [Export]
    public string PanelTitle { get; set; } = "FILES — พื้นที่ทำงาน";

    [Export]
    public string EmptyMessage { get; set; } = "ยังไม่มีไฟล์";

    private Label _titleLabel = null!;
    private ItemList _filesList = null!;

    private readonly List<string> _filePaths = new();

    public override void _Ready()
    {
        BindNodes();
        _titleLabel.Text = PanelTitle;
        _filesList.ItemSelected += OnItemSelected;
        UpdateEmptyState();
    }

    private void BindNodes()
    {
        _titleLabel = GetNode<Label>("%TitleLabel");
        _filesList = GetNode<ItemList>("%FilesList");
    }

    public void SetFiles(IEnumerable<FileDisplayItem> files)
    {
        _filePaths.Clear();
        _filesList.Clear();

        var list = files.ToList();
        if (list.Count == 0)
        {
            UpdateEmptyState();
            return;
        }

        foreach (var file in list)
        {
            _filePaths.Add(file.Path);
            var itemText = $"{file.StatusBadge}  {file.Path}";
            var idx = _filesList.AddItem(itemText);
            _filesList.SetItemCustomFgColor(idx, file.StatusColor);
        }
    }

    public void SetFiles(IEnumerable<string> fileNames)
    {
        _filePaths.Clear();
        _filesList.Clear();

        var list = fileNames.ToList();
        if (list.Count == 0)
        {
            UpdateEmptyState();
            return;
        }

        foreach (var file in list)
        {
            _filePaths.Add(file);
            _filesList.AddItem(file);
        }
    }

    private void UpdateEmptyState()
    {
        _filesList.Clear();
        _filesList.AddItem(EmptyMessage);
    }

    private void OnItemSelected(long index)
    {
        if (index >= 0 && index < _filePaths.Count)
        {
            EmitSignal(SignalName.FileSelected, _filePaths[(int)index]);
        }
    }
}
