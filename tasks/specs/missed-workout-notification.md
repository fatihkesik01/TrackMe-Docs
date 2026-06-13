# Spec: Missed Workout & Nutrition Notifications

## Overview

A background service runs daily and checks each trainer-athlete pair. If an athlete:
- Has an **active program** but hasn't completed a workout session in the last **7 days**
- Has an **active nutrition goal** but hasn't logged nutrition in the last **3 days**

...their trainer receives an in-app notification (+ SignalR real-time push).

Duplicate suppression: we don't re-send the same alert type for the same athlete to the same trainer
if one was already sent within the suppression window (7 days for workout, 3 days for nutrition).

**Priority:** P1.5  
**Effort:** M  
**Migration:** `Phase15_MissedActivityNotification` (adds `MissedWorkout` and `MissedNutritionLog` to `NotificationType` enum — enum values are stored as strings, so no schema change is needed for the enum itself, BUT we need a new table to track sent alerts. See below.)

---

## Dependencies

- Existing notification system (`AppNotification`, `EndpointHelpers.QueueNotificationAsync`, SignalR push) — already in place.
- Existing `WorkoutSession`, `DailyNutritionLog`, `NutritionGoal`, `WorkoutProgram`, `TrainerAthleteRelationship` entities — all in place.

---

## Backend

### 1. Add new NotificationType enum values

File: `src/TrackMe.Api/Models/Enums.cs`

```csharp
public enum NotificationType
{
    // ... existing values ...
    MissedWorkout,        // NEW
    MissedNutritionLog,   // NEW
}
```

Since `NotificationType` is stored as a `string` (`HasConversion<string>()`), no column type migration is needed for the enum itself.

### 2. New entity: `MissedActivityAlert`

File: `src/TrackMe.Api/Models/MissedActivityAlert.cs`

```csharp
namespace TrackMe.Api.Models;

public sealed class MissedActivityAlert
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid TrainerId { get; set; }       // trainer who received the notification
    public Guid AthleteId { get; set; }       // athlete who missed activity
    public string AlertType { get; set; } = string.Empty; // "workout" | "nutrition"
    public DateTimeOffset SentAt { get; set; } = DateTimeOffset.UtcNow;
    public Trainer Trainer { get; set; } = null!;
    public Athlete Athlete { get; set; } = null!;
}
```

### 3. DbContext — add DbSet and config

File: `src/TrackMe.Api/Data/TrackMeDbContext.cs`

**DbSet:**
```csharp
public DbSet<MissedActivityAlert> MissedActivityAlerts => Set<MissedActivityAlert>();
```

**OnModelCreating:**
```csharp
modelBuilder.Entity<MissedActivityAlert>(entity =>
{
    entity.ToTable("missed_activity_alerts");
    entity.HasKey(e => e.Id);
    entity.HasIndex(e => new { e.TrainerId, e.AthleteId, e.AlertType, e.SentAt });
    entity.Property(e => e.Id).HasColumnName("id");
    entity.Property(e => e.TrainerId).HasColumnName("trainer_id").IsRequired();
    entity.Property(e => e.AthleteId).HasColumnName("athlete_id").IsRequired();
    entity.Property(e => e.AlertType).HasColumnName("alert_type").HasMaxLength(20).IsRequired();
    entity.Property(e => e.SentAt).HasColumnName("sent_at").IsRequired();
    entity.HasOne(e => e.Trainer).WithMany().HasForeignKey(e => e.TrainerId).OnDelete(DeleteBehavior.Cascade);
    entity.HasOne(e => e.Athlete).WithMany().HasForeignKey(e => e.AthleteId).OnDelete(DeleteBehavior.Cascade);
});
```

### 4. Migration

```powershell
dotnet ef migrations add Phase15_MissedActivityNotification --project src/TrackMe.Api/TrackMe.Api.csproj
```

### 5. New background service: `MissedActivityAlertService`

File: `src/TrackMe.Api/Services/MissedActivityAlertService.cs`

