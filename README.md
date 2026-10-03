# Git-Diwaa Game

ระบบแกนกลางสำหรับเกมจำลองการทำงานของ Git ด้วย Git จริง ออกแบบให้ทดสอบผ่าน Terminal ได้ก่อน และเชื่อมกับ Godot C# ในรอบถัดไปโดยไม่ผูก domain logic เข้ากับ UI

## สถานะปัจจุบัน

- รอบพัฒนา `feat/godot-sandbox-ui` พัฒนาระบบ Godot C# Sandbox UI ตามโครงสร้าง OOP แบบโมดูล
- ประกอบด้วยคอมโพเนนต์ Terminal, Files panel, Git Graph panel, Top Bar panel และ Sandbox Orchestrator View
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

## เอกสาร

- [สถาปัตยกรรม](docs/architecture.md)
- [สถานะระบบและงานถัดไป](docs/implementation-status.md)
- [ทดสอบผ่าน Terminal](docs/testing-terminal.md)
- [แนวทางเชื่อม Godot C# รอบถัดไป](docs/godot-integration.md)
