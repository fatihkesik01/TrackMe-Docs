# API Route Reference

Base URL: `http://187.77.92.30:5050`

All `/api/*` endpoints require JWT Bearer authentication unless marked as public.

## Health

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/health` | Public | Basic health ping |
| GET | `/api/health` | Public | Detailed health check with database status |

## Auth (`/api/auth`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/auth/register` | Public | Register a user and return auth tokens |
| POST | `/api/auth/login` | Public, rate-limited | Login and return auth tokens |
| GET | `/api/auth/me` | Required | Return current user, profile id, preferred UI role, shared profile fields, notification retention, and unit preferences |
| POST | `/api/auth/refresh` | Public | Rotate refresh token and return new auth tokens |
| POST | `/api/auth/logout` | Public | Revoke refresh token |
| POST | `/api/auth/forgot-password` | Public | Create password reset token |
| POST | `/api/auth/reset-password` | Public | Reset password with token |
| PATCH | `/api/auth/profile` | Required | Update profile fields, sports list with per-sport experience years, notification dropdown retention, and unit preferences |
| PATCH | `/api/auth/preferred-role` | Required | Set preferred UI role (`Athlete` or `Trainer`) |
| POST | `/api/auth/change-password` | Required | Change password and revoke sessions |

`GET /api/auth/me`, login, refresh, and profile update responses include `sports` as a legacy name list and `sportDetails` as `{ name, trainingYears }` items for per-sport experience display. `trainingYears` accepts decimal values such as `0.5`. Responses also include `weightUnit` (`kg` or `lbs`) and `heightUnit` (`cm` or `ft-in`). API and database weight/height fields remain canonical (`weightKg`, `heightCm`); Web clients convert values at the input/display boundary. Responses also include `dumbbellIncrementKg` (default 2.0) and `barbellPlatePerSideKg` (default 2.5) — athlete equipment increment settings used by the program builder and workout mode for the +Weight button. `PATCH /api/auth/profile` accepts the same two fields for Athlete-role users; values must be > 0 and <= 50.

## Users (`/api/users`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/users/search` | Required | Search users by name or email |

## Trainers (`/api/trainers`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/trainers` | Required | List trainers, scoped by caller role |
| POST | `/api/trainers` | Required | Create or ensure trainer profile |
| GET | `/api/trainers/me/athletes` | Required | List accepted athletes for caller's trainer entity |
| GET | `/api/trainers/search` | Required | Search trainers by name or email |

## Athletes (`/api/athletes`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/athletes` | Required | List athletes, scoped by caller role |
| GET | `/api/athletes/search` | Required | Search athletes by name or email |
| GET | `/api/athletes/me` | Required | Return caller's athlete profile |
| GET | `/api/athletes/me/performed-exercises` | Required | Unique exercises the caller has performed (deduplicated) |
| GET | `/api/athletes/me/performed-exercise-sessions` | Required | All exercise+session combos with date, max weight, set count; ordered by max weight desc |
| GET | `/api/athletes/me/featured-exercises` | Required | List caller's featured exercise items (ordered by order_index) |
| POST | `/api/athletes/me/featured-exercises` | Required | Add an exercise to the featured list; returns updated list |
| DELETE | `/api/athletes/me/featured-exercises/{id}` | Required | Remove one item from the featured list |
| GET | `/api/athletes/{athleteId}/featured-exercises` | Required | Trainer/admin view of an athlete's featured exercises |
| POST | `/api/athletes` | Required | Create athlete profile |

### Add Featured Exercise Request

```json
{ "exerciseId": "guid", "sessionId": "guid-or-null" }
```

No limit on entries. The same exercise can be added multiple times with different sessions. Each item in the response includes the session date, session title, max weight, total sets, and full set list so no additional calls are needed.

## Relationships (`/api/relationships`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/relationships/requests` | Required | Trainer sends access request to athlete |
| POST | `/api/relationships/invite` | Required | Athlete invites trainer |
| GET | `/api/relationships/requests` | Required | List caller's relationships |
| POST | `/api/relationships/{id}/accept` | Required | Accept pending relationship |
| POST | `/api/relationships/{id}/reject` | Required | Reject pending relationship |
| DELETE | `/api/relationships/{id}` | Required | End an accepted relationship and deactivate linked trainer programs |

