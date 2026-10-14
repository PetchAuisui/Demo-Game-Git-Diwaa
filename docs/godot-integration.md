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
│   ├── RemoteRepoView.tscn          # โครงหน้า Remote Repository (แถบบน หัว repo พื้นที่เลื่อน)
│   ├── RepoListPage.tscn            # หน้ารายการ repo ในหน้า Remote Repository
│   ├── CodePage.tscn                # แถบเครื่องมือหน้า Code ของ repo
│   ├── NewRepoPage.tscn             # ฟอร์มสร้าง repo ใหม่
│   └── TerminalPanel.tscn           # Reusable Terminal Window และ Command Prompt
└── Scripts/
    ├── Common/
    │   └── SandboxThemeTokens.cs    # Design Tokens (Colors, StyleBoxes, Fonts)
    ├── ViewModels/
    │   └── SandboxViewModels.cs     # Workspace/File, Commit Graph และ Terminal view models
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
   - แสดงไฟล์และโฟลเดอร์ทั้งหมดใน Workspace แบบมีลำดับชั้น พร้อม Badge สถานะ Git (`[?]`, `[M]`, `[A]`, `[D]`, `[R]`)
   - รองรับสร้างไฟล์, สร้างโฟลเดอร์, เปลี่ยนชื่อ และลบพร้อม confirmation
   - เปิดไฟล์ด้วยปุ่มหรือดับเบิลคลิกใน embedded `CodeEdit` และบันทึกกลับ repository จริง
   - แสดง dirty/unsaved state และถามยืนยันก่อนทิ้งการแก้ไขเมื่อเปลี่ยนไฟล์หรือปิด editor
   - แสดง success/error feedback ใน panel และล็อก action ระหว่าง operation
   - ส่ง signals สำหรับ open/save/create/create-folder/rename/delete โดยไม่เรียก filesystem จาก UI โดยตรง

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
   - refresh Workspace และ Git graph หลัง file operation เพื่อให้ `git status`, `git add` และ `git commit` เห็น state เดียวกัน

## Data flow ของ Files/Workspace

```text
FilesPanel signal → SandboxGameView → IGitSandboxService
                                      └→ IPlayerFileSystem ใน Real Git sandbox
                         refresh ← GitRepositorySnapshot + ListEntries
```

`SandboxPlayerFileSystem` บังคับให้ path อยู่ภายใน repository, ปฏิเสธ `.git` และ symbolic links และรองรับไฟล์/โฟลเดอร์/rename โดยไม่เปิด path จริงให้ UI จัดการเอง

## วิธีการรัน

### ผ่าน Godot Engine
```sh
/Applications/Godot_mono.app/Contents/MacOS/Godot --path src/GitDiwaa.Godot
```

### Headless Mode (ทดสอบ)
```sh
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path src/GitDiwaa.Godot --quit-after 5
```
