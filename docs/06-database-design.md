# Database Design

PostgreSQL 16 is managed by EF Core code-first migrations. Entity classes and `TrackMeDbContext.OnModelCreating()` are the schema source of truth.

## Active Tables (16)

### users

| Column | Type | Notes |
|--------|------|-------|
| id | uuid PK | |
| full_name | varchar(160) | required |
| email | varchar(220) | required, unique |
| password_hash | varchar(500) | PBKDF2 hash |
| role | varchar(40) | Admin / Trainer / Athlete |
| preferred_ui_role | varchar(20) | nullable; Athlete / Trainer |
| is_active | bool | |
| email_verified_at | timestamptz | nullable |
| created_at | timestamptz | UTC |

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
| type | varchar(40) | RelationshipRequest / RelationshipAccepted / ProgramAssigned |
| title | varchar(200) | required |
| body | varchar(1000) | required |
| is_read | bool | |
| read_at | timestamptz | nullable |
| created_at | timestamptz | |

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
| starts_on | date | required |
| ends_on | date | required |
| is_active | bool | true for active programs; false after relationship end |
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
| reps | varchar(20) | nullable; supports values like `8-12` |
| target_weight_kg | numeric(6,2) | nullable |
| target_rpe | int | nullable |
| rest_seconds | int | nullable |
| notes | varchar(500) | nullable |
| created_at | timestamptz | |

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

## Inactive Schema Tables

These tables remain in the EF model and database schema, but their route registrations are not active in `Program.cs`.

| Table | Originally for |
|-------|----------------|
| program_templates | Template library |
| program_template_days | Template structure |
| program_template_exercises | Template exercises |
| template_purchases | Marketplace purchases |
| training_classes | Group sessions |
| class_participants | Group session attendance |
| user_integrations | Wearable/device integrations |

## Key Relationships

```text
users -> refresh_tokens
users -> password_reset_tokens
users -> notifications
users -> exercises.owner_id

trainers -> trainer_athlete_relationships
athletes -> trainer_athlete_relationships
trainers -> athletes.trainer_id

trainers -> workout_programs.trainer_id
athletes -> workout_programs.athlete_id
workout_programs -> workout_program_days
workout_program_days -> workout_program_exercises
workout_program_days -> workout_sessions.program_day_id

athletes -> workout_sessions
workout_programs -> workout_sessions.program_id
workout_sessions -> workout_session_exercises
workout_session_exercises -> workout_set_logs

exercises -> workout_program_exercises
exercises -> workout_session_exercises
exercises -> athletes.featured_exercise_id
workout_sessions -> athletes.featured_session_id

athletes -> body_metrics
```

## Migration Workflow

```powershell
dotnet ef migrations add <Name> --project src/TrackMe.Api/TrackMe.Api.csproj
dotnet ef database update --project src/TrackMe.Api/TrackMe.Api.csproj
```

Production applies migrations automatically at API startup via `db.Database.MigrateAsync()`.