Request targets can be supplied by id or email. Pending relationships do not grant data access. Ended/rejected relationships can be requested again; pending/accepted duplicates return conflict.

## Messages (`/api/messages`)

Direct messages are available only between users with an accepted trainer-athlete relationship. The API resolves accepted relationships through matching trainer/athlete profile emails and returns user IDs for messaging.

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/messages` | Required | List conversations for the caller |
| GET | `/api/messages/contacts` | Required | List accepted relationship contacts the caller can message |
| GET | `/api/messages/unread-count` | Required | Return unread direct message count |
| GET | `/api/messages/{userId}/references` | Required | List active programs and program exercises that can be attached to a message with this user |
| GET | `/api/messages/{userId}` | Required | Return a message thread with another user |
| POST | `/api/messages` | Required | Send a direct message and notify the recipient |
| PATCH | `/api/messages/{userId}/read` | Required | Mark messages from one user as read |

### Send Message Request

```json
{
  "recipientId": "guid",
  "body": "Merhaba",
  "referenceType": "Program-or-ProgramExercise-or-null",
  "referenceId": "guid-or-null"
}
```

`body` may be empty only when a valid reference is attached. Reference access is validated against the accepted trainer-athlete relationship and active programs.

Direct message responses include nullable reference fields:

```json
{
  "referenceType": "Program",
  "referenceId": "guid",
  "referenceProgramId": "guid",
  "referenceExerciseId": null,
  "referenceLabel": "Strength Block",
  "referenceDetail": "Trainer Name"
}
```

Sending a message creates a `NewMessage` notification for the recipient and delivers `notification.created` through SignalR. The API also emits `message.created` with the direct message DTO so an open Messages screen can update the thread without a browser refresh.

## Exercises (`/api/exercises`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/exercises` | Required | List active global and caller-owned exercises |
| GET | `/api/exercises/{id}` | Required | Get one exercise |
| POST | `/api/exercises` | Required | Create exercise |
| PUT | `/api/exercises/{id}` | Required | Update exercise |
| DELETE | `/api/exercises/{id}` | Required | Soft-delete exercise |

Query parameters for `GET /api/exercises`: `search`, `category`, `difficulty`, `page`, `pageSize`.

## Programs (`/api/programs`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/programs` | Required | List active and inactive programs, role-scoped and paginated |
| POST | `/api/programs` | Required | Create program |
| GET | `/api/programs/{id}` | Required | Get program detail with days and exercises |
| DELETE | `/api/programs/{id}` | Required | Delete program |
| POST | `/api/programs/{id}/days` | Required | Add program day |
| PUT | `/api/programs/{id}/days/{dayId}` | Required | Update day title/notes |
| DELETE | `/api/programs/{id}/days/{dayId}` | Required | Delete day |
| PATCH | `/api/programs/{id}/days/{dayId}/reschedule` | Required | Set day rescheduled date |
| POST | `/api/programs/{id}/days/{dayId}/exercises` | Required | Add exercise to day (optional `setWeights` array for per-set planned weights) |
| PUT | `/api/programs/{id}/days/{dayId}/exercises/{exerciseId}` | Required | Update day exercise (optional `setWeights` array) |
| DELETE | `/api/programs/{id}/days/{dayId}/exercises/{exerciseId}` | Required | Remove exercise from day |
| POST | `/api/programs/{id}/apply-pattern` | Required | Copy/update pattern-week days to all subsequent weeks in the program duration without deleting linked workout sessions |
| POST | `/api/programs/{id}/apply-pattern/{weeks}` | Required | Set repeat weeks to 1/2/3/4 and apply the pattern |

### Create Program Request

```json
{
  "trainerId": null,
  "athleteId": "guid",
  "title": "Strength Program",
  "description": "Optional notes",
  "startsOn": "2026-06-01",
  "endsOn": "2026-08-24",
  "templateId": null,
  "repeatPatternWeeks": 1
}
```

`repeatPatternWeeks` — `null` (no repeat), `1`, `2`, `3`, or `4`. Programs are normally created with `null`; `POST /apply-pattern/{weeks}` lets the builder set and apply the repeat later.

