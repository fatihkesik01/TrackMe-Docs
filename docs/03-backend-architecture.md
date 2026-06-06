# Backend Architecture

Repository: `TrackMe-Api`

ASP.NET Core Minimal API. The API is a single deployable project: endpoints, services, models, migrations, and data access all live under `src/TrackMe.Api`.

## Actual Project Structure

```text
TrackMe-Api/
  src/
    TrackMe.Api/
      Data/
        TrackMeDbContext.cs      - DbContext and all table/column configuration
        ExerciseSeeder.cs        - global exercise library seed data
      Endpoints/
        AuthEndpoints.cs
        UserEndpoints.cs
        TrainerEndpoints.cs
        AthleteEndpoints.cs
        RelationshipEndpoints.cs
        ExerciseEndpoints.cs
        ProgramEndpoints.cs
        SessionEndpoints.cs
        MessageEndpoints.cs
        AnalyticsEndpoints.cs
        BodyMetricEndpoints.cs
        NotificationEndpoints.cs
        AdminEndpoints.cs
        EndpointHelpers.cs
        TemplateEndpoints.cs     - retained helper/API file; routes not registered
        ClassEndpoints.cs        - routes not registered
        MarketplaceEndpoints.cs  - routes not registered
      Migrations/
      Models/
        AppUser.cs
        Athlete.cs
        Trainer.cs
        TrainerAthleteRelationship.cs
        Exercise.cs
        WorkoutProgram.cs
        WorkoutProgramDay.cs
        WorkoutProgramExercise.cs
        WorkoutSession.cs
        WorkoutSessionExercise.cs
        WorkoutSetLog.cs
        BodyMetric.cs
        AppNotification.cs
        DirectMessage.cs
        RefreshToken.cs
        PasswordResetToken.cs
        ProgramTemplate.cs       - inactive schema
        TrainingClass.cs         - inactive schema
        TemplatePurchase.cs      - inactive schema
        UserIntegration.cs       - inactive schema
        Enums.cs
        Dtos.cs
      Services/
        JwtTokenService.cs
        PasswordHasher.cs
        UserProfileSync.cs
        ClaimsReader.cs
        RelationshipQueries.cs
        SlugGenerator.cs
        InputValidator.cs
        ProfileSports.cs
        RefreshTokenCleanupService.cs
      Program.cs
```

## Registered Endpoint Groups

`Program.cs` currently registers these endpoint groups:

```text
Auth
Users
Trainers
Athletes
Relationships
Exercises
Programs
Sessions
Analytics
Notifications
Messages
Admin
BodyMetrics
```

`TemplateEndpoints`, `ClassEndpoints`, and `MarketplaceEndpoints` remain in the repository but are not mapped in `Program.cs`. Template helper logic is still referenced by program creation when a `templateId` is supplied.

## Key Services

### JwtTokenService

- Creates access tokens and refresh-token auth responses.
- Access token claims include `user_id`, `profile_id`, `name`, `email`, and `role`.

### UserProfileSync

- Ensures matching Athlete or Trainer profile rows for registered users.
- Lazily creates trainer/athlete entities for dual-role flows when needed.

### ClaimsReader

- Reads role, email, and profile id from the current principal.
- Centralizes claim parsing for endpoint access checks.

### EndpointHelpers

- Checks accepted trainer-athlete relationships.
- Validates program/session write access.
- Queues notification records.

## Response Shapes

### Paginated List

```json
{
  "data": [],
  "page": 1,
  "pageSize": 20,
  "total": 0
}
```

### Auth Response

```json
{
  "accessToken": "...",
  "accessExpiresAt": "...",
  "refreshToken": "...",
  "refreshExpiresAt": "...",
  "user": {
    "id": "...",
    "profileId": "...",
    "fullName": "...",
    "email": "...",
    "role": "Athlete",
    "preferredUiRole": "Athlete",
    "age": 28,
    "profession": "Software developer",
    "trainingYears": 4,
    "primarySport": "Fitness, Running",
    "sports": ["Fitness", "Running"],
    "sportDetails": [
      { "name": "Fitness", "trainingYears": 3 },
      { "name": "Running", "trainingYears": 0.5 }
    ],
    "readNotificationRetentionDays": 3
  }
}
```

### Error Response

```json
{ "message": "description of the error" }
```

Unhandled exceptions return a generic message plus `traceId`.

## Access Control Pattern

Endpoint access checks follow the same general order:

1. Read caller profile id, email, and role from JWT claims.
2. Allow Admin for platform-wide operations.
3. For Trainer operations, validate accepted relationship against the target athlete.
4. For Athlete operations, validate ownership of the target athlete profile.
5. For dual-role Athlete-JWT users, resolve the trainer entity by email when a trainer-scoped flow needs it.

