# Workout Program Analysis

Workout programs are created by trainers for accepted athletes, or by athletes as self-guided
programs. Athlete-JWT users in Trainer uiMode are also supported via email-based trainer resolution.

## Program Structure

```
WorkoutProgram
  └── WorkoutProgramDay
        └── WorkoutProgramExercise
```

## Program Fields

| Field | Type | Notes |
|---|---|---|
| `id` | Guid | |
| `trainerId` | Guid? | null = self-guided |
| `athleteId` | Guid | required |
| `title` | string | required |
| `description` | string? | |
| `startsOn` | DateOnly | defaults to today |
| `endsOn` | DateOnly? | nullable — null means indefinite (süresiz) program |
| `isActive` | bool | false when the trainer-athlete relationship is ended |
| `templateId` | Guid? | optional — copies days/exercises from template on creation |
| `repeatPatternWeeks` | int? | nullable; 1, 2, 3, or 4 week repeat cycle |
| `createdAt` | DateTimeOffset | |

## Day Fields

| Field | Type | Notes |
|---|---|---|
| `dayNumber` | int | non-unique; multiple workouts may share the same calendar day |
| `title` | string | e.g. "Push A", "Upper Body" |
| `notes` | string? | |
| `patternWeekNumber` | int? | week within the repeat cycle |

## Exercise Fields

| Field | Type | Notes |
|---|---|---|
| `exerciseId` | Guid | must be active |
| `orderIndex` | int | display order |
| `sets` | int | ≥ 1 |
| `reps` | string? | e.g. "8-10", "AMRAP" |
| `targetWeightKg` | decimal? | |
| `targetRpe` | int? | 1–10 |
| `restSeconds` | int? | ≥ 0 |
| `notes` | string? | |
| `setWeights` | array? | optional per-set planned weights |

## Creation Flow

```
Trainer creates program
  → selects athlete from accepted athletes
  → sets title, dates, optional template
  → backend validates accepted relationship
  → athlete notified via ProgramAssigned notification
  → program appears in both trainer and athlete program lists
```

### TrainerId Auto-Resolution

When `trainerId` is omitted or sent as `null`:

- **Trainer-JWT**: filled from JWT `profile_id` claim.
- **Athlete-JWT creating for another athlete** (Trainer uiMode): backend looks up trainer
  entity by email; lazily creates it via `EnsureTrainerEntityAsync` if not found.
- **Athlete-JWT creating for own profile**: stays `null` → self-guided program.

## Deletion Flow

```
DELETE /api/programs/{id}
  → auth check: Admin / trainer owner / athlete self-guided / email fallback
  → cascade: program days and day exercises deleted
  → WorkoutSession.ProgramId set to null (sessions preserved)
  → 204 No Content
```

Frontend shows `window.confirm` before calling delete.

## Deactivation Flow

When an accepted trainer-athlete relationship is ended:

```
DELETE /api/relationships/{id}
  → relationship status becomes Ended
  → active trainer-created programs for that trainer-athlete pair are marked isActive=false
  → self-guided programs and workout session history remain unchanged
```

Inactive program behavior:

- Active and inactive programs are both returned in program lists.
- The Web UI shows active/passive badges for each program.
- Inactive programs can still be opened for detail review.
- Inactive program details are read-only; day/exercise updates are rejected by the API.
- WorkoutMode cannot be started from an inactive program day.
- If the same trainer-athlete relationship is requested again and accepted, inactive trainer-created programs for that pair are reactivated.

## Program Visibility Rules (Web)

Program lists (`ProgramsView`) apply role-based filtering on the frontend after the API returns all relevant programs:

| uiMode | Visible programs |
|--------|-----------------|
| Trainer | Only programs where `trainerId === current user's trainer entity` — excludes self-guided programs of athletes |
| Athlete | Only programs where `athleteId === current user's athlete profile` — excludes programs written as a trainer for students |

