# Database Design

PostgreSQL 16 is managed by EF Core code-first migrations. Entity classes and `TrackMeDbContext.OnModelCreating()` are the schema source of truth.

## Active Tables (22)

### users

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| full_name | varchar(160) | required |
| email | varchar(220) | required, unique |
| password_hash | varchar(500) | PBKDF2 hash |
| role | varchar(40) | Admin / Trainer / Athlete |
| preferred_ui_role | varchar(20) | nullable; Athlete / Trainer |
| age | int | nullable |
| profession | varchar(120) | nullable |
| training_years | numeric(4,1) | nullable; summary value, currently the max per-sport experience year |
| primary_sport | varchar(300) | nullable; stores normalized comma-separated sports list for profile display |
| sports_json | varchar(2000) | nullable; JSON list of profile sports with per-sport `trainingYears` |
| read_notification_retention_days | int | default 3; topbar dropdown display setting |
| weight_unit | varchar(8) | default `kg`; user display/input preference, valid values `kg`, `lbs` |
| height_unit | varchar(8) | default `cm`; user display/input preference, valid values `cm`, `ft-in` |
| dumbbell_increment_kg | numeric(5,2) | default 2.0; athlete-owned dumbbell weight increment |
| barbell_plate_per_side_kg | numeric(5,2) | default 2.5; athlete-owned barbell smallest plate per side |
| profile_privacy_json | varchar(2000) | nullable; JSON map of per-field visibility: `{ bio, goal, age, profession, sports, bodyMetrics, avatarEmoji, featuredExercises }` each `"public"\|"connections"\|"coach_only"\|"private"` |
| avatar_emoji | varchar(10) | nullable; single emoji character shown as avatar fallback |
| avatar_media_asset_id | uuid FK -> media_assets | nullable; SetNull on delete |
| cover_media_asset_id | uuid FK -> media_assets | nullable; SetNull on delete |
| is_active | bool | |
| email_verified_at | timestamptz | nullable |
| created_at | timestamptz | UTC |

Workout and body-measurement values remain canonical in metric units in the database: workout weights are stored as kilograms (`*_weight_kg`) and body height is stored as centimeters (`height_cm`). Web clients convert values to the user's `weight_unit` and `height_unit` preferences for input and display.

### media_assets

Stores metadata for all uploaded binary files. Binary data is never stored in PostgreSQL — files live in Cloudflare R2 (production) or local filesystem (dev fallback).

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| owner_user_id | uuid FK -> users | cascade delete |
| media_type | varchar(40) | `Image` / `Video` / `Audio` |
| purpose | varchar(60) | `AvatarPhoto` / `CoverPhoto` / `ProgressPhoto` / `ExerciseVideo` / … |
| visibility | varchar(40) | `Private` / `CoachOnly` / `Public` |
| storage_provider | varchar(60) | `Local` or `CloudflareR2` |
| bucket | varchar(160) | nullable; R2 bucket name |
| object_key | varchar(600) | unique; storage path e.g. `users/{id}/profile/avatarphoto/{mediaId}.jpg` |
| status | varchar(40) | `PendingUpload` / `Ready` / `Deleted` / `Failed` |
| moderation_status | varchar(40) | `None` / `Reported` / `Approved` / `Rejected` / `Hidden` |
| mime_type | varchar(120) | e.g. `image/jpeg` |
| file_size_bytes | bigint | |
| width | int | nullable; image width px |
| height | int | nullable; image height px |
| original_file_name | varchar(260) | nullable |
| public_url | varchar(1000) | nullable; direct CDN URL when R2 public access enabled |
| metadata_json | varchar(4000) | nullable; reserved for future use |
| created_at | timestamptz | |
| uploaded_at | timestamptz | nullable |
| deleted_at | timestamptz | nullable; soft delete marker |

Indexes: `object_key` unique; `(owner_user_id, purpose)` composite. Deleted assets (`deleted_at IS NOT NULL` or `status = Deleted`) are never served via `GET /api/media/{id}/content`.

### refresh_tokens

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| user_id | uuid FK -> users | cascade delete |
| token_hash | varchar(500) | SHA-256 hash, unique |
| expires_at | timestamptz | |
| revoked_at | timestamptz | nullable |
| created_at | timestamptz | |

