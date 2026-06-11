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

## Program Locking

When a coaching relationship is ended (`DELETE /api/coaching/{id}`), all trainer-created programs for that trainer-athlete pair are **locked**:
- `locked_at` is set to the current timestamp.
- `locked_reason` is set to `"coaching_ended"`.

Locked programs:
- Remain fully visible to the athlete.
- Can still be used to do workouts (start sessions, log sets).
- The **athlete** can still reschedule program days.
- Cannot have their content (days, exercises, structure) edited by anyone except Admin.
- The trainer **cannot** edit locked programs (their write access was revoked with the relationship).

When the coaching relationship is re-established (accepted again), locked programs for the same pair are automatically unlocked (`locked_at` and `locked_reason` are cleared).

Locked programs are exposed to the frontend with `lockedAt` field in the DTO. The frontend shows a `🔒 Locked` badge and a read-only warning banner.

## Deletion

- Admins can delete any program.
- Trainers (Trainer-JWT) can delete programs they own (`trainerId == profileId`) that are not locked.
- Athletes can delete:
  - Their own self-guided programs (`athleteId == profileId` and `trainerId == null`).
  - Locked trainer programs (`lockedAt != null` and `athleteId == profileId`) — the relationship ended and it's the athlete's data.
- Athlete-JWT users acting as trainer can delete programs whose trainer entity email matches theirs (when not locked).
- Deleting a program **cascades** to all program days and day exercises.
- Sessions that reference the deleted program have their `programId` set to `null` — session history is preserved.
- The web frontend requires `window.confirm` before calling the delete endpoint.

## Modification

- Trainer can update only their own programs unless admin, and only if `lockedAt == null`.
- Athletes can edit only self-guided programs they own (no trainer assigned).
- Locked programs (`lockedAt != null`) cannot be modified by anyone except Admin.

## Content Rules

- Target RPE must be between 1 and 10 when provided.
- Rest time cannot be negative.
- Program exercises must reference active exercise library records.

## Notifications

- Assigned athletes are notified (`ProgramAssigned`) when a new program is created for them.
- Assigned athletes should be notified when a program changes (planned for future).
