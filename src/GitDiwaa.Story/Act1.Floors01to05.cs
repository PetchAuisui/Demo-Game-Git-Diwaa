using GitDiwaa.Core.Game;
using static GitDiwaa.Core.Game.Line;

namespace GitDiwaa.Story;

public static partial class Act1
{
    // ───────────── ชั้น 1 — ปลุกพลังเวท (git --version + git config) ─────────────
    public static Floor Floor01 => new()
    {
        Number = 1,
        Title = "ปลุกพลังเวท",
        Hook = "วงเวทหน้าประตูหอคอยมืดสนิท และประตูไม่รู้ว่านายเป็นใคร",
        Scene = "gate",
        Panels = UiPanel.Terminal,
        Spells = Spells.F1,
        TimeLimitSeconds = 130,
        TargetCommands = 3,
        Intro =
        [
            Narrate("ประตูหอคอยเวทสูงตระหง่าน วงเวทบนพื้นมืดสนิท"),
            Miura("ยินดีต้อนรับสู่กิลด์แห่งหอคอยเวท ฉันมิวรา… ใช่ ฉันเป็นแมว เห็นก็รู้"),
            Miura("วงเวทนี้ไม่ตอบคนที่พลังยังไม่ตื่น ลองปลุกมันดูสิ {player}"),
        ],
        Objectives =
        [
            new()
            {
                Goal = "ปลุกวงเวท — ให้มันบอกระดับพลัง Git ของนาย",
                GuidedSpell = "git --version",
                Hints = ["วงเวทตอบสนองต่อคาถาวัดพลัง", "คาถาวัดพลังคือ git ตามด้วย --version (ขีดคู่!)", "git --version"],
                IsComplete = c => c.Cast("version"),
                OnComplete = [Narrate("อักขระรอบวงเวทสว่างวาบขึ้นทีละตัว"), Miura("พลังนายตื่นอยู่แล้ว ดี… ต่อไปประตูต้องรู้ว่านายเป็นใคร")],
            },
            new()
            {
                Goal = "ประกาศนามให้ประตูหอคอยจดจำ",
                GuidedSpell = "git config --global user.name \"ชื่อของนาย\"",
                Hints = ["ทุกการจารึกต้องมีชื่อผู้จารึก", "คาถาประกาศนามคือ git config --global user.name ตามด้วยชื่อในเครื่องหมายคำพูด", "git config --global user.name \"{player}\""],
                IsComplete = c => !string.IsNullOrWhiteSpace(c.After.UserName),
                OnComplete = [Narrate("ชื่อของนายถูกสลักลงบนบานประตู")],
            },
            new()
            {
                Goal = "ผูกตราประทับวิญญาณ (อีเมล) เข้ากับนาม",
                GuidedSpell = "git config --global user.email \"อีเมลของนาย\"",
                Hints = ["ตราประทับวิญญาณคืออีเมล", "ใช้คาถาเดิม แต่เปลี่ยน user.name เป็น user.email", "git config --global user.email \"you@tower.diwaa\""],
                IsComplete = c => c.After.UserEmail?.Contains('@') == true,
                OnComplete = [Narrate("ประตูหอคอยค่อย ๆ เปิดออก… เสียงลมหอบใหญ่พัดลงมาจากบันได")],
            },
        ],
        Outro =
        [
            Miura("ตอนนี้ทุกการจารึกของนายจะมีนามกำกับเสมอ"),
            Player("หอคอยนี้… ไม่มีลิฟต์เหรอ"),
            Miura("…นั่นสิ"),
        ],
        Reflection = "git --version ตรวจว่ามี Git • git config --global user.name/user.email ตั้งตัวตนผู้เขียน commit",
        Ask =
        [
            new("พลัง Git คืออะไร?",
            [
                Miura("พลังที่บันทึกการเปลี่ยนแปลงของคัมภีร์ ทุกครั้งที่นายจารึก มันจะจำไว้"),
                Miura("ต่อให้ผ่านไปนานแค่ไหน นายก็ย้อนกลับไปดูอดีตได้"),
            ]),
            new("ฉันมาทำอะไรที่นี่?",
            [
                Miura("ปรมาจารย์หายไป พร้อมคัมภีร์เวทต้นกำเนิดที่แตกเป็น 16 เศษ"),
                Miura("เศษคัมภีร์กระจายอยู่ทั่วหอคอย 15 ชั้น… ถ้านายอยากรู้ความจริง ก็ต้องปีนขึ้นไปเก็บมัน"),
            ]),
            new("มีอะไรต้องระวังตอนร่ายคาถา?",
            [
                Miura("--version กับ --global ต้องเป็นขีดคู่ และต้องเว้นวรรคระหว่างแต่ละคำ"),
                Miura("ผิดตัวเดียว วงเวทก็ไม่ตอบ"),
            ]),
        ],
        Solution = ["git --version", "git config --global user.name \"Vel\"", "git config --global user.email \"vel@tower.diwaa\""],
    };

