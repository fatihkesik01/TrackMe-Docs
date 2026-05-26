# Development Day 5

Day 5 goal is to turn simple workout programs into structured plans.

The focus is program days and planned exercises, using the exercise library from Day 4.

## Current Baseline

- Workout programs exist as simple records.
- Exercises exist in the planned Day 4 foundation.
- Trainer-athlete accepted relationships identify which athletes a trainer can program for.

## Day 5 Scope

- Add structured workout program days.
- Add planned exercises to a program day.
- Keep the first builder simple and editable enough for MVP.
- Preserve self-guided athlete programs.

## API Tasks

- [ ] Add `WorkoutProgramDay` entity.
- [ ] Add `WorkoutProgramExercise` entity.
- [ ] Add planned set fields: order, sets, reps, target RPE, rest seconds, notes.
- [ ] Create EF Core migration.
- [ ] Add `GET /api/programs/{id}` with days and exercises.
- [ ] Add endpoint to create a program day.
- [ ] Add endpoint to add exercises to a program day.
- [ ] Add endpoint to remove or disable planned exercises.
- [ ] Enforce trainer access for trainer-led programs.
- [ ] Enforce athlete ownership for self-guided programs.

## Web Tasks

- [ ] Add program detail view or expanded program panel.
- [ ] Add day creation UI.
- [ ] Add exercise selection from exercise library.
- [ ] Add planned sets, reps, RPE, rest, and notes fields.
- [ ] Show program structure in a readable list.
- [ ] Keep simple program creation form usable.
- [ ] Keep athlete self-guided program creation usable.

## Database Tasks

- [ ] Verify program day and planned exercise tables in DBeaver.
- [ ] Verify planned exercises reference existing exercises.
- [ ] Verify deleting or disabling exercises does not break existing program rows.

## Docs Tasks

- [ ] Update workout program analysis.
- [ ] Update database design and ERD.
- [ ] Update API analysis with program structure endpoints.
- [ ] Update workout program business rules.
- [ ] Add Day 5 completion notes.

## Acceptance Criteria

Day 5 is complete when:

- A trainer can create a program for an accepted athlete.
- A trainer can add at least one day to the program.
- A trainer can add exercises with planned sets and reps.
- An athlete can still create a self-guided program.
- Program details can be retrieved from the API.
- Docs reflect the implemented program structure.

## Out Of Scope For Day 5

- Program versioning.
- Calendar drag and drop.
- Program templates marketplace.
- Advanced periodization builder.
- Workout completion against planned sets.
