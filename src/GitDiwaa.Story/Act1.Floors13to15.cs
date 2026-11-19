using GitDiwaa.Core.Game;
using static GitDiwaa.Core.Game.Line;

namespace GitDiwaa.Story;

public static partial class Act1
{
    private const UiPanel Everything = Dimensional | UiPanel.Archive;
    private const string GuardianNpc = "guardian";

    /// <summary>The Guardian maintains the Light Tome in the central archive.</summary>
    private static async Task<string> SeedLightTomeAsync(FloorContext ctx)
    {
        var url = await ctx.Author.CreateBareRemoteAsync("light-tome");
        await ctx.NpcGit(GuardianNpc, "clone", "-q", url, ".");
        await Lore.InscribeAsync(ctx, Page.Of("ก่อตั้งคัมภีร์แสงสว่าง", Lore.Guardian, "2023-01-01T09:00:00+07:00",
            ("README.txt", "คัมภีร์แสงสว่าง — ความรู้ร่วมของจอมเวททุกคน\n")), GuardianNpc);
        await Lore.InscribeAsync(ctx, Page.Of("เพิ่มเศษคัมภีร์ชิ้นที่ 10", Lore.Guardian, "2024-06-01T09:00:00+07:00",
            ("fragment-10.txt", Lore.Fragment(10).Lore + "\n")), GuardianNpc);
        await ctx.NpcGit(GuardianNpc, "push", "-q", "origin", "main");
        return url;
    }

    // ───────────── ชั้น 13 — คัมภีร์แสงสว่าง (git clone + git remote) ─────────────
    public static Floor Floor13 => new()
    {
        Number = 13,
        Title = "คัมภีร์แสงสว่าง",
        Hook = "เศษคัมภีร์ชิ้นที่ 10 ไม่ได้อยู่ในหอคอย — มันอยู่ในคัมภีร์แสงสว่างที่คลังเวทกลาง",
        Scene = "archive",
        Panels = Dimensional,
        Spells = Spells.F13,
        Guided = false,
        TimeLimitSeconds = 230,
        TargetCommands = 3,
        Setup = async ctx =>
        {
            await Lore.BlessAsync(ctx);
            await SeedLightTomeAsync(ctx);
            await ctx.Author.CreateBareRemoteAsync("light-tome-backup");
        },
        Intro =
        [
            Narrate("หน้าต่างชั้นสิบสามมองเห็นโดมแก้วของคลังเวทกลางอยู่ไกลลิบ"),
            Miura("คัมภีร์แสงสว่างอยู่ที่ https://archive.diwaa/light-tome.git"),
            Miura("นายไม่ต้องไปถึงที่นั่น — คัดลอกมันมาทั้งเล่มพร้อมประวัติได้เลย"),
        ],
        Objectives =
        [
            new()
            {
                Goal = "คัดลอกคัมภีร์แสงสว่างจากคลังเวทกลางมายังพื้นที่ของนาย",
                Hints = ["คาถาคัดลอกคัมภีร์คือ clone ตามด้วยที่อยู่", "git clone https://archive.diwaa/light-tome.git"],
                IsComplete = c => c.After.WorkspaceFiles.Any(f => f.StartsWith("light-tome/")),
                Unlocks = UiPanel.Archive,
                OnComplete = [Narrate("ลำแสงพุ่งจากโดมแก้วมาที่โต๊ะ ห้องใหม่ชื่อ light-tome ปรากฏขึ้น"), Miura("เดินเข้าไปในห้องนั้นก่อน (cd light-tome)")],
            },
            new()
            {
                Goal = "เข้าไปในห้อง light-tome แล้วตรวจสายเชื่อมของคัมภีร์ที่คัดลอกมา",
                Hints = ["cd light-tome ก่อน", "คาถาสายเชื่อมคือ remote ใส่ -v เพื่อดูที่อยู่", "git remote -v"],
                IsComplete = c => c.Cast("remote") && c.After.CurrentDirectory == "light-tome",
                OnComplete = [Miura("origin คือชื่อสายเชื่อมที่ clone สร้างให้อัตโนมัติ ชี้กลับไปยังคลังเวท")],
            },
            new()
            {
                Goal = "สร้างสายเชื่อมสำรองชื่อ backup ไปยัง https://archive.diwaa/light-tome-backup.git",
                Hints = ["remote มีคาถาย่อย add <ชื่อ> <ที่อยู่>", "git remote add backup https://archive.diwaa/light-tome-backup.git"],
                IsComplete = c => c.After.Remotes.Any(r => r.Name == "backup" && r.FetchUrl.EndsWith("light-tome-backup.git")),
                OnComplete = [Narrate("สายใยแสงเส้นที่สองเชื่อมคัมภีร์เข้ากับคลังสำรอง"), Miura("ส่วน set-url ใช้เปลี่ยนที่อยู่ remove ใช้ตัดสาย — ไว้ใช้ตอนเกิดเรื่อง")],
            },
        ],
        Reward = Lore.Fragment(10),
        Reflection = "git clone <url> คัดลอก repository พร้อมประวัติ • git remote -v ดู remote • git remote add <ชื่อ> <url> เพิ่ม remote",
        Ask = [new("clone ต่างจากดาวน์โหลดไฟล์ธรรมดายังไง?", [Miura("clone ได้ประวัติการจารึกทั้งหมด และสายเชื่อมกลับไปที่คลัง ทำให้ส่ง/รับความรู้ต่อได้")])],
        Solution = ["git clone https://archive.diwaa/light-tome.git", "cd light-tome", "git remote -v", "git remote add backup https://archive.diwaa/light-tome-backup.git"],
    };

