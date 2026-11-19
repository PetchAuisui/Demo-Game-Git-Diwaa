using GitDiwaa.Tests;

Console.OutputEncoding = System.Text.Encoding.UTF8;
RealGitTests.Register();
QuestEngineTests.Register();
Act1PlaythroughTests.Register();
return await TestRunner.RunAllAsync(args.FirstOrDefault());
