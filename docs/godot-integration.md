# สถาปัตยกรรม Godot Sandbox UI

Godot Sandbox UI (GDScript) ได้รับการพัฒนาในรูปแบบ Component-based OOP แยกส่วนชัดเจนเพื่อให้แต่ละ Panel นำไปต่อยอดและนำไปใช้ซ้ำได้

## โครงสร้างโมดูล (OOP Architecture)

```text
game/
├── project.godot                       # Godot 4.7 engine configuration
├── engine/                             # logic ที่ไม่ผูกกับ UI
│   ├── core/                           # contracts + models (GitCommandResult, GitRepositorySnapshot, GitRemoteHost, ...)
│   ├── real_git/                       # Real Git engine (session, policy, process runner, GitHub จำลอง)
│   └── cli/                            # Terminal CLI (cli_main.gd)
├── features/                           # scene + script ของแต่ละฟีเจอร์อยู่ด้วยกัน
│   ├── sandbox/                        # sandbox_game_view (Mediator), terminal_panel, files_panel,
│   │   │                               #   git_graph_panel, commit_graph_canvas, top_bar_panel, remote_repo_button
│   │   ├── services/                   # git_sandbox_service (contract), real_/mock_git_sandbox_service
│   │   └── view_models/                # Workspace/File, Commit Graph และ Terminal view models
│   ├── remote_repo/                    # remote_repo_view และหน้าย่อย, github_theme, github_icons,
│   │                                   #   github_ui, diff_viewer, markdown_view
│   ├── start/                          # start_view, start_top_bar, dressing_room_view และ controller
│   └── cutscene/                       # cutscene scenes + scripts
├── common/                             # sandbox_theme_tokens (Design Tokens), dialog_style, game_window (autoload F11)
└── assets/                             # art, audio, fonts, icons
```

## ความสามารถของแต่ละ Component

1. **TerminalPanel (`terminal_panel.gd` / `terminal_panel.tscn`)**:
   - หน้าต่าง Terminal พร้อมปุ่ม dot ตกแต่ง
   - รองรับการกรอกคำสั่ง Git และ Built-in host commands (`help`, `clear`, `write`, `cat`, `delete`)
   - ระบบประวัติคำสั่ง (Command History) เลื่อนดูด้วยลูกศรขึ้น/ลง (Up/Down)
   - ส่ง Signal `command_submitted(command: String)`
   - แยกสีแสดงผล: Command Echo (เขียว/ขาว), Standard Output (ขาวเทา), Error (แดง), System Info (ฟ้า/เหลือง)

2. **FilesPanel (`files_panel.gd` / `files_panel.tscn`)**:
   - แสดงไฟล์และโฟลเดอร์ทั้งหมดใน Workspace แบบมีลำดับชั้น พร้อม Badge สถานะ Git (`[?]`, `[M]`, `[A]`, `[D]`, `[R]`)
   - รองรับสร้างไฟล์, สร้างโฟลเดอร์, เปลี่ยนชื่อ และลบพร้อม confirmation
   - เปิดไฟล์ด้วยปุ่มหรือดับเบิลคลิกใน embedded `CodeEdit` และบันทึกกลับ repository จริง
   - แสดง dirty/unsaved state และถามยืนยันก่อนทิ้งการแก้ไขเมื่อเปลี่ยนไฟล์หรือปิด editor
   - แสดง success/error feedback ใน panel และล็อก action ระหว่าง operation
   - ส่ง signals สำหรับ open/save/create/create-folder/rename/delete โดยไม่เรียก filesystem จาก UI โดยตรง

3. **GitGraphPanel (`git_graph_panel.gd` / `git_graph_panel.tscn`)**:
   - แสดงประวัติ Commit เป็นกราฟ / ไทม์ไลน์
   - แสดง Commit Node Circle (สีทองเมื่อเป็น HEAD ของ branch ปัจจุบัน, สีฟ้าสำหรับ commit ทั่วไป)
   - เส้นเชื่อมโยง Parent/Child
   - แสดง Short SHA, Branch Badges (`[main]`, `[feat/...]`), Subject, Author และเวลา
   - หน้า Empty State แสดง `"ยังไม่มี Commit\nสร้าง repository และ commit แล้วประวัติจะแสดงที่นี่"`

4. **SandboxGameView (`sandbox_game_view.gd` / `sandbox_game_view.tscn`)**:
   - พื้นหลังธีม Dark Fantasy Dungeon (หน้าต่าง Gothic, คบเพลิง Torch Glow)
   - ทำหน้าที่เป็น Mediator เชื่อมระหว่าง UI Panels กับ `GitSandboxService`
   - ทำงานกับ `RealGitSandboxService` โดยอัตโนมัติ และ Fallback ไปที่ `MockGitSandboxService` ได้อย่างไร้รอยต่อ
   - refresh Workspace และ Git graph หลัง file operation เพื่อให้ `git status`, `git add` และ `git commit` เห็น state เดียวกัน

## Data flow ของ Files/Workspace

```text
FilesPanel signal → SandboxGameView → GitSandboxService
                                      └→ PlayerFileSystem ใน Real Git sandbox
                         refresh ← GitRepositorySnapshot + list_entries
```

`SandboxPlayerFileSystem` บังคับให้ path อยู่ภายใน repository, ปฏิเสธ `.git` และ symbolic links และรองรับไฟล์/โฟลเดอร์/rename โดยไม่เปิด path จริงให้ UI จัดการเอง

## วิธีการรัน

### ผ่าน Godot Engine
หลัง clone ให้ import โปรเจกต์ครั้งหนึ่ง: `godot --headless --path game --import`

```sh
godot --path game
```

### Headless Mode (ทดสอบ)
```sh
godot --headless --path game --quit-after 5
```