## Key Runtime Patterns

### Exercise Seeding

- Runs on startup if no global exercises exist.
- Seeds 141 global exercises across the active category set.
- Seed failures are logged and do not crash API startup.

### Program Write Access

- Trainers can write programs they own.
- Athletes can write only self-guided programs where `trainerId` is null.
- Dual-role Athlete-JWT callers can act through their trainer entity by email resolution.

### Session History Preservation

- Program deletion cascades program days/exercises.
- Historical sessions keep their records; `program_id` and `program_day_id` are nullable where needed.
- Session exercises store planned snapshots so later program edits do not rewrite history.
- Repeat-pattern application reuses/updates generated program days and must not delete linked workout sessions.

## Migrations

35 EF Core migrations are present:

| # | Name | Key change |
|---|------|------------|
| 1 | InitialCreate | Initial schema |
| 2 | AddIdentityFoundation | Users, auth foundation |
| 3 | AllowSelfGuidedPrograms | Nullable trainer programs |
| 4 | AddTrainerAthleteRelationships | Relationship table |
| 5 | AddExerciseLibrary | Exercise library |
| 6 | AddSessionExerciseTracking | Session exercise/set tracking |
| 7 | AddProgramStructure | Program days and exercises |
| 8 | Phase2_ProfileBioAndNotifications | Profile fields and notifications |
| 9 | Phase3TemplatesAnalyticsAuth | Template schema and auth additions |
| 10 | Phase3AnalyticsIndexes | Analytics indexes |
| 11 | Phase2_RelationshipInitiator | Relationship direction |
| 12 | Phase6_BodyMetricsClassesMarketplace | Body metrics and inactive platform schema |
| 13 | Phase7_ExerciseOwnership | Global/private exercises |
| 14 | Phase8_WorkoutMode | Active workout mode fields |
| 15 | Phase8b_RepsAsString | Program reps as string |
| 16 | Phase9_TargetWeightAndPlannedFields | Target/planned values |
| 17 | Phase12_TrainerNoteOnSessionExercise | Trainer review note |
| 18 | Phase15_BodyMetricsExtendedFields | Extended body metrics |
| 19 | Phase16_ExerciseDifficulty | Exercise difficulty |
| 20 | Phase17_UserPreferredUiRole | Preferred UI role |
| 21 | Phase18_AllowMultipleDaysPerDate | Non-unique program day number |
| 22 | Phase19_AthleteFeaturedExercise | Athlete featured exercise |
| 23 | Phase20_AthleteFeaturedSession | Athlete featured session |
| 24 | Phase21_SessionDayLinkAndReschedule | Session day link and rescheduled dates |
| 25 | Phase3_SessionProgramCascadeDelete | Preserve sessions when programs are deleted |
| 26 | EndRelationshipDeactivatePrograms | Ended relationships deactivate linked trainer programs |
| 27 | Phase3_FeaturedExercisesList | Featured exercise list with session-backed entries |
| 28 | ProfileNotificationSettings | Shared profile fields and notification dropdown retention |
| 29 | ProfileSportsList | Expand profile sport storage for multiple sports |
| 30 | ProfileSportExperience | Store per-sport experience years in profile sports JSON |
| 31 | ProfileTrainingYearsDecimal | Allow decimal profile training years |
| 32 | UserUnitPreferences | Store user weight and height display-unit preferences |
| 33 | DirectMessages | Direct message table for trainer-athlete chat |
| 34 | DirectMessageReferences | Nullable direct message program/exercise reference metadata |
| 35 | Phase3_RepeatPattern_SetWeights_EquipmentIncrements | Repeat-pattern programs, per-set planned weights, athlete equipment increments |

## Migration Rules

- Generate migrations with the EF CLI; do not hand-write migration files.
- Use `dotnet ef migrations add <Name> --project src/TrackMe.Api/TrackMe.Api.csproj --startup-project src/TrackMe.Api/TrackMe.Api.csproj`.
- If the latest migration is wrong and has not been applied to a shared/production database, remove it with `dotnet ef migrations remove --project src/TrackMe.Api/TrackMe.Api.csproj --startup-project src/TrackMe.Api/TrackMe.Api.csproj --force`, fix the model, then regenerate it.
- If a wrong migration may already be applied to a shared/production database, keep it and create a new corrective migration.
- Column names are configured as snake_case in `TrackMeDbContext`.
- Production applies migrations at API startup with `db.Database.MigrateAsync()`.
