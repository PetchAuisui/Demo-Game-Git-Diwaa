# GitHub จำลอง (Simulated GitHub Remote)

เป้าหมาย: คำสั่ง `git clone/fetch/pull/push` ในเกมต้องไม่ออกไปถึง GitHub จริง แต่ผู้เล่นยังเห็น URL แบบ GitHub และมีข้อมูลสำหรับหน้า Remote Repository

ข้อมูลทั้งหมดมาจากสิ่งที่ผู้เล่น push ขึ้นไปจริง ไม่ผูกกับหน้าตาตัวอย่างใน Figma

## สถานะเริ่มต้น

- ทุก session เริ่มด้วยบัญชี `user` ที่ **ยังไม่มี repo เลย** ผู้เล่นสร้าง repo ว่างเองได้ไม่จำกัดผ่านปุ่ม New (ด่านที่ต้องการ repo ตั้งต้นส่ง `RemoteSeed` เข้ามาเอง เช่น `RemoteSeed.empty()` จะได้ `https://magic-vault.com/user/my-project.git`) (`https://magic-vault.com/user/<ชื่อ>.git`) แต่ละ repo แยก branch และ PR ของตัวเอง
- เจ้าของ (host) ใช้ชื่อ `user` ไปก่อน เปลี่ยนได้ที่ `RealGitGameSessionFactory.new(workspace_root, player_name)` เมื่อมีหน้า login ที่ตั้งชื่อผู้เล่นได้
- ไม่มีข้อมูลตัวอย่างในโค้ดจริง ผู้เล่นต้อง push งานขึ้นไปเอง
- ด่านที่ต้องการ remote ที่มีประวัติอยู่แล้ว (เช่น ด่าน 37 ที่ remote นำหน้า local) กำหนดผ่าน `RemoteSeed` ต่อด่าน

## ข้อมูลและการกระทำที่ host ให้ (ตาม Notion: งานหน้า Remote Repository)

`GitGameSession.remote_account` (`GitRemoteAccount`) ให้รายการ repo / เปิด repo / สร้าง repo ใหม่ ส่วน `GitRemoteHost` ของแต่ละ repo (และ `GitGameSession.remote_host` ที่เป็น repo แรก) ให้ข้อมูลและการกระทำสำหรับหน้า repo:

| หมวด | สิ่งที่ host ให้ |
|---|---|
| หน้ารวม / Code | ข้อมูล repo, commit ล่าสุด, ไฟล์/โฟลเดอร์ตาม branch, อ่านเนื้อหาไฟล์ (เช่น README), URL สำหรับ clone |
| Commits | ประวัติ commit ของ branch |
| Branches | รายการ branch พร้อม ahead/behind เทียบ default branch, ลบ branch (ลบ default หรือ branch ที่มี PR เปิดอยู่ไม่ได้) |
| Pull requests | สร้าง PR, commits / ไฟล์ที่เปลี่ยน / diff, ความเห็นรายบรรทัดใน diff (ชี้เมาส์ที่บรรทัดแล้วกด + → Write/Preview → Comment ทันที หรือ Start a review เก็บเป็น pending ส่งพร้อมตอน Submit review), review (ปุ่ม Review changes ในแท็บ Files changed → Comment / Approve / Request changes → Submit review), คอมเมนต์และ Close pull request ที่กล่องท้ายหน้า Conversation, merge, ดู PR ที่ merge แล้วย้อนหลัง |
| repo ว่าง | `RemoteRepositoryInfo.is_empty` ใช้แสดงหน้า Quick setup |

## หน้า Remote Repository ใน Sandbox

เปิดจากปุ่ม **Remote Repo** (ไอคอนก้อนเมฆ `RemoteRepoButton`) ที่มุมขวาของหัวพาเนล Git Graph ใน Sandbox (`RemoteRepoView`) หน้าตาเลียนแบบ GitHub ธีม dark ไม่ยึดตัวอย่างใน Figma
มีแถบ URL แสดงที่อยู่ของหน้าปัจจุบัน (เช่น `magic-vault.com/user/my-project/pull/1`) กด Esc หรือปุ่ม "กลับ Sandbox" เพื่อกลับ

