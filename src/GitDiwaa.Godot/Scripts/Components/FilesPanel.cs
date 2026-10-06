using Godot;
using GitDiwaa.Godot.ViewModels;

namespace GitDiwaa.Godot.Components;

/// <summary>
/// Workspace navigator and embedded text editor. This component owns presentation state only;
/// repository and filesystem mutations are delegated through signals to the root orchestrator.
/// </summary>
public partial class FilesPanel : PanelContainer
{
	[Signal] public delegate void OpenFileRequestedEventHandler(string filePath);
	[Signal] public delegate void SaveFileRequestedEventHandler(string filePath, string content);
	[Signal] public delegate void CreateFileRequestedEventHandler(string filePath, string content);
	[Signal] public delegate void CreateFolderRequestedEventHandler(string folderPath);
	[Signal] public delegate void RenameEntryRequestedEventHandler(string sourcePath, string destinationPath);
	[Signal] public delegate void DeleteEntryRequestedEventHandler(string entryPath, bool isDirectory);

	[Export] public string PanelTitle { get; set; } = "FILES — พื้นที่ทำงาน";
	[Export] public string EmptyMessage { get; set; } = "ยังไม่มีไฟล์ — เริ่มสร้างด้านบน";

	private Label _titleLabel = null!;
	private Label _feedbackLabel = null!;
	private Control _workspaceActions = null!;
	private Control _entryActions = null!;
	private Control _navigatorSurface = null!;
	private Control _editorSurface = null!;
	private ItemList _filesList = null!;
	private Button _newFileButton = null!;
	private Button _newFolderButton = null!;
	private Button _openButton = null!;
	private Button _renameButton = null!;
	private Button _deleteButton = null!;
	private Label _editorPathLabel = null!;
	private Label _dirtyLabel = null!;
	private CodeEdit _editor = null!;
	private Control _editorLayout = null!;
	private Button _saveButton = null!;
	private Button _closeEditorButton = null!;
	private ConfirmationDialog _createFileDialog = null!;
	private LineEdit _createFileNameInput = null!;
	private ConfirmationDialog _createFolderDialog = null!;
	private LineEdit _createFolderNameInput = null!;
	private ConfirmationDialog _renameDialog = null!;
	private LineEdit _renameInput = null!;
	private ConfirmationDialog _deleteConfirmDialog = null!;
	private ConfirmationDialog _discardChangesDialog = null!;

	private readonly List<WorkspaceEntryDisplayItem> _entries = new();
	private string? _selectedPath;
	private bool _selectedIsDirectory;
	private string? _openFilePath;
	private string _savedContent = string.Empty;
	private string? _pendingOpenPath;
	private bool _pendingClose;
	private bool _suppressTextChanged;

	private Texture2D _fileIcon = null!;
	private Texture2D _folderIcon = null!;

	public bool HasUnsavedChanges => _openFilePath != null && _editor.Text != _savedContent;

