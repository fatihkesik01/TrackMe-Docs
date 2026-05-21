# Backend Modules

TrackMe backend modules are designed around clear business boundaries.

## Modules

- [Auth](auth.md)
- [User](user.md)
- [Trainer](trainer.md)
- [Athlete](athlete.md)
- [Relationship](relationship.md)
- [Exercise](exercise.md)
- [Workout Program](workout-program.md)
- [Workout Tracking](workout-tracking.md)
- [RPE](rpe.md)
- [Notification](notification.md)
- [Analytics](analytics.md)
- [Admin](admin.md)

## Shared Rules

- Every protected use case requires an authenticated user.
- Role checks are not enough; ownership checks are mandatory.
- Application services should own business workflow validation.
- Infrastructure should not contain business decisions.
- Domain entities should protect core invariants where practical.