This filtering prevents cross-mode leakage for dual-role users (Athlete-JWT with a trainer entity). The API for Athlete-JWT deliberately returns both roles' programs in a single call so both modes work without extra round-trips; the frontend separates them by `uiRole`.

A second **client-side text search** is applied on top of the role filter. The search bar (`.search-toolbar` pattern) filters by program `title` or `athleteName` (case-insensitive substring match). Filtering is reactive; the count badge reflects the filtered total. When the search query produces no results the empty state says "Sonuç bulunamadı"; when no programs exist at all it says "Henüz program yok".

## Start Workout Rules (Web)

`ProgramBuilderView` shows the start/continue/status section when:
- `onStartWorkout` prop is provided (non-null), AND
- The current user's `athleteProfileId` matches `program.athleteId` (the program belongs to this user as athlete), OR the view is in `effectiveReadOnly` mode.

`onStartWorkout` is passed from App.jsx only when the viewer has an `athleteProfileId` (i.e., the JWT role includes an athlete profile). Trainer-JWT users never receive `onStartWorkout` and therefore cannot start workouts. Athletes can start workouts from both read-only (trainer-assigned) and edit-mode (self-guided) programs.

### Day button priority order

| Priority | Condition | Button shown |
|----------|-----------|-------------|
| 1 | Session status is InProgress | Continue button |
| 2 | Day is today AND session was completed today (local date match) | Completed badge — no restart |
| 3 | Day is today | Start button |
| 4 | Otherwise (including previously-completed past days) | Pull to Today button |

"Completed today" is determined by comparing the session's `completedAt` timestamp to the current local date. A day pulled to today via "Bugüne Çek" whose session was completed on a previous date does NOT count as completed today, so the Start button appears.

The API (`StartSession`) enforces the same rule: it allows creating a new session for a day whose existing completed session's `completedAt` is before today UTC, but returns `409 Conflict` when the same day was completed within today's UTC window.

## Last Performance in Program Builder

`GET /api/analytics/athletes/{id}/exercises/{exerciseId}/last-performance` returns `ExerciseLastPerformanceDto[]` (up to 5 entries, newest first, empty array when no data). `ProgramBuilderView` stores per-exercise arrays in `lastPerformances` state.

`ExerciseLastPerformanceDto` fields: `SessionId`, `Date`, `SessionTitle`, `Sets`, `TrainerNote`, `PlannedSets`, `PlannedReps`, `PlannedWeightKg`, `AthleteNote`.

`LastPerfBanner` component displays:
- **Performans** (top): the specific session for the currently-selected program day, matched by `lp.sessionId === daySession.id`. Shows date, trainer note, athlete note, and per-set detail rows with color coding (green = met/exceeded target, orange = below target, red `✗` = skipped).
- **Son Performanslar** (bottom): up to 4 previous sessions for that exercise, displayed as **side-by-side compact columns** (`PrevPerfColumn`). Each column shows date + per-set `reps×weight` + RPE indicator + note icons.

Set color coding in `PerfSetRows`: compares each working set's reps/weight against `plannedReps`/`plannedWeightKg`. Warm-up sets are shown with a neutral badge and dimmed opacity, no target comparison.

Athlete note (`WorkoutSessionExercise.Notes`) is a general per-exercise note written by the athlete in WorkoutMode. It is saved via `PATCH /api/sessions/{sessionId}/exercises/{exerciseId}/note` when the athlete clicks "Setleri Kaydet". It is returned in both `SessionExerciseDto.notes` and `ExerciseLastPerformanceDto.athleteNote`.

## Day Editing Lock

When the athlete completes a workout for a day (`daySession.status === 'Completed'`), `isDayLocked` becomes `true` for that day. The trainer cannot edit exercises, add exercises, or change set plans for that day. A lock notice is shown in the program builder. The lock is frontend-only visibility control; the API already rejects edits on inactive programs.

## WorkoutMode Set Logging

Only sets explicitly ticked as done (`row.done === true`) are logged to the API. Unticked rows are skipped — they do not produce set log entries. The `isCompleted` flag on saved sets reflects the tick state.

