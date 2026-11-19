using GitDiwaa.Core.Game;
using static GitDiwaa.Core.Game.Line;

namespace GitDiwaa.Story;

public static partial class Act1
{
    private const UiPanel Study = UiPanel.Terminal | UiPanel.Desk | UiPanel.Altar | UiPanel.Tome;

    // ───────────── ชั้น 6 — ม้วนประวัติของอาจารย์ (git log) ─────────────
    public static Floor Floor06 => new()
    {
        Number = 6,
        Title = "ม้วนประวัติของอาจารย์",
        Hook = "ประตูสู่ชั้นเจ็ดถูกผนึก — รหัสถูกซ่อนไว้ในประวัติการจารึกของปรมาจารย์",
        Scene = "library",
        Panels = UiPanel.Terminal | UiPanel.Desk | UiPanel.Altar,
        Spells = Spells.F6,
        Guided = false,
        TimeLimitSeconds = 110,
        TargetCommands = 4,
        Setup = async ctx =>
        {
            await Lore.BlessAsync(ctx);
            await Lore.SeedTomeAsync(ctx,
                Page.Of("เริ่มศึกษาคัมภีร์เวทต้นกำเนิด", Lore.Master, "2024-03-01T08:00:00+07:00", ("journal.txt", "วันแรกของการศึกษา\n")),
                Page.Of("รับศิษย์ฝึกหัดคนใหม่เข้าหอคอย", Lore.Master, "2024-05-12T08:00:00+07:00", ("apprentices.txt", "ศิษย์: {player}\n".Replace("{player}", ctx.PlayerName))),
                Page.Of("พบรอยร้าวบนคัมภีร์ต้นกำเนิด", Lore.Master, "2024-08-20T23:10:00+07:00", ("journal.txt", "วันแรกของการศึกษา\nรอยร้าวลามเร็วผิดปกติ\n")),
                Page.Of("ผนึกประตูชั้นเจ็ด รหัสผนึก: aurora", Lore.Master, "2024-09-02T02:00:00+07:00", ("seal.txt", "ประตูชั้นเจ็ด: ผนึกแล้ว\n")),
                Page.Of("พลังโกลาหลรุนแรงขึ้นทุกคืน", Lore.Master, "2024-10-15T03:33:00+07:00", ("journal.txt", "วันแรกของการศึกษา\nรอยร้าวลามเร็วผิดปกติ\nได้ยินเสียงจากใต้หอคอย\n")),
                Page.Of("ซ่อมแท่นเตรียมชั้นสี่", Lore.Miura, "2024-11-01T10:00:00+07:00", ("repairs.txt", "แท่นเตรียม: ซ่อมแล้ว\n")),
                Page.Of("ถ้ามีใครอ่านอยู่… จงตามเศษคัมภีร์ขึ้นไป", Lore.Master, "2024-12-31T23:59:00+07:00", ("journal.txt", "…\n")));
        },
        Intro =
        [
            Narrate("ประตูหินบานใหญ่ไม่มีลูกบิด มีแค่ช่องเสียงสลักว่า \"เอ่ยรหัสผนึก\""),
            Miura("อาจารย์ชอบจดทุกอย่างไว้ในคำจารึก… คัมภีร์บนโต๊ะนี้คือของท่าน"),
        ],
        Objectives =
        [
            new()
            {
                Goal = "คลี่ม้วนประวัติการจารึกของปรมาจารย์",
                Hints = ["ประวัติการจารึกอ่านได้ด้วยคาถาคลี่ม้วน", "คาถานี้ชื่อเหมือน 'บันทึก' (log)", "git log"],
                IsComplete = c => c.Cast("log"),
                Unlocks = UiPanel.Tome,
                OnComplete = [Miura("ยาวเหยียด… ลองย่อให้เหลือบรรทัดเดียวต่อจารึกสิ จะหาง่ายขึ้น (--oneline)")],
            },
            new()
            {
                Goal = "หารหัสผนึกในประวัติ แล้วเอ่ยมันออกมา (say <รหัส>)",
                Hints = ["อาจารย์จารึกเรื่องผนึกไว้ในคำจารึกครั้งหนึ่ง", "git log --oneline แล้วมองหาคำว่า 'รหัสผนึก'", "say aurora"],
                IsComplete = c => c.Said("aurora"),
                OnComplete = [Narrate("ประตูหินสั่นสะเทือน แล้วเลื่อนเปิด… กระดาษแผ่นหนึ่งปลิวออกมาตกบนโต๊ะ")],
                WorldEvent = ctx => ctx.Files.WriteAllTextAsync("fragment-3.txt", "ย่อมสูญหายไปกับกาลเวลา\n"),
            },
            new()
            {
                Goal = "เก็บ fragment-3.txt ลงคัมภีร์ (วางขึ้นแท่นแล้วจารึก)",
                Hints = ["อย่าลืมกฎหอคอย — เศษที่ไม่จารึกจะไม่ปลอดภัย", "add แล้ว commit", "git add fragment-3.txt  แล้ว  git commit -m \"เศษคัมภีร์ชิ้นที่ 3\""],
                IsComplete = c => c.After.IsTracked("fragment-3.txt") && c.After.IsClean,
                OnComplete = [Miura("เห็นไหม คำจารึกที่ดีช่วยให้คนรุ่นหลังหาเจอ — นายเองก็ควรจารึกให้ดีแบบนี้")],
            },
        ],
        Reward = Lore.Fragment(3),
        Reflection = "git log แสดงประวัติ commit • git log --oneline ย่อเหลือบรรทัดละ commit • git log -n 3 จำกัดจำนวน",
        Ask =
        [
            new("ตัวเลขยาว ๆ หน้าคำจารึกคืออะไร?", [Miura("รหัสประจำการจารึก (commit hash) ไม่มีสองครั้งไหนซ้ำกัน ใช้ 7 ตัวแรกก็พอ")]),
            new("ดูแค่ไม่กี่ครั้งล่าสุดได้ไหม?", [Miura("ได้ git log -n 3 จะแสดงแค่ 3 ครั้งล่าสุด")]),
        ],
        Solution = ["git log", "git log --oneline", "say aurora", "git add fragment-3.txt", "git commit -m \"เศษคัมภีร์ชิ้นที่ 3\""],
    };