    // ───────────── ชั้น 14 — ความรู้ใหม่จากคลัง (git pull) ─────────────
    public static Floor Floor14 => new()
    {
        Number = 14,
        Title = "ความรู้ใหม่จากคลัง",
        Hook = "ผู้พิทักษ์คลังเวทเพิ่งจารึกเศษคัมภีร์ชิ้นที่ 11 ลงคัมภีร์แสงสว่าง — แต่สำเนาของนายยังเก่าอยู่",
        Scene = "archive",
        Panels = Everything,
        Spells = Spells.F14,
        Guided = false,
        TimeLimitSeconds = 40,
        TargetCommands = 1,
        Setup = async ctx =>
        {
            await Lore.BlessAsync(ctx);
            var url = await SeedLightTomeAsync(ctx);
            await ctx.Git("clone", "-q", url, "light-tome");
            ctx.Session.ChangeDirectory("light-tome");
            await Lore.InscribeAsync(ctx, Page.Of("เพิ่มเศษคัมภีร์ชิ้นที่ 11", Lore.Guardian, "2025-02-01T09:00:00+07:00",
                ("fragment-11.txt", Lore.Fragment(11).Lore + "\n")), GuardianNpc);
            await ctx.NpcGit(GuardianNpc, "push", "-q");
        },
        Intro =
        [
            Narrate("เสียงระฆังดังมาจากโดมแก้ว — สัญญาณว่าคลังเวทมีจารึกใหม่"),
            Miura("ผู้พิทักษ์จารึกอะไรบางอย่างเพิ่ม! คัมภีร์ของนายไม่อัปเดตเอง ต้องเรียกความรู้ลงมา"),
        ],
        Objectives =
        [
            new()
            {
                Goal = "เรียกความรู้ล่าสุดจากคลังเวทกลางลงมาในคัมภีร์ของนาย",
                Hints = ["คาถาเรียกความรู้คือ pull", "git pull"],
                IsComplete = c => c.After.WorkspaceFiles.Contains("fragment-11.txt"),
                OnComplete = [Narrate("ความรู้ไหลจากโดมแก้วลงสู่คัมภีร์ของนาย fragment-11.txt ปรากฏบนโต๊ะ")],
            },
        ],
        Reward = Lore.Fragment(11),
        Reflection = "git pull = git fetch (ดึงข้อมูล) + git merge (รวมเข้า branch ปัจจุบัน)",
        Ask = [new("fetch กับ pull ต่างกันยังไง?", [Miura("fetch แค่ส่องดูว่าคลังมีอะไรใหม่ (origin/main ขยับ) แต่ยังไม่รวม pull ส่องแล้วรวมเข้ามาเลย")])],
        Solution = ["git pull"],
    };