    // ───────────── ชั้น 2 — คัมภีร์เล่มแรก (git init) ─────────────
    public static Floor Floor02 => new()
    {
        Number = 2,
        Title = "คัมภีร์เล่มแรก",
        Hook = "เศษคัมภีร์ที่นายจะได้พบต้องมีที่จารึก แต่บนโต๊ะยังไม่มีคัมภีร์เลย",
        Scene = "study",
        Panels = UiPanel.Terminal,
        Spells = Spells.F2,
        TimeLimitSeconds = 40,
        TargetCommands = 1,
        Setup = Lore.BlessAsync,
        Intro =
        [
            Narrate("ชั้นสอง: ห้องจารึก มีโต๊ะไม้เก่า ๆ ตั้งอยู่กลางห้อง"),
            Miura("ก่อนจะเก็บเศษคัมภีร์ นายต้องมีคัมภีร์เวทส่วนตัวไว้จารึกมันก่อน"),
        ],
        Objectives =
        [
            new()
            {
                Goal = "ให้คัมภีร์เวทส่วนตัวถือกำเนิดบนโต๊ะนี้",
                GuidedSpell = "git init",
                Hints = ["คัมภีร์ต้องถูก 'เริ่มต้น' (initialize)", "คาถากำเนิดคัมภีร์สั้นมาก แค่ git กับอีกหนึ่งคำ", "git init"],
                IsComplete = c => c.After.IsInitialized,
                OnComplete =
                [
                    Narrate("แสงรวมตัวเหนือโต๊ะ ก่อตัวเป็นหนังสือเล่มหนึ่ง… หน้ากระดาษยังว่างเปล่า"),
                    Miura("มันซ่อนตัวอยู่ในห้องลับชื่อ .git และจะจดจำทุกอย่างที่เกิดบนโต๊ะนี้"),
                ],
            },
        ],
        Outro = [Miura("ไปชั้นต่อไปกัน เศษคัมภีร์ชิ้นแรกอยู่ไม่ไกลแล้ว")],
        Reflection = "git init สร้าง repository ใหม่ (โฟลเดอร์ .git) ในโฟลเดอร์ปัจจุบัน",
        Ask =
        [
            new("ถ้าร่ายซ้ำบนโต๊ะเดิมจะเป็นอะไรไหม?", [Miura("ไม่เป็นไร คัมภีร์เดิมจะไม่ถูกลบ มันแค่บอกว่ามีอยู่แล้ว (Reinitialized)")]),
        ],
        Solution = ["git init"],
    };