	public override void _Ready()
	{
		_fileIcon = GD.Load<Texture2D>("res://assets/icons/file.svg");
		_folderIcon = GD.Load<Texture2D>("res://assets/icons/folder.svg");

		BindNodes();
		_createFileDialog.GetOkButton().ThemeTypeVariation = "CreateAction";
		_createFileDialog.GetOkButton().CustomMinimumSize = new Vector2(172, 46);
		_createFileDialog.GetCancelButton().CustomMinimumSize = new Vector2(112, 46);
		_createFileDialog.RegisterTextEnter(_createFileNameInput);
		_createFileNameInput.TextChanged += text =>
			_createFileDialog.GetOkButton().Disabled = string.IsNullOrWhiteSpace(text);

		_createFolderDialog.GetOkButton().ThemeTypeVariation = "CreateAction";
		_createFolderDialog.GetOkButton().CustomMinimumSize = new Vector2(172, 46);
		_createFolderDialog.GetCancelButton().CustomMinimumSize = new Vector2(112, 46);
		_createFolderDialog.RegisterTextEnter(_createFolderNameInput);
		_createFolderNameInput.TextChanged += text =>
			_createFolderDialog.GetOkButton().Disabled = string.IsNullOrWhiteSpace(text);

		_titleLabel.Text = PanelTitle;

		_filesList.ItemSelected += OnItemSelected;
		_filesList.ItemActivated += OnItemActivated;
		_newFileButton.Pressed += () => ShowCreateDialog(_createFileDialog, _createFileNameInput);
		_newFolderButton.Pressed += () => ShowCreateDialog(_createFolderDialog, _createFolderNameInput);
		_openButton.Pressed += () =>
		{
			if (_selectedPath != null && !_selectedIsDirectory) RequestOpenFile(_selectedPath);
		};
		_renameButton.Pressed += OnRenameButtonPressed;
		_deleteButton.Pressed += OnDeleteButtonPressed;
		_saveButton.Pressed += RequestSave;
		_closeEditorButton.Pressed += RequestCloseEditor;
		_editor.TextChanged += UpdateDirtyState;

		_createFileDialog.Confirmed += OnCreateFileConfirmed;
		_createFolderDialog.Confirmed += OnCreateFolderConfirmed;
		_renameDialog.Confirmed += OnRenameConfirmed;
		_deleteConfirmDialog.Confirmed += OnDeleteConfirmed;
		_discardChangesDialog.Confirmed += OnDiscardChangesConfirmed;

		ShowEmptyEditor();
		UpdateActionButtons();
		SetEntries(Array.Empty<WorkspaceEntryDisplayItem>());
	}

	private void BindNodes()
	{
		_titleLabel = GetNode<Label>("%TitleLabel");
		_feedbackLabel = GetNode<Label>("%FeedbackLabel");
		_workspaceActions = GetNode<Control>("%WorkspaceActions");
		_entryActions = GetNode<Control>("%EntryActions");
		_navigatorSurface = GetNode<Control>("%NavigatorSurface");
		_editorSurface = GetNode<Control>("%EditorSurface");
		_filesList = GetNode<ItemList>("%FilesList");
		_newFileButton = GetNode<Button>("%NewFileButton");
		_newFolderButton = GetNode<Button>("%NewFolderButton");
		_openButton = GetNode<Button>("%OpenButton");
		_renameButton = GetNode<Button>("%RenameButton");
		_deleteButton = GetNode<Button>("%DeleteButton");
		_editorPathLabel = GetNode<Label>("%EditorPathLabel");
		_dirtyLabel = GetNode<Label>("%DirtyLabel");
		_editor = GetNode<CodeEdit>("%Editor");
		_editorLayout = GetNode<Control>("%EditorLayout");
		_saveButton = GetNode<Button>("%SaveButton");
		_closeEditorButton = GetNode<Button>("%CloseEditorButton");
		_createFileDialog = GetNode<ConfirmationDialog>("%CreateFileDialog");
		_createFileNameInput = GetNode<LineEdit>("%CreateFileNameInput");
		_createFolderDialog = GetNode<ConfirmationDialog>("%CreateFolderDialog");
		_createFolderNameInput = GetNode<LineEdit>("%CreateFolderNameInput");
		_renameDialog = GetNode<ConfirmationDialog>("%RenameDialog");
		_renameInput = GetNode<LineEdit>("%RenameInput");
		_deleteConfirmDialog = GetNode<ConfirmationDialog>("%DeleteConfirmDialog");
		_discardChangesDialog = GetNode<ConfirmationDialog>("%DiscardChangesDialog");
	}

	public void SetEntries(IEnumerable<WorkspaceEntryDisplayItem> entries)
	{
		_allEntries.Clear();
		_allEntries.AddRange(SortAsTree(entries));
		RenderEntries();
	}