### password_reset_tokens

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| user_id | uuid FK -> users | cascade delete |
| token_hash | varchar(500) | unique |
| expires_at | timestamptz | |
| used_at | timestamptz | nullable |
| created_at | timestamptz | |

### notifications

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| user_id | uuid FK -> users | cascade delete |
| type | varchar(40) | RelationshipRequest / RelationshipAccepted / RelationshipRejected / RelationshipEnded / ProgramAssigned / WorkoutCompleted / NewMessage |
| title | varchar(200) | required |
| body | varchar(1000) | required |
| sender_name | varchar(160) | nullable; denormalized display sender |
| sender_role | varchar(40) | nullable; Trainer / Athlete / Admin |
| is_read | bool | |
| read_at | timestamptz | nullable |
| created_at | timestamptz | |

### direct_messages

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| sender_id | uuid FK -> users | restrict delete |
| recipient_id | uuid FK -> users | restrict delete |
| body | varchar(2000) | required |
| reference_type | varchar(40) | nullable; Program / ProgramExercise |
| reference_id | uuid | nullable; id of the referenced program or program exercise |
| reference_program_id | uuid | nullable; referenced program id for navigation/context |
| reference_exercise_id | uuid | nullable; referenced exercise id when `reference_type = ProgramExercise` |
| reference_label | varchar(240) | nullable; denormalized display label |
| reference_detail | varchar(500) | nullable; denormalized display detail |
| sent_at | timestamptz | UTC |
| read_at | timestamptz | nullable |
| is_read | bool | default false |

Indexes on `(sender_id, recipient_id)` and `(recipient_id, is_read)`.

Reference fields are intentionally denormalized and nullable. They let old messages keep readable labels even if a program/exercise is later changed, deactivated, or deleted.

### trainers

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| full_name | varchar(160) | required |
| email | varchar(220) | required, unique |
| bio | varchar(500) | nullable |
| created_at | timestamptz | |

### athletes

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| trainer_id | uuid FK -> trainers | nullable; legacy/default trainer |
| full_name | varchar(160) | required |
| email | varchar(220) | required, unique |
| goal | varchar(500) | nullable |
| bio | varchar(500) | nullable |
| created_at | timestamptz | |

### athlete_featured_exercises

Athlete's showcase list shown on their profile and to their trainer. Unlimited entries; same exercise can appear multiple times with different sessions.

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| athlete_id | uuid FK -> athletes | cascade delete |
| exercise_id | uuid FK -> exercises | cascade delete |
| session_id | uuid FK -> workout_sessions | nullable; SetNull on delete |
| order_index | int | display order |
| created_at | timestamptz | |

### trainer_athlete_relationships

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| trainer_id | uuid FK -> trainers | cascade delete |
| athlete_id | uuid FK -> athletes | cascade delete |
| status | varchar(40) | Pending / Accepted / Rejected / Ended |
| initiated_by_athlete | bool | true when athlete invited trainer |
| created_at | timestamptz | |
| responded_at | timestamptz | nullable |

Unique index on `(trainer_id, athlete_id)`.

### exercises

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| name | varchar(160) | required |
| slug | varchar(180) | required |
| category | varchar(80) | required |
| primary_muscles | varchar(240) | nullable |
| equipment | varchar(120) | nullable |
| difficulty | varchar(20) | nullable; Easy / Medium / Hard |
| instructions | varchar(2000) | nullable |
| is_active | bool | soft delete flag |
| is_global | bool | seeded library item when true |
| owner_id | uuid FK -> users | nullable; null for global exercises |
| created_at | timestamptz | |

Unique index on `(slug, owner_id)`.

### workout_programs

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| trainer_id | uuid FK -> trainers | nullable; null means self-guided |
| athlete_id | uuid FK -> athletes | required, cascade delete |
| title | varchar(180) | required |
| description | varchar(1000) | nullable |
| starts_on | date | nullable — null until program is explicitly started via `PATCH /api/programs/{id}/start` |
| ends_on | date | nullable — calculated from duration fields on start; null means indefinite |
| started_at | timestamptz | nullable — timestamp when `PATCH /start` was called |
| duration_type | varchar(20) | nullable; `unlimited`, `weeks`, `months`, `years` |
| duration_value | int | nullable; number of weeks/months/years |
| source_published_program_id | uuid FK -> published_programs | nullable; set when program is saved from a published program |
| is_active | bool | true for active programs; false after relationship end |
| repeat_pattern_weeks | int | nullable; 1, 2, 3, or 4 week repeat cycle |
| created_at | timestamptz | |

