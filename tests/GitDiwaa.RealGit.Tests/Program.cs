using GitDiwaa.Tests;

Console.OutputEncoding = System.Text.Encoding.UTF8;
RealGitTests.Register();
QuestEngineTests.Register();
return await TestRunner.RunAllAsync(args.FirstOrDefault());
