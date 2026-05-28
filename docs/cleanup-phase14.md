# Module Cleanup Log — Phase 14

Phase 14 introduced the athlete-centric architecture. Several earlier modules and navigation structures were removed to eliminate dead code and simplify the system.

## Removed Frontend Modules

### Standalone workout/session pages
Before Phase 14, sessions and workouts had their own top-level navigation entries separate from the athlete-centric flow. These were folded into `AthleteDetailView` (trainer perspective) and `ProgramsView` + `SessionsView` (athlete perspective).

### Templates marketplace
A frontend `MarketplaceView` and associated API calls existed for purchasing and applying program templates. This module was not part of the core training management flow and was removed entirely.

### Group workout (classes) module
A `ClassesView` existed for trainer-managed group training sessions. Removed; no replacement in the current architecture.

### Standalone programs page (old)
The old standalone programs page that mixed trainer and athlete views was replaced by separate `myPrograms` (trainer) and `myProgram` (athlete) views backed by the same `ProgramsView` component with different props.

### Old navigation structure
Before Phase 14, a single `NAV_ITEMS` array was shared across roles. Replaced by three separate arrays: `TRAINER_NAV`, `ATHLETE_NAV`, `ADMIN_NAV`.

## Removed Backend Endpoints

The following endpoint files were commented out of `Program.cs` in Phase 14:

```csharp
// Templates, Classes, Marketplace removed in Phase 14 (athlete-centric architecture)
// app.MapTemplateEndpoints();
// app.MapClassEndpoints();
// app.MapMarketplaceEndpoints();
```

The endpoint files themselves (`TemplateEndpoints.cs`, `ClassEndpoints.cs`, `MarketplaceEndpoints.cs`) remain in the repository but are not registered. No routes exist for them.

## Dead Database Tables

These tables remain in the database schema because dropping them from a migration risks data loss. They have no active endpoints and no application code writes to them.

| Table                      | Originally for                           |
|----------------------------|------------------------------------------|
| `program_templates`        | Reusable program template library        |
| `program_template_days`    | Template day structure                   |
| `program_template_exercises` | Template exercise entries              |
| `template_purchases`       | Marketplace purchase records             |
| `training_classes`         | Group training session scheduling        |
| `class_participants`       | Athlete enrollment in group sessions     |
| `user_integrations`        | Wearable device OAuth tokens             |

## What Replaced the Removed Features

| Removed                       | Replacement                                                  |
|-------------------------------|--------------------------------------------------------------|
| Marketplace template purchase | Programs are created directly per athlete by trainers        |
| Group classes                 | Individual athlete sessions via WorkoutMode                  |
| Shared program templates      | Program builder creates from scratch per athlete             |
| Mixed-role nav                | Separate TRAINER_NAV / ATHLETE_NAV / ADMIN_NAV               |
| Standalone workout page       | WorkoutMode overlay launched from ProgramBuilderView         |

## Retained Endpoint Files (Inactive)

`TemplateEndpoints.cs` is still used for one internal path: `ProgramEndpoints.Create` calls `TemplateEndpoints.CanRead()` when a `templateId` is provided in the create request. The template-to-program copy logic remains functional for internal use even though the template management API routes are not exposed.
