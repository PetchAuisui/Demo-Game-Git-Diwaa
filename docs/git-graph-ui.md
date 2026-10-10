# Git Graph ใน Godot

กราฟรับ `GitRepositorySnapshot` จาก sandbox ผ่าน `SetSnapshot` และแสดงความสัมพันธ์จาก `ParentIds` ของ commit จริง แสดงสีแต่ละ lane, HEAD สีทอง, hash ย่อ และชื่อ branch

- คลิกแถว commit หรือใช้ปุ่มขึ้น/ลงเมื่อกราฟมี focus เพื่อดูผู้เขียน เวลา และข้อความ commit ด้านล่าง
- เลื่อนในกราฟเพื่อดูประวัติที่ยาวหรือมีหลาย lane
- วางเมาส์บนรายละเอียดเพื่อดู hash เต็มและ parent hashes
- repository ที่ยังไม่มี commit แสดงคำแนะนำเริ่มต้น

## ส่วนประกอบ

- `CommitGraphLayout`: เรียง child ก่อน parent และคำนวณ lane/edges
- `CommitGraphCanvas`: วาดกราฟและรับการเลือก
- `GitGraphPanel`: จัดกราฟและรายละเอียด
- `SandboxGameView`: ส่ง snapshot หลัง refresh repository

## เปิดตรวจตัวอย่าง

Build Godot C# แล้วเปิด `Scenes/GitGraphPreview.tscn` และ Run Current Scene (F6) ตัวอย่างประกอบด้วย merge สอง parents, feature branch และ HEAD พร้อมตรวจ ancestry, lane split, keyboard selection และการเปลี่ยนผ่าน empty state เมื่อเริ่ม scene

```sh
dotnet build src/GitDiwaa.Godot/GitDiwaa.Godot.csproj --no-restore --disable-build-servers -m:1
```

Preview ใช้ข้อมูลตัวอย่างและไม่เขียน repository ของผู้เล่น การตรวจนี้ไม่ครอบคลุมประวัติ Git ทุกรูปแบบ โดย snapshot ปัจจุบันมีขีดจำกัด 200 commits และ parent ที่อยู่นอก snapshot จะไม่มีเส้นปลายทาง กราฟยังไม่มี zoom หรือการแก้ไข branch จากหน้าจอ
