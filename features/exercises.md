# Exercise Library

## Overview

TrackMe maintains a centralized, shared exercise library. All programs reference exercises from this library by `exercise_id`. The library ships with 141+ seeded exercises and grows via trainer/admin additions.

## Data Model

### `exercises` Table

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid PK | |
| `name` | string | required, unique (normalized) |
| `slug` | string | unique, URL-safe |
| `category` | string | required — see categories below |
| `primary_muscles` | string? | editable text (e.g. "Chest, Anterior Deltoid") |
| `equipment` | string? | editable text (e.g. "Barbell, Power Rack") |
| `instructions` | string? | editable text |
| `measurement_type` | string | controls which set fields are valid |
| `is_active` | bool | soft-delete flag |
| `created_at` | timestamptz | |

### Measurement Types

| Type | Valid set fields |
|------|----------------|
| `weight_reps` | reps + weight_kg (primary) |
| `reps_only` | reps only |
| `duration` | duration_seconds |
| `distance` | distance_meters |
| `time_distance` | duration + distance |
| `bodyweight` | reps only, bodyweight noted |
| `machine_level` | machine resistance level |
| `hold_time` | hold duration in seconds |
| `amrap` | reps (as many as possible) |

### Categories

Strength, Cardio, Flexibility, Balance, Calisthenics, Olympic Weightlifting, Powerlifting, Machine, Functional, Sport-Specific, Rehabilitation.

---

## Business Rules

- Exercise name is required and must be globally unique (normalized comparison — case-insensitive, whitespace-normalized).
- Slug must be unique.
- Exercises used in historical workouts must NOT be hard-deleted — use `is_active = false` (soft delete).
- `measurement_type` controls which set fields are presented in WorkoutMode and validated by the API.
- `primary_muscles`, `equipment`, and `instructions` are free-text fields until a structured taxonomy is needed.

---

## Access Control

| Role | Can do |
|------|--------|
| Admin | Create, update, soft-delete, un-delete any exercise |
| Trainer | Create new exercises, update own submissions |
| Athlete | Read active exercises only |

---

## Seeding

`ExerciseSeeder.SeedAsync(db)` runs at API startup. Seeds all exercises from a JSON fixture if the `exercises` table is empty. Seeded exercises are pre-populated with `category`, `primary_muscles`, `equipment`, `measurement_type`.

Current seed count: **141+ exercises**

---

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/exercises` | List active exercises (filterable) |
| `GET` | `/api/exercises/{id}` | Get single exercise |
| `POST` | `/api/exercises` | Create exercise (Trainer / Admin) |
| `PATCH` | `/api/exercises/{id}` | Update exercise (Trainer / Admin) |
| `DELETE` | `/api/exercises/{id}` | Soft-delete (Admin only) |
| `GET` | `/api/admin/exercises/duplicates` | Review duplicate candidates (Admin) |

### Query Params for List

| Param | Description |
|-------|-------------|
| `q` | Name search (substring, case-insensitive) |
| `category` | Filter by category |
| `muscle` | Filter by primary muscle |
| `equipment` | Filter by equipment |
| `measurementType` | Filter by measurement type |
| `isActive` | Default true; admin can pass false to see deactivated |

---

## Duplicate Detection

The admin can review exercises flagged as potential duplicates via `GET /api/admin/exercises/duplicates`. Detection uses normalized name comparison (lowercase, no punctuation) and Levenshtein distance threshold.

---

## Frontend

### ExercisesView (`ExercisesView.jsx`)

Available to Admin, Trainer, and Athlete roles.

- Search bar filters by name in real-time (client-side after initial load)
- Category filter chips
- Each exercise card: name, category badge, muscle/equipment tags, measurement type
- Trainer/Admin: "+" button to create new exercise
- Inline edit for Trainer-created exercises

### ExerciseEditorSection (shared component)

Used in both `ProgramBuilderView` and `TemplatesView` for set-level planning. Renders per-set rows with: reps input, weight input, RPE picker, rest input, warm-up toggle, notes. Respects `measurement_type` of the selected exercise to show/hide irrelevant fields.

### Exercise Search in WorkoutMode

Athletes can search and add exercises to an active session. The search is against the full active library; selected exercises are added as `WorkoutSessionExercise` rows.
