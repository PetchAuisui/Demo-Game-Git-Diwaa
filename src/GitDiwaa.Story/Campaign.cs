using GitDiwaa.Core.Game;

namespace GitDiwaa.Story;

public static partial class Act1
{
    public static IReadOnlyList<Floor> Floors =>
    [
        Floor01, Floor02, Floor03, Floor04, Floor05,
        Floor06, Floor07, Floor08, Floor09, Floor10,
        Floor11, Floor12, Floor13, Floor14, Floor15,
    ];
}

public static class Campaign
{
    public const string Title = "Git-Diwaa: บททดสอบแห่งหอคอยเวทมนตร์";

    public static IReadOnlyList<Floor> Floors => Act1.Floors;

    public static Floor? Find(int number) => Floors.FirstOrDefault(f => f.Number == number);
}