    // ───────────── ชั้น 7 — รอยอักขระที่ถูกแก้ (git diff) ─────────────
    private const string Fragment4Original = "จงสังเกตทุกรอยที่เปลี่ยนไป\nอักขระกุญแจ: lumina\n";

    public static Floor Floor07 => new()
    {
        Number = 7,
        Title = "รอยอักขระที่ถูกแก้",
        Hook = "พลังโกลาหลแอบแก้อักขระกุญแจบนเศษคัมภีร์ชิ้นที่ 4 — ถ้าเอ่ยอักขระผิด เศษจะสลาย",
        Scene = "library",
        Panels = Study,
        Spells = Spells.F7,
        Guided = false,
        TimeLimitSeconds = 100,
        TargetCommands = 2,
        Setup = async ctx =>
        {
            await Lore.BlessAsync(ctx);
            await Lore.SeedTomeAsync(ctx,
                Page.Of("จารึกเศษคัมภีร์ชิ้นที่ 3", ctx.PlayerName, files: [("fragment-3.txt", "ย่อมสูญหายไปกับกาลเวลา\n")]),
                Page.Of("จารึกเศษคัมภีร์ชิ้นที่ 4 (ยังไม่ปลุก)", ctx.PlayerName, files: [("fragment-4.txt", Fragment4Original)]));
            await ctx.Files.WriteAllTextAsync("fragment-4.txt", "จงสังเกตทุกรอยที่เปลี่ยนไป\nอักขระกุญแจ: umbra\n");
        },
        Intro =
        [
            Narrate("หมอกสีม่วงลอยผ่านโต๊ะ… อักขระบน fragment-4.txt บิดเบี้ยวไปชั่วครู่"),
            Miura("โกลาหลแก้มันแล้ว! อ่านตอนนี้ก็เห็นแต่ของปลอม ต้องเทียบกับที่จารึกไว้"),
        ],
        Objectives =
        [
            new()
            {
                Goal = "หาว่าอักขระกุญแจ 'ดั้งเดิม' คืออะไร แล้วเอ่ยมัน (say <อักขระ>)",
                Hints = ["read จะเห็นแต่ฉบับที่ถูกแก้ ต้องเทียบกับฉบับที่จารึก", "คาถาเทียบรอย: บรรทัด - คือของเดิม + คือของใหม่", "git diff  แล้ว  say lumina"],
                IsComplete = c => c.Said("lumina"),
                OnComplete =
                [
                    Narrate("อักขระ lumina เปล่งแสงขับหมอกออกไป เศษคัมภีร์กลับคืนสภาพเดิม"),
                    Narrate("…แต่ทันใดนั้น แท่นเตรียมก็สว่างขึ้นเอง มีบางอย่างแอบขึ้นไปบนแท่น!"),
                ],
                WorldEvent = async ctx =>
                {
                    await ctx.Files.WriteAllTextAsync("fragment-4.txt", Fragment4Original);
                    await ctx.Files.WriteAllTextAsync("fragment-4.txt", Fragment4Original + "นามแท้: ignis\n");
                    await Lore.StageAsync(ctx, "fragment-4.txt");
                },
            },
            new()
            {
                Goal = "เทียบรอยสิ่งที่อยู่บนแท่นเตรียม แล้วเอ่ย 'นามแท้' ที่ถูกเพิ่มเข้ามา",
                Hints = ["git diff เฉย ๆ เทียบแค่โต๊ะกับแท่น — ตอนนี้โต๊ะกับแท่นเหมือนกัน", "ต้องเทียบแท่นเตรียมกับคัมภีร์ (staged)", "git diff --staged  แล้ว  say ignis"],
                IsComplete = c => c.Said("ignis"),
                OnComplete = [Miura("diff ดูโต๊ะ↔แท่น, diff --staged ดูแท่น↔คัมภีร์ ส่วน diff HEAD ดูโต๊ะ↔คัมภีร์ทั้งหมด จำไว้นะ")],
            },
        ],
        Reward = Lore.Fragment(4),
        Reflection = "git diff = working tree ↔ stage • git diff --staged = stage ↔ commit ล่าสุด • git diff HEAD = ทั้งหมด ↔ commit ล่าสุด",
        Ask = [new("เครื่องหมาย + กับ - หมายถึงอะไร?", [Miura("- คืออักขระที่หายไปจากของเดิม + คืออักขระที่ถูกเติมเข้ามา")])],
        Solution = ["git diff", "say lumina", "git diff --staged", "say ignis"],
    };

