namespace GitDiwaa.Core.Levels;

/// <summary>Level data from the Notion design doc. Levels 4-40 are added as their final states are specified.</summary>
public static class LevelCatalog
{
    private static readonly Lazy<IReadOnlyList<LevelDefinition>> All = new(() =>
    [
        LevelBuilder.ForLevel(1)
            .Titled("ตรวจสอบและตั้งค่าผู้ใช้งาน (git --version + git config)")
            .AddTask("ตรวจสอบพลัง Git")
            .AddTask("ร่ายคาถาประกาศนาม")
            .AddTask("ร่ายคาถาผูกตราประทับวิญญาณ")
            .AddTask("ตรวจสอบว่าลงทะเบียนสำเร็จ")
            .Build(),

        LevelBuilder.ForLevel(2)
            .Titled("สร้างพื้นที่ Git Repository (git init)")
            .AddTask("ร่ายคาถาสร้างคัมภีร์เวทส่วนตัว")
            .ExpectFinalState(s => s.Initialized())
            .Build(),

        LevelBuilder.ForLevel(3)
            .Titled("ตรวจสอบสถานะไฟล์ (git status)")
            .AddTask("ตรวจสอบสถานะคัมภีร์เวทส่วนตัว อย่างน้อย 1 ครั้ง")
            .ExpectFinalState(s => s.Initialized())
            .Build(),
    ]);

    public static IReadOnlyList<LevelDefinition> Levels => All.Value;

    public static LevelDefinition? Find(int number) => Levels.FirstOrDefault(l => l.Number == number);

    public static IEnumerable<LevelDefinition> InAct(GameAct act) => Levels.Where(l => l.Act == act);
}