    // ───────────── ชั้น 3 — เศษคัมภีร์ไร้ตรา (git status) ─────────────
    public static Floor Floor03 => new()
    {
        Number = 3,
        Title = "เศษคัมภีร์ไร้ตรา",
        Hook = "กระดาษหลายแผ่นร่วงลงบนโต๊ะ บางแผ่นคัมภีร์รู้จัก บางแผ่นไม่ — และมีแผ่นหนึ่งถูกใครแอบแก้",
        Scene = "study",
        Panels = UiPanel.Terminal,
        Spells = Spells.F3,
        TimeLimitSeconds = 60,
        TargetCommands = 1,
        Guided = true,
        Setup = async ctx =>
        {
            await Lore.BlessAsync(ctx);
            await Lore.SeedTomeAsync(ctx,
                Page.Of("บันทึกของมิวรา", Lore.Miura, files:
                [
                    ("miura-note.txt", "อย่าลืมให้อาหารแมว\n"),
                    ("tower-rules.txt", "กฎหอคอย ข้อ 1: ห้ามวิ่งบนบันได\n"),
                ]));
            await ctx.Files.WriteAllTextAsync("tower-rules.txt",
                "กฎหอคอย ข้อ 1: ห้ามวิ่งบนบันได\nกฎหอคอย ข้อ 2: เศษคัมภีร์ที่ยังไม่จารึก ห้ามสะสมเกิน 3 ชิ้น!\n");
            await ctx.Files.WriteAllTextAsync("whisper.txt",
                "…เศษคัมภีร์ชิ้นแรกถูกแบ่งเป็นสามส่วน ซ่อนอยู่บนชั้นถัดไป…\n");
        },
        Intro =
        [
            Narrate("ลมพัดกระดาษปลิวมาตกบนโต๊ะ"),
            Miura("คัมภีร์ของนายรู้จักกระดาษบางแผ่น แต่บางแผ่นไม่มีตราของมันเลย"),
            Miura("ใช้คาถาหยั่งสถานะ แล้วดูว่าคัมภีร์มองโต๊ะนี้ยังไง"),
        ],
        Objectives =
        [
            new()
            {
                Goal = "หยั่งสถานะของโต๊ะ — ให้คัมภีร์บอกว่าเห็นอะไรบ้าง",
                GuidedSpell = "git status",
                Hints = ["คาถาหยั่งสถานะ", "git ตามด้วยคำว่า 'สถานะ' ภาษาอังกฤษ", "git status"],
                IsComplete = c => c.Cast("status"),
                Unlocks = UiPanel.Desk,
                OnComplete = [Miura("Untracked = ไร้ตรา (คัมภีร์ไม่รู้จัก), modified = ถูกแก้ไปจากที่จารึกไว้")],
            },
            new()
            {
                Goal = "หยิบอ่านเศษคัมภีร์ที่ไร้ตรา (read <ไฟล์>)",
                Hints = ["ดูในหมวด Untracked files", "มันมีแผ่นเดียว และชื่อของมันเหมือนเสียงกระซิบ", "read whisper.txt"],
                IsComplete = c => c.HasRead("whisper.txt"),
                OnComplete = [Player("เศษคัมภีร์ชิ้นแรก… อยู่ชั้นบน!")],
            },
            new()
            {
                Goal = "อ่านแผ่นที่ถูกใครแอบแก้ไข",
                Hints = ["ดูในหมวด Changes not staged (modified)", "มันคือกฎของหอคอย", "read tower-rules.txt"],
                IsComplete = c => c.HasRead("tower-rules.txt"),
                OnComplete =
                [
                    Miura("…กฎข้อ 2 ใครเพิ่มเข้ามา? แต่ก็จริงนะ ถ้านายเก็บเศษคัมภีร์ไว้ไม่จารึกเกิน 3 ชิ้น หอคอยจะไม่ยอม"),
                ],
            },
        ],
        Outro = [Miura("เก่งมาก นายเริ่ม 'มองเห็น' สิ่งที่คัมภีร์เห็นแล้ว")],
        Reflection = "git status บอกสถานะไฟล์: untracked (ใหม่), modified (ถูกแก้), staged (รอ commit)",
        Ask = [new("ทำไมต้องดูสถานะก่อนทำอะไร?", [Miura("นักเวทที่ดีดูก่อนร่ายเสมอ จะได้ไม่จารึกของผิดลงไป")])],
        Solution = ["git status", "read whisper.txt", "read tower-rules.txt"],
    };