    // ───────────── ชั้น 8 — คาถาฟื้นคืน (git restore) ─────────────
    public static Floor Floor08 => new()
    {
        Number = 8,
        Title = "คาถาฟื้นคืน",
        Hook = "คำสาปเกาะเศษคัมภีร์ชิ้นที่ 5 และม้วนคำสาปแอบขึ้นแท่นเตรียม — ถ้าจารึกลงไป คัมภีร์จะแปดเปื้อน",
        Scene = "library",
        Panels = Study,
        Spells = Spells.F8,
        Guided = false,
        TimeLimitSeconds = 90,
        TargetCommands = 2,
        Setup = async ctx =>
        {
            await Lore.BlessAsync(ctx);
            await Lore.SeedTomeAsync(ctx,
                Page.Of("จารึกเศษคัมภีร์ชิ้นที่ 4", ctx.PlayerName, files: [("fragment-4.txt", Fragment4Original)]),
                Page.Of("จารึกเศษคัมภีร์ชิ้นที่ 5", ctx.PlayerName, files: [("fragment-5.txt", "ความผิดพลาดแก้ไขได้เสมอ\n")]));
            await ctx.Files.WriteAllTextAsync("fragment-5.txt", "ค̷ว̷า̷ม̷ผ̷ิ̷ด̷พ̷ล̷า̷ด̷ ̷ค̷ื̷อ̷จ̷̷ุด̷จ̷บ̷\n");
            await ctx.Files.WriteAllTextAsync("curse.txt", "☠ ผู้ใดจารึกม้วนนี้ คัมภีร์จะเป็นของโกลาหล ☠\n");
            await Lore.StageAsync(ctx, "curse.txt");
        },
        Intro =
        [
            Narrate("อักขระบน fragment-5.txt แตกเป็นรอยหยัก และมีม้วนกระดาษสีดำวางอยู่บนแท่นเตรียม"),
            Miura("อย่าเพิ่งจารึกอะไรทั้งนั้น! ต้องฟื้นคืนเศษคัมภีร์ แล้วเอาม้วนนั่นลงจากแท่นก่อน"),
        ],
        Objectives =
        [
            new()
            {
                Goal = "ลบรอยสาปบน fragment-5.txt ให้กลับเป็นเหมือนที่จารึกไว้",
                Hints = ["ไฟล์นี้เคยจารึกไว้แล้ว ฉบับที่ถูกต้องอยู่ในคัมภีร์", "คาถาฟื้นคืนคือ restore", "git restore fragment-5.txt"],
                IsComplete = c => c.After.IsTracked("fragment-5.txt") && c.After.FindFile("fragment-5.txt") is null,
                OnComplete = [Narrate("รอยหยักสลายเป็นผงแสง อักขระเดิมกลับมาชัดเจน")],
            },
            new()
            {
                Goal = "นำ curse.txt ลงจากแท่นเตรียม (แต่อย่าจารึกมัน!)",
                Hints = ["restore ทำได้มากกว่าฟื้นคืนไฟล์บนโต๊ะ", "เพิ่มตัวเลือกที่หมายถึง 'แท่นเตรียม' (staged)", "git restore --staged curse.txt"],
                IsComplete = c => c.After.FindFile("curse.txt")?.IsUntracked == true,
                OnComplete = [Narrate("ม้วนสีดำหล่นลงจากแท่น ไร้พลังเมื่อไม่มีใครจารึกมัน"), Miura("ไฟล์ยังอยู่บนโต๊ะ แต่จะไม่ถูกจารึกจนกว่าจะมีใครวางมันขึ้นแท่นอีก")],
            },
        ],
        FailWhen = c => c.After.IsTracked("curse.txt") && c.After.HeadHistoryLength > c.Before.HeadHistoryLength
            ? "คำสาปถูกจารึกลงคัมภีร์แล้ว! หน้ากระดาษดำมืด… (พิมพ์ retry เพื่อเริ่มชั้นนี้ใหม่)"
            : null,
        Reward = Lore.Fragment(5),
        Reflection = "git restore <ไฟล์> ทิ้งการแก้ไขใน working tree • git restore --staged <ไฟล์> นำออกจาก staging area",
        Ask = [new("restore แล้วงานที่แก้ไว้จะกลับมาไหม?", [Miura("ไม่ — restore ไฟล์บนโต๊ะคือทิ้งการแก้ไขไปจริง ๆ ใช้เมื่อแน่ใจว่าไม่ต้องการมันแล้ว")])],
        Solution = ["git restore fragment-5.txt", "git restore --staged curse.txt"],
    };

