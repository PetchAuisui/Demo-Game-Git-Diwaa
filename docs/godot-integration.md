# สถาปัตยกรรม Godot C# Sandbox UI

Godot C# Sandbox UI ได้รับการพัฒนาในรูปแบบ Component-based OOP แยกส่วนชัดเจนเพื่อให้แต่ละ Panel นำไปต่อยอดและนำไปใช้ซ้ำได้

## โครงสร้างโมดูล (OOP Architecture)

```text
src/GitDiwaa.Godot/
├── project.godot                     # Godot 4.7 engine configuration
├── GitDiwaa.Godot.csproj            # C# project อ้างอิง Core & RealGit
├── Scenes/
│   ├── SandboxGameView.tscn         # หน้าจอหลัก (Orchestrator Scene)
│   ├── TopBarPanel.tscn             # Header Bar แสดง Level, Branch, Timer, Coins
│   ├── FilesPanel.tscn              # Panel แสดงไฟล์ใน Workspace และสถานะ Git
│   ├── GitGraphPanel.tscn           # Panel แสดง Commit DAG, Branch Badges, ประวัติ
│   └── TerminalPanel.tscn           # Reusable Terminal Window และ Command Prompt
└── Scripts/
    ├── Common/
    │   └── SandboxThemeTokens.cs    # Design Tokens (Colors, StyleBoxes, Fonts)
    ├── ViewModels/
    │   └── SandboxViewModels.cs     # FileDisplayItem, CommitGraphDisplayNode, TerminalLogEntry
    ├── Services/
    │   ├── IGitSandboxService.cs    # Service Contract สำหรับ UI
    │   ├── RealGitSandboxService.cs # Adapter เชื่อมกับ Real Git Engine
    │   └── MockGitSandboxService.cs # Mock Service สำหรับ Preview และ Unit Testing
    ├── Components/
    │   ├── TopBarPanel.cs           # Control component สำหรับ Header
    │   ├── FilesPanel.cs            # Control component สำหรับแสดงและจัดการไฟล์
    │   ├── GitGraphPanel.cs         # Control component สำหรับแสดง Commit Graph
    │   └── TerminalPanel.cs         # Control component สำหรับ Terminal & ประวัติคำสั่ง
    └── SandboxGameView.cs           # Controller / Mediator ประสานงานระหว่าง Panels กับ Service
```

## ความสามารถของแต่ละ Component

1. **TerminalPanel (`TerminalPanel.cs` / `TerminalPanel.tscn`)**:
   - หน้าต่าง Terminal พร้อมปุ่ม dot ตกแต่ง
   - รองรับการกรอกคำสั่ง Git และ Built-in host commands (`help`, `clear`, `write`, `cat`, `delete`)
   - ระบบประวัติคำสั่ง (Command History) เลื่อนดูด้วยลูกศรขึ้น/ลง (Up/Down)
   - ส่ง Signal `CommandSubmitted(string command)`
   - แยกสีแสดงผล: Command Echo (เขียว/ขาว), Standard Output (ขาวเทา), Error (แดง), System Info (ฟ้า/เหลือง)

2. **FilesPanel (`FilesPanel.cs` / `FilesPanel.tscn`)**:
   - แสดงรายการไฟล์ใน Workspace พร้อม Badge แสดงสถานะ Git (`[?]` Untracked, `[M]` Modified, `[A]` Added/Staged, `[D]` Deleted)
   - หน้า Empty State แสดง `"ยังไม่มีไฟล์"`
   - ปุ่มสร้างไฟล์ `+ สร้างไฟล์`
   - ส่ง Signal `FileSelected(string filePath)` และ `CreateFileRequested(string filePath, string content)`

3. **GitGraphPanel (`GitGraphPanel.cs` / `GitGraphPanel.tscn`)**:
   - แสดงประวัติ Commit เป็นกราฟ / ไทม์ไลน์
   - แสดง Commit Node Circle (สีทองเมื่อเป็น HEAD ของ branch ปัจจุบัน, สีฟ้าสำหรับ commit ทั่วไป)
   - เส้นเชื่อมโยง Parent/Child
   - แสดง Short SHA, Branch Badges (`[main]`, `[feat/...]`), Subject, Author และเวลา
   - หน้า Empty State แสดง `"ยังไม่มี Commit\nสร้าง repository และ commit แล้วประวัติจะแสดงที่นี่"`

4. **SandboxGameView (`SandboxGameView.cs` / `SandboxGameView.tscn`)**:
   - พื้นหลังธีม Dark Fantasy Dungeon (หน้าต่าง Gothic, คบเพลิง Torch Glow)
   - ทำหน้าที่เป็น Mediator เชื่อมระหว่าง UI Panels กับ `IGitSandboxService`
   - ทำงานกับ `RealGitSandboxService` โดยอัตโนมัติ และ Fallback ไปที่ `MockGitSandboxService` ได้อย่างไร้รอยต่อ

## วิธีการรัน

### ผ่าน Godot Engine
```sh
/Applications/Godot_mono.app/Contents/MacOS/Godot --path src/GitDiwaa.Godot
```

### Headless Mode (ทดสอบ)
```sh
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path src/GitDiwaa.Godot --quit-after 5
```

