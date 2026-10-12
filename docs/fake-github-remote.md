# GitHub จำลอง (Fake GitHub Remote)

เป้าหมาย: คำสั่ง `git clone/fetch/pull/push` ในเกมต้องไม่ออกไปถึง GitHub จริง แต่ผู้เล่นยังเห็น URL แบบ GitHub และมีข้อมูลสำหรับหน้า Remote Repository

ข้อมูลทั้งหมดมาจากสิ่งที่ผู้เล่น push ขึ้นไปจริง ไม่ผูกกับหน้าตาตัวอย่างใน Figma

## สถานะเริ่มต้น

- ทุก session มี remote เป็น repo **ว่าง** ที่ผู้เล่นเป็นเจ้าของ: `https://github.com/user/my-project.git`
- เจ้าของ (host) ใช้ชื่อ `user` ไปก่อน เปลี่ยนได้ที่ `RealGitGameSessionFactory(workspaceRoot, playerName)` เมื่อมีหน้า login ที่ตั้งชื่อผู้เล่นได้
- ไม่มีข้อมูลตัวอย่างในโค้ดจริง ผู้เล่นต้อง push งานขึ้นไปเอง
- ด่านที่ต้องการ remote ที่มีประวัติอยู่แล้ว (เช่น ด่าน 37 ที่ remote นำหน้า local) กำหนดผ่าน `RemoteSeed` ต่อด่าน

## ข้อมูลและการกระทำที่ host ให้ (ตาม Notion: งานหน้า Remote Repository)

`IGitGameSession.RemoteHost` (`IGitRemoteHost`) ให้ข้อมูลและการกระทำสำหรับหน้า Remote Repository ของเกม:

| หมวด | สิ่งที่ host ให้ |
|---|---|
| หน้ารวม / Code | ข้อมูล repo, commit ล่าสุด, ไฟล์/โฟลเดอร์ตาม branch, อ่านเนื้อหาไฟล์ (เช่น README), URL สำหรับ clone |
| Commits | ประวัติ commit ของ branch |
| Branches | รายการ branch พร้อม ahead/behind เทียบ default branch, ลบ branch (ลบ default หรือ branch ที่มี PR เปิดอยู่ไม่ได้) |
| Pull requests | สร้าง PR, commits / ไฟล์ที่เปลี่ยน / diff, review (Approve / Request changes / Comment), merge, ปิด PR, ดู PR ที่ merge แล้วย้อนหลัง |
| repo ว่าง | `RemoteRepositoryInfo.IsEmpty` ใช้แสดงหน้า Quick setup |

## หน้า Remote Repository ใน Sandbox

เปิดจากปุ่ม **Remote Repo** (ไอคอนก้อนเมฆ `RemoteRepoButton`) ที่มุมขวาของหัวพาเนล Git Graph ใน Sandbox (`RemoteRepoView`) หน้าตาเลียนแบบ GitHub ธีม dark ไม่ยึดตัวอย่างใน Figma
มีแถบ URL แสดงที่อยู่ของหน้าปัจจุบัน (เช่น `github.com/user/my-project/pull/1`) กด Esc หรือปุ่ม "กลับ Sandbox" เพื่อกลับ

| หน้า | สิ่งที่ทำได้ |
|---|---|
| repo ว่าง | Quick setup: คำแนะนำวิธีใช้อยู่บนสุด, URL (Copy), ขั้นตอน 1) ตั้งชื่อผู้ใช้ Git 2) สร้างไฟล์แรกแล้ว commit 3) ผูก remote แล้ว push และ clone ท้ายหน้า คลิกที่คำสั่งเพื่อคัดลอกทีละบรรทัด (ย้อมสีและมีคำอธิบายสั้นๆ ข้างบรรทัด) |
| Code | เลือก branch, เปิดโฟลเดอร์/ไฟล์ (มีเลขบรรทัดและปุ่ม Copy), commit ล่าสุด, ค้นหาไฟล์ (Go to file), README แสดงเป็น Markdown, เมนู Clone |
| Commits | ประวัติ commit ของ branch จัดกลุ่มตามวัน |
| Branches | แยก Default / Other, ชิป ahead/behind, เปิด PR, ลบ branch |
| Pull requests | รายการ (ค้นหา, Open/Closed), เปิด PR (base ← compare, Title เติมจาก commit ล่าสุดให้), หน้า PR แบบ Conversation / Commits / Files changed (diff), review, merge, ปิด PR, ลบ branch หลัง merge |