## Templates (`/api/templates`)

Template routes are active and trainer-scoped. Templates are copied into programs/days as snapshots; later template edits do not mutate existing programs.

| Method | Path | Auth | Notes |
|--------|------|------|-------|
| GET | `/api/templates` | Required | List current trainer templates |
| GET | `/api/templates/{id}` | Required | Template detail with days/exercises |
| POST | `/api/templates` | Required | Create `DayTemplate`, `ProgramTemplate`, or `PatternTemplate` |
| PUT | `/api/templates/{id}` | Required | Update title/description |
| DELETE | `/api/templates/{id}` | Required | Delete template |
| POST | `/api/templates/{id}/days` | Required | Add template day |
| POST | `/api/templates/{id}/days/{dayId}/exercises` | Required | Add template exercise, including warm-up count and plan fields |
| POST | `/api/templates/{id}/apply-to-day` | Required | Copy a day template into a program day |
| POST | `/api/templates/{id}/apply-to-program` | Required | Copy a program or pattern template into a program |

### Add/Update Exercise Request (Phase 3)

```json
{
  "exerciseId": "guid",
  "sets": 4,
  "reps": "8-10",
  "targetWeightKg": 80.0,
  "setWeights": [
    { "setNumber": 1, "plannedWeightKg": 75.0 },
    { "setNumber": 2, "plannedWeightKg": 80.0 },
    { "setNumber": 3, "plannedWeightKg": 80.0 },
    { "setNumber": 4, "plannedWeightKg": 82.5 }
  ]
}
```

`setWeights` is optional. When provided, per-set planned weights override the uniform `targetWeightKg` in workout mode. Existing set weights are replaced on each PUT. Program and session exercise responses include `exerciseEquipment` so clients can apply dumbbell/barbell increment rules.

Access rules:

- Trainers can create programs for accepted athletes.
- Athletes can create self-guided programs for themselves.
- Dual-role Athlete-JWT callers can operate through their trainer entity by email resolution.
- Admin can access all programs.
- Inactive programs are returned with `isActive: false`, remain readable in detail, and reject day/exercise write operations.
- Starting a workout session from an inactive program is forbidden.

## Sessions (`/api/sessions`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/sessions` | Required | List sessions, role-scoped and filterable |
| POST | `/api/sessions` | Required | Create completed manual session |
| POST | `/api/sessions/start` | Required | Start in-progress session from WorkoutMode |
| GET | `/api/sessions/{id}` | Required | Get session detail with exercises and sets |
| POST | `/api/sessions/{id}/complete` | Required | Complete in-progress session |
| GET | `/api/sessions/{sessionId}/exercises` | Required | List session exercises |
| POST | `/api/sessions/{sessionId}/exercises` | Required | Add exercise to session |
| PATCH | `/api/sessions/{sessionId}/exercises/{exerciseId}/feeling` | Required | Update completion/feeling for exercise |
| POST | `/api/sessions/{sessionId}/exercises/{exerciseId}/sets` | Required | Add set log |
| PUT | `/api/sessions/{sessionId}/exercises/{exerciseId}/sets/{setId}` | Required | Update set log |
| DELETE | `/api/sessions/{sessionId}/exercises/{exerciseId}` | Required | Remove exercise from session |
| PATCH | `/api/sessions/{sessionId}/exercises/{exerciseId}/review` | Required | Trainer writes review note |

### Start Session Request

```json
{ "athleteId": "guid", "programId": "guid", "programDayId": "guid", "title": "Day 1" }
```

`programId` and `programDayId` are optional for manual flows, but WorkoutMode uses both when launched from a program day.

When an Athlete completes an in-progress session linked to a trainer-owned program, the trainer receives a `WorkoutCompleted` notification.

