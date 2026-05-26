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

- [ ] Add `Exercise` entity.
- [ ] Add fields: name, slug, category, primary muscles, equipment, instructions, active status, created time.
- [ ] Configure unique exercise slug.
- [ ] Create EF Core migration.
- [ ] Add `GET /api/exercises`.
- [ ] Add `GET /api/exercises/{id}`.
- [ ] Add `POST /api/exercises`.
- [ ] Add `PUT /api/exercises/{id}` or defer with docs note.
- [ ] Add `DELETE /api/exercises/{id}` as soft disable or defer with docs note.
- [ ] Require authentication for exercise endpoints.
- [ ] Decide MVP role rule: admin/trainer can write, athlete can read.

## Web Tasks

- [ ] Add Exercises navigation entry.
- [ ] Add exercise list view.
- [ ] Add create exercise form.
- [ ] Add category and equipment fields.
- [ ] Add empty and loading states.
- [ ] Show validation errors from API.
- [ ] Keep dashboard workflows stable.

## Database Tasks

- [ ] Apply exercise migration locally or on VPS.
- [ ] Verify `exercises` table in DBeaver.
- [ ] Seed a small manual exercise list through the UI or Scalar.
- [ ] Confirm slug uniqueness.

## Docs Tasks

- [ ] Update database design with `exercises`.
- [ ] Update API analysis with exercise endpoints.
- [ ] Update exercise module docs.
- [ ] Update business rules for exercise ownership.
- [ ] Add completion notes to this file.

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
