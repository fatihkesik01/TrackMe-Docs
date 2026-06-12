# Workout Programs

## Program Structure

```
WorkoutProgram
  └── WorkoutProgramDay
        └── WorkoutProgramExercise
```

## Data Model

### WorkoutProgram Fields

| Field | Type | Notes |
|-------|------|-------|
| `id` | Guid PK | |
| `trainer_id` | Guid? FK | null = self-guided |
| `athlete_id` | Guid FK | required |
| `title` | string | required |
| `description` | string? | |
| `starts_on` | DateOnly | defaults to today |
| `ends_on` | DateOnly? | null = indefinite |
| `is_active` | bool | false when coaching relationship ended (deprecated field; use `locked_at`) |
| `locked_at` | timestamptz? | set when coaching ends; cleared on re-accept |
| `locked_reason` | string? | `"coaching_ended"` when locked via relationship end |
| `template_id` | Guid? | source template for day/exercise copy-in |
| `repeat_pattern_weeks` | int? | 1, 2, 3, or 4 week repeat cycle |
| `source_version_number` | int? | set when program was saved from a PublishedProgram |
| `has_pending_update` | bool | true when publisher released a new version |
| `pending_version_id` | Guid? FK | points to the new PublishedProgram version |
| `created_at` | timestamptz | |

### WorkoutProgramDay Fields

| Field | Type | Notes |
|-------|------|-------|
| `day_number` | int | non-unique; multiple days may share the same number |
| `title` | string | e.g. "Push A", "Upper Body" |
| `notes` | string? | |
| `pattern_week_number` | int? | week within the repeat cycle |
| `rescheduled_date` | DateOnly? | overrides the calculated calendar date |

### WorkoutProgramExercise Fields

| Field | Type | Notes |
|-------|------|-------|
| `exercise_id` | Guid FK | must be active |
| `order_index` | int | display order |
| `sets` | int | ≥ 1 |
| `reps` | string? | e.g. "8-10", "AMRAP" |
| `target_weight_kg` | decimal? | |
| `target_rpe` | int? | 1–10 |
| `rest_seconds` | int? | ≥ 0 |
| `notes` | string? | |
| `set_weights` | array? | per-set planned weights |

---

## Creation Rules

- Trainer-JWT: can create programs for any athlete with an accepted coaching relationship. `trainer_id` auto-fills from JWT `profile_id`.
- Athlete-JWT (self-guided): `trainer_id` stays null. Program belongs to athlete only.
- Athlete-JWT in Trainer uiMode (dual-role): backend resolves trainer entity by email via `EnsureTrainerEntityAsync`, fills `trainer_id`.
- `trainer_id` must match the caller's own trainer profile — trainers cannot create programs as another trainer.
- A `ProgramAssigned` notification is sent to the athlete on creation.

---

## Locking Rules

When a coaching relationship is ended (`DELETE /api/coaching/{id}`):
- All trainer-created programs for that pair have `locked_at` set to now, `locked_reason = "coaching_ended"`.
- Locked programs remain visible (read-only) to both trainer and athlete.
- Athletes **can** still start sessions from locked programs.
- Athletes **can** reschedule program days.
- Nobody (except Admin) can edit program structure (days, exercises, sets) on a locked program.
- When the same coaching relationship is accepted again, locked programs are automatically unlocked (`locked_at = null`, `locked_reason = null`).

Frontend shows a `🔒 Locked` badge and a read-only warning banner when `lockedAt != null`.

---

## Deletion Rules

