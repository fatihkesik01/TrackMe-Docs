# Database ERD

```mermaid
erDiagram
    users ||--o{ user_roles : has
    roles ||--o{ user_roles : assigned
    users ||--o{ refresh_tokens : owns
    users ||--o| athlete_profiles : has
    users ||--o{ trainer_athlete_relations : trainer
    users ||--o{ trainer_athlete_relations : athlete
    users ||--o{ workout_programs : creates
    workout_programs ||--o{ workout_program_weeks : contains
    workout_program_weeks ||--o{ workout_program_days : contains
    workout_program_days ||--o{ workout_program_exercises : contains
    exercises ||--o{ workout_program_exercises : planned
    workout_program_exercises ||--o{ workout_program_exercise_sets : has
    workout_programs ||--o{ workout_program_assignments : assigned
    users ||--o{ workout_program_assignments : athlete
    users ||--o{ workout_sessions : performs
    workout_sessions ||--o{ workout_session_exercises : contains
    exercises ||--o{ workout_session_exercises : logged
    workout_session_exercises ||--o{ workout_set_logs : has
    workout_sessions ||--o{ workout_notes : has
    workout_set_logs ||--o{ rest_logs : after
    users ||--o{ notifications : receives
    users ||--o{ trainer_notes : trainer
    users ||--o{ trainer_notes : athlete
    users ||--o{ progress_records : tracks
```

## Notes

- `users` stores all account identities.
- Trainer and athlete behavior is controlled by roles.
- Athlete-specific fields are stored in `athlete_profiles`.
- Trainer-athlete access is controlled by `trainer_athlete_relations`.
- Workout program data stores planned training.
- Workout session data stores actual performed training.
