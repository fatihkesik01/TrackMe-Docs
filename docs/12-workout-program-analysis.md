# Workout Program Analysis

Workout programs are created by trainers and assigned to athletes.

## Program Structure

```text
Program
  Week
    Day
      Exercise
        Planned Sets
```

## Program Fields

- Name
- Description
- Trainer ID
- Goal
- Training level
- Start date
- End date
- Status
- Notes

## Program Exercise Fields

- Exercise ID
- Order
- Target sets
- Target reps min
- Target reps max
- Target RPE
- Rest time seconds
- Tempo optional
- Notes

## Example

```text
Program: Hypertrophy Block 1

Week 1
Day 1 - Push

Bench Press
4 sets
6-8 reps
RPE 8
Rest 180 sec
```

## Program Rules

- A program belongs to the trainer who created it.
- A program may be assigned only to accepted athletes.
- Program days should preserve exercise order.
- Program updates should notify assigned athletes.
- Assigned program history should remain interpretable after edits.

## Versioning Recommendation

For the first version, keep program edits simple. Preserve workout session history independently so past completed workouts are not damaged by future program changes.

For later versions, introduce program versioning:

- Program version
- Assignment version
- Historical snapshot for completed sessions
