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
| `createdAt` | DateTimeOffset | |

## Day Fields

| Field | Type | Notes |
|---|---|---|
| `dayNumber` | int | must be unique within program |
| `title` | string | e.g. "Push A", "Upper Body" |
| `notes` | string? | |

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

Inactive programs are hidden from normal user program lists and cannot be used to start new sessions.

## Program Builder (Web)

The web app provides an Excel-style full-page program builder (`ProgramBuilderView`):

- Left panel: day list with exercise count badges
- Right panel: exercise table with inline editing (Sets / Reps / Target kg / RPE / Rest)
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