### workout_program_days

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| program_id | uuid FK -> workout_programs | cascade delete |
| day_number | int | required |
| title | varchar(180) | required |
| notes | varchar(1000) | nullable |
| rescheduled_date | date | nullable |
| pattern_week_number | int | nullable; week within repeat cycle |
| created_at | timestamptz | |

Non-unique index on `(program_id, day_number)` allows multiple workouts on the same calendar day.

### workout_program_exercises

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| day_id | uuid FK -> workout_program_days | cascade delete |
| exercise_id | uuid FK -> exercises | restrict delete |
| order_index | int | required |
| sets | int | required |
| warm_up_sets | int | default 0; warm-up set count before working sets |
| reps | varchar(20) | nullable; supports values like `8-12` |
| target_weight_kg | numeric(6,2) | nullable |
| target_rpe | int | nullable |
| rest_seconds | int | nullable |
| notes | varchar(500) | nullable |
| created_at | timestamptz | |

### workout_program_exercise_sets

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| program_exercise_id | uuid FK -> workout_program_exercises | cascade delete |
| set_number | int | required |
| planned_weight_kg | numeric(6,2) | nullable |
| planned_reps | varchar(20) | nullable — per-set reps override (added Phase24) |
| planned_rpe | int | nullable — per-set RPE override (added Phase24) |
| planned_rest_seconds | int | nullable — per-set rest override (added Phase24) |
| notes | varchar(500) | nullable — per-set trainer note (added Phase24) |
| created_at | timestamptz | |

Unique index on `(program_exercise_id, set_number)`. These rows define per-set planned data (weight, reps, RPE, rest, note) and override the exercise-level defaults for workout start snapshots.

### workout_sessions

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| athlete_id | uuid FK -> athletes | cascade delete |
| program_id | uuid FK -> workout_programs | nullable, set null on delete |
| program_day_id | uuid FK -> workout_program_days | nullable, set null on delete |
| title | varchar(180) | required |
| notes | varchar(1000) | nullable |
| status | varchar(20) | InProgress / Completed |
| completed_at | timestamptz | nullable |
| duration_minutes | int | required |
| rpe | int | 1-10 |
| created_at | timestamptz | |

Index on `(athlete_id, created_at)`.

### workout_session_exercises

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| session_id | uuid FK -> workout_sessions | cascade delete |
| exercise_id | uuid FK -> exercises | restrict delete |
| order_index | int | required |
| notes | varchar(500) | nullable |
| is_completed | bool | |
| feeling_rating | int | nullable; 1-5 |
| planned_sets | int | nullable |
| planned_reps | varchar(20) | nullable |
| planned_weight_kg | numeric(6,2) | nullable |
| planned_rpe | int | nullable |
| planned_rest_seconds | int | nullable |
| planned_warm_up_sets | int | default 0; warm-up set count snapshot from program exercise |
| planned_set_weights_json | varchar(4000) | nullable; JSON snapshot of per-set planned weights |
| trainer_note | varchar(500) | nullable |
| created_at | timestamptz | |

### workout_set_logs

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| session_exercise_id | uuid FK -> workout_session_exercises | cascade delete |
| set_number | int | required |
| reps | int | nullable |
| weight_kg | numeric(6,2) | nullable |
| rpe | int | nullable; 1-10 |
| is_completed | bool | |
| is_warm_up | bool | default false; excluded from compliance calculations |
| notes | varchar(300) | nullable |
| created_at | timestamptz | |

### body_metrics

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| athlete_id | uuid FK -> athletes | cascade delete |
| date | date | required |
| weight_kg | numeric(5,2) | nullable |
| body_fat_pct | numeric(4,1) | nullable |
| muscle_pct | numeric(4,1) | nullable |
| height_cm | numeric(5,1) | nullable |
| waist_cm | numeric(5,1) | nullable |
| chest_cm | numeric(5,1) | nullable |
| arms_cm | numeric(5,1) | nullable |
| legs_cm | numeric(5,1) | nullable |
| hips_cm | numeric(5,1) | nullable |
| notes | varchar(500) | nullable |
| created_at | timestamptz | |

At least one measurement field must be non-null. Index on `(athlete_id, date)`.

