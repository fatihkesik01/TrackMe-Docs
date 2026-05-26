# Business Rules

This file summarizes the core business rules. Detailed rule files are available under `business-rules/`.

## Global Rules

- Users must have at least one role.
- Passwords must be hashed.
- JWT secrets must not be stored in source control.
- All protected endpoints require authentication.
- Role checks must be combined with ownership checks.
- Users can only access their own data unless a valid trainer-athlete relationship or admin role exists.

## Trainer-Athlete Rules

- A trainer can manage multiple athletes.
- An athlete can work with multiple trainers.
- A trainer can only view athlete history after a relationship is accepted.
- Pending relationship requests do not grant data access.
- Either side may end a relationship.

## Exercise Rules

- Exercise names must be unique after normalization.
- Exercise slugs must be unique.
- Measurement type determines valid set fields.
- Exercises used in history should not be hard deleted.

## Program Rules

- Only trainers can create workout programs.
- Trainers can edit only their own programs unless admin.
- A program must contain at least one day before assignment.
- Program exercises must reference valid exercises from the exercise library.
- Target RPE should be between 1 and 10.

## Workout Tracking Rules

- Athletes can start workouts only for themselves.
- Set RPE must be between 1 and 10 when provided.
- Completed workouts should become immutable except for admin correction or controlled edit flow.
- Workout duration is calculated from start and end time.
- Workout sessions must preserve historical exercise names even if the exercise library changes later.

## Notification Rules

- Notifications must belong to a user.
- Notifications should be created for relevant trainer-athlete events.
- Read status is per user.
- Push notification failure must not fail the core business transaction.

## Analytics Rules

- Analytics should use completed workouts by default.
- Draft or cancelled workouts should not affect progress metrics.
- Volume calculations should respect measurement type.
- RPE analysis should compare planned RPE with actual RPE when program data exists.
