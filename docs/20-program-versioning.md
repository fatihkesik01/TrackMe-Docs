# Program Versioning & Optional Update System

## Overview

Program owners can publish new versions of a previously-published program. Users who have saved a copy receive an in-app notification and can choose to apply or dismiss the update. Applying an update replaces the program plan; workout history is never deleted.

## Version Chain Model

Each `PublishedProgram` row has:

| Column | Type | Purpose |
|--------|------|---------|
| `version_number` | int (default 1) | Monotonically increasing within a chain |
| `root_published_program_id` | uuid? | null = this IS the root (v1); non-null points to the root for all later versions |
| `previous_version_id` | uuid? | Points to the immediately prior version (null for v1) |
| `changelog` | varchar 1000? | Human-readable summary of what changed |

Chain example:
```
v1 (A): root_id = null, previous_id = null
v2 (B): root_id = A, previous_id = A
v3 (C): root_id = A, previous_id = B
```

## Saved Program Update State

`WorkoutProgram` gains three columns to track pending updates:

| Column | Type | Purpose |
|--------|------|---------|
| `source_version_number` | int? | Version number at the time the user saved the copy |
| `has_pending_update` | bool (default false) | Set to true when a new version is published |
| `pending_version_id` | uuid? | FK to `published_programs` — the newest available version to apply |

## Snapshot Improvement

`ProgramSnapshotExerciseDto` now includes `ExerciseId` (Guid?) and `ExerciseSlug` (string?) alongside `ExerciseName`. When applying a saved program or update, the exercise is resolved in priority order:

1. By `ExerciseId` (most reliable — survives name changes)
2. By `ExerciseName` case-insensitive fallback

## Endpoints

### Published Programs

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/published-programs/{id}/versions` | Publish new version (owner only) |
| `GET` | `/api/published-programs/{id}/versions` | List all versions in a chain |
| `GET` | `/api/published-programs/{id}/versions/{versionId}/diff` | Diff between two versions |

#### POST /api/published-programs/{id}/versions — Request

```json
{
  "programId": "guid",
  "changelog": "Added warm-up sets, updated rest times",
  "visibility": "public"  // optional, inherits from previous if omitted
}
```

#### Response

```json
{
  "id": "guid",
  "versionNumber": 2,
  "notifiedCount": 14
}
```

#### GET .../versions — Response

```json
[
  { "id": "...", "versionNumber": 1, "changelog": null, "publishedAt": "...", "isActive": true, "previousVersionId": null },
  { "id": "...", "versionNumber": 2, "changelog": "Added squats", "publishedAt": "...", "isActive": true, "previousVersionId": "..." }
]
```

#### GET .../versions/{versionId}/diff — Response

```json
{
  "oldVersionNumber": 1,
  "newVersionNumber": 2,
  "oldTitle": "5x5 Beginner",
  "newTitle": "5x5 Beginner",
  "addedDays": [],
  "removedDays": [],
  "changedDays": [
    {
      "dayNumber": 1,
      "oldTitle": "Day A",
      "newTitle": "Day A",
      "addedExercises": [{ "name": "Squat", "sets": 5, "reps": "5", "restSeconds": 180 }],
      "removedExercises": [],
      "changedExercises": [
        { "name": "Bench Press", "oldSets": 3, "newSets": 5, "oldReps": "8", "newReps": "5", "oldRestSeconds": 90, "newRestSeconds": 180, "oldNotes": null, "newNotes": null }
      ]
    }
  ]
}
```

### Workout Programs (saved copies)

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/programs/{id}/apply-update` | Apply pending version to saved copy |
| `POST` | `/api/programs/{id}/dismiss-update` | Dismiss the pending update |

`apply-update` replaces all program days and exercises from the new version snapshot. Sessions' `program_day_id` links to deleted days are nullified; session history (sets, weights, performance data) is untouched.

## Notification

When a new version is published, all users who have a saved copy from any version in the same chain receive a `ProgramUpdateAvailable` notification:

> "Kaydettiğin 'X' programının 2. sürümü yayınlandı."

The notification is delivered via both database persistence and SignalR push.

## Security Rules

- Only the program owner (`publisher_user_id == callerId`) can publish a new version.
- Only the athlete who saved the copy (`athlete_id == callerAthleteId`) can apply or dismiss an update.
- Applying an update never deletes workout sessions, set logs, or performance data.
- Notifications are sent only to unique recipient emails (deduplication within the same publish event).

## Frontend Behavior

### Programs List (ProgramsView)
- Programs with `hasPendingUpdate = true` show a `🔄 Güncelleme` badge next to the status badge.
- Clicking the badge or the "Güncelleme" button opens the `ProgramUpdateModal`.

### Program Builder (ProgramBuilderView)
- When `canPublishNewVersion = true` (the caller is the publisher of the linked published program), a "Yeni Sürüm Yayınla" button replaces the "Publish" button.
- The modal takes only a `changelog` field; visibility is inherited from the existing published program.

### ProgramUpdateModal
- Fetches the diff between `sourcePublishedProgramId` (old) and `pendingVersionId` (new).
- Displays added/removed/changed days and exercises.
- "Güncellemeyi Uygula" calls `POST /api/programs/{id}/apply-update` and reloads the programs list.
- "Yok Say" calls `POST /api/programs/{id}/dismiss-update` and dismisses the modal.

## Duplicate Save Prevention

When saving a published program, the duplicate check spans all versions in the chain (not just the specific version). A user who saved v1 cannot save v2 as a separate copy; instead they are offered the update flow.
