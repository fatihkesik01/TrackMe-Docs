# Workout Tracking Analysis

Workout tracking is one of the most important systems in TrackMe.

## Workout Session Data

- Athlete ID
- Program ID optional
- Program day ID optional
- Start time
- End time
- Duration
- Status
- Workout RPE
- Notes

## Exercise Log Data

- Session ID
- Exercise ID
- Exercise name snapshot
- Order
- Notes

## Set Log Data

- Session exercise ID
- Set number
- Weight
- Reps
- Duration
- Distance
- RPE
- Rest time
- Notes

## Session Statuses

- Draft
- InProgress
- Completed
- Cancelled

## Tracking Flow

1. Athlete starts workout.
2. App creates session or local draft.
3. Athlete logs exercises and sets.
4. App tracks rest timers.
5. Athlete completes workout.
6. Backend validates and stores final session.
7. Trainer receives notification when relevant.
8. Analytics become available.

## Fast Logging Requirements

- Add set quickly.
- Repeat previous set values.
- Adjust weight, reps, and RPE with minimal taps.
- Keep rest timer visible.
- Save draft automatically.
- Do not lose active workout data.

## Historical Integrity

Workout history must remain meaningful even when:

- Program changes later.
- Exercise instructions change.
- Trainer-athlete relationship ends.
- Athlete profile changes.
