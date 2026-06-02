# Database Design

PostgreSQL 16 managed by EF Core 10 code-first migrations. The schema is the source of truth — no hand-written SQL.

## Active Tables (14)

### users
| Column              | Type         | Notes                                |
|---------------------|--------------|--------------------------------------|
| id                  | uuid PK      |                                      |
| full_name           | varchar(160) | required                             |
| email               | varchar(220) | unique index, required               |
| password_hash       | varchar(500) | PBKDF2 hash                          |
| role                | varchar(40)  | Admin / Trainer / Athlete            |
| preferred_ui_role   | varchar(20)  | nullable — Athlete / Trainer; set at onboarding, changeable from topbar |
| is_active           | bool         |                                      |
| email_verified_at   | timestamptz  | nullable                             |
| created_at          | timestamptz  | UTC                                  |

### refresh_tokens
| Column      | Type         | Notes                                      |
|-------------|-------------|---------------------------------------------|
| id          | uuid PK     |                                             |
| user_id     | uuid FK→users | cascade delete                            |
| token_hash  | varchar(500) | SHA-256 hash of raw token, unique index    |
| expires_at  | timestamptz  |                                            |
| revoked_at  | timestamptz  | nullable — null means still valid          |
| created_at  | timestamptz  |                                            |

### password_reset_tokens
| Column      | Type         | Notes                               |
|-------------|-------------|--------------------------------------|
| id          | uuid PK     |                                      |
| user_id     | uuid FK→users | cascade delete                     |
| token_hash  | varchar(500) | unique index                        |
| expires_at  | timestamptz  | 30 minutes from creation            |
| used_at     | timestamptz  | nullable — null means unused        |
| created_at  | timestamptz  |                                     |

### trainers
| Column     | Type         | Notes                    |
|------------|-------------|---------------------------|
| id         | uuid PK     |                           |
| full_name  | varchar(160) | required                 |
| email      | varchar(220) | unique index, required   |
| bio        | varchar(500) | nullable                 |
| created_at | timestamptz  |                          |

### athletes
| Column     | Type         | Notes                                       |
|------------|-------------|----------------------------------------------|
| id         | uuid PK     |                                              |
| trainer_id | uuid FK→trainers | nullable — null means self-guided      |
| full_name  | varchar(160) | required                                    |
| email      | varchar(220) | unique index, required                      |
| goal       | varchar(500) | nullable                                    |
| bio        | varchar(500) | nullable                                    |
| created_at | timestamptz  |                                             |

### trainer_athlete_relationships
| Column              | Type        | Notes                                              |
|---------------------|------------|-----------------------------------------------------|
| id                  | uuid PK    |                                                     |
| trainer_id          | uuid FK→trainers | cascade delete                              |
| athlete_id          | uuid FK→athletes | cascade delete                              |
| status              | varchar(40) | Pending / Accepted / Rejected                      |
| initiated_by_athlete| bool        | true = athlete invited trainer; false = trainer sent|
| created_at          | timestamptz |                                                     |
| responded_at        | timestamptz | nullable                                            |

Unique index on `(trainer_id, athlete_id)`.

### exercises
| Column          | Type          | Notes                                                        |
|-----------------|--------------|--------------------------------------------------------------|
| id              | uuid PK      |                                                              |
| name            | varchar(160)  | required                                                     |
| slug            | varchar(180)  | required                                                     |
| category        | varchar(80)   | required — Chest / Back / Shoulders / Arms / Legs / Glutes / Core / Cardio / Functional / Full Body / Mobility / Stretching |
| primary_muscles | varchar(240)  | nullable                                                     |
| equipment       | varchar(120)  | nullable                                                     |
| difficulty      | varchar(20)   | nullable — "Easy" / "Medium" / "Hard" (Phase 16)            |
| instructions    | varchar(2000) | nullable                                                     |
| is_active       | bool          | soft delete flag                                             |
| is_global       | bool          | true = seeded global library; false = user-owned             |
| owner_id        | uuid FK→users | nullable — null for global exercises                         |
| created_at      | timestamptz   |                                                              |