## Analytics

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/dashboard` | Required | Dashboard stats for caller |
| GET | `/api/analytics/athletes/{athleteId}/overview` | Required | Athlete overview metrics |
| GET | `/api/analytics/athletes/{athleteId}/rpe-trend` | Required | Daily average RPE |
| GET | `/api/analytics/athletes/{athleteId}/volume` | Required | Daily volume trend |
| GET | `/api/analytics/athletes/{athleteId}/exercise/{exerciseId}/progress` | Required | Exercise progress history |
| GET | `/api/analytics/athletes/{athleteId}/consistency` | Required | Session consistency and streaks |
| GET | `/api/analytics/athletes/{athleteId}/sessions-by-month` | Required | Monthly session counts |
| GET | `/api/analytics/athletes/{athleteId}/body-trend` | Required | Body metric trend |
| GET | `/api/analytics/athletes/{athleteId}/exercises/{exerciseId}/last-performance` | Required | Last actual performance for planned exercise |
| GET | `/api/analytics/trainers/me/overview` | Required | Trainer overview metrics |
| GET | `/api/programs/{programId}/compliance` | Required | Program completion/compliance |

## Body Metrics (`/api/body-metrics`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/body-metrics` | Required | Log measurement |
| GET | `/api/body-metrics/me` | Required | Resolve caller's athlete body metric context |
| GET | `/api/body-metrics/{athleteId}` | Required | List athlete measurements |
| DELETE | `/api/body-metrics/{id}` | Required | Delete measurement |

At least one measurement field is required when creating a body metric.

## Notifications (`/api/notifications`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/notifications` | Required | List caller notifications |
| POST | `/api/notifications/{id}/read` | Required | Mark one notification as read |
| POST | `/api/notifications/read-all` | Required | Mark all notifications as read |

Notification types currently used by the app: `RelationshipRequest`, `RelationshipAccepted`, `RelationshipRejected`, `RelationshipEnded`, `ProgramAssigned`, `WorkoutCompleted`, `NewMessage`.

`GET /api/notifications` is the source of truth. Notification DTOs include nullable `senderName` and `senderRole` metadata for display/search. The Web topbar applies the user's `readNotificationRetentionDays` setting locally, hiding only read notifications older than that value. Unread notifications are never hidden by age, and the dedicated Notifications page shows the full loaded notification list.

Realtime Web delivery uses SignalR:

| Hub | Auth | Client event | Description |
|-----|------|--------------|-------------|
| `/hubs/notifications` | Required | `notification.created` | Delivers newly-created notifications to the recipient user |
| `/hubs/notifications` | Required | `message.created` | Delivers the newly-created direct message DTO to the recipient user |

The Web client authenticates the hub connection with the same JWT access token used by REST requests. REST notification endpoints remain the source of truth for initial load and reconnect recovery. Relationship, program, and workout notification events also trigger a Web data refresh so open screens update relationship/program/session state without a manual browser refresh. Direct message screens use `message.created` for live thread/conversation updates and `/api/messages` remains the recovery source.

## Admin (`/api/admin`)

All admin routes require authentication and admin authorization.

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/admin/stats` | Admin | System stats |
| GET | `/api/admin/users` | Admin | List users |
| PATCH | `/api/admin/users/{id}` | Admin | Update user full name, role, or active state |
| DELETE | `/api/admin/users/{id}` | Admin | Deactivate user |
| GET | `/api/admin/exercises` | Admin | List exercises including inactive |
| POST | `/api/admin/exercises/{id}/restore` | Admin | Restore soft-deleted exercise |
| DELETE | `/api/admin/reset-data` | Admin | Delete all application data |
| POST | `/api/admin/seed-exercises` | Admin | Rerun exercise seeding |

## Authorization Matrix

| Area | Admin | Trainer | Athlete |
|------|-------|---------|---------|
| Auth/Profile | Own account | Own account | Own account |
| Trainers | All | Own/relevant trainer data | Search/invite trainers |
| Athletes | All | Accepted athletes | Own athlete profile |
| Relationships | All | Own relationships | Own relationships |
| Exercises | All | Global + own private | Global + own private |
| Programs | All | Own programs for accepted athletes | Own/self-guided programs |
| Sessions | All | Accepted athletes | Own sessions |
| Analytics | All | Accepted athletes | Own analytics |
| Body metrics | All | Accepted athletes | Own metrics |
| Notifications | All | Own notifications | Own notifications |
| Messages | All | Accepted athletes | Accepted trainers |
| Admin | All | No access | No access |
