# EF Core Migration Strategy

TrackMe uses PostgreSQL, but the application schema is managed from the `TrackMe-Api` repository with Entity Framework Core migrations.

## Source Of Truth

- Entity classes and `TrackMeDbContext` configuration define the model.
- EF Core migration files define schema history.
- Hand-written SQL schema files are not used as the source of truth.

## Auto-Apply on Startup

The API calls `db.Database.MigrateAsync()` at startup (up to 10 retries, 3s apart). **No manual `dotnet ef database update` is needed in production.** Just deploy and restart — pending migrations apply automatically.

## Adding a New Migration — ALWAYS Use the CLI

**Never write migration files by hand.** Always use:

```powershell
dotnet ef migrations add Phase<N>_<Description> --project .\src\TrackMe.Api\TrackMe.Api.csproj --startup-project .\src\TrackMe.Api\TrackMe.Api.csproj
```

This generates three files correctly:
| File | Purpose |
|------|---------|
| `Migrations/<timestamp>_<Name>.cs` | Up/Down SQL with correct table/column names |
| `Migrations/<timestamp>_<Name>.Designer.cs` | EF Core metadata for this migration point |
| `Migrations/TrackMeDbContextModelSnapshot.cs` | Updated compiled model snapshot |

**All three files must be committed together.** Do not edit only one of them.

If the latest migration is wrong and has not been applied to any shared/production database, remove it with the CLI before regenerating:

```powershell
dotnet ef migrations remove --project .\src\TrackMe.Api\TrackMe.Api.csproj --startup-project .\src\TrackMe.Api\TrackMe.Api.csproj --force
```

If a wrong migration may already be applied to a shared/production database, do not rewrite it. Create a new corrective migration.

If a migration partially ran in production and created objects but did not write to `__EFMigrationsHistory`, treat it as an incident:

- Do not drop production data casually.
- Make the pending migration idempotent for the already-created objects, or create a carefully reviewed repair migration if the pending migration is already recorded.
- Verify the next API startup writes the migration history row and `/api/health` reports the database as reachable.

### Why manual migration files crash the API

EF Core 9+ throws `PendingModelChangesWarning` as a fatal exception when the compiled model doesn't match the snapshot. A manually written migration will:
- Use wrong table/column names (this project uses snake_case via explicit `HasColumnName()`)
- Produce an inconsistent snapshot
- Cause the API to enter a crash/restart loop on every startup

### Column naming convention

All columns use **snake_case** (e.g. `athlete_id`, `order_index`), configured via `HasColumnName()` in `TrackMeDbContext.OnModelCreating()`. The CLI reads this and generates correct names automatically.

## Workflow Checklist When Adding a Field

1. Add property to the model class
2. Add `HasColumnName("snake_case_name")` + FK/index config to `TrackMeDbContext.OnModelCreating()`
3. Run `dotnet ef migrations add Phase<N>_<Description> --project .\src\TrackMe.Api\TrackMe.Api.csproj --startup-project .\src\TrackMe.Api\TrackMe.Api.csproj`
4. Run `dotnet ef database update --project .\src\TrackMe.Api\TrackMe.Api.csproj` against the local development database
5. Commit all three generated files plus the model/DbContext changes
6. Push — production migrations apply automatically on next API startup

## Local Workflow

```powershell
# Add migration
dotnet ef migrations add <Name> --project .\src\TrackMe.Api\TrackMe.Api.csproj --startup-project .\src\TrackMe.Api\TrackMe.Api.csproj

# Apply locally
dotnet ef database update --project .\src\TrackMe.Api\TrackMe.Api.csproj
```

## Migration History (Phase 3)

`Phase3_RepeatPattern_SetWeights_EquipmentIncrements` adds:
- `workout_programs.repeat_pattern_weeks` (nullable int) — 1/2/4 week repeat cycle
- `workout_program_days.pattern_week_number` (nullable int) — which week-within-cycle the day belongs to
- `workout_program_exercise_sets` table — per-set planned weights for program exercises
- `workout_session_exercises.planned_set_weights_json` (varchar 4000) — JSON snapshot of per-set weights copied from program at session start
- `app_users.dumbbell_increment_kg` (numeric 5,2 default 2.0) — athlete dumbbell weight increment
- `app_users.barbell_plate_per_side_kg` (numeric 5,2 default 2.5) — athlete barbell plate increment per side

