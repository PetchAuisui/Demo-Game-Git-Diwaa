# Git-Diwaa Game

ระบบแกนกลางสำหรับเกมจำลองการทำงานของ Git ด้วย Git จริง เขียนด้วย GDScript ทั้งหมดบน Godot 4 ออกแบบให้ทดสอบผ่าน Terminal ได้โดยไม่ต้องเปิดเกม และไม่ผูก domain logic เข้ากับ UI

## สถานะปัจจุบัน

- Godot Sandbox UI (GDScript) ใช้โครงสร้าง OOP แบบโมดูลและเชื่อมกับ repository จำลองที่ใช้ Git จริง
- ประกอบด้วยคอมโพเนนต์ Terminal, Files panel, Git Graph panel, Top Bar panel และ Sandbox Orchestrator View
- Files/Workspace แสดงโครงสร้างไฟล์และโฟลเดอร์ พร้อมสร้าง เปลี่ยนชื่อ ลบ เปิด แก้ไข บันทึก และแจ้งสถานะ unsaved
- ฐานระบบ Real Git engine, Terminal CLI และ integration tests พร้อมใช้งาน ทุกส่วนเป็น GDScript และไม่ต้องติดตั้ง .NET

## โครงสร้าง

```text
game/                            Godot 4 project (GDScript)
├── engine/                      logic ที่ไม่ผูกกับ UI
│   ├── core/                    contracts และ models ที่ CLI/UI ใช้ร่วมกัน
│   ├── real_git/                adapter สำหรับ Git จริงและ sandbox ของผู้เล่น
│   └── cli/                     โปรแกรมทดสอบผ่าน Terminal
├── features/                    แต่ละฟีเจอร์เก็บ scene + script ไว้ด้วยกัน
│   ├── sandbox/                 หน้า Sandbox (Terminal, Files, Git Graph) + services/ + view_models/
│   ├── remote_repo/             หน้า Remote Repository จำลอง GitHub (theme, diff, markdown)
│   ├── start/                   หน้าเริ่มเกมและห้องแต่งตัว
│   └── cutscene/                cutscene
├── common/                      ของที่ใช้ร่วมกัน (theme tokens, dialog style, window controls)
└── assets/                      art, audio, fonts, icons
tests/
└── engine/                      integration tests กับ Git จริง (run_tests.gd)
docs/                            เอกสาร
```

## สิ่งที่ต้องมี

- Godot 4.7 (รุ่นมาตรฐาน ไม่ต้องใช้รุ่น .NET/Mono)
- Git CLI

ระบบไม่ใช้ package ภายนอก

ในตัวอย่างด้านล่างใช้ `godot` แทน path ของโปรแกรม Godot บนเครื่อง (เช่น `/Applications/Godot.app/Contents/MacOS/Godot` บน macOS)

## เตรียมโปรเจกต์ (ครั้งแรกหลัง clone)

Godot ต้อง import โปรเจกต์หนึ่งครั้งเพื่อสร้าง class cache ของสคริปต์

```sh
godot --headless --path game --import
```

## เปิดเกม Godot Sandbox UI

```sh
godot --path game
```

หรือทดสอบ headless mode:
```sh
godot --headless --path game --quit-after 5
```

## เปิดห้องทดลอง Terminal

```sh
godot --headless --path game --script res://engine/cli/cli_main.gd
```

ตัวอย่าง one-shot สำหรับตรวจ Git จริงและดู state ที่ UI จะได้รับ (option ของ CLI อยู่หลัง `--`):

```sh
godot --headless --path game --script res://engine/cli/cli_main.gd -- \
  --workspace /tmp/git-diwaa-lab \
  --attempt demo-1 \
  --command "git init" \
  --snapshot
```

ดู options ทั้งหมด:

```sh
godot --headless --path game --script res://engine/cli/cli_main.gd -- --help
```

## ทดสอบ

```sh
godot --headless --path game --script "$PWD/tests/engine/run_tests.gd"
```

ชุดทดสอบสร้าง repository จริงใต้ cache directory ของระบบ และลบเฉพาะพื้นที่ทดสอบของตัวเองเมื่อจบ จบด้วย exit code 0 เมื่อผ่านทั้งหมด

## ทดสอบ Files/Workspace ด้วยตนเอง

1. เปิด Godot Sandbox UI แล้วใช้ปุ่ม `+ ไฟล์` หรือ `+ โฟลเดอร์`
2. เลือกไฟล์และกด `เปิด` หรือดับเบิลคลิก จากนั้นแก้ข้อความและตรวจ badge `ยังไม่บันทึก`
3. กด `บันทึก` แล้วพิมพ์ `git status` ใน Terminal เพื่อยืนยันว่า Git เห็นการเปลี่ยนแปลง
4. ทดสอบ `เปลี่ยนชื่อ` และ `ลบ` แล้วตรวจ confirmation, feedback และ `git status` อีกครั้ง
5. ลองเปิดหรือปิด editor ขณะมีเนื้อหาที่ยังไม่บันทึก เพื่อตรวจ dialog ป้องกันข้อมูลสูญหาย

## เอกสาร

- [Game Design v2 — LM-GM, อุปมาโลกเวท, การออกแบบด่าน](docs/game-design.md)
- [สถาปัตยกรรม](docs/architecture.md)
- [สถานะระบบและงานถัดไป](docs/implementation-status.md)
- [ทดสอบผ่าน Terminal](docs/testing-terminal.md)
- [สถาปัตยกรรม Godot Sandbox UI](docs/godot-integration.md)
- [รายการและการใช้งานฟอนต์](docs/fonts.md)
- [คู่มือระบบควบคุมคัตซีน](docs/cutscene-controls.md)
- [คัตซีนภายในหอคอยเวท (Inside Tower Cutscene)](docs/inside-tower-cutscene.md)
- [คัตซีนหอคอยเวทกลาง (Central Tower Cutscene)](docs/central-tower-cutscene.md)