Unique index on `(slug, owner_id)`.

**Library size:** 141 global exercises across 13 categories seeded on first startup.

### workout_programs
| Column      | Type         | Notes                                          |
|-------------|-------------|------------------------------------------------|
| id          | uuid PK     |                                                |
| trainer_id  | uuid FK→trainers | nullable (set null on delete) — null = self-guided |
| athlete_id  | uuid FK→athletes | required, cascade delete                  |
| title       | varchar(180) | required                                       |
| description | varchar(1000)| nullable                                       |
| starts_on   | date         | required                                       |
| ends_on     | date         | required                                       |
| created_at  | timestamptz  |                                                |

### workout_program_days
| Column     | Type         | Notes                                    |
|------------|-------------|-------------------------------------------|
| id         | uuid PK     |                                           |
| program_id | uuid FK→workout_programs | cascade delete                |
| day_number | int          | required                                  |
| title      | varchar(180) | required                                  |
| notes      | varchar(1000)| nullable                                  |
| created_at | timestamptz  |                                           |

Non-unique index on `(program_id, day_number)` — multiple workout days can share the same day number (multiple workouts on the same calendar date is allowed, Phase 18).

### workout_program_exercises
| Column           | Type              | Notes                         |
|------------------|------------------|-------------------------------|
| id               | uuid PK          |                               |
| day_id           | uuid FK→workout_program_days | cascade delete  |
| exercise_id      | uuid FK→exercises | restrict delete               |
| order_index      | int              | required                      |
| sets             | int              | required                      |
| reps             | varchar(20)      | nullable (string: "8-12", "5")|
| target_weight_kg | numeric(6,2)     | nullable                      |
| target_rpe       | int              | nullable (1-10)               |
| rest_seconds     | int              | nullable                      |
| notes            | varchar(500)     | nullable                      |
| created_at       | timestamptz      |                               |

### workout_sessions
| Column           | Type         | Notes                                   |
|------------------|-------------|------------------------------------------|
| id               | uuid PK     |                                          |
| athlete_id       | uuid FK→athletes | cascade delete                       |
| program_id       | uuid FK→workout_programs | nullable, set null on delete |
| title            | varchar(180) | required                                 |
| notes            | varchar(1000)| nullable                                 |
| status           | varchar(20)  | InProgress / Completed                   |
| completed_at     | timestamptz  | nullable                                 |
| duration_minutes | int          | required                                 |
| rpe              | int          | 1-10 required                            |
| created_at       | timestamptz  |                                          |

Index on `(athlete_id, created_at)`.

### workout_session_exercises
| Column              | Type              | Notes                           |
|---------------------|------------------|----------------------------------|
| id                  | uuid PK          |                                  |
| session_id          | uuid FK→workout_sessions | cascade delete           |
| exercise_id         | uuid FK→exercises | restrict delete                 |
| order_index         | int              | required                         |
| notes               | varchar(500)     | nullable                         |
| is_completed        | bool             | default true                     |
| feeling_rating      | int              | nullable (1-5)                   |
| planned_sets        | int              | nullable — snapshot from program |
| planned_reps        | varchar(20)      | nullable                         |
| planned_weight_kg   | numeric(6,2)     | nullable                         |
| planned_rpe         | int              | nullable                         |
| planned_rest_seconds| int              | nullable                         |
| trainer_note        | varchar(500)     | nullable — written by trainer    |
| created_at          | timestamptz      |                                  |

