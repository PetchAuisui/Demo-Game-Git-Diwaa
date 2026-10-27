# สถานะระบบ Git และ Godot Workspace

บันทึก ณ 4 ตุลาคม 2026

## ขอบเขตที่พร้อมนำเข้า main

มี Core contracts, Real Git adapter, Terminal CLI, Godot Sandbox UI และ integration tests ทั้งหมดเขียนด้วย GDScript ระบบเรียก Git ที่ติดตั้งในเครื่องและสร้างพื้นที่ฝึกแยกต่อ attempt

ผลตรวจล่าสุด: integration tests ผ่าน 24/24 กลุ่มสถานการณ์ และ Godot 4.7.2 โหลดทุก scene/script แบบ headless ได้โดยไม่มี error ผลนี้ยืนยันเฉพาะกรณีที่ทดสอบ ไม่ได้หมายความว่าทุกคำสั่ง ทุก option หรือทุกระบบปฏิบัติการได้รับการตรวจครบแล้ว

## หลักฐานจากชุดทดสอบปัจจุบัน

อ้างอิง `tests/engine/run_tests.gd`

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
| Workspace API | สร้าง/list โฟลเดอร์, rename ไฟล์, ลบ recursive และป้องกัน path ที่ไม่ปลอดภัย |
| Attempt validation | ปฏิเสธ identifier ไม่ถูกต้องและ attempt ที่มีข้อมูลอยู่แล้ว |

## ข้อจำกัดที่ต้องทราบ

- Command policy เปิดใช้เฉพาะบางรูปแบบ เช่น `git status` ใช้ได้ แต่ `git status -s` ยังไม่รองรับ
- ยังไม่เปิด `stash`, `tag`, `revert`, `cherry-pick`, `checkout` และ `rebase` แบบสั่งตรง
- `commit --amend`, `pull --rebase`, force push, `merge --abort`, reset แบบ soft/mixed และการแก้ conflict ยังไม่มี tests ครอบคลุมครบวงจร
- Clone ยังไม่ได้ทดสอบกับ remote ที่มีไฟล์และประวัติอยู่ก่อน
- แต่ละ session มี remote ของตัวเอง ยังไม่มี API เตรียม remote ร่วมสำหรับผู้เล่นและ NPC
- CLI ถามข้อความให้เมื่อพิมพ์ `git commit` เปล่า ส่วน Godot ต้องสร้างขั้นตอนรับข้อความและส่ง `commit -m` เอง
- Terminal มี `write`, `cat`, `delete`, `files` แต่ยังไม่มี `touch`, `mkdir`, `ls` หรือ `cd`; การจัดการโฟลเดอร์ทำผ่าน Files/Workspace UI ได้แล้ว
- เปิด CLI แต่ละครั้งสร้าง attempt ใหม่ ยังไม่มีขั้นตอนเปิด session เดิม ข้อมูลบนดิสก์ไม่ได้ถูกลบเมื่อ dispose
- Snapshot จำกัดประวัติไว้ 200 commits และยังต้องทดสอบ parser กับชื่อไฟล์/ข้อความพิเศษเพิ่มเติม
- การแยก workspace เป็นการป้องกันในระดับแอป ยังต้องตรวจ environment ที่ process สืบทอด, symbolic links และกรณีหลบข้อจำกัดเพิ่มเติมก่อนเผยแพร่เกม
- Empty directory ไม่สร้างการเปลี่ยนแปลงใน Git จนกว่าจะมีไฟล์ภายใน ซึ่งเป็นพฤติกรรมปกติของ Git
- Editor เป็น text editor สำหรับ UTF-8 text files; ยังไม่มี binary preview, syntax profile ตามนามสกุล, search/replace หรือ multi-tab

## ลำดับงานหลัง merge

1. เพิ่ม integration tests ของคำสั่งที่เปิดใช้อยู่: conflict/resolve/abort, amend, reset soft/mixed, force push และ pull --rebase พร้อมแก้ปัญหาที่พบ ตรวจ environment isolation และ path handling ในรอบนี้ด้วย
2. เพิ่มการเตรียม remote ที่มีประวัติและ API สำหรับผู้เล่น/NPC ใช้ remote ร่วมกัน ทดสอบ clone ที่มีข้อมูลและกรณี push ถูกปฏิเสธเมื่อ remote มีงานใหม่
3. เพิ่มคำสั่งไฟล์ใน Terminal เกม เช่น touch/mkdir/ls และกำหนดพฤติกรรม current directory ก่อนเพิ่ม cd
4. เพิ่ม syntax profile, search/replace และ multi-tab ให้ text editor เมื่อ gameplay ต้องใช้ไฟล์หลายไฟล์พร้อมกัน