Warm-up set rows default to empty reps and RPE (no pre-filled placeholders). Working set rows default to `reps=10`, `RPE=5` when no planned values are set.

On "Antrenmanı Tamamla", any ticked-but-not-yet-saved sets are auto-logged and all session exercises are marked `isCompleted=true` so analytics can include them.

## Program Builder (Web)

The web app provides an Excel-style full-page program builder (`ProgramBuilderView`):

- Left panel: day list sorted **newest-to-oldest** by effective date (`rescheduledDate` if set, else `startsOn + dayNumber − 1`). Toggle button cycles through **Hepsi / Haftalık / Aylık** views; in Haftalık/Aylık mode ‹/› buttons navigate by week/month and ↺ resets to Hepsi. Shows "Bu dönemde gün yok" when no days fall in the selected period.
- Right panel: exercise table with inline editing (Sets / Reps / Target kg / RPE / Rest)
- Per-set planned weight, reps, RPE, rest, and note per exercise row; rendered via shared `ExerciseEditorSection` component (also used by TemplatesView)
- Edit mode uses `visibility:hidden` on quick-action buttons so layout is pixel-identical in view vs edit mode
- Day and program templates can be copied into the program as snapshots, including per-set data
- Quick buttons for ±weight/±reps/±RPE/±rest per set row; +weight uses exercise equipment and athlete's dumbbell/barbell increment settings; defaults: reps=10, RPE=5, rest=60s
- Repeat pattern apply copies 1, 2, 3, or 4 week blocks; the selected calendar date is used as the source cycle start (`fromDate`); fill range is capped at 1–3 months; reuses existing generated days so linked workout sessions are preserved
- Program template `apply-to-program` accepts an optional `fromDate` so template day 1 lands on the chosen calendar date
- Last performance hint per exercise row (fetched from analytics API)
- Accessible to Trainer-JWT users and Athlete-JWT users in Trainer uiMode

## Program Calendar (Web)

`ProgramBuilderView` includes a **Program Calendar** card below the builder:

- Custom ‹/› month navigation buttons (DayPicker built-in nav is disabled; controlled via `month` + `onMonthChange` state)
- Calendar dots: teal dot = planned program day, green dot = completed session. Multiple planned days on the same date show a count.
- Clicking a date shows a detail panel with two sections:
  - **Planlanan Antrenmanlar** — clickable rows; clicking navigates to that day in the builder panel below and scrolls it into view.
  - **Tamamlanan Antrenmanlar** — clickable rows (when `programDayId` is present); clicking navigates to the linked program day.
- Rows use the `prog-cal-row-btn` class — simple buttons with `ChevronRight` indicator, no inline expansion.
- In edit mode an "Bu Güne Antrenman Ekle" button adds a new day scheduled on the selected date.
- A **Hazırlık Araçları** toolbar is rendered inside the calendar detail panel, above the planned workouts section. It has three rows: (1) day template + program template selects side by side, (2) repeat pattern select + months cap (1–3) + apply button. All operations use the selected calendar date as their reference point (`fromDate`).

## Compliance Tracking

`GET /api/programs/{id}/compliance` returns:

```json
{
  "compliancePct": 66.7,
  "completedDays": 2,
  "totalDays": 3,
  "days": [
    { "dayId": "...", "dayNumber": 1, "title": "Push", "hasSession": true },
    ...
  ]
}
```

## Example

```
Program: Hypertrophy Block 1
Day 1 - Push
  Bench Press: 4 sets × 6-8 reps @ RPE 8, 180s rest
  OHP: 3 sets × 8-10 reps @ RPE 7, 120s rest
Day 2 - Pull
  ...
```

## Versioning Note

For the first version, program edits are simple. Session history is independent and
unaffected by future program changes. For a future version, introduce program versioning
with snapshots.

Pattern re-apply is also history-safe: generated program days may be updated or added, but linked workout sessions must not be deleted as part of refreshing the pattern.