	private void RenderEntries()
	{
		var previousSelection = _selectedPath;
		_entries.Clear();
		_entries.AddRange(_allEntries.Where(entry => !IsHiddenByCollapsedAncestor(entry.Path)));
		_filesList.Clear();

		if (_entries.Count == 0)
		{
			_filesList.AddItem(EmptyMessage);
			_filesList.SetItemDisabled(0, true);
			_selectedPath = null;
			_selectedIsDirectory = false;
			UpdateActionButtons();
			return;
		}

		for (var index = 0; index < _entries.Count; index++)
		{
			var entry = _entries[index];
			var depth = entry.Path.Count(character => character == '/');
			var status = string.IsNullOrEmpty(entry.StatusBadge) ? string.Empty : $" {entry.StatusBadge}";
			var icon = GetTreeIcon(entry.IsDirectory, depth, entry.IsDirectory && !_collapsed.Contains(entry.Path));
			_filesList.AddItem($"{entry.Name}{status}", icon);
			_filesList.SetItemTooltip(index, entry.Path);
			if (entry.StatusColor.HasValue)
			{
				_filesList.SetItemCustomFgColor(index, entry.StatusColor.Value);
			}

			if (entry.Path == previousSelection)
				_filesList.Select(index);
		}

		if (previousSelection != null && _entries.All(entry => entry.Path != previousSelection))
		{
			_selectedPath = null;
			_selectedIsDirectory = false;
		}
		UpdateActionButtons();
	}

	private const int IndentPixels = 22;
	private const int ChevronSlotPixels = 22;
	private readonly List<WorkspaceEntryDisplayItem> _allEntries = new();
	private readonly HashSet<string> _collapsed = new(StringComparer.Ordinal);
	private readonly Dictionary<(bool, int, bool), Texture2D> _treeIcons = new();

	private bool IsHiddenByCollapsedAncestor(string path)
	{
		var slash = path.LastIndexOf('/');
		while (slash > 0)
		{
			if (_collapsed.Contains(path[..slash])) return true;
			slash = path.LastIndexOf('/', slash - 1);
		}
		return false;
	}

	/// <summary>
	/// ItemList always draws the icon at the far left, so each row's icon texture is composed as
	/// [indent][chevron slot][icon]: folders get a chevron, files leave the slot blank (VS Code style).
	/// </summary>
	private Texture2D GetTreeIcon(bool isDirectory, int depth, bool expanded)
	{
		var key = (isDirectory, depth, expanded);
		if (_treeIcons.TryGetValue(key, out var cached)) return cached;

		var source = (isDirectory ? _folderIcon : _fileIcon).GetImage();
		if (source.IsCompressed()) source.Decompress();
		source.Convert(Image.Format.Rgba8);

		var left = depth * IndentPixels;
		var gap = 2;
		var width = left + ChevronSlotPixels + gap + source.GetWidth();
		var height = Math.Max(source.GetHeight(), ChevronSlotPixels);
		var image = Image.CreateEmpty(width, height, false, Image.Format.Rgba8);
		if (isDirectory) DrawChevron(image, left, height / 2, expanded);
		image.BlitRect(source, new Rect2I(Vector2I.Zero, source.GetSize()),
			new Vector2I(left + ChevronSlotPixels + gap, (height - source.GetHeight()) / 2));

		var texture = ImageTexture.CreateFromImage(image);
		_treeIcons[key] = texture;
		return texture;
	}

	private static void DrawChevron(Image image, int slotX, int centerY, bool expanded)
	{
		var color = new Color(0.78f, 0.80f, 0.88f);
		var cx = slotX + ChevronSlotPixels / 2;
		for (var i = 0; i < 7; i++)
		{
			for (var thickness = 0; thickness < 2; thickness++)
			{
				if (expanded)
				{
					// "v": arms meet at the bottom.
					image.SetPixel(cx - 6 + i, centerY - 3 + i - thickness + 1, color);
					image.SetPixel(cx + 6 - i, centerY - 3 + i - thickness + 1, color);
				}
				else
				{
					// ">": arms meet at the right.
					image.SetPixel(cx - 3 + i - thickness + 1, centerY - 6 + i, color);
					image.SetPixel(cx - 3 + i - thickness + 1, centerY + 6 - i, color);
				}
			}
		}
	}