แต่ละรอบควรแยก feature branch และ commit ตามงานที่ตรวจสอบได้ ไม่ถือว่ารายการในแผนนี้พัฒนาเสร็จแล้ว

## GitHub จำลอง (feature/github-remote-simulator)

รายละเอียดอยู่ใน `docs/simulated-github-remote.md`

- บัญชีเริ่มต้นไม่มี repo (เจ้าของ `user`, กำหนดผ่าน `player_name` ของ factory) `create(mission_id, attempt_id)` ใช้ `RemoteSeed.no_repository()`; ส่ง `RemoteSeed.empty()` หรือ seed ของด่านถ้าต้องการ repo `https://magic-vault.com/user/my-project.git` ตั้งต้น ไม่มีข้อมูลตัวอย่างในโค้ดจริง; `RemoteSeed` ใช้ตั้งประวัติเริ่มต้นต่อด่านได้
- URL GitHub จริงถูกปฏิเสธโดย command policy (clone / remote add / remote set-url) และข้อความบอก URL ที่อนุญาต
- `RemoteHost` รองรับ: branches (ahead/behind), commits, ไฟล์/โฟลเดอร์, ลบ branch, สร้าง PR, diff/commits/ไฟล์ที่เปลี่ยน, review, ตรวจ conflict ก่อน merge, ปิด PR, ดู PR ที่ merge แล้วย้อนหลัง
- กติกา PR ปรับได้ด้วย `RemoteRules` (ค่าเริ่มต้นเหมาะกับ sandbox คนเดียว: review เป็นทางเลือก รีวิว PR ตัวเองได้)
- ข้อจำกัด: PR เก็บในหน่วยความจำ ไม่มี comment รายบรรทัด และแก้ conflict ผ่านหน้าเว็บไม่ได้ (ต้องแก้ใน terminal)
- ผลทดสอบ: integration tests 20/20 (รวมเทสต์ workspace จาก main)

### หน้า Remote Repository ใน Sandbox (feature/sandbox-repo-button)

- ปุ่ม Remote Repo (ไอคอนก้อนเมฆ) ที่หัวพาเนล Git Graph ของ Sandbox (ไม่อยู่ที่แถบบน) เปิด `RemoteRepoView` หน้าตาเลียนแบบ GitHub dark: Quick setup เมื่อ repo ว่าง, Code (ตารางไฟล์, README Markdown, Go to file, เมนู Clone), Commits, Branches, Pull requests (รายการ, เปิด PR, Conversation / Commits / Files changed, review, merge) พร้อมแถบ URL และกด Esc เพื่อกลับ
- `GitSandboxService.remote_host` ส่ง GitHub จำลองของ session ให้หน้า UI (mock service ไม่มี จึงกดปุ่มไม่ได้) และ `RealGitSandboxService` ใช้ชื่อผู้เล่นเป็นเจ้าของ repo (ยังเป็นค่าคงที่ `user` เพราะยังไม่มีหน้า login)
- ตรวจ flow ในเกมจริงด้วยสคริปต์ที่พิมพ์คำสั่งผ่าน terminal ของ Sandbox แล้วเปิดหน้า repo, สร้าง PR, review, ดู diff, merge และกด Esc (ยังไม่มีเทสต์อัตโนมัติฝั่ง UI)

### ปรับ UX/UI หน้า Remote Repository (feature/remote-repo-ui-polish)

- ขยายตัวอักษรและช่องไฟทั้งหน้า (`GitHubTheme.UI_SCALE`) ให้อ่านง่ายเท่า UI ส่วนอื่นของเกม, แยกสีเป็นชั้น (INSET/CANVAS/SURFACE/SURFACE_RAISED) ให้ตัดกันชัด และจัดเนื้อหากึ่งกลางกว้างไม่เกินที่กำหนด
- Quick setup เป็นขั้นตอน 1-2-3: คำแนะนำวิธีใช้อยู่บนสุด, คลิกคำสั่งเพื่อคัดลอก (ย้อมสี มีคำอธิบายข้างบรรทัด)
- แถบบนมีป้าย Esc ปุ่มรีเฟรช และป้าย "Magic Vault"; หน้า PR วางเลข #N ต่อท้ายชื่อ และฟอร์มเปิด PR เติม Title จาก commit ล่าสุด; หน้า Branches แสดง ahead/behind เป็นชิป
- ตรวจด้วยสคริปต์ที่จับภาพทุกหน้า (repo ว่าง, Code, ไฟล์, Commits, Branches, PR ทุกแท็บ, merge) ผ่านทั้ง flow
