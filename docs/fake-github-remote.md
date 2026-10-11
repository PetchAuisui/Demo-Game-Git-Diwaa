# GitHub จำลอง (Fake GitHub Remote)

เป้าหมาย: คำสั่ง `git clone/fetch/pull/push` ในเกมต้องไม่ออกไปถึง GitHub จริง แต่ผู้เล่นยังเห็น URL และหน้า Remote Repository เหมือน GitHub

## ที่มาของสเปก

**Notion (โครงสร้างของเกมส์)**
- ด่าน 13/34/35/36 ใช้ `git clone <url>`, `git remote -v`, `git remote add|set-url|remove` และตรวจว่า `origin` ชี้ไป URL ที่ด่านกำหนด
- ด่าน 37 ต้องมี remote ที่มี commit ใหม่กว่า local เพื่อให้ push ถูกปฏิเสธ
- ด่าน 38-40 ใช้ push feature branch, review และ merge
- การตรวจผ่านดู "สถานะ Repository" ไม่ใช่ข้อความคำสั่ง
- งานหน้า Remote Repository: หน้ารวม, หน้า code, หน้า branch ทั้งหมด, หน้า pull request ที่ Review และ Merge ได้

**Figma (game-based-git-learning, frame "Html → Body")**
- หัวเรื่อง `<owner> / <repo>` เช่น `Preeyaporn / Khamphi_Projects_one`
- แท็บ Code / Pull requests
- แถบ branch selector + จำนวน branch, ช่องค้นหาไฟล์, ปุ่ม Add file, ปุ่มเขียว Code (clone URL)
- แถว commit ล่าสุด (ผู้เขียน, ข้อความ, hash สั้น, เวลา, จำนวน commits)
- ตารางไฟล์พร้อม commit message ล่าสุดของแต่ละไฟล์ และ README render ด้านล่าง

## แนวทาง

1. URL ที่ผู้เล่นเห็นเป็น URL สมมติรูปแบบ GitHub ต่อด่าน แต่ถูก rewrite (`url.<bare>.insteadOf`) ไปยัง bare repository ในโฟลเดอร์ session เท่านั้น
2. Policy ยอมรับเฉพาะ URL ที่ลงทะเบียนไว้ URL ของ GitHub จริงถูกปฏิเสธ
3. `IGitRemoteHost` ให้ข้อมูลที่ UI Figma ต้องใช้ (repo, branches, commits, files, README, pull requests) โดยอ่านจาก bare repository จริง
4. Pull request เก็บสถานะในหน่วยความจำของ session ส่วน merge ทำด้วย Git จริงแล้ว push เข้า bare remote
5. Seed ประวัติเริ่มต้นได้ต่อด่าน (`RemoteSeed`) เพื่อสร้างสถานการณ์ เช่น remote นำหน้า local

## นอกขอบเขตรอบนี้

- การเชื่อมหน้า Godot (ทำในรอบ UI)
- Authentication / permission จำลอง
- Review comment แบบ thread