```csharp
using Microsoft.EntityFrameworkCore;
using TrackMe.Api.Data;
using TrackMe.Api.Models;
using Microsoft.AspNetCore.SignalR;
using TrackMe.Api.Hubs;

namespace TrackMe.Api.Services;

public sealed class MissedActivityAlertService(
    IServiceScopeFactory scopeFactory,
    ILogger<MissedActivityAlertService> logger)
    : BackgroundService
{
    private static readonly TimeSpan WorkoutWindow = TimeSpan.FromDays(7);
    private static readonly TimeSpan NutritionWindow = TimeSpan.FromDays(3);
    private static readonly TimeSpan AlertSuppression = TimeSpan.FromDays(7); // don't re-alert within this window

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // Wait 10 minutes on startup so DB is fully up and migrations applied
        await Task.Delay(TimeSpan.FromMinutes(10), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            try { await RunAsync(stoppingToken); }
            catch (Exception ex) when (ex is not OperationCanceledException)
            { logger.LogError(ex, "MissedActivityAlertService failed"); }

            await Task.Delay(TimeSpan.FromHours(24), stoppingToken);
        }
    }

    private async Task RunAsync(CancellationToken ct)
    {
        using var scope = scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<TrackMeDbContext>();
        var hubContext = scope.ServiceProvider.GetRequiredService<IHubContext<NotificationHub>>();

        var now = DateTimeOffset.UtcNow;
        var today = DateOnly.FromDateTime(now.UtcDateTime);

        // Load all accepted coaching relationships with trainer email + athlete info
        var relationships = await db.TrainerAthleteRelationships
            .Where(r => r.Status == RelationshipStatus.Accepted)
            .Include(r => r.Trainer)
            .Include(r => r.Athlete)
            .AsNoTracking()
            .ToListAsync(ct);

        int workoutAlerts = 0, nutritionAlerts = 0;

        foreach (var rel in relationships)
        {
            // ── Missed workout check ──────────────────────────────────────────
            var hasActiveProgram = await db.WorkoutPrograms.AnyAsync(p =>
                p.AthleteId == rel.AthleteId &&
                p.IsActive &&
                (p.EndsOn == null || p.EndsOn >= today), ct);

            if (hasActiveProgram)
            {
                var lastSession = await db.WorkoutSessions
                    .Where(s => s.AthleteId == rel.AthleteId && s.Status == SessionStatus.Completed)
                    .OrderByDescending(s => s.CompletedAt)
                    .Select(s => s.CompletedAt)
                    .FirstOrDefaultAsync(ct);

                var missedWorkout = lastSession == null || now - lastSession > WorkoutWindow;

                if (missedWorkout)
                {
                    var alreadyAlerted = await db.MissedActivityAlerts.AnyAsync(a =>
                        a.TrainerId == rel.TrainerId &&
                        a.AthleteId == rel.AthleteId &&
                        a.AlertType == "workout" &&
                        a.SentAt > now - AlertSuppression, ct);

                    if (!alreadyAlerted)
                    {
                        var notification = await EndpointHelpers.QueueNotificationAsync(
                            db,
                            rel.Trainer.Email,
                            NotificationType.MissedWorkout,
                            "Antrenman yapılmadı",
                            $"{rel.Athlete.FullName} son {(int)WorkoutWindow.TotalDays} günde antrenman yapmadı.",
                            senderName: rel.Athlete.FullName,
                            senderRole: "Athlete");

                        db.MissedActivityAlerts.Add(new MissedActivityAlert
                        {
                            TrainerId = rel.TrainerId,
                            AthleteId = rel.AthleteId,
                            AlertType = "workout",
                            SentAt = now
                        });

                        await db.SaveChangesAsync(ct);

                        if (notification is not null)
                            await EndpointHelpers.PushNotificationAsync(hubContext, notification);

                        workoutAlerts++;
                    }
                }
            }

            // ── Missed nutrition check ────────────────────────────────────────
            var hasActiveGoal = await db.NutritionGoals.AnyAsync(g =>
                g.AthleteId == rel.AthleteId && g.IsActive, ct);

            if (hasActiveGoal)
            {
                var lastLog = await db.DailyNutritionLogs
                    .Where(l => l.AthleteId == rel.AthleteId)
                    .OrderByDescending(l => l.Date)
                    .Select(l => l.Date)
                    .FirstOrDefaultAsync(ct);

                var missedNutrition = lastLog == default ||
                    today.DayNumber - lastLog.DayNumber > (int)NutritionWindow.TotalDays;

                if (missedNutrition)
                {
                    var alreadyAlerted = await db.MissedActivityAlerts.AnyAsync(a =>
                        a.TrainerId == rel.TrainerId &&
                        a.AthleteId == rel.AthleteId &&
                        a.AlertType == "nutrition" &&
                        a.SentAt > now - AlertSuppression, ct);

                    if (!alreadyAlerted)
                    {
                        var notification = await EndpointHelpers.QueueNotificationAsync(
                            db,
                            rel.Trainer.Email,
                            NotificationType.MissedNutritionLog,
                            "Beslenme kaydedilmedi",
                            $"{rel.Athlete.FullName} son {(int)NutritionWindow.TotalDays} günde beslenme kaydetmedi.",
                            senderName: rel.Athlete.FullName,
                            senderRole: "Athlete");

                        db.MissedActivityAlerts.Add(new MissedActivityAlert
                        {
                            TrainerId = rel.TrainerId,
                            AthleteId = rel.AthleteId,
                            AlertType = "nutrition",
                            SentAt = now
                        });

                        await db.SaveChangesAsync(ct);

                        if (notification is not null)
                            await EndpointHelpers.PushNotificationAsync(hubContext, notification);

                        nutritionAlerts++;
                    }
                }
            }
        }

        logger.LogInformation(
            "MissedActivityAlertService: sent {W} workout alert(s), {N} nutrition alert(s)",
            workoutAlerts, nutritionAlerts);
    }
}
```