แนวทางการออกแบบหน้าตา (ปรับตามฟีดแบ็กว่า "ดูยาก สีกลืนกัน")
- **ขนาด**: เกมตั้งฟอนต์เริ่มต้น 24 แต่ GitHub จริงใช้ 14–16 จึงคูณทุกขนาด (ตัวอักษร ไอคอน ช่องไฟ) ด้วย `GitHubTheme.UiScale` (1.35) ผ่าน `GitHubTheme.S()` ถ้าจะปรับความใหญ่ทั้งหน้าให้แก้ค่าเดียว
- **สีเป็นชั้น**: `Inset` (แถบบน ช่องกรอก บล็อกโค้ด) < `Canvas` (พื้นหน้า) < `Surface` (การ์ด หัว repo) < `SurfaceRaised` (หัวการ์ด แถวที่ชี้ เมนู) ตัวอักษรและเส้นขอบสว่างกว่า GitHub เดิมเล็กน้อย ฉากเกมด้านหลังถูกบังเกือบทึบ
- **คอลัมน์กึ่งกลาง**: เนื้อหากว้างสูงสุด `ContentMaxWidth` ทั้งหัว repo และตัวหน้า (ขอบซ้าย/ขวาตรงกัน) ไม่ยืดตามจอกว้าง
- **แถบบน**: ปุ่มกลับ Sandbox พร้อมป้าย Esc, ช่อง URL, ปุ่มรีเฟรช, ป้าย "GitHub จำลอง"

โครงโค้ด UI
- `Scripts/Common/GitHubTheme.cs` พาเลตต์ สเกล และ Theme (ปุ่ม ช่องกรอก เมนู แถบเลื่อน), `GitHubIcons.cs` ไอคอน SVG
- `Scripts/Components/GitHubUi.cs` ชิ้นส่วนใช้ซ้ำ (แท็บ กล่องรายการ แถวคลิกได้ ป้ายสถานะ avatar แถบแจ้งผล หัวข้อมีเลขกำกับ การ์ดขั้นตอน `Step` และบล็อกคำสั่ง `CommandBlock` ที่ย้อมสีคำสั่งและคลิกเพื่อคัดลอก)
- `DiffViewer.cs` (diff แบบการ์ดต่อไฟล์), `MarkdownView.cs` (README และคำอธิบาย PR)
- `RemoteRepoView.cs` โครงหน้าต่างและการนำทาง, `.Code.cs` / `.History.cs` / `.Pulls.cs` แยกตามหน้า

ข้อจำกัดของหน้า UI: เป็น overlay ครอบ Sandbox ต้องกลับไปพิมพ์คำสั่งใน terminal แล้วเปิดหน้าใหม่เพื่อดูผล

## การทำงาน

1. URL ที่ผู้เล่นเห็นเป็น URL สมมติรูปแบบ GitHub แต่ถูก rewrite (`url.<bare>.insteadOf`) ไปยัง bare repository ในโฟลเดอร์ session เท่านั้น
2. Policy ยอมรับเฉพาะ URL ของ session นั้นแบบตรงตัว URL อื่นรวมถึง GitHub จริงถูกปฏิเสธและบอก URL ที่อนุญาต
3. `IGitRemoteHost` อ่านข้อมูลจาก bare repository จริงด้วย Git ส่วน merge ทำด้วย Git จริงแล้ว push เข้า bare remote
4. สถานะ PR และ review เก็บในหน่วยความจำของ session
5. ตรวจ conflict ก่อน merge ทุกครั้งด้วย `git merge-tree` ผลสรุปอยู่ใน `PullRequestDetail.MergeBlockedReason` เพื่อให้ UI ไม่ต้องรู้กติกาเอง

## กติกา pull request (`RemoteRules`)

| กติกา | ค่าเริ่มต้น (sandbox คนเดียว) | โหมดเข้ม (ด่าน code review) |
|---|---|---|
| `RequireApproval` | `false` merge ได้เลย review เป็นทางเลือก | `true` ต้อง Approve ก่อน merge |
| `AllowSelfReview` | `true` รีวิว PR ตัวเองได้ | `false` Approve/Request changes ของตัวเองไม่ได้ (Comment ได้) |

ตั้งต่อด่านผ่าน `RemoteSeed.Rules` เช่น ด่าน 39 (แก้ตาม Code Review)

## ข้อจำกัด

- PR และ review เก็บในหน่วยความจำของ session
- แก้ conflict ผ่านหน้าเว็บไม่ได้ (แก้ใน terminal)
- ไม่มี comment รายบรรทัดใน diff และไม่มี authentication / permission จำลอง
