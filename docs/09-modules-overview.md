# Modules Overview

TrackMe should be implemented as a modular backend with clear boundaries.

## Module List

- Auth Module
- User Module
- Trainer Module
- Athlete Module
- Relationship Module
- Exercise Module
- Workout Program Module
- Workout Tracking Module
- RPE Module
- Notification Module
- Analytics Module
- Admin Module

## Module Boundary Rules

- Modules expose application services or use cases.
- Modules should not directly modify unrelated module data without a defined service contract.
- Shared primitives should live in domain or common packages.
- Cross-module side effects should use domain events where practical.

## Suggested Dependency Direction

```text
Api -> Application -> Domain
Application -> Infrastructure abstractions
Infrastructure -> Application abstractions + Domain
```

## Module Documentation

Detailed module files:

- [Auth Module](../backend/modules/auth.md)
- [User Module](../backend/modules/user.md)
- [Trainer Module](../backend/modules/trainer.md)
- [Athlete Module](../backend/modules/athlete.md)
- [Relationship Module](../backend/modules/relationship.md)
- [Exercise Module](../backend/modules/exercise.md)
- [Workout Program Module](../backend/modules/workout-program.md)
- [Workout Tracking Module](../backend/modules/workout-tracking.md)
- [RPE Module](../backend/modules/rpe.md)
- [Notification Module](../backend/modules/notification.md)
- [Analytics Module](../backend/modules/analytics.md)
- [Admin Module](../backend/modules/admin.md)