	/// <summary>
	/// Orders entries depth-first so every child sits directly under its parent,
	/// with folders listed before files at each level.
	/// </summary>
	private static List<WorkspaceEntryDisplayItem> SortAsTree(IEnumerable<WorkspaceEntryDisplayItem> entries)
	{
		var list = entries.ToList();
		var directories = new HashSet<string>(
			list.Where(entry => entry.IsDirectory).Select(entry => entry.Path), StringComparer.Ordinal);

		(string Name, bool IsDir)[] Key(WorkspaceEntryDisplayItem entry)
		{
			var parts = entry.Path.Split('/');
			var result = new (string, bool)[parts.Length];
			for (var i = 0; i < parts.Length; i++)
			{
				var isLast = i == parts.Length - 1;
				result[i] = (parts[i], !isLast || directories.Contains(entry.Path));
			}
			return result;
		}

		var keyed = list.Select(entry => (Entry: entry, Key: Key(entry))).ToList();
		keyed.Sort((a, b) =>
		{
			var length = Math.Min(a.Key.Length, b.Key.Length);
			for (var i = 0; i < length; i++)
			{
				if (a.Key[i].IsDir != b.Key[i].IsDir) return a.Key[i].IsDir ? -1 : 1;
				var byName = string.Compare(a.Key[i].Name, b.Key[i].Name, StringComparison.OrdinalIgnoreCase);
				if (byName != 0) return byName;
			}
			return a.Key.Length.CompareTo(b.Key.Length);
		});
		return keyed.Select(item => item.Entry).ToList();
	}

	public void ShowFile(string filePath, string content)
	{
		_openFilePath = filePath;
		_savedContent = content;
		_suppressTextChanged = true;
		_editor.Text = content;
		_suppressTextChanged = false;
		_editorPathLabel.Text = filePath;
		_workspaceActions.Visible = false;
		_navigatorSurface.Visible = false;
		_editorSurface.Visible = true;
		_editorLayout.Visible = true;
		UpdateDirtyState();
		_editor.GrabFocus();
	}

	public void MarkSaved(string filePath)
	{
		if (_openFilePath != filePath) return;
		_savedContent = _editor.Text;
		UpdateDirtyState();
	}

	public void NotifyEntryRenamed(string sourcePath, string destinationPath)
	{
		if (_openFilePath == sourcePath || _openFilePath?.StartsWith(sourcePath + "/", StringComparison.Ordinal) == true)
		{
			_openFilePath = destinationPath + _openFilePath[sourcePath.Length..];
			_editorPathLabel.Text = _openFilePath;
		}
		if (_selectedPath == sourcePath || _selectedPath?.StartsWith(sourcePath + "/", StringComparison.Ordinal) == true)
			_selectedPath = destinationPath + _selectedPath[sourcePath.Length..];
	}

	public void NotifyEntryDeleted(string path)
	{
		if (_openFilePath == path || _openFilePath?.StartsWith(path + "/", StringComparison.Ordinal) == true)
			ShowEmptyEditor();
	}

	public void ShowFeedback(string message, bool isError = false)
	{
		_feedbackLabel.Text = message;
		_feedbackLabel.Modulate = isError ? new Color(1.0f, 0.48f, 0.52f) : new Color(0.45f, 0.95f, 0.66f);
		_feedbackLabel.Visible = true;
	}

	public void SetBusy(bool busy)
	{
		_newFileButton.Disabled = busy;
		_newFolderButton.Disabled = busy;
		_openButton.Disabled = busy || _selectedPath == null || _selectedIsDirectory;
		_renameButton.Disabled = busy || _selectedPath == null;
		_deleteButton.Disabled = busy || _selectedPath == null;
		_saveButton.Disabled = busy || !HasUnsavedChanges;
		if (!busy) UpdateActionButtons();
	}

