using GitDiwaa.Server.Persistence;
using GitDiwaa.Server.Persistence.InMemory;

namespace GitDiwaa.Server.Tests;

internal static class RepositoryTests
{
    public static async Task RunAsync(TestRunner runner)
    {
        await runner.RunAsync("UserRepo_AddThenFind_ByIdUsernameEmail", async static () =>
        {
            var repo = new InMemoryUserRepository();
            var user = TestData.NewUser("mage01", "mage@example.com");

            var added = await repo.TryAddAsync(user);
            Assert.True(added);

            var byId = await repo.FindByIdAsync(user.Id);
            Assert.Equal(user, byId);

            var byUsername = await repo.FindByUsernameAsync("mage01");
            Assert.Equal(user, byUsername);

            var byEmail = await repo.FindByEmailAsync("mage@example.com");
            Assert.Equal(user, byEmail);
        });

        await runner.RunAsync("UserRepo_FindUnknown_ReturnsNull", async static () =>
        {
            var repo = new InMemoryUserRepository();

            Assert.Equal(null, await repo.FindByIdAsync(Guid.NewGuid()));
            Assert.Equal(null, await repo.FindByUsernameAsync("unknown"));
            Assert.Equal(null, await repo.FindByEmailAsync("unknown@example.com"));
        });

        await runner.RunAsync("UserRepo_DuplicateUsername_Rejected", async static () =>
        {
            var repo = new InMemoryUserRepository();
            var user1 = TestData.NewUser("mage01", "user1@example.com");
            var user2 = TestData.NewUser("mage01", "user2@example.com") with { Id = Guid.NewGuid() };

            Assert.True(await repo.TryAddAsync(user1));
            Assert.False(await repo.TryAddAsync(user2));
        });

        await runner.RunAsync("UserRepo_DuplicateEmail_Rejected", async static () =>
        {
            var repo = new InMemoryUserRepository();
            var user1 = TestData.NewUser("mage01", "same@example.com");
            var user2 = TestData.NewUser("mage02", "same@example.com") with { Id = Guid.NewGuid() };

            Assert.True(await repo.TryAddAsync(user1));
            Assert.False(await repo.TryAddAsync(user2));
        });

        await runner.RunAsync("UserRepo_ConcurrentSameUsername_OnlyOneWins", async static () =>
        {
            var repo = new InMemoryUserRepository();
            var tasks = new Task<bool>[50];

            for (int i = 0; i < 50; i++)
            {
                var user = TestData.NewUser("concurrent_mage", $"user{i}@example.com") with { Id = Guid.NewGuid() };
                tasks[i] = Task.Run(() => repo.TryAddAsync(user));
            }

            var results = await Task.WhenAll(tasks);
            int successCount = results.Count(r => r);

            Assert.Equal(1, successCount, "Only exactly one task must succeed in adding duplicate username.");
        });

        await runner.RunAsync("UserRepo_Update_ReplacesRecord_UnknownThrows", async static () =>
        {
            var repo = new InMemoryUserRepository();
            var user = TestData.NewUser("mage01", "mage@example.com");
            await repo.TryAddAsync(user);

            var updated = user with { DisplayName = "Arch Mage Supreme", FailedLoginCount = 2 };
            await repo.UpdateAsync(updated);

            var fetched = await repo.FindByIdAsync(user.Id);
            Assert.Equal("Arch Mage Supreme", fetched?.DisplayName);
            Assert.Equal(2, fetched?.FailedLoginCount);

            var unknownUser = TestData.NewUser("nobody", "nobody@example.com") with { Id = Guid.NewGuid() };
            await Assert.ThrowsAsync<InvalidOperationException>(() => repo.UpdateAsync(unknownUser));
        });

        await runner.RunAsync("UserRepo_Update_CannotStealUsernameOrEmail", async static () =>
        {
            var repo = new InMemoryUserRepository();
            var userA = TestData.NewUser("mage_a", "a@x.com");
            var userB = TestData.NewUser("mage_b", "b@x.com");

            Assert.True(await repo.TryAddAsync(userA));
            Assert.True(await repo.TryAddAsync(userB));

            var stealUsername = userA with { Username = userB.Username };
            await Assert.ThrowsAsync<InvalidOperationException>(() => repo.UpdateAsync(stealUsername));

            var stealEmail = userA with { EmailNormalized = userB.EmailNormalized };
            await Assert.ThrowsAsync<InvalidOperationException>(() => repo.UpdateAsync(stealEmail));

            var fetchedBByEmail = await repo.FindByEmailAsync(userB.EmailNormalized);
            Assert.Equal(userB, fetchedBByEmail);

            var fetchedBByUsername = await repo.FindByUsernameAsync(userB.Username);
            Assert.Equal(userB, fetchedBByUsername);
        });

        runner.Run("UserRecord_ToString_HidesSecrets", static () =>
        {
            var user = TestData.NewUser("mage01", "secret_mage@example.com");
            var text = user.ToString();

            Assert.DoesNotContain(text, "test-hash");
            Assert.DoesNotContain(text, "secret_mage@example.com");
            Assert.Contains(text, "PasswordHash = ***");
            Assert.Contains(text, "Email = ***");
            Assert.Contains(text, "mage01");
        });

        await runner.RunAsync("SessionRepo_AddThenFindByHash", async static () =>
        {
            var repo = new InMemorySessionRepository();
            var now = DateTimeOffset.UtcNow;
            var session = new SessionRecord(
                Guid.NewGuid(),
                Guid.NewGuid(),
                "dummy-token-hash-64-hex",
                true,
                now,
                now.AddDays(30),
                now,
                null);

            await repo.AddAsync(session);

            var fetched = await repo.FindByTokenHashAsync("dummy-token-hash-64-hex");
            Assert.Equal(session, fetched);

            var notFound = await repo.FindByTokenHashAsync("unknown-hash");
            Assert.Equal(null, notFound);
        });

        await runner.RunAsync("SessionRepo_Add_DuplicateIdOrHash_Throws", async static () =>
        {
            var repo = new InMemorySessionRepository();
            var now = DateTimeOffset.UtcNow;
            var sessionId = Guid.NewGuid();
            var session1 = new SessionRecord(sessionId, Guid.NewGuid(), "hash-unique-1", false, now, now.AddHours(1), now, null);
            await repo.AddAsync(session1);

            var dupId = session1 with { TokenHash = "hash-different" };
            await Assert.ThrowsAsync<InvalidOperationException>(() => repo.AddAsync(dupId));

            var dupHash = new SessionRecord(Guid.NewGuid(), Guid.NewGuid(), "hash-unique-1", false, now, now.AddHours(1), now, null);
            await Assert.ThrowsAsync<InvalidOperationException>(() => repo.AddAsync(dupHash));
        });

        await runner.RunAsync("SessionRepo_Update_PersistsRevocation", async static () =>
        {
            var repo = new InMemorySessionRepository();
            var now = DateTimeOffset.UtcNow;
            var session = new SessionRecord(
                Guid.NewGuid(),
                Guid.NewGuid(),
                "dummy-token-hash-to-revoke",
                false,
                now,
                now.AddHours(12),
                now,
                null);

            await repo.AddAsync(session);

            var revoked = session with { RevokedAt = now.AddMinutes(5) };
            await repo.UpdateAsync(revoked);

            var fetched = await repo.FindByTokenHashAsync("dummy-token-hash-to-revoke");
            Assert.Equal(revoked, fetched);
            Assert.True(fetched?.RevokedAt is not null);
        });

        await runner.RunAsync("SessionRepo_Update_CannotChangeTokenHashOrUser", async static () =>
        {
            var repo = new InMemorySessionRepository();
            var now = DateTimeOffset.UtcNow;
            var session = new SessionRecord(
                Guid.NewGuid(),
                Guid.NewGuid(),
                "hash-original",
                false,
                now,
                now.AddHours(1),
                now,
                null);

            await repo.AddAsync(session);

            var changeHash = session with { TokenHash = "hash-new-attempt" };
            await Assert.ThrowsAsync<InvalidOperationException>(() => repo.UpdateAsync(changeHash));

            var changeUser = session with { UserId = Guid.NewGuid() };
            await Assert.ThrowsAsync<InvalidOperationException>(() => repo.UpdateAsync(changeUser));

            var original = await repo.FindByTokenHashAsync("hash-original");
            Assert.Equal(session, original);

            var nonExistent = await repo.FindByTokenHashAsync("hash-new-attempt");
            Assert.Equal(null, nonExistent);
        });

        await runner.RunAsync("SessionRepo_RevokeAllForUser_OnlyThatUser", async static () =>
        {
            var repo = new InMemorySessionRepository();
            var userA = Guid.NewGuid();
            var userB = Guid.NewGuid();
            var now = DateTimeOffset.UtcNow;

            var sessionA1 = new SessionRecord(Guid.NewGuid(), userA, "hash-a1", false, now, now.AddHours(1), now, null);
            var sessionA2 = new SessionRecord(Guid.NewGuid(), userA, "hash-a2", false, now, now.AddHours(1), now, null);
            var sessionB1 = new SessionRecord(Guid.NewGuid(), userB, "hash-b1", false, now, now.AddHours(1), now, null);

            await repo.AddAsync(sessionA1);
            await repo.AddAsync(sessionA2);
            await repo.AddAsync(sessionB1);

            var revokeTime = now.AddMinutes(10);
            await repo.RevokeAllForUserAsync(userA, revokeTime);

            var fetchedA1 = await repo.FindByTokenHashAsync("hash-a1");
            var fetchedA2 = await repo.FindByTokenHashAsync("hash-a2");
            var fetchedB1 = await repo.FindByTokenHashAsync("hash-b1");

            Assert.Equal(revokeTime, fetchedA1?.RevokedAt);
            Assert.Equal(revokeTime, fetchedA2?.RevokedAt);
            Assert.Equal(null, fetchedB1?.RevokedAt);
        });
        
        await runner.RunAsync("SessionRepo_TryRevoke_SucceedsOnlyOnce", async static () =>
        {
            var repo = new InMemorySessionRepository();
            var now = DateTimeOffset.UtcNow;
            var sessionId = Guid.NewGuid();
            var session = new SessionRecord(sessionId, Guid.NewGuid(), "hash-atomic", false, now, now.AddHours(1), now, null);
            await repo.AddAsync(session);

            var firstRevoke = await repo.TryRevokeAsync(sessionId, now.AddMinutes(1));
            Assert.True(firstRevoke);

            var secondRevoke = await repo.TryRevokeAsync(sessionId, now.AddMinutes(2));
            Assert.False(secondRevoke);

            var nonExistentRevoke = await repo.TryRevokeAsync(Guid.NewGuid(), now);
            Assert.False(nonExistentRevoke);
        });

        await runner.RunAsync("SessionRepo_Touch_DoesNotClearRevocation", async static () =>
        {
            var repo = new InMemorySessionRepository();
            var now = DateTimeOffset.UtcNow;
            var sessionId = Guid.NewGuid();
            var session = new SessionRecord(sessionId, Guid.NewGuid(), "hash-touch", false, now, now.AddHours(1), now, null);
            await repo.AddAsync(session);

            var revokeTime = now.AddMinutes(5);
            await repo.TryRevokeAsync(sessionId, revokeTime);

            var touchTime = now.AddMinutes(10);
            await repo.TouchAsync(sessionId, touchTime);

            var fetched = await repo.FindByTokenHashAsync("hash-touch");
            Assert.Equal(revokeTime, fetched?.RevokedAt);
            Assert.Equal(touchTime, fetched?.LastUsedAt);
        });
    }
}