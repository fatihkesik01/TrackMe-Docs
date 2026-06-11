# Daily Engagement & Retention (Phase 4)

## Overview

Phase 4 adds athlete-focused daily engagement features designed to reduce friction from "open app" to "start workout." No new migrations were needed — all additions are pure read endpoints or enum value additions.

---

## Today's Workout Widget (Dashboard)

### Purpose

Athletes see a single action card on the Dashboard showing either today's scheduled workout or the next upcoming one. One tap navigates directly into WorkoutMode (or continues an in-progress session).

### Backend: `GET /api/analytics/athletes/{id}/today-workout`

Returns `TodayWorkoutDto`:

```json
{
  "today": {
    "programId": "...", "programTitle": "Push/Pull/Legs",
    "dayId": "...", "dayTitle": "Push Day",
    "exerciseCount": 6,
    "trainerName": "Ali Veli",
    "activeSessionId": null, "hasActiveSession": false, "alreadyCompleted": false
  },
  "next": {
    "programId": "...", "programTitle": "Push/Pull/Legs",
    "dayId": "...", "dayTitle": "Pull Day",
    "date": "2026-06-13", "trainerName": "Ali Veli"
  }
}
```

**Day date calculation:** `RescheduledDate ?? program.StartsOn + day.DayNumber`

- If a day was manually rescheduled, `RescheduledDate` takes precedence.
- `today` is `null` if no day is scheduled for today's local date.
- `next` is `null` if no future day exists after today.

### Frontend: `DashboardView.jsx`

**TodayWorkoutCard** — rendered only in athlete mode when programs exist:
- Shows day title, exercise count badge, trainer name badge
- "Antrenmanı Başla" button → opens WorkoutMode
- "Devam Et" button → continues an in-progress session
- "Bugün Tamamlandı" badge → workout already done today
- If today is a rest day: shows "Bugün Dinlenme Günü" + next workout date + "Sonraki Antrenman" info

**GettingStartedCards** — shown only when athlete has no programs:
- "Program Oluştur" card → navigates to `myProgram`
- "Antrenör Bul" card → navigates to `relationships`
- "Program Keşfet" card → navigates to `publishedPrograms`

**Pending Update Banner** — shown when `programs.some(p => p.hasPendingUpdate)`:
- Alert banner with "Güncellemeyi İncele" link → navigates to `myProgram`

---

## Athlete Analytics Screen (New View)

### Route

`analytics` — added to `ATHLETE_NAV` between sessions and bodyMetrics.

### File: `AthleteAnalyticsView.jsx`

Fetches via `Promise.all`:
1. `GET /api/analytics/athletes/{id}` — overview (extended with `totalSets`, `totalWeightKg`)
2. `GET /api/analytics/athletes/{id}/rpe-trend?days=30`
3. `GET /api/analytics/athletes/{id}/volume-trend?days=30`
4. `GET /api/analytics/athletes/{id}/consistency`

**Stat cards (8):**

| Stat | Source |
|------|--------|
| Total sessions | `overview.totalSessions` |
| This week | `overview.weeklySessions` |
| This month | `overview.monthlySessions` |
| Current streak | `consistency.currentStreakDays` |
| Total duration | `overview.totalDurationMinutes` (h or min) |
| Average RPE | `overview.averageRpe` |
| Total sets | `overview.totalSets` (warm-up excluded) |
| Total volume | `overview.totalWeightKg` (kg or lbs) |

Reuses existing `RpeTrendChart`, `VolumeTrendChart`, `ConsistencyGrid` components.

### Backend: Extended `GetAthleteOverview`

`AthleteAnalyticsDto` extended with:
- `TotalSets` — count of completed, non-warm-up sets across all completed sessions
- `TotalWeightKg` — sum of `Reps × WeightKg` for the same set population

Warm-up sets (`IsWarmUp = true`) are excluded from both totals.

---

## Follow Notifications (NewFollower)

### Enum: `NotificationType.NewFollower = 12`

Added as int 12. No migration needed (stored as int in DB).

### Backend: `FollowEndpoints.Follow`

When a user follows another:
1. `EndpointHelpers.QueueNotificationAsync` creates a DB notification (`NewFollower` type) for the followed user.
2. `EndpointHelpers.PushNotificationAsync` pushes it via SignalR.
3. Both happen before `SaveChangesAsync` so the notification and the follow row are committed atomically.

Notification message format: `"{callerName} seni takip etmeye başladı."` / `"{callerName} started following you."`

### Frontend

`notificationText.js` — `getNotificationText` handles `NewFollower` type, extracts sender name from body regex.

`i18n.js` — new keys: `notificationTitleNewFollower`, `notificationBodyNewFollower`, `notificationBodyNewFollowerGeneric`, `newFollowerNotification`.

---

## No Migration

Phase 4 required zero DB migrations:
- `NotificationType.NewFollower = 12` — enum stored as int, new value appended at end.
- `GET /api/analytics/athletes/{id}/today-workout` — pure read query, no schema change.
- Extended `AthleteAnalyticsDto` — computed from existing `WorkoutSetLog` rows.
