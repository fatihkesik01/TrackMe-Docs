# Workout Tracking

## Overview

Workout tracking converts a program plan into a logged performance history. Each completed session is the atomic unit for analytics — all RPE calculations, volume totals, PR detection, and consistency metrics derive from session data.

## Data Model

### WorkoutSession

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid PK | |
| `athlete_id` | Guid FK | → `athletes` |
| `program_id` | Guid? FK | null if program was deleted |
| `program_day_id` | Guid? FK | null if day was deleted, or free-form session |
| `title` | string | snapshot of day title at session start |
| `status` | string | `InProgress` / `Completed` / `Cancelled` |
| `started_at` | timestamptz | required |
| `completed_at` | timestamptz? | set when status → Completed |
| `duration_minutes` | int? | computed from start/end |
| `workout_rpe` | int? | overall session RPE (1–10) |
| `notes` | string? | athlete session notes |
| `created_at` | timestamptz | |

### WorkoutSessionExercise

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid PK | |
| `session_id` | Guid FK | |
| `exercise_id` | Guid? FK | nullable for historical integrity |
| `exercise_name` | string | **snapshot** — preserved even if exercise renamed/deleted |
| `order_index` | int | |
| `is_completed` | bool | set to true on session complete |
| `notes` | string? | athlete note per exercise |

### WorkoutSetLog

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid PK | |
| `session_exercise_id` | Guid FK | |
| `set_number` | int | |
| `reps` | int? | |
| `weight_kg` | decimal? | |
| `rpe` | int? | 1–10 |
| `is_warm_up` | bool | warm-up sets excluded from analytics |
| `is_completed` | bool | ticked in WorkoutMode |
| `notes` | string? | |
| `logged_at` | timestamptz | |

---

## Session Lifecycle

```
POST /api/sessions  →  status: InProgress
     │
     ├── PATCH /api/sessions/{id}/exercises/{exId}/sets  (log sets)
     ├── PATCH /api/sessions/{id}/exercises/{exId}/note   (athlete note)
     │
     └── POST /api/sessions/{id}/complete
              → status: Completed
              → completedAt set
              → trainer notified (WorkoutCompleted)
              → PRs upserted
              → analytics updated
```

### Start Rules

- Athletes can start sessions only for themselves.
- One active (`InProgress`) session per program day at a time.
- Same-day completed session lock: if the day was already completed within today's UTC window → 409.
- Completed sessions from a prior date CAN be restarted (treated as a new session for that day).

### Complete Rules

- `completed_at` must be after `started_at`.
- All ticked-but-not-yet-saved sets are auto-logged before status changes.
- All `WorkoutSessionExercise.is_completed` → true.
- Trainer who owns the linked program receives a `WorkoutCompleted` notification.

---

## Set Logging

Only rows explicitly ticked (`row.done === true`) are sent to the API. Unticked rows are skipped — they do not produce `WorkoutSetLog` entries.

Warm-up set rows default to empty reps and RPE. Working set rows default to `reps=10`, `RPE=5` when no planned values exist.

`is_warm_up = true` sets are excluded from:
- Analytics volume totals
- PR detection
- Consistency metrics

---

## Personal Records (PRs)

PRs are auto-upserted on session completion:

| PR Type | Calculation |
|---------|------------|
| Max weight for an exercise | highest `weight_kg` in a completed, non-warm-up set |
| Max reps at weight | tracked per `(exercise_id, weight_kg)` bucket |

PRs are stored in the `progress_records` table and surfaced in the analytics dashboard.

---

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/sessions` | Start session (requires `programDayId`) |
| `GET` | `/api/sessions` | List athlete's sessions (paginated, filterable) |
| `GET` | `/api/sessions/{id}` | Get session detail |
| `PATCH` | `/api/sessions/{id}` | Update session notes / workout RPE |
| `DELETE` | `/api/sessions/{id}` | Cancel session (only InProgress) |
| `POST` | `/api/sessions/{id}/complete` | Complete session |
| `GET` | `/api/sessions/{id}/exercises` | List exercises in session |
| `POST` | `/api/sessions/{id}/exercises` | Add exercise to session |
| `PATCH` | `/api/sessions/{id}/exercises/{exId}/sets` | Save set logs (batch) |
| `PATCH` | `/api/sessions/{id}/exercises/{exId}/note` | Save athlete exercise note |
| `GET` | `/api/trainers/me/athletes/{athleteId}/sessions` | Trainer views athlete sessions |

---

## History Preservation

- Deleting a program sets `session.program_id = null` but never deletes sessions.
- Deleting a program day sets `session.program_day_id = null`.
- `exercise_name` is stored as a snapshot so renaming or deleting an exercise does not corrupt history.
- `exercise_id` is preserved for exercise-specific analytics when possible.

---

## WorkoutMode (Frontend)

`WorkoutMode.jsx` — full-screen overlay overlay that overlays the main nav during an active session.

### Flow

1. Athlete taps "Antrenmanı Başla" or "Devam Et" from Dashboard or Program Builder
2. `POST /api/sessions` creates InProgress session
3. WorkoutMode renders exercises from the program day
4. Each exercise shows planned sets as rows with: `IsWarmUp` toggle, reps input, weight input, RPE picker, tick checkbox, notes icon
5. "Setleri Kaydet" saves the set batch for an exercise
6. "Antrenmanı Tamamla" button auto-logs remaining ticked sets and calls `POST .../complete`
7. Completion summary: duration, total volume, new PRs

### Set Row Defaults

| Type | Reps default | RPE default | Weight |
|------|-------------|-------------|--------|
| Warm-up | empty | empty | empty |
| Working | `plannedReps` or 10 | `plannedRpe` or 5 | `targetWeightKg` or empty |

### Quick-Weight Buttons

`+weight` / `-weight` buttons respect the athlete's dumbbell/barbell increment settings and the exercise's equipment type.

### Session History View

`SessionsView.jsx` — paginated list of past sessions with filters:
- Date range picker
- Program filter
- Status filter (Completed / Cancelled)
- Exercise search

Each row shows: date, program title, day title, duration, workout RPE, set/rep totals.

Session detail: expandable per-exercise rows with per-set breakdown, PR badges, athlete notes.
