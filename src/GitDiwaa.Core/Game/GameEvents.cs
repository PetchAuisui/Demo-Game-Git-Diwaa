namespace GitDiwaa.Core.Game;

public abstract record GameEvent;

public sealed record SpokenLine(Line Line) : GameEvent;
public sealed record SpellOutput(string Command, string Output, bool Success) : GameEvent;
public sealed record SpellRejected(string Command, string Reason) : GameEvent;
public sealed record EffectPlayed(WorldEffect Effect) : GameEvent;
public sealed record ObjectiveDone(int Index, string Goal) : GameEvent;
public sealed record ObjectiveStarted(int Index, Objective Objective, bool Guided) : GameEvent;
public sealed record ScrollText(string Path, string Content) : GameEvent;
public sealed record HintGiven(int Level, int MaxLevel, string Text) : GameEvent;
public sealed record FragmentObtained(Fragment Fragment) : GameEvent;
public sealed record FloorCleared(ScoreCard Score, string Reflection) : GameEvent;
public sealed record FloorFailed(string Reason) : GameEvent;
public sealed record Notice(string Text) : GameEvent;

/// <summary>Translates common real git messages into one in-world line from Miura (the real text is still shown).</summary>
public static class MiuraInterpreter
{
    public static string? Explain(string output)
    {
        var o = output.ToLowerInvariant();
        return o switch
        {
            _ when o.Contains("not a git repository") => "ที่นี่ยังไม่มีคัมภีร์เวท — ต้องกำเนิดคัมภีร์ก่อน หรือเดินเข้าห้องที่มีคัมภีร์",
            _ when o.Contains("nothing to commit") => "แท่นเตรียมว่างเปล่า ไม่มีอะไรให้จารึก",
            _ when o.Contains("nothing added to commit") => "ยังไม่มีเศษคัมภีร์บนแท่นเตรียมเลย ต้องวางขึ้นแท่นก่อน",
            _ when o.Contains("did not match any file") || o.Contains("pathspec") => "ไม่มีเศษคัมภีร์ชื่อนั้นบนโต๊ะ ลองสำรวจชื่อให้ดี",
            _ when o.Contains("aborting commit due to empty commit message") => "การจารึกต้องมีคำจารึกเสมอ ใช้ -m \"ข้อความ\"",
            _ when o.Contains("please tell me who you are") => "หอคอยยังไม่รู้ว่านายเป็นใคร ต้องประกาศนามก่อน",
            _ when o.Contains("not fully merged") => "มิตินั้นยังมีจารึกที่ไม่ถูกหลอม ถ้าปิดตอนนี้จารึกจะหาย",
            _ when o.Contains("already exists") => "มีสิ่งนั้นอยู่แล้ว ลองใช้ชื่ออื่น",
            _ when o.Contains("invalid reference") || o.Contains("not a valid") || o.Contains("unknown revision") => "ไม่มีมิติหรือจารึกนั้นอยู่จริง",
            _ when o.Contains("conflict") => "สองมิติจารึกอักขระต่างกัน ณ จุดเดียวกัน นายต้องตัดสินเอง",
            _ when o.Contains("rejected") && o.Contains("fetch first") => "คลังเวทมีความรู้ใหม่ที่นายยังไม่มี เรียกความรู้ลงมาก่อนแล้วค่อยส่ง",
            _ when o.Contains("no upstream") || o.Contains("has no upstream") => "เส้นทางนี้ยังไม่ผูกกับคลังเวท ต้องส่งพร้อม -u ครั้งแรก",
            _ when o.Contains("does not appear to be a git repository") => "สายเชื่อมนั้นไม่ได้ชี้ไปที่คลังเวทใด",
            _ when o.Contains("unknown option") || o.Contains("usage:") || o.Contains("is not a git command") => "อักขระคาถาผิดไปนิด ตรวจขีด เว้นวรรค และชื่อคาถาอีกครั้ง",
            _ when o.Contains("you have unstaged changes") || o.Contains("would be overwritten") => "บนโต๊ะยังมีงานที่ยังไม่จารึก ประตูมิติจะทับมัน",
            _ => null,
        };
    }
}