### 6. Register in Program.cs

File: `src/TrackMe.Api/Program.cs`

In the `// ─── Background Services ───` section:

```csharp
builder.Services.AddHostedService<MissedActivityAlertService>();
```

---

## Frontend

### i18n.js — notification display strings

The notification center already renders all `AppNotification` types. Add display strings for the two new types if the frontend switches on `type`:

```js
// TR:
missedWorkoutNotif: 'Antrenman yapılmadı',
missedNutritionNotif: 'Beslenme kaydedilmedi',

// EN:
missedWorkoutNotif: 'Missed workout',
missedNutritionNotif: 'Nutrition not logged',
```

No new views needed — notifications appear in the existing `NotificationsView.jsx`.

---

## Docs to update after implementation

- `TrackMe-Docs/tasks/phases.md` — add Phase 15 entry, update migration count to 60
- `TrackMe-Docs/tasks/backlog.md` — mark "Bildirim: athlete günlük logu atladığında trainer'a uyarı" ✅
- `TrackMe-Docs/architecture/overview.md` — add `MissedActivityAlertService` to startup sequence section
- `TrackMe-Docs/database/migration-strategy.md` — add Phase15 row
- `TrackMe-Api/README.md` — update migration count, mention new background service

---

## Testing checklist

- [ ] `MissedActivityAlert` table exists in DB after migration
- [ ] `MissedWorkout` and `MissedNutritionLog` appear in Scalar/OpenAPI notification type docs
- [ ] Service logs "sent X workout alert(s)" on startup run
- [ ] An athlete with an active program and 0 sessions in last 7 days → trainer gets `MissedWorkout` notification
- [ ] Same alert is NOT re-sent within 7 days (suppression check)
- [ ] An athlete with an active nutrition goal and 0 logs in last 3 days → trainer gets `MissedNutritionLog` notification
- [ ] Notifications appear in trainer's `NotificationsView`
- [ ] SignalR pushes notification in real time (trainer receives toast if online)
- [ ] Athletes without an active program are skipped for workout check
- [ ] Athletes without an active nutrition goal are skipped for nutrition check
- [ ] Build: `dotnet build` 0 errors
