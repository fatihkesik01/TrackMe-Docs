# Workout Program Module

## Purpose

Allows trainers and athletes to create, manage, and delete structured workout programs.
Trainers create programs for accepted athletes; athletes can create self-guided programs.
Dual-role users (Athlete-JWT + Trainer uiMode) are supported via email-based resolution.

## Responsibilities

- Create workout programs (trainer-assigned or self-guided)
- Auto-resolve trainer identity from JWT or email when `trainerId` is omitted
- Manage program days and day exercises
- Delete programs with cascade to days/exercises (sessions are preserved with null programId)
- Enforce trainer-athlete relationship requirements
- Notify athletes on program assignment

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/programs` | List programs scoped by caller role |
| `POST` | `/api/programs` | Create program (auto-resolves trainerId) |
| `GET` | `/api/programs/{id}` | Program detail with days and exercises |
| `DELETE` | `/api/programs/{id}` | Delete program (cascades to days/exercises) |
| `POST` | `/api/programs/{id}/days` | Add program day |
| `PUT` | `/api/programs/{id}/days/{dayId}` | Update day title/notes |
| `DELETE` | `/api/programs/{id}/days/{dayId}` | Remove day |
| `POST` | `/api/programs/{id}/days/{dayId}/exercises` | Add exercise to day |
| `PUT` | `/api/programs/{id}/days/{dayId}/exercises/{exId}` | Update exercise plan |
| `DELETE` | `/api/programs/{id}/days/{dayId}/exercises/{exId}` | Remove exercise from day |

## Entity Hierarchy

```
WorkoutProgram
  └── WorkoutProgramDay (cascade delete)
        └── WorkoutProgramExercise (cascade delete)

WorkoutSession.ProgramId → SET NULL on program delete (sessions preserved)
WorkoutProgram.TrainerId → SET NULL on trainer delete
```

## Access Control

| Caller | Create | Read | Edit Days | Delete |
|---|---|---|---|---|
| Admin | ✓ any | ✓ all | ✓ any | ✓ any |
| Trainer-JWT | ✓ own athletes | own + relationship athletes | own programs only | own programs only |
| Athlete-JWT | ✓ self-guided only | own programs | self-guided only | own self-guided only |
| Athlete-JWT (Trainer uiMode) | ✓ via email fallback | own + trainer entity programs | via email fallback | via email fallback |

## TrainerId Auto-Resolution (POST /api/programs)

When `trainerId` is `null` in the request body:

1. **Trainer-JWT caller** → filled from JWT `profile_id` claim.
2. **Athlete-JWT caller creating for another athlete** → trainer entity looked up by caller email;
   lazily created via `EnsureTrainerEntityAsync` if not found.
3. **Athlete-JWT caller creating for own profile** → remains `null` (self-guided).

## Business Rules

- Trainer programs require an accepted trainer-athlete relationship.
- Athlete self-guided programs must have `trainerId = null` and `athleteId = callerProfileId`.
- Target RPE: 1–10 when provided.
- Rest seconds cannot be negative.
- Exercises must reference active exercise library records.
- Assigned athletes are notified on program creation (`ProgramAssigned` notification).
