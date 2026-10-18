# Git-Diwaa Game

ระบบแกนกลางสำหรับเกมจำลองการทำงานของ Git ด้วย Git จริง ออกแบบให้ทดสอบผ่าน Terminal ได้ก่อน และเชื่อมกับ Godot C# ในรอบถัดไปโดยไม่ผูก domain logic เข้ากับ UI

## สถานะปัจจุบัน

- Godot C# Sandbox UI ใช้โครงสร้าง OOP แบบโมดูลและเชื่อมกับ repository จำลองที่ใช้ Git จริง
- ประกอบด้วยคอมโพเนนต์ Terminal, Files panel, Git Graph panel, Top Bar panel และ Sandbox Orchestrator View
- Files/Workspace แสดงโครงสร้างไฟล์และโฟลเดอร์ พร้อมสร้าง เปลี่ยนชื่อ ลบ เปิด แก้ไข บันทึก และแจ้งสถานะ unsaved
- ฐานระบบ Real Git engine, Terminal CLI และ integration tests พร้อมใช้งาน

## โครงสร้าง

```text
src/
├── GitDiwaa.Core/       contracts และ models ที่ CLI/Godot ใช้ร่วมกัน
├── GitDiwaa.RealGit/    adapter สำหรับ Git จริงและ sandbox ของผู้เล่น
├── GitDiwaa.Cli/        โปรแกรมทดสอบผ่าน Terminal
└── GitDiwaa.Godot/      Godot 4 C# Sandbox UI (Terminal, Files, Git Graph)
tests/
└── GitDiwaa.RealGit.Tests/  integration tests กับ Git จริง
docs/
├── architecture.md      ข้อกำหนด ขอบเขต และ data flow
└── godot-integration.md สถาปัตยกรรม Godot C# Sandbox UI
```

## สิ่งที่ต้องมี

- .NET SDK 10
- Git CLI

ระบบไม่ใช้ NuGet package ภายนอกในรอบนี้

## Restore และ build

```sh
dotnet restore src/GitDiwaa.Cli/GitDiwaa.Cli.csproj \
  --configfile NuGet.Config --disable-build-servers
dotnet restore tests/GitDiwaa.RealGit.Tests/GitDiwaa.RealGit.Tests.csproj \
  --configfile NuGet.Config --disable-build-servers
dotnet build GitDiwaa.slnx --no-restore --disable-build-servers -m:1
```

## เปิดห้องทดลอง Terminal

```sh
dotnet run --project src/GitDiwaa.Cli/GitDiwaa.Cli.csproj
```

## เปิดเกม Godot Sandbox UI

```sh
/Applications/Godot_mono.app/Contents/MacOS/Godot --path src/GitDiwaa.Godot
```

หรือทดสอบ headless mode:
```sh
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path src/GitDiwaa.Godot --quit-after 5
```

ตัวอย่าง one-shot สำหรับตรวจ Git จริงและดู state ที่ UI จะได้รับ:

```sh
dotnet run --project src/GitDiwaa.Cli/GitDiwaa.Cli.csproj -- \
  --workspace /tmp/git-diwaa-lab \
  --attempt demo-1 \
  --command "git init" \
  --snapshot
```

ดู options ทั้งหมด:

```sh
dotnet run --project src/GitDiwaa.Cli/GitDiwaa.Cli.csproj -- --help
```

## ทดสอบ

```sh
dotnet run --project tests/GitDiwaa.RealGit.Tests/GitDiwaa.RealGit.Tests.csproj
```

ชุดทดสอบสร้าง repository จริงใต้ temporary directory และลบเฉพาะพื้นที่ทดสอบของตัวเองเมื่อจบ

## ทดสอบ Files/Workspace ด้วยตนเอง

1. เปิด Godot Sandbox UI แล้วใช้ปุ่ม `+ ไฟล์` หรือ `+ โฟลเดอร์`
2. เลือกไฟล์และกด `เปิด` หรือดับเบิลคลิก จากนั้นแก้ข้อความและตรวจ badge `ยังไม่บันทึก`
3. กด `บันทึก` แล้วพิมพ์ `git status` ใน Terminal เพื่อยืนยันว่า Git เห็นการเปลี่ยนแปลง
4. ทดสอบ `เปลี่ยนชื่อ` และ `ลบ` แล้วตรวจ confirmation, feedback และ `git status` อีกครั้ง
5. ลองเปิดหรือปิด editor ขณะมีเนื้อหาที่ยังไม่บันทึก เพื่อตรวจ dialog ป้องกันข้อมูลสูญหาย

## เอกสาร

- [สถาปัตยกรรม](docs/architecture.md)
- [สถานะระบบและงานถัดไป](docs/implementation-status.md)
- [ทดสอบผ่าน Terminal](docs/testing-terminal.md)
- [แนวทางเชื่อม Godot C# รอบถัดไป](docs/godot-integration.md)
- [รายการและการใช้งานฟอนต์](docs/fonts.md)
- [คัตซีนหอคอยเวทกลาง (Central Tower Cutscene)](docs/central-tower-cutscene.md)
