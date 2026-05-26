# Database Design

TrackMe uses PostgreSQL with Entity Framework Core migrations.

The database should support scalability, relational consistency, workout history, analytics queries, and notification systems.

## Database Principles

- Normalized structure
- Relational consistency
- UUID primary keys
- UTC timestamps
- Audit-friendly structure
- Soft delete for important records
- Efficient workout history queries
- Unique exercise naming
- Schema changes should be generated and reviewed as EF Core migrations.

## Main Tables

Current MVP tables:

- users
- refresh_tokens
- trainers
- athletes
- workout_programs
- workout_sessions

Current identity model:

- `users.email` is unique.
- `users.role` stores `Admin`, `Trainer`, or `Athlete`.
- `users.password_hash` stores PBKDF2-SHA256 hashes.
- `refresh_tokens` is prepared for future refresh token rotation.
- `workout_programs.trainer_id` is nullable so athletes can create self-guided programs.
- A person can appear in both `trainers` and `athletes` when a coach is coached by another coach.

Target product tables:

- users
- roles
- user_roles
- refresh_tokens
- trainer_athlete_relations
- athlete_profiles
- exercises
- workout_programs
- workout_program_weeks
- workout_program_days
- workout_program_exercises
- workout_program_exercise_sets
- workout_sessions
- workout_session_exercises
- workout_set_logs
- workout_notes
- rest_logs
- notifications
- trainer_notes
- progress_records

## Migration Workflow

The application repository owns schema changes through EF Core migrations.

Recommended flow:

1. Update domain entities and DbContext configuration in `TrackMe-Api`.
2. Generate a migration with `dotnet ef migrations add <Name>`.
3. Review the generated migration before committing it.
4. Apply it with `dotnet ef database update` in local/dev environments.
5. Run production migrations as a controlled deployment step.

Hand-written SQL files are not the source of truth for the application schema.

## Relationship Summary

- One user can have one athlete profile.
- One trainer can manage many athletes.
- One athlete can work with many trainers.
- One workout program belongs to a trainer.
- One workout program may be assigned to one or more athletes.
- One workout session belongs to one athlete.
- One workout session can reference a program day.
- One exercise can appear in many program exercises and session logs.

## Data Ownership

- Athlete-owned data: profile, workout sessions, set logs, progress records.
- Trainer-owned data: programs, trainer notes, athlete assignments.
- Admin-managed data: exercise library, users, reports, permissions.

## Indexing Strategy

Recommended indexes:

- users.email unique
- exercises.slug unique
- trainer_athlete_relations.trainer_id
- trainer_athlete_relations.athlete_id
- workout_sessions.athlete_id, started_at
- workout_set_logs.session_exercise_id
- notifications.user_id, is_read, created_at
- progress_records.athlete_id, recorded_at

## Analytics Query Requirements

The schema must support:

- Exercise history by athlete
- Volume progression by exercise
- RPE trend by athlete and program
- Workout frequency by week
- Missed workout detection
- Trainer athlete consistency review
