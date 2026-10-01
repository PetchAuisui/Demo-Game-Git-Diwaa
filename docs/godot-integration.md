# แนวทางเชื่อม Godot C# ในรอบถัดไป

รอบปัจจุบันยังไม่สร้าง Godot project หรือ UI แต่ Core API ถูกแยกไว้เพื่อให้ Godot เป็นเพียง host อีกตัวหนึ่งเหมือน CLI

## Project references

Godot C# project ควรอ้างอิง:

```xml
<ItemGroup>
  <ProjectReference Include="../GitDiwaa.Core/GitDiwaa.Core.csproj" />
  <ProjectReference Include="../GitDiwaa.RealGit/GitDiwaa.RealGit.csproj" />
</ItemGroup>
```

## Lifecycle ที่แนะนำ

1. เมื่อเริ่มด่าน ใช้ `ProjectSettings.GlobalizePath("user://git-workspaces")` เป็น workspace root
2. สร้าง factory หนึ่งตัว และสร้าง session ใหม่ต่อ attempt
3. ส่งข้อความจาก Terminal UI เข้า `ExecuteAsync`
4. แสดง `GitCommandResult.Output`
5. เรียก `InspectAsync` หลังคำสั่งเพื่อ refresh Files, Branches และ Commit Graph
6. dispose session เมื่อออกจากด่าน

ตัวอย่าง C# เชิงโครงสร้าง:

```csharp
var root = ProjectSettings.GlobalizePath("user://git-workspaces");
IGitGameSessionFactory factory = new RealGitGameSessionFactory(root);
await using var session = await factory.CreateAsync(levelId, attemptId);

var result = await session.ExecuteAsync(commandFromTerminal);
var snapshot = await session.InspectAsync();
```

Godot layer ไม่ควรเรียก `System.Diagnostics.Process` หรือ parse `git log` เอง เพื่อให้ command policy, timeout, isolation และ parsing อยู่ที่ Real Git adapter จุดเดียว

## งานที่ยังไม่รวม

- Godot scenes/nodes/signals
- mission validator และ multi-step objective
- score, timer, streak, stars และ rewards
- save game และ migration
- การ render commit graph
- online remote/authentication

เมื่อเริ่มพัฒนา UI ควรสร้าง adapter สำหรับแปลง `GitRepositorySnapshot` เป็น view model ของแต่ละ panel แทนการผูก Node เข้ากับ record โดยตรง
