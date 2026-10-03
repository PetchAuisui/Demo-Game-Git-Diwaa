using Godot;
using GitDiwaa.Godot.ViewModels;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// Reusable OOP Files Component for Godot.
/// Uses the authentic ItemList presentation matching Checkpoint-01 with Add, Edit, Delete file actions.
/// </summary>
public partial class FilesPanel : PanelContainer
{
    [Signal]
    public delegate void FileSelectedEventHandler(string filePath);

    [Signal]
    public delegate void CreateFileRequestedEventHandler(string filePath, string content);

    [Signal]
    public delegate void EditFileRequestedEventHandler(string filePath, string content);

    [Signal]
    public delegate void DeleteFileRequestedEventHandler(string filePath);

    [Signal]
    public delegate void RequestFileContentForEditEventHandler(string filePath);

    [Export]
    public string PanelTitle { get; set; } = "FILES — พื้นที่ทำงาน";

    [Export]
    public string EmptyMessage { get; set; } = "ยังไม่มีไฟล์";

    private Label _titleLabel = null!;
    private ItemList _filesList = null!;
    private Button _addButton = null!;
    private Button _editButton = null!;
    private Button _deleteButton = null!;

    private ConfirmationDialog _createFileDialog = null!;
    private LineEdit _createNameInput = null!;
    private TextEdit _createContentInput = null!;

    private ConfirmationDialog _editFileDialog = null!;
    private Label _editFileLabel = null!;
    private TextEdit _editContentInput = null!;

    private ConfirmationDialog _deleteConfirmDialog = null!;

    private readonly List<string> _filePaths = new();
    private string? _selectedFilePath;
    private string? _editingFilePath;

    public override void _Ready()
    {
        BindNodes();
        _titleLabel.Text = PanelTitle;

        _filesList.ItemSelected += OnItemSelected;
        _filesList.ItemActivated += OnItemActivated;

        _addButton.Pressed += OnAddButtonPressed;
        _editButton.Pressed += OnEditButtonPressed;
        _deleteButton.Pressed += OnDeleteButtonPressed;

        _createFileDialog.Confirmed += OnCreateFileDialogConfirmed;
        _createFileDialog.AboutToPopup += () => _createNameInput.CallDeferred(Control.MethodName.GrabFocus);

        _editFileDialog.Confirmed += OnEditFileDialogConfirmed;
        _editFileDialog.AboutToPopup += () => _editContentInput.CallDeferred(Control.MethodName.GrabFocus);

        _deleteConfirmDialog.Confirmed += OnDeleteConfirmDialogConfirmed;

        UpdateEmptyState();
    }

    private void BindNodes()
    {
        _titleLabel = GetNode<Label>("%TitleLabel");
        _filesList = GetNode<ItemList>("%FilesList");
        _addButton = GetNode<Button>("%AddButton");
        _editButton = GetNode<Button>("%EditButton");
        _deleteButton = GetNode<Button>("%DeleteButton");

        _createFileDialog = GetNode<ConfirmationDialog>("%CreateFileDialog");
        _createNameInput = GetNode<LineEdit>("%CreateNameInput");
        _createContentInput = GetNode<TextEdit>("%CreateContentInput");

        _editFileDialog = GetNode<ConfirmationDialog>("%EditFileDialog");
        _editFileLabel = GetNode<Label>("%EditFileLabel");
        _editContentInput = GetNode<TextEdit>("%EditContentInput");

        _deleteConfirmDialog = GetNode<ConfirmationDialog>("%DeleteConfirmDialog");
    }

    public void SetFiles(IEnumerable<FileDisplayItem> files)
    {
        _filePaths.Clear();
        _filesList.Clear();
        _selectedFilePath = null;
        UpdateActionButtons();

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
        _selectedFilePath = null;
        UpdateActionButtons();

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
        _selectedFilePath = null;
        UpdateActionButtons();
    }

    private void UpdateActionButtons()
    {
        var hasSelection = !string.IsNullOrEmpty(_selectedFilePath);
        _editButton.Disabled = !hasSelection;
        _deleteButton.Disabled = !hasSelection;
    }

    private void OnItemSelected(long index)
    {
        if (index >= 0 && index < _filePaths.Count)
        {
            _selectedFilePath = _filePaths[(int)index];
            UpdateActionButtons();
            EmitSignal(SignalName.FileSelected, _selectedFilePath);
        }
        else
        {
            _selectedFilePath = null;
            UpdateActionButtons();
        }
    }

    private void OnItemActivated(long index)
    {
        OnItemSelected(index);
        OnEditButtonPressed();
    }

    private void OnAddButtonPressed()
    {
        _createNameInput.Clear();
        _createContentInput.Clear();
        _createFileDialog.PopupCentered();
    }

    private void OnCreateFileDialogConfirmed()
    {
        var fileName = _createNameInput.Text.Trim();
        if (string.IsNullOrEmpty(fileName)) return;

        var content = _createContentInput.Text;
        EmitSignal(SignalName.CreateFileRequested, fileName, content);
    }

    private void OnEditButtonPressed()
    {
        if (string.IsNullOrEmpty(_selectedFilePath)) return;
        EmitSignal(SignalName.RequestFileContentForEdit, _selectedFilePath);
    }

    public void ShowEditDialog(string filePath, string content)
    {
        _editingFilePath = filePath;
        _editFileLabel.Text = $"แก้ไขไฟล์: {filePath}";
        _editContentInput.Text = content;
        _editFileDialog.PopupCentered();
    }

    private void OnEditFileDialogConfirmed()
    {
        if (string.IsNullOrEmpty(_editingFilePath)) return;
        var content = _editContentInput.Text;
        EmitSignal(SignalName.EditFileRequested, _editingFilePath, content);
    }

    private void OnDeleteButtonPressed()
    {
        if (string.IsNullOrEmpty(_selectedFilePath)) return;
        _deleteConfirmDialog.DialogText = $"คุณต้องการลบไฟล์ '{_selectedFilePath}' หรือไม่?";
        _deleteConfirmDialog.PopupCentered();
    }

    private void OnDeleteConfirmDialogConfirmed()
    {
        if (string.IsNullOrEmpty(_selectedFilePath)) return;
        EmitSignal(SignalName.DeleteFileRequested, _selectedFilePath);
    }
}