Repeat-pattern application is a data-preserving update path: it may create or update generated program days/exercises, but it must not delete workout sessions already linked to generated days.

## Migration History (Phase 4)

`Phase4_TemplateTypes_WarmupSets` adds:
- `program_templates.template_type` (int, no default) — `0` = DayTemplate, `1` = ProgramTemplate, `2` = PatternTemplate (`TemplateType` enum). No `HasDefaultValue()` — sentinel conflict with enum CLR default 0. `PatternTemplate` reuses the same column and does not need a new migration.
- `workout_program_exercises.warm_up_sets` (int, default 0) — planned warm-up sets per exercise in a program day
- `workout_session_exercises.planned_warm_up_sets` (int, default 0) — snapshot of warm-up sets taken at session start
- `workout_set_logs.is_warm_up` (bool, default false) — marks a logged set as a warm-up (excluded from compliance)
- `program_template_exercises.warm_up_sets` (int, default 0) — warm-up sets for template exercises
- `program_template_exercises.target_weight_kg` (numeric 7,3, nullable) — target weight for template exercises

## Migration History (Phase 22–24)

`Phase22_RemoveDeadFeatures` drops unused tables and columns:
- `training_classes`, `class_participants`, `template_purchases` tabloları silindi
- `program_templates.price_cents` ve `is_marketplace` sütunları kaldırıldı

`Phase23_SessionDayIndex` adds:
- Index on `workout_sessions.program_day_id` — session-day lookup performance

`Phase24_PerSetDetails` adds:
- `workout_program_exercise_sets.planned_reps` (varchar 20, nullable) — per-set planned reps override
- `workout_program_exercise_sets.planned_rpe` (int, nullable) — per-set planned RPE override
- `workout_program_exercise_sets.planned_rest_seconds` (int, nullable) — per-set planned rest override
- `workout_program_exercise_sets.notes` (varchar 500, nullable) — per-set trainer note

## Migration History (Phase 5)

`Phase5_TemplateExerciseSetWeights` adds:
- `program_template_exercise_sets` table — per-set planned data for template exercises, mirroring `workout_program_exercise_sets`
  - `id` uuid PK
  - `template_exercise_id` uuid FK → `program_template_exercises` (cascade delete)
  - `set_number` int — 1-based set index; unique constraint with `template_exercise_id`
  - `planned_weight_kg` numeric(6,2) nullable
  - `planned_reps` varchar(20) nullable
  - `planned_rpe` int nullable
  - `planned_rest_seconds` int nullable
  - `notes` varchar(500) nullable
  - `created_at` timestamptz
- `ApplyToDay` and `ApplyToProgram` endpoints now copy `program_template_exercise_sets` rows as `workout_program_exercise_sets` when applying a template

## Migration History (Phase 3 continued)

`Phase3_NullableEndsOn` modifies:
- `workout_programs.ends_on` — changed from `NOT NULL` to nullable `DateOnly?` — enables indefinite programs with no fixed end date

Pattern-application behavior change: `apply-pattern` now accepts an optional `months` route segment (1–3). When present it caps the fill range to that many months from `StartsOn`. For programs without an `ends_on` this parameter determines how far ahead to generate days. For programs with an end date, the effective limit is `min(endsOn, startsOn + months)`.

## Migration History (Phase 4 continued)

`Phase4_RestDayInTemplate` adds:
- `program_template_days.is_rest_day` (bool, default false) — marks a template day as a rest day; no exercises are added and the day is skipped when the template is applied to a program. The day-number gap is preserved so subsequent training days land on the correct dates.

## Migration History (Phase 5 — Personal Records)

