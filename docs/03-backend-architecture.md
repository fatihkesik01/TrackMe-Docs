# Backend Architecture

Repository: `TrackMe-Api`

ASP.NET Core 10 Minimal API. Single deployable project: all endpoints, services, models, and data access live in `TrackMe.Api`.

## Actual Project Structure

```text
TrackMe-Api/
  src/
    TrackMe.Api/
      Data/
        TrackMeDbContext.cs      — DbContext + OnModelCreating (all table/column config)
        ExerciseSeeder.cs        — seeds global exercise library on startup
      Endpoints/
        AuthEndpoints.cs
        UserEndpoints.cs
        TrainerEndpoints.cs
        AthleteEndpoints.cs
        RelationshipEndpoints.cs
        ExerciseEndpoints.cs
        ProgramEndpoints.cs
        SessionEndpoints.cs
        AnalyticsEndpoints.cs
        BodyMetricEndpoints.cs
        NotificationEndpoints.cs
        AdminEndpoints.cs
        EndpointHelpers.cs       — shared access-check helpers
      Migrations/                — EF Core migration files (22 migrations)
      Models/
        AppUser.cs
        Athlete.cs
        Trainer.cs
        TrainerAthleteRelationship.cs
        WorkoutProgram.cs
        WorkoutProgramDay.cs
        WorkoutProgramExercise.cs
        WorkoutSession.cs
        WorkoutSessionExercise.cs
        WorkoutSetLog.cs
        Exercise.cs
        BodyMetric.cs
        AppNotification.cs
        RefreshToken.cs
        PasswordResetToken.cs
        ProgramTemplate.cs       — schema exists, no active endpoints
        TrainingClass.cs         — schema exists, no active endpoints
        TemplatePurchase.cs      — schema exists, no active endpoints
        UserIntegration.cs       — schema exists, no active endpoints
        Enums.cs                 — UserRole, RelationshipStatus, SessionStatus, NotificationType
        Dtos.cs                  — all request/response record types
      Services/
        JwtTokenService.cs       — token generation + CreateAuthResponse
        PasswordHasher.cs        — PBKDF2 hash + verify
        UserProfileSync.cs       — EnsureProfileAsync, EnsureTrainerEntityAsync, EnsureAthleteEntityAsync
        ClaimsReader.cs          — IsRole, GetProfileId, GetEmail helpers
        RelationshipQueries.cs   — ToDto projection for relationships
        SlugGenerator.cs         — exercise slug generation
        InputValidator.cs        — email format validation
        RefreshTokenCleanupService.cs — background IHostedService
      Program.cs                 — DI, middleware, startup
```

## Key Services

### JwtTokenService
- `CreateAuthResponse(user, profileId, rawRefreshToken)` — returns `AuthResponse` with access token, refresh token, and user DTO
- Access token claims: `user_id`, `profile_id`, `name`, `email`, `role`

### UserProfileSync
- `EnsureProfileAsync` — creates matching Athlete or Trainer profile row on register/login if missing
- `EnsureTrainerEntityAsync` — lazily creates Trainer profile for any non-admin user (used in relationships and program creation)
- `EnsureAthleteEntityAsync` — lazily creates Athlete profile for any non-admin user

### ClaimsReader
- `IsRole(principal, role)` — checks JWT `role` claim
- `GetProfileId(principal)` — reads `profile_id` claim as `Guid?`
- `GetEmail(principal)` — reads `email` claim

### EndpointHelpers
- `HasAcceptedRelationshipAsync(db, trainerId, athleteId)` — checks for an accepted relationship row
- `ValidateProgramWriteAccessAsync` — access check for program creation
- `ValidateSessionWriteAccessAsync` — access check for session creation
- `QueueNotificationAsync(db, recipientEmail, type, title, body)` — creates `AppNotification` record

## Response Shapes

### Paginated list
```json
{
  "data": [...],
  "page": 1,
  "pageSize": 20,
  "total": 54
}
```

### Auth response
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
    "preferredUiRole": "Athlete"
  }
}
```

### Error response
```json
{ "message": "description of the error." }
```

### Unhandled exception
```json
{ "message": "An unexpected error occurred. Please try again later.", "traceId": "..." }
```

## HTTP Status Codes

| Code | Meaning                                |
|------|----------------------------------------|
| 200  | OK                                     |
| 201  | Created (with Location header)         |
| 204  | No Content (delete success)            |
| 400  | Bad Request (validation failure)       |
| 401  | Unauthorized (missing/invalid JWT)     |
| 403  | Forbidden (role or ownership failure)  |
| 404  | Not Found                              |
| 409  | Conflict (duplicate or wrong state)    |
| 429  | Too Many Requests (rate limited)       |
| 500  | Internal Server Error                  |

## Access Control Pattern

All write and read endpoints follow this pattern:

1. Extract `profileId` and `email` from JWT claims
2. For Trainer role: check `HasAcceptedRelationshipAsync` against the target athlete
3. For Athlete role: check `profileId == target.AthleteId`
4. For dual-role Athlete-JWT acting as trainer: resolve trainer entity by email, then check relationship
5. For Admin: bypass all ownership checks

## Key Patterns

### ExerciseSeeder
- Runs on startup if no global exercises exist (`AnyAsync(e => e.IsGlobal)` guard)
- Seeds 141 exercises across 13 categories: Chest, Back, Shoulders, Arms, Legs, Glutes, Core, Cardio, Functional, Full Body, Mobility, Stretching
- Every seeded exercise has a `Difficulty` value (Easy / Medium / Hard)
- Wrapped in try-catch in `Program.cs`; failure is logged but does not crash the app
- `Program.cs` logs exercise count before/after seeding for diagnostics

### CheckProgramWriteAccess (ProgramEndpoints.cs)
Athletes can only write to programs where `TrainerId == null` (self-guided). If a trainer created the program (`TrainerId != null`), athletes receive 403. Trainer entities resolved by email for dual-role users.

## Migrations

22 EF Core migrations in order:

| #  | Name                                        | Key change                                        |
|----|---------------------------------------------|---------------------------------------------------|
|  1 | InitialCreate                               |                                                   |
|  2 | AddIdentityFoundation                       |                                                   |
|  3 | AllowSelfGuidedPrograms                     |                                                   |
|  4 | AddTrainerAthleteRelationships              |                                                   |
|  5 | AddExerciseLibrary                          |                                                   |
|  6 | AddSessionExerciseTracking                  |                                                   |
|  7 | AddProgramStructure                         |                                                   |
|  8 | Phase2_ProfileBioAndNotifications           |                                                   |
|  9 | Phase2_RelationshipInitiator                |                                                   |
| 10 | Phase3TemplatesAnalyticsAuth                |                                                   |
| 11 | Phase3AnalyticsIndexes                      |                                                   |
| 12 | Phase6_BodyMetricsClassesMarketplace        |                                                   |
| 13 | Phase7_ExerciseOwnership                    |                                                   |
| 14 | Phase8_WorkoutMode                          |                                                   |
| 15 | Phase8b_RepsAsString                        |                                                   |
| 16 | Phase9_TargetWeightAndPlannedFields         |                                                   |
| 17 | Phase12_TrainerNoteOnSessionExercise        |                                                   |
| 18 | Phase15_BodyMetricsExtendedFields           |                                                   |
| 19 | Phase16_ExerciseDifficulty                  | adds `difficulty` to exercises                    |
| 20 | Phase17_UserPreferredUiRole                 | adds `preferred_ui_role` to users                 |
| 21 | Phase18_AllowMultipleDaysPerDate            | drops unique index on (program_id, day_number)    |