| หน้า | สิ่งที่ทำได้ |
|---|---|
| รายการ repo | หน้าแรกหลังกดปุ่ม Remote Repo: พื้นหลังห้องบัลลังก์ (`assets/art/remote/throne-room.png`), การ์ดโปรไฟล์ซ้าย, ช่องค้นหา, ปุ่ม **New** และรายการ repo ขวา กดชื่อ repo เพื่อเข้า กดชื่อเจ้าของที่หัว repo เพื่อกลับมารายการ |
| New repository | ฟอร์มตั้งชื่อ (ตัวอักษรอังกฤษ ตัวเลข `-` `_` ชื่อซ้ำไม่ได้) และคำอธิบาย สร้างเป็น repo ว่างแล้วเข้าหน้า Quick setup ของ repo นั้นทันที |
| repo ว่าง | Quick setup: คำแนะนำวิธีใช้อยู่บนสุด, URL (Copy), ขั้นตอน 1) ตั้งชื่อผู้ใช้ Git 2) สร้างไฟล์แรกแล้ว commit 3) ผูก remote แล้ว push และ clone ท้ายหน้า คลิกที่คำสั่งเพื่อคัดลอกทีละบรรทัด (ย้อมสีและมีคำอธิบายสั้นๆ ข้างบรรทัด) |
| Code | เลือก branch, เปิดโฟลเดอร์/ไฟล์ (มีเลขบรรทัดและปุ่ม Copy), commit ล่าสุด, ค้นหาไฟล์ (Go to file), README แสดงเป็น Markdown, เมนู Clone |
| Commits | ประวัติ commit ของ branch จัดกลุ่มตามวัน |
| Branches | แยก Default / Other, ชิป ahead/behind, เปิด PR, ลบ branch |
| Pull requests | รายการ (ค้นหา, Open/Closed), เปิด PR (base ← compare, Title เติมจาก commit ล่าสุดให้), หน้า PR แบบ Conversation / Commits / Files changed (diff), review, merge, ปิด PR, ลบ branch หลัง merge |

แนวทางการออกแบบหน้าตา (ปรับตามฟีดแบ็กว่า "ดูยาก สีกลืนกัน")
- **ขนาด**: เกมตั้งฟอนต์เริ่มต้น 24 แต่ GitHub จริงใช้ 14–16 จึงคูณทุกขนาด (ตัวอักษร ไอคอน ช่องไฟ) ด้วย `GitHubTheme.UI_SCALE` (1.35) ผ่าน `GitHubTheme.s()` ถ้าจะปรับความใหญ่ทั้งหน้าให้แก้ค่าเดียว
- **สีเป็นชั้น**: `INSET` (แถบบน ช่องกรอก บล็อกโค้ด) < `CANVAS` (พื้นหน้า) < `SURFACE` (การ์ด หัว repo) < `SURFACE_RAISED` (หัวการ์ด แถวที่ชี้ เมนู) ตัวอักษรและเส้นขอบสว่างกว่า GitHub เดิมเล็กน้อย ฉากเกมด้านหลังถูกบังเกือบทึบ
- **คอลัมน์กึ่งกลาง**: เนื้อหากว้างสูงสุด `_content_max_width()` (ที่ขนาดจอปกติเกือบเต็มกรอบ เหลือขอบข้างละราว 40px) ทั้งแถบบน หัว repo และตัวหน้า ขอบซ้าย/ขวาตรงกัน และไม่ยืดตามจอที่กว้างกว่านั้น
- **แถบบน**: ปุ่มกลับ Sandbox พร้อมป้าย Esc, ช่อง URL, ปุ่มรีเฟรช, ป้าย "Magic Vault"