    // ───────────── ชั้น 15 — ประตูสู่คลังเวทกลาง (git push) ─────────────
    public static Floor Floor15 => new()
    {
        Number = 15,
        Title = "ประตูสู่คลังเวทกลาง",
        Hook = "ยอดหอคอยมีประตูเวทเชื่อมไปยังคลังเวทกลาง — มันจะเปิดให้เฉพาะผู้ที่ส่งคัมภีร์ของตนเข้าคลังแล้วเท่านั้น",
        Scene = "summit",
        Panels = Everything,
        Spells = Spells.F15,
        Guided = false,
        TimeLimitSeconds = 110,
        TargetCommands = 2,
        Setup = async ctx =>
        {
            await SeedFragmentsAsync(ctx, 11);
            await ctx.Author.CreateBareRemoteAsync("apprentice-tome");
        },
        Intro =
        [
            Narrate("ยอดหอคอย ลมแรง ประตูเวทวงกลมหมุนช้า ๆ อยู่กลางอากาศ"),
            Miura("ที่อยู่ในคลังของนายเตรียมไว้แล้ว: https://archive.diwaa/apprentice-tome.git"),
            Miura("ต่อสายเชื่อมชื่อ origin แล้วส่งคัมภีร์ของนายผ่านประตูไป"),
        ],
        Objectives =
        [
            new()
            {
                Goal = "สร้างสายเชื่อมชื่อ origin ไปยังที่อยู่ในคลังของนาย",
                Hints = ["git remote add <ชื่อ> <ที่อยู่>", "git remote add origin https://archive.diwaa/apprentice-tome.git"],
                IsComplete = c => c.After.Remotes.Any(r => r.Name == "origin" && r.FetchUrl.EndsWith("apprentice-tome.git")),
            },
            new()
            {
                Goal = "ส่งคัมภีร์เข้าคลังเป็นครั้งแรก พร้อมผูก main เข้ากับ origin/main",
                Hints = ["คาถาส่งผ่านประตูคือ push", "ครั้งแรกต้องผูกเส้นทางด้วย -u (upstream)", "git push -u origin main"],
                IsComplete = c => c.After.FindBranch("main")?.Upstream == "origin/main" &&
                    c.After.FindBranch("origin/main")?.CommitId == c.After.HeadCommitId,
                OnComplete =
                [
                    Narrate("เศษคัมภีร์ทั้งหมดของนายบินวนเป็นเกลียว แล้วพุ่งเข้าประตูเวท"),
                    Narrate("ประตูหยุดหมุน… และเปิดออก"),
                ],
            },
        ],
        Outro =
        [
            Miura("ครั้งต่อไปแค่ git push ก็พอ เพราะเส้นทางผูกไว้แล้ว"),
            Miura("…ฉันไปได้แค่ตรงนี้ หลังประตูคือคลังเวทกลาง ผู้พิทักษ์จะดูแลนายต่อ"),
            Player("มิวรา… ขอบคุณนะ"),
            Miura("อย่าลืมกินข้าวด้วยล่ะ ศิษย์ฝึกหัด"),
            Narrate("— จบ Act 1: หอคอยเวทมนตร์ — เศษคัมภีร์ 12/16 —"),
        ],
        Reward = Lore.Fragment(12),
        Reflection = "git push -u origin main ส่ง commit ขึ้น remote และตั้ง upstream • ครั้งต่อไปใช้ git push ได้เลย",
        Ask = [new("ถ้าคลังมีจารึกใหม่ที่เรายังไม่มีล่ะ?", [Miura("ประตูจะปฏิเสธ (rejected) นายต้อง pull ก่อนแล้วค่อย push — เดี๋ยวได้เจอใน Act ถัดไป")])],
        Solution = ["git remote add origin https://archive.diwaa/apprentice-tome.git", "git push -u origin main"],
    };
}
