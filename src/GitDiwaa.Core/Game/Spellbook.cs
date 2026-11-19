namespace GitDiwaa.Core.Game;

public enum MagicSchool
{
    Awakening,   // เวทปลุกพลัง
    Divination,  // เวทหยั่งรู้
    Inscription, // เวทจารึก
    Chronomancy, // เวทกาลเวลา
    Dimension,   // เวทมิติ
    Conjuration, // เวทเชื่อมคลัง
}

/// <summary>A git command presented as an in-world spell.</summary>
public sealed record Spell(
    string Key,
    string Incantation,
    string MagicName,
    MagicSchool School,
    string WhatItDoes,
    string RealMeaning);

/// <summary>
/// The in-game terminology layer: characters speak in magic terms,
/// the real git incantation is shown next to it so players connect the two.
/// </summary>
public static class Spellbook
{
    public static string SchoolName(MagicSchool school) => school switch
    {
        MagicSchool.Awakening => "🔮 เวทปลุกพลัง",
        MagicSchool.Divination => "👁  เวทหยั่งรู้",
        MagicSchool.Inscription => "✒️  เวทจารึก",
        MagicSchool.Chronomancy => "⏳ เวทกาลเวลา",
        MagicSchool.Dimension => "🌌 เวทมิติ",
        MagicSchool.Conjuration => "🏛  เวทเชื่อมคลัง",
        _ => school.ToString(),
    };

    public static IReadOnlyList<Spell> All { get; } =
    [
        new("version", "git --version", "คาถาวัดพลัง", MagicSchool.Awakening,
            "วงเวทตอบระดับพลัง Git ที่ตื่นอยู่ในตัวนาย", "แสดงเวอร์ชันของ Git ที่ติดตั้ง"),
        new("config", "git config --global user.name \"ชื่อ\"", "คาถาประกาศนาม / ผูกตราประทับ", MagicSchool.Awakening,
            "ทำให้ทุกการจารึกรู้ว่าใครเป็นผู้จารึก", "ตั้งชื่อและอีเมลผู้เขียน commit"),
        new("init", "git init", "คาถากำเนิดคัมภีร์", MagicSchool.Awakening,
            "สร้างคัมภีร์เวทส่วนตัวที่จดจำทุกการเปลี่ยนแปลงบนโต๊ะนี้", "สร้าง Git repository ใหม่"),
        new("status", "git status", "คาถาหยั่งสถานะ", MagicSchool.Divination,
            "เผยว่าเศษคัมภีร์ชิ้นไหนไร้ตรา ถูกแก้ หรืออยู่บนแท่นเตรียม", "ดูสถานะไฟล์ใน working tree และ staging area"),
        new("add", "git add <ไฟล์> | git add .", "คาถาวางขึ้นแท่น", MagicSchool.Inscription,
            "ยกเศษคัมภีร์จากโต๊ะขึ้นแท่นเตรียม รอการจารึก", "เพิ่มการเปลี่ยนแปลงเข้า staging area"),
        new("commit", "git commit -m \"คำจารึก\"", "คาถาจารึก", MagicSchool.Inscription,
            "จารึกทุกอย่างบนแท่นลงคัมภีร์อย่างถาวร พร้อมคำจารึก", "บันทึก snapshot เป็น commit ใหม่"),
        new("log", "git log --oneline", "คาถาคลี่ม้วนประวัติ", MagicSchool.Divination,
            "อ่านการจารึกทั้งหมดย้อนหลัง ใคร จารึกอะไร เมื่อไร", "ดูประวัติ commit"),
        new("diff", "git diff | git diff --staged", "คาถาเทียบรอย", MagicSchool.Divination,
            "เทียบรอยอักขระ ว่าอะไรถูกเติม (+) อะไรถูกลบ (-)", "ดูความแตกต่างของไฟล์"),
        new("show", "git show <รหัสจารึก>", "คาถาเปิดหน้าจารึก", MagicSchool.Divination,
            "เปิดดูรายละเอียดของการจารึกครั้งหนึ่ง", "ดูรายละเอียด commit"),
        new("restore", "git restore <ไฟล์> | git restore --staged <ไฟล์>", "คาถาฟื้นคืน", MagicSchool.Chronomancy,
            "ลบรอยสาปบนโต๊ะ หรือนำเศษคัมภีร์ลงจากแท่น", "คืนค่าไฟล์ / ยกเลิก stage"),
        new("reset", "git reset --soft|--mixed|--hard HEAD~1", "เวทย้อนกาล", MagicSchool.Chronomancy,
            "เลื่อนที่คั่นหน้ากลับในอดีต: soft เก็บไว้บนแท่น, mixed เก็บไว้บนโต๊ะ, hard ลบหมด", "ย้าย HEAD/branch ไปยัง commit ก่อนหน้า"),
        new("branch", "git branch <ชื่อ> | git branch -d <ชื่อ>", "คาถาแยกมิติ", MagicSchool.Dimension,
            "เปิดเส้นเวลาคู่ขนานที่ทดลองได้โดยไม่กระทบมิติหลัก", "สร้าง/ลบ/ดู branch"),
        new("switch", "git switch <มิติ> | git switch -c <มิติใหม่>", "คาถาประตูมิติ", MagicSchool.Dimension,
            "ก้าวไปยืนในมิติอื่น โลกรอบตัวจะเปลี่ยนตาม", "เปลี่ยน branch"),
        new("merge", "git merge <มิติ>", "พิธีหลอมมิติ", MagicSchool.Dimension,
            "หลอมเส้นเวลาของอีกมิติเข้ากับมิติที่ยืนอยู่", "รวม branch"),
        new("clone", "git clone https://archive.diwaa/<ชื่อ>.git", "คาถาคัดลอกคัมภีร์", MagicSchool.Conjuration,
            "คัดลอกคัมภีร์ทั้งเล่มพร้อมประวัติจากคลังเวทกลาง", "คัดลอก remote repository"),
        new("remote", "git remote -v | git remote add <ชื่อ> <ที่อยู่>", "คาถาสายเชื่อม", MagicSchool.Conjuration,
            "ดู/สร้างสายเชื่อมระหว่างคัมภีร์ของนายกับคลังเวท", "จัดการ remote"),
        new("fetch", "git fetch", "คาถาส่องคลัง", MagicSchool.Conjuration,
            "มองว่าคลังเวทมีจารึกใหม่อะไร โดยยังไม่รวมเข้าคัมภีร์", "ดาวน์โหลดข้อมูลจาก remote"),
        new("pull", "git pull", "คาถาเรียกความรู้", MagicSchool.Conjuration,
            "ดึงจารึกใหม่จากคลังเวทลงมารวมกับคัมภีร์ของนาย", "fetch + merge จาก remote"),
        new("push", "git push -u origin main", "คาถาส่งผ่านประตูเวท", MagicSchool.Conjuration,
            "ส่งการจารึกของนายเข้าคลังเวทกลาง", "อัปโหลด commit ไปยัง remote"),
    ];

    public static Spell? Find(string key) => All.FirstOrDefault(s => s.Key == key);

    /// <summary>Extracts the spell key (git subcommand) from a raw command line.</summary>
    public static string? KeyOf(string commandLine)
    {
        var parts = commandLine.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length < 2 || parts[0] != "git") return null;
        return parts[1] is "--version" or "-v" or "version" ? "version" : parts[1];
    }
}
