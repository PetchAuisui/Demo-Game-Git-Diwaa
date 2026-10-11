# สถานะระบบ Git รุ่นแรก

บันทึก ณ 1 ตุลาคม 2026 สำหรับรอบพัฒนา `feat/git-engine`

## ขอบเขตที่พร้อมนำเข้า main

มี Core contracts, Real Git adapter, Terminal CLI และ integration tests โดยยังไม่มี Godot UI ระบบเรียก Git ที่ติดตั้งในเครื่องและสร้างพื้นที่ฝึกแยกต่อ attempt

ผลตรวจล่าสุดก่อนการปรับเอกสาร: build ผ่าน 0 warnings / 0 errors และ integration tests ผ่าน 10/10 กลุ่มสถานการณ์ ผลนี้ยืนยันเฉพาะกรณีที่ทดสอบ ไม่ได้หมายความว่าทุกคำสั่ง ทุก option หรือทุกระบบปฏิบัติการได้รับการตรวจครบแล้ว

## หลักฐานจากชุดทดสอบปัจจุบัน

อ้างอิง `tests/GitDiwaa.RealGit.Tests/Program.cs`

| กลุ่ม | สิ่งที่ตรวจแล้ว |
|---|---|
| Session | เริ่มต้นโดยยังไม่มี repository และตรวจข้อมูล session |
| Version/config | เรียก Git จริง ตั้งและอ่านชื่อ/อีเมลผ่าน config ของ attempt |
| Command policy | ปฏิเสธคำสั่งบางชนิด การออกนอก path และ remote ที่ไม่ได้ลงทะเบียน |
| Repository state | init, สร้างไฟล์, add, commit และตรวจ typed snapshot |
| Branch/graph | switch, สร้าง branch และ merge ที่มีสอง parent |
| ย้อนการเปลี่ยนแปลง | diff, restore และ reset --hard |
| Remote | push, fetch และ pull จาก local bare remote ของ session |
| Clone | clone local bare remote ว่าง |
| File API | ปฏิเสธ path traversal และการเขียน .git/config |
| Attempt validation | ปฏิเสธ identifier ไม่ถูกต้องและ attempt ที่มีข้อมูลอยู่แล้ว |

## ข้อจำกัดที่ต้องทราบ

- Command policy เปิดใช้เฉพาะบางรูปแบบ เช่น `git status` ใช้ได้ แต่ `git status -s` ยังไม่รองรับ
- ยังไม่เปิด `stash`, `tag`, `revert`, `cherry-pick`, `checkout` และ `rebase` แบบสั่งตรง
- `commit --amend`, `pull --rebase`, force push, `merge --abort`, reset แบบ soft/mixed และการแก้ conflict ยังไม่มี tests ครอบคลุมครบวงจร
- Clone ยังไม่ได้ทดสอบกับ remote ที่มีไฟล์และประวัติอยู่ก่อน
- แต่ละ session มี remote ของตัวเอง ยังไม่มี API เตรียม remote ร่วมสำหรับผู้เล่นและ NPC
- CLI ถามข้อความให้เมื่อพิมพ์ `git commit` เปล่า ส่วน Godot ต้องสร้างขั้นตอนรับข้อความและส่ง `commit -m` เอง
- Terminal มี `write`, `cat`, `delete`, `files` แต่ยังไม่มี `touch`, `mkdir`, `ls` หรือ `cd`
- เปิด CLI แต่ละครั้งสร้าง attempt ใหม่ ยังไม่มีขั้นตอนเปิด session เดิม ข้อมูลบนดิสก์ไม่ได้ถูกลบเมื่อ dispose
- Snapshot จำกัดประวัติไว้ 200 commits และยังต้องทดสอบ parser กับชื่อไฟล์/ข้อความพิเศษเพิ่มเติม
- การแยก workspace เป็นการป้องกันในระดับแอป ยังต้องตรวจ environment ที่ process สืบทอด, symbolic links และกรณีหลบข้อจำกัดเพิ่มเติมก่อนเผยแพร่เกม
- Core/RealGit ใช้ `net10.0`; การต่อ Godot ต้องตรวจ target framework และแหล่ง NuGet ให้เข้ากันก่อน

## ลำดับงานหลัง merge

1. เพิ่ม integration tests ของคำสั่งที่เปิดใช้อยู่: conflict/resolve/abort, amend, reset soft/mixed, force push และ pull --rebase พร้อมแก้ปัญหาที่พบ ตรวจ environment isolation และ path handling ในรอบนี้ด้วย
2. เพิ่มการเตรียม remote ที่มีประวัติและ API สำหรับผู้เล่น/NPC ใช้ remote ร่วมกัน ทดสอบ clone ที่มีข้อมูลและกรณี push ถูกปฏิเสธเมื่อ remote มีงานใหม่
3. เพิ่มคำสั่งไฟล์ใน Terminal เกม เช่น touch/mkdir/ls และกำหนดพฤติกรรม current directory ก่อนเพิ่ม cd
4. เชื่อม Godot C#: รับคำสั่งทีละรายการ แสดงผล Terminal และ refresh Files/Branches/Commit Graph จาก session API

แต่ละรอบควรแยก feature branch และ commit ตามงานที่ตรวจสอบได้ ไม่ถือว่ารายการในแผนนี้พัฒนาเสร็จแล้ว

## GitHub จำลอง (feature/github-remote-simulator)

รายละเอียดอยู่ใน `docs/fake-github-remote.md`

- remote เริ่มต้นเป็น repo ว่าง `https://github.com/user/my-project.git` (เจ้าของ `user`, กำหนดผ่าน `playerName` ของ factory) ไม่มีข้อมูลตัวอย่างในโค้ดจริง; `RemoteSeed` ใช้ตั้งประวัติเริ่มต้นต่อด่านได้
- URL GitHub จริงถูกปฏิเสธโดย command policy (clone / remote add / remote set-url) และข้อความบอก URL ที่อนุญาต
- `RemoteHost` รองรับ: branches (ahead/behind), commits, ไฟล์/โฟลเดอร์, ลบ branch, สร้าง PR, diff/commits/ไฟล์ที่เปลี่ยน, review, ตรวจ conflict ก่อน merge, ปิด PR, ดู PR ที่ merge แล้วย้อนหลัง
- กติกา PR ปรับได้ด้วย `RemoteRules` (ค่าเริ่มต้นเหมาะกับ sandbox คนเดียว: review เป็นทางเลือก รีวิว PR ตัวเองได้)
- ข้อจำกัด: PR เก็บในหน่วยความจำ ไม่มี comment รายบรรทัด แก้ conflict ผ่านหน้าเว็บไม่ได้ (ต้องแก้ใน terminal) และยังไม่ต่อกับ Godot UI (ทำในรอบ UI ของ Sandbox)
- ผลทดสอบ: integration tests 19/19
