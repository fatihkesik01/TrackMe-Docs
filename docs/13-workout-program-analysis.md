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
| `endsOn` | DateOnly | defaults to startsOn + 28 days |
| `isActive` | bool | false when the trainer-athlete relationship is ended |
| `templateId` | Guid? | optional — copies days/exercises from template on creation |
| `repeatPatternWeeks` | int? | nullable; 1, 2, or 4 week repeat cycle |
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

## Program Builder (Web)

The web app provides an Excel-style full-page program builder (`ProgramBuilderView`):

- Left panel: day list with exercise count badges
- Right panel: exercise table with inline editing (Sets / Reps / Target kg / RPE / Rest)
- Per-set planned weight, reps, RPE, rest, and note per exercise row; rendered via shared `ExerciseEditorSection` component (also used by TemplatesView)
- Edit mode uses `visibility:hidden` on quick-action buttons so layout is pixel-identical in view vs edit mode
- Day and program templates can be copied into the program as snapshots, including per-set data
- Quick buttons for ±weight/±reps/±RPE/±rest per set row; +weight uses exercise equipment and athlete's dumbbell/barbell increment settings; defaults: reps=10, RPE=5, rest=60s
- Repeat pattern apply copies 1, 2, or 4 week blocks to later weeks and reuses existing generated days so linked workout sessions are preserved
- Last performance hint per exercise row (fetched from analytics API)
- Accessible to Trainer-JWT users and Athlete-JWT users in Trainer uiMode

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