### workout_set_logs
| Column              | Type          | Notes                             |
|---------------------|--------------|-----------------------------------|
| id                  | uuid PK      |                                   |
| session_exercise_id | uuid FK→workout_session_exercises | cascade delete |
| set_number          | int          | required                          |
| reps                | int          | nullable                          |
| weight_kg           | numeric(6,2) | nullable                          |
| rpe                 | int          | nullable (1-10)                   |
| is_completed        | bool         | required                          |
| notes               | varchar(300) | nullable                          |
| created_at          | timestamptz  |                                   |

### body_metrics
| Column       | Type          | Notes                          |
|--------------|--------------|--------------------------------|
| id           | uuid PK      |                                |
| athlete_id   | uuid FK→athletes | cascade delete             |
| date         | date         | required                       |
| weight_kg    | numeric(5,2) | nullable                       |
| body_fat_pct | numeric(4,1) | nullable                       |
| muscle_pct   | numeric(4,1) | nullable (Phase 15)            |
| height_cm    | numeric(5,1) | nullable (Phase 15)            |
| waist_cm     | numeric(5,1) | nullable (Phase 15)            |
| chest_cm     | numeric(5,1) | nullable (Phase 15)            |
| arms_cm      | numeric(5,1) | nullable (Phase 15)            |
| legs_cm      | numeric(5,1) | nullable (Phase 15)            |
| hips_cm      | numeric(5,1) | nullable (Phase 15)            |
| notes        | varchar(500) | nullable                       |
| created_at   | timestamptz  |                                |

At least one measurement field must be non-null.
Index on `(athlete_id, date)`.

### notifications
| Column     | Type          | Notes                                |
|------------|--------------|---------------------------------------|
| id         | uuid PK      |                                       |
| user_id    | uuid FK→users | cascade delete                      |
| type       | varchar(40)  | RelationshipRequest / RelationshipAccepted / ProgramAssigned |
| title      | varchar(200) | required                              |
| body       | varchar(1000)| required                              |
| is_read    | bool         | required                              |
| created_at | timestamptz  |                                       |
| read_at    | timestamptz  | nullable                              |

## Dead Tables (schema exists, no active endpoints)

These tables exist in the database schema from earlier development phases but have no active API endpoints. They are kept to preserve data integrity; no application code reads or writes them.

| Table                    | Originally for           |
|--------------------------|--------------------------|
| program_templates        | Template library         |
| program_template_days    | Template structure       |
| program_template_exercises | Template exercises      |
| template_purchases       | Marketplace purchases    |
| training_classes         | Group sessions           |
| class_participants       | Group session attendance |
| user_integrations        | Wearable device tokens   |

## Key Relationships

```
users ─────────────── refresh_tokens      (1:many, cascade)
users ─────────────── password_reset_tokens (1:many, cascade)
users ─────────────── notifications        (1:many, cascade)
trainers ──────────── athletes             (1:many, set null on trainer delete)
trainers ──────────── trainer_athlete_relationships (1:many, cascade)
athletes ──────────── trainer_athlete_relationships (1:many, cascade)
athletes ──────────── workout_programs     (1:many, cascade)
trainers ──────────── workout_programs     (1:many, set null on trainer delete)
athletes ──────────── workout_sessions     (1:many, cascade)
athletes ──────────── body_metrics         (1:many, cascade)
workout_programs ───── workout_program_days (1:many, cascade)
workout_program_days ── workout_program_exercises (1:many, cascade)
workout_sessions ───── workout_session_exercises (1:many, cascade)
workout_session_exercises ── workout_set_logs (1:many, cascade)
exercises ──────────── workout_program_exercises (1:many, restrict)
exercises ──────────── workout_session_exercises (1:many, restrict)
```

## Migration Workflow

```powershell
# Add a migration (run from repo root or TrackMe-Api folder)
dotnet ef migrations add <Name> --project src/TrackMe.Api/TrackMe.Api.csproj

# Apply locally
dotnet ef database update --project src/TrackMe.Api/TrackMe.Api.csproj
```

In production, migrations are applied automatically at API startup via `db.Database.MigrateAsync()`.
