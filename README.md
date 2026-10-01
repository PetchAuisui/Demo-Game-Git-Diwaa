# Git-Diwaa Game

ระบบแกนกลางสำหรับเกมจำลองการทำงานของ Git ด้วย Git จริง ออกแบบให้ทดสอบผ่าน Terminal ได้ก่อน และเชื่อมกับ Godot C# ในรอบถัดไปโดยไม่ผูก domain logic เข้ากับ UI

## สถานะปัจจุบัน

- รอบพัฒนา `feat/git-engine` เพิ่มระบบ Real Git, Terminal CLI และ integration tests สำหรับรวมเข้า `main`
- สถานะเป็นฐานระบบรุ่นแรกสำหรับทดลองและต่อ UI ยังไม่ครอบคลุมคำสั่งและสถานการณ์ของทุกบทเรียน
- ยังไม่พัฒนา Godot UI ตามขอบเขตงานรอบนี้
- ดู [สถานะการทดสอบ ข้อจำกัด และงานถัดไป](docs/implementation-status.md) ก่อนนำไปใช้งานต่อ

## โครงสร้าง

```text
src/
├── GitDiwaa.Core/       contracts และ models ที่ CLI/Godot ใช้ร่วมกัน
├── GitDiwaa.RealGit/    adapter สำหรับ Git จริงและ sandbox ของผู้เล่น
└── GitDiwaa.Cli/        โปรแกรมทดสอบผ่าน Terminal
tests/
└── GitDiwaa.RealGit.Tests/  integration tests กับ Git จริง
docs/
└── architecture.md      ข้อกำหนด ขอบเขต และ data flow
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