	private void OnItemSelected(long index)
	{
		if (index < 0 || index >= _entries.Count) return;
		var entry = _entries[(int)index];
		_selectedPath = entry.Path;
		_selectedIsDirectory = entry.IsDirectory;
		if (entry.IsDirectory)
		{
			// Click toggles expand/collapse, like a VS Code explorer folder.
			if (!_collapsed.Remove(entry.Path)) _collapsed.Add(entry.Path);
			RenderEntries();
		}
		UpdateActionButtons();
		ShowFeedback(entry.IsDirectory ? $"เลือกโฟลเดอร์ {entry.Path}" : $"เลือกไฟล์ {entry.Path}");
	}

	private void OnItemActivated(long index)
	{
		if (index < 0 || index >= _entries.Count || _entries[(int)index].IsDirectory) return;
		RequestOpenFile(_entries[(int)index].Path);
	}

	private void RequestOpenFile(string filePath)
	{
		if (_openFilePath == filePath) return;
		if (HasUnsavedChanges)
		{
			_pendingOpenPath = filePath;
			_pendingClose = false;
			_discardChangesDialog.DialogText = $"'{_openFilePath}' ยังไม่ได้บันทึก\nต้องการทิ้งการแก้ไขแล้วเปิด '{filePath}' หรือไม่?";
			_discardChangesDialog.PopupCentered();
			return;
		}
		EmitSignal(SignalName.OpenFileRequested, filePath);
	}

	private void RequestSave()
	{
		if (_openFilePath == null || !HasUnsavedChanges) return;
		EmitSignal(SignalName.SaveFileRequested, _openFilePath, _editor.Text);
	}

	private void RequestCloseEditor()
	{
		if (HasUnsavedChanges)
		{
			_pendingClose = true;
			_pendingOpenPath = null;
			_discardChangesDialog.DialogText = $"'{_openFilePath}' ยังไม่ได้บันทึก\nต้องการทิ้งการแก้ไขและปิด editor หรือไม่?";
			_discardChangesDialog.PopupCentered();
			return;
		}
		ShowEmptyEditor();
	}

	private void OnDiscardChangesConfirmed()
	{
		if (_pendingClose)
		{
			ShowEmptyEditor();
		}
		else if (_pendingOpenPath != null)
		{
			var nextPath = _pendingOpenPath;
			_pendingOpenPath = null;
			EmitSignal(SignalName.OpenFileRequested, nextPath);
		}
		_pendingClose = false;
	}

	private void ShowEmptyEditor()
	{
		_openFilePath = null;
		_savedContent = string.Empty;
		_suppressTextChanged = true;
		_editor.Clear();
		_suppressTextChanged = false;
		_workspaceActions.Visible = true;
		_navigatorSurface.Visible = true;
		_editorSurface.Visible = false;
		_editorLayout.Visible = false;
		UpdateDirtyState();
	}

	private void UpdateDirtyState()
	{
		if (_suppressTextChanged) return;
		var dirty = HasUnsavedChanges;
		_dirtyLabel.Visible = dirty;
		_dirtyLabel.Text = dirty ? "● ยังไม่บันทึก" : string.Empty;
		_saveButton.Disabled = !dirty;
		if (_openFilePath != null)
			_editorPathLabel.Text = dirty ? $"{_openFilePath} *" : _openFilePath;
	}