`Phase5_PersonalRecords` adds:
- `personal_records` table — one row per `(athlete_id, exercise_id)` combination (unique index)
  - `id` uuid PK
  - `athlete_id` uuid FK → `athletes` (cascade delete)
  - `exercise_id` uuid FK → `exercises` (cascade delete)
  - `exercise_name` varchar(160) — denormalized for display without join
  - `max_weight_kg` numeric(8,2) — heaviest single set weight
  - `estimated_one_rm_kg` numeric(8,2) — Epley formula: `weight × (1 + reps/30)`
  - `max_volume_session_kg` numeric(10,2) — highest single-session volume for this exercise
  - `record_session_id` uuid FK → `workout_sessions` (restrict delete)
  - `recorded_at` timestamptz

Records are UPSERTED automatically by the `CompleteSession` endpoint. If any metric is beaten, all three are updated atomically in the same `SaveChangesAsync` call.

## Rules

- **Never write migration files manually** — always use `dotnet ef migrations add`
- Do not hand-edit only the migration `.cs`, `.Designer.cs`, or snapshot; keep generated files in sync through the EF CLI
- Do not edit production database structure manually (except as emergency hotfix, documented)
- Review generated migrations before commit
- Apply migrations locally before pushing schema changes
- Do not run `dotnet ef database update` in GitHub Actions or directly on the VPS for normal deploys
- Keep destructive migrations explicit and planned
- Back up production data before schema changes

## Current Production Access

PostgreSQL is available to the API through Docker networking with:

```text
Host=postgres;Port=5432;Database=trackme;Username=trackme
```

For DBeaver, use an SSH tunnel to the VPS and connect to:

```text
Host=localhost
Port=15432
Database=trackme
Username=trackme
```

The database port is bound to `127.0.0.1` on the VPS only. It is not exposed publicly.


## Migration History (Phase 7)

`Phase7_ProgramCoverPhoto` adds:
- `cover_media_asset_id` (nullable UUID, FK → `media_assets.id`, ON DELETE SET NULL) on `published_programs`

## Migration History (Phase 8)

`Phase8_ProgressPhotos` adds:
- `progress_photos` table:
  - `id` uuid PK
  - `athlete_id` uuid FK → `athletes` (cascade delete)
  - `media_asset_id` uuid FK → `media_assets` (cascade delete)
  - `taken_on` date NOT NULL
  - `notes` varchar(1000) nullable
  - `visibility` int NOT NULL (0=Private, 1=CoachOnly, 2=Public)
  - `weight_kg_snapshot` numeric(6,2) nullable
  - `created_at` timestamptz
- Index on `(athlete_id, taken_on)` for efficient timeline queries
- R2 object key pattern: `athletes/{athleteId}/progress/{mediaId}{ext}`

## Migration History (Phase 9)

`Phase9_SubmissionVideos` adds:
- `video_submissions` table:
  - `id` uuid PK
  - `athlete_id` uuid FK to `athletes` (cascade delete)
  - `media_asset_id` uuid FK to `media_assets` (cascade delete)
  - `session_id` uuid FK to `workout_sessions` (set null)
  - `session_exercise_id` uuid FK to `workout_session_exercises` (set null)
  - `title` varchar(200) nullable
  - `notes` varchar(2000) nullable
  - `visibility` int NOT NULL (0=Private, 1=CoachOnly, 2=Public)
  - `created_at` timestamptz
- Index on `(athlete_id, created_at)` for athlete timeline queries
- `video_feedbacks` table:
  - `id` uuid PK
  - `submission_id` uuid FK to `video_submissions` (cascade delete)
  - `trainer_id` uuid FK to `trainers` (restrict delete)
  - `media_asset_id` uuid FK to `media_assets` (cascade delete)
  - `notes` varchar(2000) nullable
  - `created_at` timestamptz
  - `viewed_at` timestamptz nullable
- Index on `submission_id` for feedback lookup
- R2 object key patterns:
  - `athletes/{athleteId}/submissions/{mediaId}{ext}`
  - `trainers/{trainerId}/feedback/{mediaId}{ext}`

**Total migrations as of Phase 9: 55**

## Migration History (Phase 10)

