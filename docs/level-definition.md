# Level Definition — วิธีสร้างและใช้งานด่าน

namespace: `GitDiwaa.Core.Levels` (โค้ดอยู่ที่ `src/GitDiwaa.Core/Levels/`)

ระบบนี้ใช้นิยามด่านของเกม โดยแต่ละด่านบอกได้ว่า **ด่านที่เท่าไหร่ · อยู่ Act ไหน · มีกี่งาน · สถานะสุดท้ายของ repo ที่คาดหวังคืออะไร**
แล้วนำสถานะนั้นไปเทียบกับ repo ของผู้เล่นได้

## 1. โครงสร้างเกม (`GameStructure`)

ยึดตามหน้า Notion "โครงสร้างของเกมส์" (40 ด่าน)

| Act | `GameAct` | ด่าน | Phase |
|---|---|---|---|
| 1 การใช้งาน Git เบื้องต้น | `BasicGit` | 1–15 | `Teaching` |
| 2 การทำงานเป็นทีม | `Teamwork` | 16–20 | `Teaching` |
| 3 การแก้ปัญหาในการใช้งาน Git | `Troubleshooting` | 21–40 | `ProblemSolving` |

```csharp
GameStructure.ActOf(17);       // GameAct.Teamwork
GameStructure.PhaseOf(act);    // Teaching / ProblemSolving
GameStructure.MaxScoreOf(10);  // 190  (สูตร 90 + 10n)
GameStructure.ActOf(41);       // throw ArgumentOutOfRangeException
```

## 2. ข้อมูลของด่าน (`LevelDefinition`)

| สมาชิก | ความหมาย |
|---|---|
| `Number` | ด่านที่เท่าไหร่ (1–40) |
| `Act` | Act ที่ด่านนี้อยู่ (คำนวณจากเลขด่าน) |
| `Phase` | ขั้นสอน หรือ ขั้นแก้ปัญหา |
| `Title` | ชื่อด่าน |
| `Tasks` / `TaskCount` | รายการงาน (`LevelTask(Id, Description)`) และจำนวนงาน |
| `MaxScore` | คะแนนเต็มของด่าน = 90 + 10n |
| `ExpectedFinalState` | สถานะ repo สุดท้ายที่คาดหวัง |
| `CompareFinalState(snapshot)` | เทียบ repo ของผู้เล่นกับสถานะที่คาดหวัง |

## 3. สร้างด่านด้วย `LevelBuilder`

```csharp
var level = LevelBuilder.ForLevel(5)
    .Titled("บันทึก Version ของงาน (git commit)")
    .AddTask("นำเศษคัมภีร์ขึ้นแท่นเตรียม")
    .AddTask("จารึกเศษคัมภีร์พร้อมข้อความกำกับ")
    .ExpectFinalState(s => s
        .Initialized()
        .OnBranch("main")
        .CommitCount(min: 1)
        .CleanWorkingTree())
    .Build();
```

- `ForLevel(n)` ตรวจว่า n อยู่ใน 1–40 และกำหนด Act ให้เอง จึงใส่ Act ผิดไม่ได้
- `AddTask` ให้ id อัตโนมัติ: `L05-T1`, `L05-T2`, ...
- `Build()` จะ throw `InvalidOperationException` ถ้าไม่มีชื่อ หรือไม่มีงานเลย
- ถ้าไม่เรียก `ExpectFinalState` จะไม่มีเงื่อนไขสถานะ (ทุกอย่างเป็น "ไม่ตรวจ")

### ตัวช่วยกำหนดสถานะปลายทาง (`ExpectedRepositoryStateBuilder`)

| เมธอด | ตรวจอะไร |
|---|---|
| `Initialized(bool)` | repo ถูก `git init` แล้วหรือไม่ |
| `OnBranch(name)` | branch ปัจจุบัน |
| `HasBranch(params names)` | ต้องมี branch เหล่านี้ |
| `HasFile(path, index?, workingTree?)` | สถานะไฟล์ใน index / working tree (`GitFileState`) |
| `CommitCount(min?, max?)` | จำนวน commit ต่ำสุด/สูงสุด |
| `HasCommit(params subjects)` | ต้องมี commit ที่ subject ตรงกัน |
| `CleanWorkingTree()` | ไม่มีไฟล์ที่ค้างสถานะ |

**หลักสำคัญ:** ช่องที่ไม่ได้กำหนดคือ "ไม่ตรวจ" ระบบจึงตรวจจากสถานะ repo ไม่ใช่ข้อความคำสั่ง
คำสั่งต่างกันที่ให้ผลเท่ากันจึงผ่านทั้งคู่

## 4. ดึงด่านจาก `LevelCatalog`

```csharp
LevelCatalog.Levels;                  // ด่านทั้งหมดที่ลงทะเบียนไว้
LevelCatalog.Find(2);                 // LevelDefinition? (null ถ้ายังไม่มี)
LevelCatalog.InAct(GameAct.BasicGit); // ด่านทั้งหมดใน Act 1
```

เพิ่มด่านใหม่โดยเติมใน list ใน [LevelCatalog.cs](../src/GitDiwaa.Core/Levels/LevelCatalog.cs)
ตอนนี้มีเฉพาะด่าน 1–3

## 5. ตรวจสถานะผู้เล่นกับสถานะที่เราตั้งไว้

```csharp
IGitGameSession session = ...;                       // session ของผู้เล่น
GitRepositorySnapshot snapshot = await session.InspectAsync();

var level = LevelCatalog.Find(2)!;
StateComparison result = level.CompareFinalState(snapshot);

if (result.IsMatch)
{
    // ผ่านด่าน
}
else
{
    foreach (var m in result.Mismatches)
        Console.WriteLine(m);   // เช่น "initialized: expected True, got False"
}
```

`Mismatches` บอกว่าตรงไหนไม่ตรง นำไปทำ Feedback ในหน้าสรุปผลได้

## 6. ข้อจำกัดปัจจุบัน

- ใน catalog มีเฉพาะด่าน 1–3 ส่วน 4–40 รอข้อมูลจาก Notion (ภารกิจมีถึงด่าน 20 เท่านั้น ไม่มีสถานะปลายทางรายด่าน)
- ด่าน 1 (`git config`) ยังไม่มีเงื่อนไขสถานะ เพราะ `GitRepositorySnapshot` ไม่ได้เก็บ config
- ด่านที่มีหลายขั้น (16, 17, 19) ยังเป็นรายการงานแบบเรียบ ยังไม่แยกเป็นขั้น
- ยังไม่รวม Timer, Star, Coin, Stack (อยู่ในงาน Balance แยกต่างหาก)
