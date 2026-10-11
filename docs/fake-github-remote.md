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
- ยังไม่ต่อกับหน้า Godot (ทำในรอบ UI ของ Sandbox)
