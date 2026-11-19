using GitDiwaa.Core.Game;
using static GitDiwaa.Core.Game.Line;

namespace GitDiwaa.Story;

public static partial class Act1
{
    private const UiPanel Dimensional = Study | UiPanel.Dimensions;

    private static async Task SeedFragmentsAsync(FloorContext ctx, int upTo)
    {
        await Lore.BlessAsync(ctx);
        await ctx.Git("init", "-q");
        for (var n = Math.Max(1, upTo - 2); n <= upTo; n++)
        {
            await Lore.InscribeAsync(ctx, Page.Of($"จารึกเศษคัมภีร์ชิ้นที่ {n}", ctx.PlayerName,
                $"2025-01-{n:00}T09:00:00+07:00", ($"fragment-{n}.txt", Lore.Fragment(n).Lore + "\n")));
        }
    }

    // ───────────── ชั้น 10 — รอยแยกมิติ (git branch) ─────────────
    public static Floor Floor10 => new()
    {
        Number = 10,
        Title = "รอยแยกมิติ",
        Hook = "อากาศในห้องบิดเป็นรอยแยก — มีมิติผีค้างอยู่ และมิวราอยากให้นายเปิดมิติทดลองของตัวเอง",
        Scene = "rift",
        Panels = Study,
        Spells = Spells.F10,
        Guided = false,
        TimeLimitSeconds = 105,
        TargetCommands = 3,
        Setup = async ctx =>
        {
            await SeedFragmentsAsync(ctx, 6);
            await ctx.Git("branch", "phantom");
        },
        Intro =
        [
            Narrate("กลางห้องมีรอยแยกในอากาศ เห็นภาพห้องเดียวกันซ้อนอยู่ข้างใน"),
            Miura("คัมภีร์มีหลายเส้นเวลาได้ — เราเรียกว่า 'มิติ' นายทดลองในมิติอื่นได้โดยไม่ทำให้มิติหลักพัง"),
        ],
        Objectives =
        [
            new()
            {
                Goal = "สำรวจว่าคัมภีร์นี้มีมิติอะไรอยู่บ้าง",
                Hints = ["คาถาแยกมิติถ้าร่ายเฉย ๆ จะแสดงรายชื่อมิติ", "git branch"],
                IsComplete = c => c.Cast("branch") && c.Input.Split(' ', StringSplitOptions.RemoveEmptyEntries).Skip(2).All(a => a.StartsWith('-') && a is not ("-d" or "-D")),
                Unlocks = UiPanel.Dimensions,
                OnComplete = [Miura("ดอกจัน * คือมิติที่นายยืนอยู่ ส่วน phantom… มิติผีที่ไม่มีใครใช้แล้ว")],
            },
            new()
            {
                Goal = "เปิดมิติทดลองใหม่ชื่อ experiment",
                Hints = ["ร่ายคาถาแยกมิติตามด้วยชื่อ", "git branch experiment"],
                IsComplete = c => c.After.FindBranch("experiment") is not null,
                OnComplete = [Narrate("รอยแยกใหม่เปิดออก เรืองแสงสีฟ้า"), Miura("สังเกตนะ นายยังยืนอยู่ใน main — การสร้างมิติไม่ได้พานายเข้าไป")],
            },
            new()
            {
                Goal = "ปิดมิติผี phantom",
                Hints = ["คาถาแยกมิติมีตัวเลือกสำหรับลบ", "-d (delete)", "git branch -d phantom"],
                IsComplete = c => c.After.FindBranch("phantom") is null && c.After.FindBranch("experiment") is not null,
                OnComplete = [Narrate("มิติผีหดตัวหายไป… และสิ่งที่มันกักไว้ก็หล่นลงมาบนโต๊ะ")],
                WorldEvent = async ctx =>
                {
                    await ctx.Files.WriteAllTextAsync("fragment-7.txt", Lore.Fragment(7).Lore + "\n");
                    await ctx.Git("add", "fragment-7.txt");
                    await ctx.CommitAs(ctx.PlayerName, "จารึกเศษคัมภีร์ชิ้นที่ 7");
                },
            },
        ],
        Reward = Lore.Fragment(7),
        Reflection = "git branch แสดงรายการ • git branch <ชื่อ> สร้าง branch • git branch -d <ชื่อ> ลบ branch ที่รวมแล้ว",
        Ask = [new("-d กับ -D ต่างกันยังไง?", [Miura("-d ปิดได้เฉพาะมิติที่ถูกหลอมแล้ว -D บังคับปิดแม้งานข้างในจะหาย — อันตราย")])],
        Solution = ["git branch", "git branch experiment", "git branch -d phantom"],
    };