	private void ShowCreateDialog(ConfirmationDialog dialog, LineEdit input)
	{
		input.Clear();
		dialog.GetOkButton().Disabled = true;
		var folder = System.IO.Path.GetDirectoryName(BuildPathInSelectedFolder("dummy"))?.Replace('\\', '/');

		if (dialog == _createFileDialog)
		{
			var location = GetNode<Label>("%CreateFileLocation");
			location.Text = string.IsNullOrEmpty(folder) ? "ตำแหน่ง: พื้นที่ทำงาน /" : $"ตำแหน่ง: /{folder}";
			location.TooltipText = location.Text;
		}
		else if (dialog == _createFolderDialog)
		{
			var location = GetNode<Label>("%CreateFolderLocation");
			location.Text = string.IsNullOrEmpty(folder) ? "ตำแหน่ง: พื้นที่ทำงาน /" : $"ตำแหน่ง: /{folder}";
			location.TooltipText = location.Text;
		}
		dialog.PopupCentered();
		input.CallDeferred(Control.MethodName.GrabFocus);
	}

	private void OnCreateFileConfirmed()
	{
		var name = ValidateSimpleName(_createFileNameInput.Text);
		if (name == null) return;
		EmitSignal(SignalName.CreateFileRequested, BuildPathInSelectedFolder(name), string.Empty);
	}

	private void OnCreateFolderConfirmed()
	{
		var name = ValidateSimpleName(_createFolderNameInput.Text);
		if (name == null) return;
		EmitSignal(SignalName.CreateFolderRequested, BuildPathInSelectedFolder(name));
	}

	private void OnRenameButtonPressed()
	{
		if (_selectedPath == null) return;
		_renameInput.Text = System.IO.Path.GetFileName(_selectedPath);
		_renameDialog.DialogText = $"เปลี่ยนชื่อ '{_selectedPath}'";
		_renameDialog.PopupCentered();
		_renameInput.CallDeferred(Control.MethodName.GrabFocus);
	}

	private void OnRenameConfirmed()
	{
		if (_selectedPath == null) return;
		var name = ValidateSimpleName(_renameInput.Text);
		if (name == null) return;
		var parent = System.IO.Path.GetDirectoryName(_selectedPath)?.Replace('\\', '/');
		var destination = string.IsNullOrEmpty(parent) ? name : $"{parent}/{name}";
		if (destination == _selectedPath)
		{
			ShowFeedback("ชื่อใหม่เหมือนชื่อเดิม", true);
			return;
		}
		EmitSignal(SignalName.RenameEntryRequested, _selectedPath, destination);
	}

	private void OnDeleteButtonPressed()
	{
		if (_selectedPath == null) return;
		var kind = _selectedIsDirectory ? "โฟลเดอร์และไฟล์ทั้งหมดภายใน" : "ไฟล์";
		_deleteConfirmDialog.DialogText = $"ต้องการลบ{kind} '{_selectedPath}' หรือไม่?";
		_deleteConfirmDialog.PopupCentered();
	}

	private void OnDeleteConfirmed()
	{
		if (_selectedPath == null) return;
		EmitSignal(SignalName.DeleteEntryRequested, _selectedPath, _selectedIsDirectory);
	}

	private string BuildPathInSelectedFolder(string name)
	{
		if (_selectedPath == null) return name;
		var folder = _selectedIsDirectory
			? _selectedPath
			: System.IO.Path.GetDirectoryName(_selectedPath)?.Replace('\\', '/');
		return string.IsNullOrEmpty(folder) ? name : $"{folder}/{name}";
	}

	private string? ValidateSimpleName(string value)
	{
		var name = value.Trim();
		if (string.IsNullOrEmpty(name) || name is "." or ".." || name.Contains('/') || name.Contains('\\'))
		{
			ShowFeedback("กรุณาใช้ชื่อเดียวที่ไม่มี / หรือ \\", true);
			return null;
		}
		return name;
	}

	private void UpdateActionButtons()
	{
		var hasSelection = _selectedPath != null;
		_entryActions.Visible = hasSelection && _openFilePath == null;
		_openButton.Disabled = !hasSelection || _selectedIsDirectory;
		_renameButton.Disabled = !hasSelection;
		_deleteButton.Disabled = !hasSelection;
	}
}