    // ───────────── ชั้น 9 — เวทย้อนกาล (git reset) ─────────────
    private const string CursedInscription = "จารึกเศษคัมภีร์ชิ้นที่ 6";
    private const string SafeInscription = "จารึกเศษคัมภีร์ชิ้นที่ 5";

    public static Floor Floor09 => new()
    {
        Number = 9,
        Title = "เวทย้อนกาล",
        Hook = "การจารึกครั้งล่าสุดมีม้วนคำสาปติดเข้าไปพร้อมเศษคัมภีร์ชิ้นที่ 6 — คัมภีร์ฉีกหน้าไม่ได้ แต่ย้อนเวลาได้",
        Scene = "clock",
        Panels = Study,
        Spells = Spells.F9,
        Guided = false,
        TimeLimitSeconds = 110,
        TargetCommands = 4,
        Setup = async ctx =>
        {
            await Lore.BlessAsync(ctx);
            await Lore.SeedTomeAsync(ctx,
                Page.Of("จารึกเศษคัมภีร์ชิ้นที่ 4", ctx.PlayerName, files: [("fragment-4.txt", Fragment4Original)]),
                Page.Of(SafeInscription, ctx.PlayerName, files: [("fragment-5.txt", "ความผิดพลาดแก้ไขได้เสมอ\n")]),
                Page.Of(CursedInscription, ctx.PlayerName, files:
                [
                    ("fragment-6.txt", "หากเจ้ากล้าย้อนกลับไปมอง\n"),
                    ("curse.txt", "☠ ผู้ใดจารึกม้วนนี้ คัมภีร์จะเป็นของโกลาหล ☠\n"),
                ]));
        },
        Intro =
        [
            Narrate("หน้าล่าสุดของคัมภีร์มีรอยดำลามออกมาจากขอบ"),
            Miura("ม้วนคำสาปติดไปกับการจารึกครั้งล่าสุด! เราต้องย้อนเวลาไปก่อนจารึกนั้น"),
            Miura("แต่ระวัง… เวทย้อนกาลมีสามระดับ ถ้าแรงเกินไป เศษคัมภีร์ชิ้นที่ 6 จะหายไปด้วย"),
        ],
        Objectives =
        [
            new()
            {
                Goal = "ตรวจม้วนประวัติ หาว่าต้องย้อนกลับไปกี่การจารึก",
                Hints = ["ดูประวัติแบบย่อ", "git log --oneline"],
                IsComplete = c => c.Cast("log"),
            },
            new()
            {
                Goal = "ย้อนกาลไปก่อนการจารึกต้องสาป โดยไม่ให้เศษคัมภีร์ชิ้นที่ 6 หายไปจากโต๊ะ",
                Hints =
                [
                    "HEAD~1 หมายถึง 'หนึ่งการจารึกก่อนหน้าที่คั่นหน้าปัจจุบัน'",
                    "--soft เก็บของไว้บนแท่น, --mixed เก็บไว้บนโต๊ะ, --hard ลบทิ้งหมด",
                    "git reset --soft HEAD~1",
                ],
                IsComplete = c => c.After.Head?.Subject == SafeInscription && c.After.WorkspaceFiles.Contains("fragment-6.txt"),
                OnComplete = [Narrate("นาฬิกาทรายยักษ์หมุนกลับ หน้าคัมภีร์ที่ดำมืดม้วนตัวหายไป")],
            },
            new()
            {
                Goal = "จารึกเฉพาะเศษคัมภีร์ชิ้นที่ 6 อีกครั้ง — ทิ้งคำสาปไว้นอกคัมภีร์",
                Hints =
                [
                    "ดูสถานะก่อน: ม้วนคำสาปอยู่บนแท่นหรือบนโต๊ะ?",
                    "ถ้ามันอยู่บนแท่น ใช้ restore --staged เอามันลง ถ้าอยู่บนโต๊ะ ก็ add เฉพาะ fragment-6.txt",
                    "git restore --staged curse.txt  แล้ว  git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 6\"",
                ],
                IsComplete = c => c.After.IsTracked("fragment-6.txt") && !c.After.IsTracked("curse.txt") &&
                    c.After.Head?.Subject != SafeInscription && !c.After.StagedFiles.Any(),
                OnComplete = [Miura("ย้อนกาลแล้วเลือกจารึกใหม่ได้ถูกต้อง นายเริ่มเป็นนักเวทตัวจริงแล้ว")],
            },
        ],
        FailWhen = c => c.After.Head?.Subject == SafeInscription && !c.After.WorkspaceFiles.Contains("fragment-6.txt")
            ? "reset --hard ลบเศษคัมภีร์ชิ้นที่ 6 ไปพร้อมคำสาป! (พิมพ์ retry แล้วลองระดับที่อ่อนกว่า)"
            : null,
        Reward = Lore.Fragment(6),
        Reflection = "git reset --soft HEAD~1 ย้อน commit เก็บงานใน stage • --mixed เก็บใน working tree • --hard ทิ้งงานทั้งหมด",
        Ask =
        [
            new("soft / mixed / hard ต่างกันยังไง?",
            [
                Miura("ทั้งสามย้ายที่คั่นหน้ากลับในอดีตเหมือนกัน ต่างกันที่ 'ของในการจารึกนั้น' ไปอยู่ไหน"),
                Miura("soft → อยู่บนแท่นเตรียม, mixed → อยู่บนโต๊ะ, hard → หายไปเลย"),
            ]),
        ],
        Solution = ["git log --oneline", "git reset --soft HEAD~1", "git restore --staged curse.txt", "git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 6\""],
    };
}