    // ───────────── ชั้น 11 — ประตูมิติ (git switch) ─────────────
    public static Floor Floor11 => new()
    {
        Number = 11,
        Title = "ประตูมิติ",
        Hook = "เศษคัมภีร์ชิ้นที่ 8 ปรากฏได้เฉพาะในมิติทดลองเท่านั้น",
        Scene = "rift",
        Panels = Dimensional,
        Spells = Spells.F11,
        Guided = false,
        TimeLimitSeconds = 80,
        TargetCommands = 5,
        Setup = async ctx =>
        {
            await SeedFragmentsAsync(ctx, 7);
            await ctx.Git("branch", "experiment");
        },
        Intro =
        [
            Narrate("รอยแยกสีฟ้าของมิติ experiment ยังเปิดอยู่"),
            Miura("ได้ยินไหม… มีเสียงเรียกจากอีกฝั่ง เศษคัมภีร์ชิ้นต่อไปอยู่ในนั้น"),
        ],
        Objectives =
        [
            new()
            {
                Goal = "ก้าวผ่านประตูเข้าสู่มิติ experiment",
                Hints = ["คาถาประตูมิติคือ switch", "git switch experiment"],
                IsComplete = c => c.After.CurrentBranch == "experiment",
                OnComplete = [Narrate("โลกรอบตัวกระพริบเป็นสีฟ้า… กระดาษแผ่นใหม่ค่อย ๆ ก่อตัวบนโต๊ะ")],
                WorldEvent = ctx => ctx.Files.WriteAllTextAsync("fragment-8.txt", Lore.Fragment(8).Lore + "\n"),
            },
            new()
            {
                Goal = "จารึก fragment-8.txt ในมิติทดลองนี้",
                Hints = ["add แล้ว commit ตามปกติ — การจารึกจะอยู่ในมิติที่นายยืนอยู่", "git add fragment-8.txt  แล้ว  git commit -m \"เศษคัมภีร์ชิ้นที่ 8\""],
                IsComplete = c => c.After.CurrentBranch == "experiment" && c.After.IsTracked("fragment-8.txt") && c.After.IsClean,
            },
            new()
            {
                Goal = "กลับสู่มิติหลัก main แล้วดูว่าเศษคัมภีร์ชิ้นที่ 8 เป็นอย่างไร",
                Hints = ["git switch main"],
                IsComplete = c => c.After.CurrentBranch == "main",
                OnComplete =
                [
                    Player("มันหายไปแล้ว!?"),
                    Miura("ไม่ได้หาย มันอยู่ในมิติ experiment — แต่ละมิติมีโลกของตัวเอง"),
                ],
            },
            new()
            {
                Goal = "สร้างและก้าวเข้ามิติใหม่ชื่อ trial ในคาถาเดียว",
                Hints = ["switch มีตัวเลือกสำหรับ 'สร้าง' (create)", "git switch -c trial"],
                IsComplete = c => c.After.CurrentBranch == "trial" && c.Before.FindBranch("trial") is null,
                OnComplete = [Miura("switch -c = branch + switch ในคาถาเดียว นักเวทขี้เกียจชอบใช้")],
            },
        ],
        Reward = Lore.Fragment(8),
        Reflection = "git switch <branch> ย้ายไป branch อื่น (ไฟล์เปลี่ยนตาม) • git switch -c <ใหม่> สร้างแล้วย้ายทันที",
        Ask = [new("ทำไมไม่ใช้ git checkout?", [Miura("checkout เป็นคาถารุ่นเก่าที่ทำหลายอย่างปนกัน Git สมัยใหม่แยกเป็น switch (มิติ) กับ restore (ฟื้นคืน)")])],
        Solution = ["git switch experiment", "git add fragment-8.txt", "git commit -m \"เศษคัมภีร์ชิ้นที่ 8\"", "git switch main", "git switch -c trial"],
    };