โครงโค้ด UI
- `features/remote_repo/github_theme.gd` พาเลตต์ สเกล และ Theme (ปุ่ม ช่องกรอก เมนู แถบเลื่อน), `github_icons.gd` ไอคอน SVG
- `features/remote_repo/github_ui.gd` ชิ้นส่วนใช้ซ้ำ (แท็บ กล่องรายการ แถวคลิกได้ ป้ายสถานะ avatar แถบแจ้งผล หัวข้อมีเลขกำกับ การ์ดขั้นตอน `step` และบล็อกคำสั่ง `command_block` ที่ย้อมสีคำสั่งและคลิกเพื่อคัดลอก)
- `diff_viewer.gd` (diff แบบการ์ดต่อไฟล์), `markdown_view.gd` (README และคำอธิบาย PR)
- `features/remote_repo/remote_repo_view.tscn` โครงคงที่ของหน้า (กรอบหน้าต่าง แถบบน หัว repo แท็บ พื้นที่เลื่อน) ปรับหน้าตาใน Godot editor ได้ ค่าสี/ขนาดใน scene ต้องตรงกับ `GitHubTheme` (สเกล ×1.35 คำนวณไว้แล้ว)
- `features/remote_repo/repo_list_page.tscn` (หน้ารายการ repo: การ์ดโปรไฟล์ ช่องค้นหา ปุ่ม New), `features/remote_repo/new_repo_page.tscn` (ฟอร์มสร้าง repo) และ `features/remote_repo/code_page.tscn` (แถบเครื่องมือหน้า Code: branch, Branches, Go to file, Code) แยก scene ต่อหน้า มีสคริปต์ `repo_list_page.gd` / `new_repo_page.gd` / `code_page.gd` ใส่ข้อมูลและต่อสัญญาณ
- `remote_repo_view.gd` ผูก node ของ scene นำทาง รีเฟรช และสร้างเนื้อหาที่เปลี่ยนตามข้อมูลด้วยโค้ด (breadcrumb ตารางไฟล์ README แถว commit PR diff)

ข้อจำกัดของหน้า UI: เป็น overlay ครอบ Sandbox ต้องกลับไปพิมพ์คำสั่งใน terminal แล้วเปิดหน้าใหม่เพื่อดูผล

## การทำงาน

1. URL ที่ผู้เล่นเห็นเป็น URL สมมติรูปแบบ GitHub แต่ถูก rewrite (`url.<bare>.insteadOf`) ไปยัง bare repository ในโฟลเดอร์ session เท่านั้น
2. Policy ยอมรับเฉพาะ URL ของ repo ในบัญชีนี้แบบตรงตัว (ทั้ง repo แรกและที่สร้างเพิ่ม) URL อื่นรวมถึง GitHub จริงจะไม่ผ่านและบอก URL ที่ใช้ได้
3. `GitRemoteHost` อ่านข้อมูลจาก bare repository จริงด้วย Git ส่วน merge ทำด้วย Git จริงแล้ว push เข้า bare remote
4. สถานะ PR และ review เก็บในหน่วยความจำของ session
5. ตรวจ conflict ก่อน merge ทุกครั้งด้วย `git merge-tree` ผลสรุปอยู่ใน `PullRequestDetail.merge_blocked_reason` เพื่อให้ UI ไม่ต้องรู้กติกาเอง

## กติกา pull request (`RemoteRules`)

| กติกา | ค่าเริ่มต้น (sandbox คนเดียว) | โหมดเข้ม (ด่าน code review) |
|---|---|---|
| `require_approval` | `false` merge ได้เลย review เป็นทางเลือก | `true` ต้อง Approve ก่อน merge |
| `allow_self_review` | `true` รีวิว PR ตัวเองได้ | `false` Approve/Request changes ของตัวเองไม่ได้ (Comment ได้) |

ตั้งต่อด่านผ่าน `RemoteSeed.rules` เช่น ด่าน 39 (แก้ตาม Code Review)

## ข้อจำกัด

- PR และ review เก็บในหน่วยความจำของ session
- แก้ conflict ผ่านหน้าเว็บไม่ได้ (แก้ใน terminal)
- ไม่มี comment รายบรรทัดใน diff และไม่มี authentication / permission จำลอง