    // ───────────── ชั้น 4 — แท่นเตรียม (git add) ─────────────
    public static Floor Floor04 => new()
    {
        Number = 4,
        Title = "แท่นเตรียม",
        Hook = "เศษคัมภีร์ชิ้นที่ 1 แตกเป็นสามส่วนบนโต๊ะ — ต้องวางบนแท่นเตรียมให้ครบจึงจะหลอมกลับ",
        Scene = "altar",
        Panels = UiPanel.Terminal | UiPanel.Desk,
        Spells = Spells.F4,
        TimeLimitSeconds = 100,
        TargetCommands = 2,
        Setup = async ctx =>
        {
            await Lore.BlessAsync(ctx);
            await Lore.SeedTomeAsync(ctx, Page.Of("บันทึกของมิวรา", Lore.Miura, files: [("miura-note.txt", "อย่าลืมให้อาหารแมว\n")]));
            await ctx.Files.WriteAllTextAsync("fragment-1a.txt", "ศิษย์\n");
            await ctx.Files.WriteAllTextAsync("fragment-1b.txt", "ของ\n");
            await ctx.Files.WriteAllTextAsync("fragment-1c.txt", "ข้า…\n");
        },
        Intro =
        [
            Narrate("กลางห้องมีแท่นหินสลักวงเวท ข้างกันคือโต๊ะที่มีกระดาษสามแผ่นเรืองแสงจาง ๆ"),
            Miura("นี่คือแท่นเตรียม — ของที่จะจารึกต้องขึ้นแท่นนี้ก่อน นายเลือกได้ว่าจะจารึกชิ้นไหน"),
        ],
        Objectives =
        [
            new()
            {
                Goal = "วางส่วนแรก fragment-1a.txt ขึ้นแท่นเตรียม (เฉพาะชิ้นเดียว)",
                GuidedSpell = "git add fragment-1a.txt",
                Hints = ["คาถาวางขึ้นแท่นคือ add", "ระบุชื่อไฟล์ต่อท้ายคาถา", "git add fragment-1a.txt"],
                IsComplete = c => c.After.StagedFiles.Any(f => f.Path == "fragment-1a.txt"),
                Unlocks = UiPanel.Altar,
                OnComplete = [Narrate("กระดาษแผ่นแรกลอยขึ้นจากโต๊ะ ไปหมุนวนเหนือแท่นเตรียม")],
            },
            new()
            {
                Goal = "วางส่วนที่เหลือทั้งหมดขึ้นแท่นในคาถาเดียว",
                GuidedSpell = "git add .",
                Hints = ["ไม่ต้องร่ายทีละชิ้น มีสัญลักษณ์ที่แปลว่า 'ทุกอย่างตรงนี้'", "จุด (.) แปลว่าโฟลเดอร์ปัจจุบันทั้งหมด", "git add ."],
                IsComplete = c => c.Cast("add") &&
                    new[] { "fragment-1a.txt", "fragment-1b.txt", "fragment-1c.txt" }.All(p => c.After.StagedFiles.Any(f => f.Path == p)),
                OnComplete =
                [
                    Narrate("สามส่วนลอยขึ้นพร้อมกัน หมุนวนเร็วขึ้น… แล้วหลอมรวมเป็นแผ่นเดียว!"),
                    Miura("เศษคัมภีร์ชิ้นที่ 1! แต่มันยังอยู่แค่บนแท่นนะ ยังไม่ได้จารึกลงคัมภีร์"),
                ],
            },
        ],
        Reward = Lore.Fragment(1),
        Reflection = "git add <ไฟล์> นำไฟล์เข้า staging area • git add . นำทุกการเปลี่ยนแปลงในโฟลเดอร์นี้",
        Ask =
        [
            new("ทำไมไม่จารึกตรง ๆ เลย ต้องขึ้นแท่นก่อนทำไม?",
            [
                Miura("เพราะบางทีบนโต๊ะมีของหลายอย่าง แต่นายอยากจารึกแค่บางชิ้น"),
                Miura("แท่นเตรียมให้นายเลือก — นักเวทเรียกมันว่า Staging Area"),
            ]),
            new("git add --all ต่างกับ git add . ยังไง?", [Miura("--all เก็บทั้งคัมภีร์ ส่วน . เก็บเฉพาะห้องที่ยืนอยู่ ถ้ายืนที่ห้องบนสุดก็ได้ผลเหมือนกัน")]),
        ],
        Solution = ["git add fragment-1a.txt", "git add ."],
    };