    // ───────────── ชั้น 12 — พิธีหลอมมิติ (git merge) ─────────────
    public static Floor Floor12 => new()
    {
        Number = 12,
        Title = "พิธีหลอมมิติ",
        Hook = "สองมิติจารึกอักขระแกนกลางของเศษคัมภีร์ชิ้นที่ 9 ต่างกัน — ไฟในมิติหนึ่ง น้ำแข็งในอีกมิติ",
        Scene = "rift",
        Panels = Dimensional,
        Spells = Spells.F12,
        Guided = false,
        TimeLimitSeconds = 75,
        TargetCommands = 3,
        Setup = async ctx =>
        {
            await SeedFragmentsAsync(ctx, 8);
            await Lore.InscribeAsync(ctx, Page.Of("วางแกนเศษคัมภีร์ชิ้นที่ 9", ctx.PlayerName, files:
                [("fragment-9.txt", "แล้วนำสิ่งที่ดีที่สุดกลับมารวมกัน\nแกนกลาง: ???\n")]));
            await ctx.Git("switch", "-q", "-c", "experiment");
            await Lore.InscribeAsync(ctx, Page.Of("แกนกลางแห่งไฟ", ctx.PlayerName, files:
                [("fragment-9.txt", "แล้วนำสิ่งที่ดีที่สุดกลับมารวมกัน\nแกนกลาง: เปลวไฟ\n")]));
            await ctx.Git("switch", "-q", "main");
            await Lore.InscribeAsync(ctx, Page.Of("แกนกลางแห่งน้ำแข็ง", ctx.PlayerName, files:
                [("fragment-9.txt", "แล้วนำสิ่งที่ดีที่สุดกลับมารวมกัน\nแกนกลาง: น้ำแข็ง\n")]));
        },
        Intro =
        [
            Narrate("วงเวทหลอมมิติเรืองแสงอยู่กลางห้อง ทั้งสองรอยแยกสั่นสะเทือน"),
            Miura("นายยืนอยู่ใน main ที่แกนกลางเป็นน้ำแข็ง ส่วน experiment เป็นเปลวไฟ"),
            Miura("หลอมมิติ experiment เข้ามา… แล้วเตรียมใจไว้ด้วย"),
        ],
        Objectives =
        [
            new()
            {
                Goal = "เริ่มพิธีหลอมมิติ experiment เข้ากับ main",
                Hints = ["คาถาหลอมมิติคือ merge ตามด้วยชื่อมิติที่จะดึงเข้ามา", "git merge experiment"],
                IsComplete = c => c.After.IsMerging || c.After.Head?.IsMerge == true,
                OnComplete = [Narrate("⚡ ไฟกับน้ำแข็งปะทะกันกลางวงเวท! ⚡"), Miura("การปะทะ (conflict) — สองมิติเขียนบรรทัดเดียวกันต่างกัน นายต้องเป็นคนตัดสิน")],
            },
            new()
            {
                Goal = "ตัดสินการปะทะใน fragment-9.txt (resolve fragment-9.txt ours|theirs|both)",
                Hints = ["read fragment-9.txt เพื่อดูรอยปะทะ <<<<<<< ======= >>>>>>>", "ours = มิติที่ยืนอยู่ (น้ำแข็ง), theirs = มิติที่หลอมเข้ามา (ไฟ)", "resolve fragment-9.txt both"],
                IsComplete = c => c.Action == PlayerActionKind.Resolve ||
                    (c.After.IsMerging && !c.After.UnmergedFiles.Any()),
            },
            new()
            {
                Goal = "วางผลการหลอมขึ้นแท่นแล้วจารึก ให้พิธีเสร็จสมบูรณ์",
                Hints = ["หลังตัดสินแล้ว คัมภีร์ยังรอให้นายยืนยัน", "git add fragment-9.txt  แล้ว  git commit -m \"หลอมมิติ\""],
                IsComplete = c => c.After.Head?.IsMerge == true && !c.After.IsMerging,
                OnComplete =
                [
                    Narrate("สองแสงหมุนเข้าหากันแล้วหลอมเป็นหนึ่ง เศษคัมภีร์ชิ้นที่ 9 ลอยขึ้นจากวงเวท"),
                    Miura("ถ้าวันหน้ากลัวการปะทะ ใช้ git merge --abort เพื่อยกเลิกพิธีกลับไปก่อนหลอมได้"),
                ],
            },
        ],
        Reward = Lore.Fragment(9),
        Reflection = "git merge <branch> รวม branch • conflict: แก้ไฟล์ → git add → git commit • git merge --abort ยกเลิก",
        Ask = [new("ถ้าสองมิติไม่ได้แก้บรรทัดเดียวกันล่ะ?", [Miura("Git หลอมให้เองอัตโนมัติ การปะทะเกิดเฉพาะเมื่อแก้จุดเดียวกันเท่านั้น")])],
        Solution = ["git merge experiment", "resolve fragment-9.txt both", "git add fragment-9.txt", "git commit -m \"หลอมมิติ\""],
    };
}
