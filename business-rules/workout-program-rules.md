# Workout Program Rules

## Creation

- Trainer-JWT users can create programs for their accepted athletes.
- Athlete-JWT users can create self-guided programs (no `trainerId`) for their own profile.
- Athlete-JWT users who also have a trainer entity (via Trainer uiMode / dual-role) can create
  trainer-assigned programs for their accepted athletes. The backend auto-resolves `trainerId`
  from the caller's email when the frontend sends `null`.
- A program can only be assigned to an athlete with an accepted trainer-athlete relationship.
- `trainerId` must match the caller's own trainer profile; trainers cannot create programs on
  behalf of another trainer.
- `athleteId` must reference an existing athlete record.

## Deletion

- Admins can delete any program.
- Trainers (Trainer-JWT) can delete programs they own (`trainerId == profileId`).
- Athletes can delete only their own self-guided programs (`athleteId == profileId` and `trainerId == null`).
- Athlete-JWT users acting as trainer can delete programs whose trainer entity email matches theirs.
- Deleting a program **cascades** to all program days and day exercises.
- Sessions that reference the deleted program have their `programId` set to `null` — session history is preserved.
- The web frontend requires `window.confirm` before calling the delete endpoint.

## Modification

- Trainer can update only their own programs unless admin.
- Athletes can edit only self-guided programs they own (no trainer assigned).

## Content Rules

- Target RPE must be between 1 and 10 when provided.
- Rest time cannot be negative.
- Program exercises must reference active exercise library records.

## Notifications

- Assigned athletes are notified (`ProgramAssigned`) when a new program is created for them.
- Assigned athletes should be notified when a program changes (planned for future).