`Phase10_NutritionTracking` adds:
- `nutrition_goals` table:
  - `id` uuid PK
  - `athlete_id` uuid FK to `athletes` (cascade delete)
  - `set_by_trainer_id` uuid FK to `trainers` (set null)
  - `calories_kcal`, `protein_g`, `carbs_g`, `fat_g` int NOT NULL
  - `is_active` bool NOT NULL
  - `created_at` timestamptz
  - `deactivated_at` timestamptz nullable
- Index on `(athlete_id, is_active)` for active goal lookup
- `daily_nutrition_logs` table:
  - `id` uuid PK
  - `athlete_id` uuid FK to `athletes` (cascade delete)
  - `date` date NOT NULL
  - `calories_kcal`, `protein_g`, `carbs_g`, `fat_g` int NOT NULL
  - `notes` varchar(1000) nullable
  - `created_at`, `updated_at` timestamptz
- Unique index on `(athlete_id, date)`; the API uses upsert behavior for same-day logs.

**Total migrations as of Phase 10: 56**

## Migration History (Phase 11)

`Phase11_ExerciseDemoVideo` adds:
- `exercises.demo_video_media_asset_id` nullable uuid FK to `media_assets.id`
- `ON DELETE SET NULL` so media removal cannot delete an exercise
- Index on `demo_video_media_asset_id`
- Demo binaries remain in R2/local media storage under `exercises/{exerciseId}/demo/{mediaId}.{ext}`

**Total migrations as of Phase 11: 57**

## Migration History (Phase 12)

`Phase12_NutritionMeals` adds:
- `food_items` with per-100g calorie/protein/carbohydrate/fat/fiber values, global/custom ownership, searchable name index, and filtered unique barcode index
- `meals` with `athlete_id`, `date`, integer `meal_type`, notes, and `(athlete_id, date)` lookup index
- `meal_entries` with food and meal foreign keys, gram amount, and macros calculated and stored at save time
- Cascade delete from athlete to meals and meal to entries; restrict food deletion while entries reference it

**Total migrations as of Phase 12: 58**

## Migration History (Phase 13)

`Phase13_AdminAuditLog` adds:
- `admin_audit_logs` table with `actor_user_id` FK to `users`, `action` varchar(80), `target_user_id` nullable FK, `target_email` varchar(220) nullable, `detail` varchar(1000) nullable, `ip_address` varchar(45) nullable, `created_at` timestamptz
- Index on `created_at` for time-ordered pagination
- Index on `action` for filter queries
- Cascade delete on `actor_user_id`

**Total migrations as of Phase 13: 59**

## Migration History (Phase 14)

`Phase14_ProgressPhotoBodyMetricLink` adds:
- `progress_photos.body_metric_id` nullable uuid FK to `body_metrics.id`
- Index on `body_metric_id` for linked snapshot lookup
- `ON DELETE SET NULL` so deleting a body metric preserves the progress photo

**Total migrations as of Phase 14: 60**

## Migration History (Phase 15)

`Phase15_MissedActivityNotification` adds:
- `missed_activity_alerts` table with trainer, athlete, alert type, and sent timestamp
- Cascade FKs to `trainers` and `athletes`
- Composite index on `(trainer_id, athlete_id, alert_type, sent_at)` for duplicate suppression checks
- `NotificationType.MissedWorkout` and `NotificationType.MissedNutritionLog` are stored as strings and require no notification-column schema change

**Total migrations as of Phase 15: 61**

## Migration History (Phase 16)

`Phase16_MediaReporting` adds:
- `media_assets.reported_by_user_id` — nullable uuid FK to `users.id` (ON DELETE SET NULL)
- `media_assets.report_reason` — nullable varchar(500)
- `media_assets.reported_at` — nullable timestamptz

**Total migrations as of Phase 16: 62**

## Migration History (Phase 17)

`Phase17_AthleteTemplates` adds:
- `program_templates.athlete_id` — nullable uuid FK to `athletes.id` (ON DELETE SET NULL)

Athletes can now own program templates independently of trainers. The `trainer_id` column remains; a template belongs to exactly one owner (trainer or athlete) or neither (system/admin).

**Total migrations as of Phase 17: 63**
