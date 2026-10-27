# สถาปัตยกรรมระบบ Git สำหรับเกม Git-Diwaa

## เป้าหมาย

ระบบนี้ให้ผู้เล่นใช้คำสั่ง Git จริงในพื้นที่ฝึกที่เกมสร้างขึ้น รองรับการทดสอบผ่าน Terminal ในรอบแรก และให้ Godot UI เรียก API ชุดเดียวกัน (ทั้งหมดเขียนด้วย GDScript)

อ้างอิงจากเอกสารโปรเจกต์ใน Notion ณ วันที่ 1 ตุลาคม 2026 เกมต้องครอบคลุมการตั้งค่าและเริ่ม repository, status/add/commit, log/diff/restore/reset, branch/switch/merge และ local remote workflow เช่น clone/fetch/pull/push โดย repository ต้องเปลี่ยนตามผลคำสั่งจริง

## ขอบเขตรอบนี้

- เรียก executable `git` จริงโดยไม่ผ่าน shell
- สร้าง repository ผู้เล่นแยกต่อ session
- ใช้ global config และ hooks แยกจากเครื่องผู้ใช้
- จำกัดคำสั่งและ options ตามบทเรียน
- สร้าง local bare repository เพื่อจำลอง remote โดยไม่ใช้เครือข่าย
- ส่งคืนผลคำสั่งและ snapshot แบบ typed object สำหรับ Terminal และ UI
- มี integration tests ที่ตรวจการเปลี่ยนแปลง repository จริง
- ยังไม่รวม Godot scene, scoring, dialogue, save game และ online Git hosting

## Component diagram

```text
┌───────────────────┐       ┌──────────────────────┐
│ Terminal CLI      │       │ Godot UI (GDScript) │
└─────────┬─────────┘       └──────────┬───────────┘
          └──────────────┬─────────────┘
                         ▼
              ┌─────────────────────┐
              │ engine/core         │
              │ contracts + models  │
              └──────────┬──────────┘
                         ▼
              ┌─────────────────────┐
              │ engine/real_git     │
              │ session / policy /  │
              │ process / snapshot  │
              └──────────┬──────────┘
                         ▼
              ┌─────────────────────┐
              │ isolated workspace  │
              │ player repo + bare  │
              │ remote + git config │
              └─────────────────────┘
```

## Object responsibilities

| Object | Responsibility |
|---|---|
| `GitGameSessionFactory` | สร้าง attempt ใหม่ให้แต่ละภารกิจ |
| `GitGameSession` | API หลักสำหรับสั่ง Git และอ่าน state |
| `PlayerFileSystem` | จัดการไฟล์เฉพาะใน working tree โดยห้ามแตะ `.git` |
| `GitCommandResult` | ผลลัพธ์ที่ UI แสดงได้โดยไม่รู้จัก process |
| `GitRepositorySnapshot` | branch, files และ commit graph สำหรับ UI |
| Real Git adapter | ตรวจ policy และเรียก Git จริงใน sandbox |

## Data flow

1. Host ขอสร้าง session ด้วย mission ID และ attempt ID
2. Factory สร้าง working tree, config, disabled hooks และ local bare remote
3. ผู้เล่นส่ง command line ผ่าน `GitGameSession.execute()`
4. Adapter tokenize และตรวจ command policy
5. Process runner เรียก Git ด้วย argument list และ environment ที่แยกไว้
6. Host แสดง `GitCommandResult` และขอ `inspect()` เพื่อ refresh panels/graph

## Security boundary

- ไม่ส่งข้อความผู้เล่นเข้า shell
- ไม่อนุญาต `-C`, `--git-dir`, `--work-tree`, aliases หรือ paths ที่ออกนอก workspace
- ปิด credential prompt และ interactive editor
- redirect global config, ปิด system config และกำหนด hooks path ว่าง
- remote ในเกมชี้ได้เฉพาะ alias/local repository ที่ factory ลงทะเบียน
- destructive Git เช่น `reset --hard` กระทบได้เฉพาะ repository ของ session

Sandbox ลดความเสี่ยงแต่ไม่ถือเป็น OS-level security boundary หากภายหลังรองรับ mod หรือ input ที่ไม่น่าเชื่อถือ ควรเพิ่ม process sandbox ของระบบปฏิบัติการ

## Trade-offs

- ใช้ Git CLI แทน library: พฤติกรรมตรงกับงานจริงและบทเรียน แต่ต้องจัดการความต่างของเวอร์ชัน/ข้อความ output
- ใช้ local bare remote: ทดสอบซ้ำได้และไม่ต้องมี network แต่ยังไม่จำลอง authentication/hosting provider
- ใช้ console test harness: ไม่มี dependency ภายนอกและเหมาะกับ repo เริ่มต้น แต่เมื่อระบบโตควรย้ายไป test framework พร้อมรายงานที่ละเอียดขึ้น
- snapshot แยกจาก raw output: UI ใช้ง่ายและไม่ parse เอง แต่ต้องดูแล parser เมื่อเพิ่มข้อมูล Git รูปแบบใหม่

## สิ่งที่ควรทบทวนเมื่อระบบโต

- แยก policy ราย Act/ด่านแทน allowlist กลาง
- เพิ่ม multi-step mission state และ event stream
- เพิ่ม OS sandbox หากเปิดรับ repository/remote ภายนอก
- เพิ่ม persistence และ migration สำหรับ save game
- เพิ่ม telemetry ของ command, latency และ failure โดยไม่เก็บข้อมูลลับ

## แหล่งอ้างอิง

- [Final Project: พัฒนา Unity Terminal และ Git Branching Graph](https://app.notion.com/p/531af1a8af7744d2a6c1a8c23c572208)
- เอกสารและต้นแบบเดิมใน `/Users/petchauisui/Desktop/Dev/Git-Diwaa-Desktop`

