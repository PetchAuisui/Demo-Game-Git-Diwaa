# Git-Diwaa Game

ระบบแกนกลางสำหรับเกมจำลองการทำงานของ Git ด้วย Git จริง ออกแบบให้ทดสอบผ่าน Terminal ได้ก่อน และเชื่อมกับ Godot C# ในรอบถัดไปโดยไม่ผูก domain logic เข้ากับ UI

## สถานะปัจจุบัน

- `main` เก็บโครงสร้าง solution, contracts และเอกสารสถาปัตยกรรม
- ระบบ Real Git จะพัฒนาบน feature branch แยกจาก `main`
- ยังไม่พัฒนา Godot UI ตามขอบเขตงานรอบนี้

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

## ตรวจสอบโครงสร้าง

```sh
dotnet build GitDiwaa.slnx
```

อ่านรายละเอียดที่ [docs/architecture.md](docs/architecture.md)