### published_programs

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| publisher_user_id | uuid FK -> users | required, restrict delete |
| source_program_id | uuid | nullable; the original workout_programs id (informational only, no FK) |
| title | varchar(180) | required |
| description | varchar(2000) | nullable |
| duration_type | varchar(20) | nullable; `unlimited`, `weeks`, `months`, `years` |
| duration_value | int | nullable |
| visibility | varchar(20) | required; `public`, `connections`, `coach_only`, `private` |
| snapshot_json | text | required; serialized `ProgramSnapshotDto` — plan structure only, no personal data |
| is_active | bool | false after unpublish |
| like_count | int | maintained counter (incremented/decremented on toggle) |
| comment_count | int | maintained counter |
| save_count | int | incremented when any user saves (copies) the program |
| start_count | int | incremented when a saved copy is started via `PATCH /api/programs/{id}/start` |
| published_at | timestamptz | UTC |

Snapshot contains: day number, day title, exercise name, sets, warm-up sets, reps, rest seconds, notes. Never includes weights, workout logs, or performance history.

### program_likes

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| published_program_id | uuid FK -> published_programs | cascade delete |
| user_id | uuid FK -> users | cascade delete |
| liked_at | timestamptz | UTC |

Unique constraint on `(published_program_id, user_id)`.

### program_comments

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| published_program_id | uuid FK -> published_programs | cascade delete |
| author_user_id | uuid FK -> users | cascade delete |
| text | varchar(1000) | required |
| is_deleted | bool | soft-delete flag; deleted comments remain in DB |
| created_at | timestamptz | UTC |

## Inactive Schema Tables

These tables remain in the EF model and database schema but are not exposed via active endpoints.

| Table | Status |
|-------|--------|
| program_templates | Active — used by TemplateEndpoints |
| program_template_days | Active — used by TemplateEndpoints; `is_rest_day` column added Phase4_RestDayInTemplate |
| program_template_exercises | Active — used by TemplateEndpoints |
| program_template_exercise_sets | Active — per-set planned data for template exercises (added Phase5_TemplateExerciseSetWeights) |
| user_integrations | Inactive — wearable/device integrations, schema reserved |
| program_forks | Inactive — future fork feature; tracks which user forked which published program into an editable copy |
| program_collections | Inactive — future collections feature; curated named lists of published programs |
| program_collection_items | Inactive — join table for program_collections ↔ published_programs |
| program_favorites | Inactive — future bookmark feature; distinct from save-to-programs (no program copy) |
| program_followers | Inactive — future follow feature; subscribe to a user's published program updates |

`training_classes`, `class_participants`, and `template_purchases` were dropped in **Phase22_RemoveDeadFeatures** migration. `price_cents` and `is_marketplace` columns were removed from `program_templates` at the same time.

## Key Relationships

```text
users -> refresh_tokens
users -> password_reset_tokens
users -> notifications
users -> direct_messages.sender_id
users -> direct_messages.recipient_id
users -> exercises.owner_id

trainers -> trainer_athlete_relationships
athletes -> trainer_athlete_relationships
trainers -> athletes.trainer_id

trainers -> workout_programs.trainer_id
athletes -> workout_programs.athlete_id
workout_programs -> workout_program_days
workout_program_days -> workout_program_exercises
workout_program_exercises -> workout_program_exercise_sets
workout_program_days -> workout_sessions.program_day_id

athletes -> workout_sessions
workout_programs -> workout_sessions.program_id
workout_sessions -> workout_session_exercises
workout_session_exercises -> workout_set_logs

exercises -> workout_program_exercises
exercises -> workout_session_exercises
exercises -> athlete_featured_exercises.exercise_id
workout_sessions -> athlete_featured_exercises.session_id
athletes -> athlete_featured_exercises.athlete_id

athletes -> body_metrics

program_templates -> program_template_days
program_template_days -> program_template_exercises
program_template_exercises -> program_template_exercise_sets

users -> published_programs.publisher_user_id
published_programs -> program_likes
published_programs -> program_comments
users -> program_likes.user_id
users -> program_comments.author_user_id
published_programs -> workout_programs.source_published_program_id
```

## Migration Workflow

```powershell
dotnet ef migrations add <Name> --project src/TrackMe.Api/TrackMe.Api.csproj
dotnet ef database update --project src/TrackMe.Api/TrackMe.Api.csproj
```

Production applies migrations automatically at API startup via `db.Database.MigrateAsync()`.
