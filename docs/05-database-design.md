# Database Design

TrackMe uses PostgreSQL.

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

## Main Tables

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
