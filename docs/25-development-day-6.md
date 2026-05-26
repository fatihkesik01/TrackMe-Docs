# Development Day 6

Day 6 goal is to add structured workout tracking.

The focus is moving from a simple session log to exercises and set-level data that can power analytics.

## Current Baseline

- Sessions exist as simple records with duration and RPE.
- Program days and planned exercises are planned for Day 5.
- Exercises are planned for Day 4.

## Day 6 Scope

- Add workout session exercises.
- Add set logs for reps, weight, RPE, and completion data.
- Support free sessions and program-based sessions.
- Keep logging fast and low-friction.

## API Tasks

- [ ] Add `WorkoutSessionExercise` entity.
- [ ] Add `WorkoutSetLog` entity.
- [ ] Create EF Core migration.
- [ ] Add endpoint to create a structured workout session.
- [ ] Add endpoint to add exercises to a session.
- [ ] Add endpoint to add set logs.
- [ ] Add endpoint to update set logs.
- [ ] Add endpoint to complete a workout session.
- [ ] Validate athlete ownership and trainer access.
- [ ] Keep existing simple session endpoint compatible or clearly replace it.

## Web Tasks

- [ ] Add session detail or logging panel.
- [ ] Add exercise selector for free sessions.
- [ ] Add planned exercise display for program sessions.
- [ ] Add set rows for reps, weight, RPE, and notes.
- [ ] Add complete session action.
- [ ] Keep mobile future workflow in mind: minimal taps, clear fields.

## Database Tasks

- [ ] Verify session exercise and set log tables in DBeaver.
- [ ] Verify set logs reference session exercises.
- [ ] Verify existing simple sessions survive migration.
- [ ] Verify analytics fields are queryable.

## Docs Tasks

- [ ] Update workout tracking analysis.
- [ ] Update database design and ERD.
- [ ] Update API analysis with workout tracking endpoints.
- [ ] Update workout tracking business rules.
- [ ] Add Day 6 completion notes.

## Acceptance Criteria

Day 6 is complete when:

- A session can contain multiple exercises.
- Each exercise can contain multiple set logs.
- Set logs store reps, weight, and RPE.
- Free sessions and program sessions both work.
- Trainer/athlete access rules are respected.
- Docs reflect the structured tracking model.

## Out Of Scope For Day 6

- Offline mobile logging.
- Timers and rest tracking automation.
- Wearable integration.
- Exercise video capture.
- Advanced analytics dashboards.