    // ───────────── ชั้น 5 — การจารึกครั้งแรก (git commit) ─────────────
    public static Floor Floor05 => new()
    {
        Number = 5,
        Title = "การจารึกครั้งแรก",
        Hook = "เศษคัมภีร์ชิ้นที่ 1 บนแท่นเตรียมเริ่มสั่นไหว — ถ้าไม่จารึก พลังของมันจะสลาย",
        Scene = "altar",
        Panels = UiPanel.Terminal | UiPanel.Desk | UiPanel.Altar,
        Spells = Spells.F5,
        TimeLimitSeconds = 115,
        TargetCommands = 2,
        Setup = async ctx =>
        {
            await Lore.BlessAsync(ctx);
            await Lore.SeedTomeAsync(ctx, Page.Of("บันทึกของมิวรา", Lore.Miura, files: [("miura-note.txt", "อย่าลืมให้อาหารแมว\n")]));
            await ctx.Files.WriteAllTextAsync("fragment-1a.txt", "ศิษย์\n");
            await ctx.Files.WriteAllTextAsync("fragment-1b.txt", "ของ\n");
            await ctx.Files.WriteAllTextAsync("fragment-1c.txt", "ข้า…\n");
            await Lore.StageAsync(ctx, ".");
        },
        Intro =
        [
            Narrate("เศษคัมภีร์ชิ้นที่ 1 บนแท่นเตรียมสั่นแรงขึ้นเรื่อย ๆ"),
            Miura("จารึกมันลงคัมภีร์ซะ! และอย่าลืม 'คำจารึก' — อนาคตนายจะได้รู้ว่าจารึกอะไรไว้"),
        ],
        Objectives =
        [
            new()
            {
                Goal = "จารึกทุกอย่างบนแท่นเตรียมลงคัมภีร์ พร้อมคำจารึก",
                GuidedSpell = "git commit -m \"คำจารึกของนาย\"",
                Hints = ["คาถาจารึกคือ commit", "คำจารึกใส่หลัง -m ในเครื่องหมายคำพูด", "git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 1\""],
                IsComplete = c => c.After.HeadHistoryLength > c.Before.HeadHistoryLength && c.After.IsTracked("fragment-1a.txt"),
                Unlocks = UiPanel.Tome,
                OnComplete =
                [
                    Narrate("แสงสีทองจารึกลงบนหน้ากระดาษ เศษคัมภีร์หยุดสั่น"),
                    Narrate("…แล้วอักขระใหม่ก็ค่อย ๆ ปรากฏต่อท้าย fragment-1c.txt"),
                    Miura("เศษคัมภีร์ชิ้นที่ 2 ซ่อนอยู่ในชิ้นแรก! มันแก้ไขไฟล์ที่คัมภีร์รู้จักอยู่แล้ว"),
                ],
                WorldEvent = ctx => ctx.Files.WriteAllTextAsync("fragment-1c.txt", "ข้า…\nความรู้ที่ไม่ถูกจารึก\n"),
            },
            new()
            {
                Goal = "จารึกการแก้ไขนี้ทันที — โดยไม่ต้องร่ายวางขึ้นแท่นก่อน (คาถาเดียว)",
                GuidedSpell = "git commit -am \"คำจารึก\"",
                Hints = ["ไฟล์ที่คัมภีร์รู้จักแล้ว จารึกข้ามแท่นได้", "เพิ่มตัวเลือก -a (all) เข้าไปในคาถาจารึก", "git commit -am \"เศษคัมภีร์ชิ้นที่ 2\""],
                IsComplete = c => c.Cast("commit") && c.After.IsClean &&
                    c.Input.Split(' ').Any(t => t is "-a" or "--all" || (t.StartsWith('-') && !t.StartsWith("--") && t.Contains('a'))),
                OnComplete = [Narrate("หน้าที่สองของคัมภีร์เรืองแสง"), Miura("สองชิ้นในคราวเดียว ไม่เลวเลยศิษย์ฝึกหัด")],
            },
        ],
        Reward = Lore.Fragment(2),
        Reflection = "git commit -m บันทึก snapshot จาก staging area • git commit -am ข้าม add สำหรับไฟล์ที่ถูก track แล้ว",
        Ask =
        [
            new("ถ้าจารึกโดยไม่มีคำจารึกล่ะ?", [Miura("คัมภีร์จะปฏิเสธ (Aborting commit due to empty commit message) ทุกการจารึกต้องมีความหมาย")]),
            new("-a ใช้กับไฟล์ใหม่ได้ไหม?", [Miura("ไม่ได้ -a เก็บเฉพาะไฟล์ที่คัมภีร์รู้จักแล้ว ไฟล์ไร้ตรายังต้อง add ก่อน")]),
        ],
        Solution = ["git commit -m \"จารึกเศษคัมภีร์ชิ้นที่ 1\"", "git commit -am \"เศษคัมภีร์ชิ้นที่ 2\""],
    };
}