| Who | Can delete |
|-----|-----------|
| Admin | Any program |
| Trainer-JWT | Own programs where `trainer_id == profileId` AND `locked_at == null` |
| Athlete-JWT (self-guided) | Programs where `athlete_id == profileId AND trainer_id == null` |
| Athlete-JWT (locked program) | Locked trainer programs where `athlete_id == profileId` (relationship ended, athlete's data) |
| Dual-role Athlete-JWT | Programs whose trainer entity email matches, when not locked |

Cascade on delete: all program days and day exercises. Sessions referencing deleted program have `program_id` set to null — history preserved.

---

## Modification Rules

- Trainer can edit only their own programs and only if `locked_at == null`.
- Athletes can edit only self-guided programs (`trainer_id == null`).
- Locked programs → 403 for everyone except Admin.
- Target RPE must be 1–10 when provided. Rest time cannot be negative. Exercises must be active library records.

---

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/programs` | List all programs visible to caller |
| `POST` | `/api/programs` | Create program |
| `GET` | `/api/programs/{id}` | Get program with days + exercises |
| `PATCH` | `/api/programs/{id}` | Update program header |
| `DELETE` | `/api/programs/{id}` | Delete program |
| `POST` | `/api/programs/{id}/days` | Add day |
| `PATCH` | `/api/programs/{id}/days/{dayId}` | Update day |
| `DELETE` | `/api/programs/{id}/days/{dayId}` | Delete day |
| `POST` | `/api/programs/{id}/days/{dayId}/exercises` | Add exercise to day |
| `PATCH` | `/api/programs/{id}/days/{dayId}/exercises/{exId}` | Update exercise |
| `DELETE` | `/api/programs/{id}/days/{dayId}/exercises/{exId}` | Remove exercise from day |
| `GET` | `/api/programs/{id}/compliance` | Compliance summary |
| `POST` | `/api/programs/{id}/apply-update` | Apply pending published program update |
| `POST` | `/api/programs/{id}/dismiss-update` | Dismiss pending update |

---

## Program Templates

Templates are shareable day/exercise configurations stored as `ProgramTemplate` rows. A template snapshot can be applied to a program day. Per-set weights, reps, RPE, and rest are included in the snapshot.

`GET /api/templates` — list available templates  
`POST /api/templates` — create template  
`POST /api/programs/{id}/days/{dayId}/apply-template` — copy template into day  
`POST /api/programs/{id}/apply-program-template` — copy entire program template into program

Template apply accepts `fromDate` so template day 1 lands on the chosen calendar date. Rest days in the template are skipped (no program day created) but preserve day-number gaps so subsequent days land on correct dates.

---

## Repeat Pattern

`repeat_pattern_weeks`: 1, 2, 3, or 4. Defines a repeating training cycle:
- Apply copies 1–4 week blocks forward from a chosen calendar date
- Fill range capped at 1–3 months (configurable via apply request)
- Existing generated days are reused so linked workout sessions are preserved

---

## Compliance Tracking

`GET /api/programs/{id}/compliance` returns:

```json
{
  "compliancePct": 66.7,
  "completedDays": 2,
  "totalDays": 3,
  "days": [
    { "dayId": "...", "dayNumber": 1, "title": "Push", "hasSession": true }
  ]
}
```

---

## Published Programs (Program Marketplace)

A trainer or athlete can publish any private program as a `PublishedProgram` for others to discover, like, save, and fork.

### PublishedProgram Fields

| Column | Type | Notes |
|--------|------|-------|
| `publisher_user_id` | Guid FK | → `users` |
| `source_program_id` | Guid FK | the private program that was published |
| `title` | string | |
| `description` | string? | |
| `visibility` | string | `public` / `connections` / `coach_only` |
| `sport_category` | string? | e.g. "Powerlifting" |
| `difficulty_level` | string? | beginner / intermediate / advanced |
| `equipment_required` | string? | comma-separated |
| `tags` | string? | comma-separated |
| `cover_media_asset_id` | Guid? FK | → `media_assets` |
| `version_number` | int | default 1 |
| `root_published_program_id` | Guid? FK | null = this IS the root |
| `previous_version_id` | Guid? FK | null for v1 |
| `changelog` | string? | what changed in this version |
| `like_count` | int | cached count |
| `save_count` | int | cached count |

### Published Program Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/published-programs` | Browse (filtered by visibility, tags, difficulty) |
| `POST` | `/api/published-programs` | Publish a program |
| `GET` | `/api/published-programs/{id}` | Get detail with days + exercises |
| `DELETE` | `/api/published-programs/{id}` | Unpublish (owner only) |
| `POST` | `/api/published-programs/{id}/like` | Like |
| `DELETE` | `/api/published-programs/{id}/like` | Unlike |
| `POST` | `/api/published-programs/{id}/save` | Save (fork) as private program |
| `POST` | `/api/published-programs/{id}/versions` | Publish new version (owner only) |
| `GET` | `/api/published-programs/{id}/versions` | List version chain |
| `GET` | `/api/published-programs/{id}/versions/{vid}/diff` | Diff between versions |
| `GET` | `/api/feed/following` | Programs from followed users |
| `GET` | `/api/users/{id}/programs/published` | User's published programs |

### Program Versioning

Each `PublishedProgram` row belongs to a version chain:

```
v1 (A): root_id = null, previous_id = null
v2 (B): root_id = A, previous_id = A
v3 (C): root_id = A, previous_id = B
```

When a new version is published:
1. A new `PublishedProgram` row is created with incremented `version_number`
2. All users with a saved copy from any version in the chain receive `ProgramUpdateAvailable` notification
3. Their `WorkoutProgram.has_pending_update` is set to true, `pending_version_id` points to new version

`apply-update` replaces all program days and exercises. Sessions' `program_day_id` links to deleted days are nullified; history is untouched.

Duplicate save prevention spans all versions in the chain — a user who saved v1 is offered the update flow for v2, not a fresh save.

### Cover Photo

`POST /api/media/programs/published/{id}/cover` — upload cover (multipart)  
`DELETE /api/media/programs/published/{id}/cover` — remove cover  
Cover image served via `/api/media/{assetId}/content`

---

## Frontend

### ProgramsView (`ProgramsView.jsx`)

Role-filtered program list:
- **Trainer uiMode**: shows only programs where `trainerId === callerTrainerId`
- **Athlete uiMode**: shows only programs where `athleteId === callerAthleteId`

Programs with `hasPendingUpdate = true` show a `🔄 Güncelleme` badge. Programs with `lockedAt != null` show a `🔒 Locked` badge.

Text search (client-side): filters by program `title` or `athleteName`, case-insensitive.

### ProgramBuilderView (`ProgramBuilderView.jsx`)

Excel-style full-page program builder:
- Left panel: day list (newest-to-oldest by effective date). Toggle: Hepsi / Haftalık / Aylık with ‹/› navigation
- Right panel: exercise table with inline editing
- Per-set weight, reps, RPE, rest, and note per exercise row
- Last performance hint per exercise (from analytics API)
- Program Calendar below: dots for planned/completed days, date-click detail panel, "Hazırlık Araçları" toolbar

#### Start Workout Rules

| Priority | Condition | Button |
|----------|-----------|--------|
| 1 | Session status is InProgress | Continue |
| 2 | Day is today AND completed today (local date match) | "Tamamlandı" badge |
| 3 | Day is today | Start |
| 4 | Otherwise | "Bugüne Çek" |

Only athletes can start workouts (`onStartWorkout` prop only passed when viewer has `athleteProfileId`).

#### Day Editing Lock

When `daySession.status === 'Completed'`, `isDayLocked = true` for that day. Trainer cannot edit exercises or sets. Lock notice shown in builder.

### PublishedProgramsView (`PublishedProgramsView.jsx`)

- "Discover" tab: browse public programs with sport/difficulty/equipment filters
- "Following" tab: feed from followed users (`/api/feed/following`)
- Program cards show cover image (if set), like count, save count, difficulty badge
- Program detail modal: full program preview, like/save actions, cover photo management (for owner)
- `ProgramUpdateModal`: shows diff (added/removed/changed days+exercises), apply or dismiss buttons
