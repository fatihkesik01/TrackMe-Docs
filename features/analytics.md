# Analytics

## Overview

Analytics converts completed workout sessions into progress insights for athletes and trainers. All analytics derive from `WorkoutSetLog` and `WorkoutSession` rows. Warm-up sets (`is_warm_up = true`) and cancelled sessions are excluded from every calculation.

## RPE System

### Scale

| Range | Meaning |
|-------|---------|
| 1–3 | Very easy — can do many more reps |
| 4–6 | Moderate — comfortably working |
| 7–8 | Hard but controlled |
| 9 | Very hard — could barely do one more rep |
| 10 | Maximal effort — nothing left |

### Set RPE vs Workout RPE

- **Set RPE**: logged per `WorkoutSetLog` row. Fine-grained effort measure.
- **Workout RPE**: logged on `WorkoutSession` as a single overall session value.

### Planned vs Actual

Trainers set `target_rpe` on `WorkoutProgramExercise`. If actual set RPE consistently exceeds target, the program may be too intense. The `LastPerfBanner` component shows this comparison per set with color coding:
- Green: reps/weight met or exceeded target
- Orange: below target
- Red ✗: set was skipped

---

## Analytics Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/analytics/athletes/{id}` | Overview stats (aggregates) |
| `GET` | `/api/analytics/athletes/{id}/rpe-trend` | RPE over time |
| `GET` | `/api/analytics/athletes/{id}/volume-trend` | Total volume over time |
| `GET` | `/api/analytics/athletes/{id}/consistency` | Consistency grid + streak |
| `GET` | `/api/analytics/athletes/{id}/exercises/{exId}/last-performance` | Last 5 sessions for exercise |
| `GET` | `/api/analytics/athletes/{id}/today-workout` | Today's scheduled workout widget |
| `GET` | `/api/analytics/athletes/{id}/prs` | All-time personal records |

All trainer access requires an accepted coaching relationship with the target athlete.

---

## Overview Stats (`AthleteAnalyticsDto`)

| Field | Description |
|-------|-------------|
| `totalSessions` | All completed sessions |
| `weeklySessions` | Completed sessions in the last 7 days |
| `monthlySessions` | Completed sessions in the last 30 days |
| `totalDurationMinutes` | Sum of session durations |
| `averageRpe` | Average set RPE across all completed non-warm-up sets |
| `totalSets` | Count of completed non-warm-up sets |
| `totalWeightKg` | Sum of `reps × weight_kg` across completed non-warm-up sets |

---

## RPE Trend

`GET /api/analytics/athletes/{id}/rpe-trend?days=30`

Returns one data point per workout session day. Each point: `date`, `averageRpe`, `sessionCount`.

---

## Volume Trend

`GET /api/analytics/athletes/{id}/volume-trend?days=30`

Returns one data point per day. Each point: `date`, `totalWeightKg`, `totalSets`.

Volume formula:
```
volume = weight_kg × reps   (per set)
```

Totaled per day across all completed non-warm-up sets.

---

## Consistency Grid

`GET /api/analytics/athletes/{id}/consistency`

Returns:
```json
{
  "currentStreakDays": 5,
  "longestStreakDays": 14,
  "completedDays": [...dates...],
  "complianceGrid": {
    "planned": 20,
    "completed": 15,
    "compliancePct": 75.0
  }
}
```

`currentStreakDays` = consecutive calendar days ending today where at least one session was completed.

---

## Last Performance (Exercise-Specific)

`GET /api/analytics/athletes/{id}/exercises/{exId}/last-performance`

Returns up to 5 most recent sessions where this exercise was logged:

```json
[
  {
    "sessionId": "...",
    "date": "2026-06-10",
    "sessionTitle": "Push Day",
    "sets": [
      { "setNumber": 1, "reps": 5, "weightKg": 100, "rpe": 8, "isWarmUp": false }
    ],
    "trainerNote": "Keep chest up",
    "plannedSets": 5,
    "plannedReps": "5",
    "plannedWeightKg": 100,
    "athleteNote": "Felt strong today"
  }
]
```

Used by `LastPerfBanner` and `PrevPerfColumn` in the Program Builder to show history inline.

---

## Today's Workout Widget

`GET /api/analytics/athletes/{id}/today-workout`

Returns `TodayWorkoutDto`:
```json
{
  "today": {
    "programId": "...", "programTitle": "Push/Pull/Legs",
    "dayId": "...", "dayTitle": "Push Day",
    "exerciseCount": 6, "trainerName": "Ali Veli",
    "activeSessionId": null, "hasActiveSession": false, "alreadyCompleted": false
  },
  "next": {
    "programId": "...", "dayId": "...", "dayTitle": "Pull Day",
    "date": "2026-06-13", "trainerName": "Ali Veli"
  }
}
```

Day date calculation: `RescheduledDate ?? program.StartsOn + day.DayNumber`

`today` is null if no program day is scheduled for today. `next` is null if no future days exist.

---

## Personal Records

PRs are auto-upserted on every session completion:
- Max weight for each exercise
- Max reps at each weight

Stored in `progress_records`. Surfaced as PR badges in WorkoutMode completion summary and analytics dashboard.

---

## Access Rules

| Caller | Can access |
|--------|-----------|
| Athlete | Own data only |
| Trainer | Athletes with accepted coaching relationship |
| Admin | Any athlete |

---

## Frontend

### AthleteAnalyticsView (`AthleteAnalyticsView.jsx`)

Route: `analytics` in Athlete nav (between Sessions and Body Metrics).

Loads via `Promise.all`:
1. Overview stats
2. RPE trend (30 days)
3. Volume trend (30 days)
4. Consistency data

**8 stat cards:** Total sessions, This week, This month, Current streak, Total duration, Avg RPE, Total sets, Total volume.

**Charts (reused components):**
- `RpeTrendChart` — line chart of daily average RPE
- `VolumeTrendChart` — bar chart of daily volume
- `ConsistencyGrid` — calendar heatmap with streak info

### DashboardView — TodayWorkoutCard

Athlete-mode only. Shows today's scheduled workout or next upcoming day.
- "Antrenmanı Başla" → WorkoutMode
- "Devam Et" → continues InProgress session
- "Bugün Tamamlandı" badge → read-only
- Rest day: shows "Bugün Dinlenme Günü" + next workout info

### TrainerDashboard

Trainers see a summary of all accepted athletes' recent sessions. Clicking an athlete navigates to their detail view with sessions/analytics tabs.

### LastPerfBanner (in ProgramBuilderView)

Two-section panel:
1. **Performans** (top): session matching the currently-selected program day — trainer note, athlete note, per-set detail with color coding
2. **Son Performanslar** (bottom): up to 4 previous sessions as side-by-side compact columns (`PrevPerfColumn`). Each column: date + per-set `reps×weight` + RPE indicator + note icon

Color coding: green = met/exceeded target, orange = below, red ✗ = skipped. Warm-up sets shown with neutral badge + dimmed opacity, no target comparison.
