# Development Day 4

Day 4 goal is to add the exercise library foundation.

The focus is a reusable exercise catalog that workout programs and workout sessions can use later.

## Current Baseline

- Trainers and athletes can authenticate.
- Trainer-athlete relationships exist.
- Programs and sessions currently store simple MVP fields.
- No structured exercise catalog exists yet.

## Day 4 Scope

- Add exercise entity and database table.
- Add basic CRUD endpoints for exercises.
- Add simple web management UI.
- Prepare exercises for program builder and workout logging.

## API Tasks

- [x] Add `Exercise` entity.
- [x] Add fields: name, slug, category, primary muscles, equipment, instructions, active status, created time.
- [x] Configure unique exercise slug.
- [x] Create EF Core migration.
- [x] Add `GET /api/exercises`.
- [x] Add `GET /api/exercises/{id}`.
- [x] Add `POST /api/exercises`.
- [x] Add `PUT /api/exercises/{id}`.
- [x] Add `DELETE /api/exercises/{id}` as soft disable.
- [x] Require authentication for exercise endpoints.
- [x] Decide MVP role rule: admin/trainer can write, athlete can read.

## Web Tasks

- [x] Add Exercises navigation entry.
- [x] Add exercise list view.
- [x] Add create exercise form.
- [x] Add category and equipment fields.
- [x] Add empty and loading states.
- [x] Show validation errors from API.
- [x] Keep dashboard workflows stable.

## Database Tasks

- [x] Apply exercise migration on VPS through deploy workflow.
- [x] Verify `exercises` table through PostgreSQL.
- [x] Seed a small manual exercise list through the deployed API.
- [x] Confirm slug uniqueness.

## Docs Tasks

- [x] Update database design with `exercises`.
- [x] Update API analysis with exercise endpoints.
- [x] Update exercise module docs.
- [x] Update business rules for exercise ownership.
- [x] Add completion notes to this file.

## Acceptance Criteria

Day 4 is complete when:

- Exercises can be created and listed from the web app.
- Exercises are stored in PostgreSQL.
- Duplicate slugs or duplicate names are handled clearly.
- API reference shows exercise endpoints.
- Docs reflect the implemented exercise library.

## Out Of Scope For Day 4

- Exercise media uploads.
- Exercise demo videos.
- Public exercise marketplace.
- Program builder exercise assignment.
- Workout set logging.

## Completion Notes

- API exercise library was implemented and deployed in `TrackMe-Api` commit `3dff49e`.
- Web exercise library UI was implemented and deployed in `TrackMe-Web` commit `15db8d0`.
- EF Core migration `20260526173405_AddExerciseLibrary` creates the `exercises` table and unique slug index.
- Trainer/admin users can create, update, and soft-delete exercises.
- Athlete users can read active exercises but cannot create exercises.
- `DELETE /api/exercises/{id}` sets `is_active` to false and active exercise lists hide inactive rows.
- Duplicate exercise slugs return conflict.
- Seeded active exercises: Back Squat, Bench Press, and Plank.
