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

Direct messages are available between users with an accepted trainer-athlete relationship **or** an accepted social connection.

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/messages` | Required | List conversations for the caller |
| GET | `/api/messages/contacts` | Required | List accepted relationship contacts the caller can message |
| GET | `/api/messages/unread-count` | Required | Return unread direct message count |
| GET | `/api/messages/{userId}/references` | Required | List attachable references; coaching relationships return programs + exercises + published programs; social-only connections return only the caller's published programs |
| GET | `/api/messages/{userId}` | Required | Return a message thread with another user |
| POST | `/api/messages` | Required | Send a direct message and notify the recipient |
| PATCH | `/api/messages/{userId}/read` | Required | Mark messages from one user as read |

### Send Message Request

```json
{
  "recipientId": "guid",
  "body": "Merhaba",
  "referenceType": "Program-or-ProgramExercise-or-PublishedProgram-or-null",
  "referenceId": "guid-or-null"
}
```

`body` may be empty only when a valid reference is attached. `Program` and `ProgramExercise` references require an accepted coaching relationship. `PublishedProgram` references only require that the sender is the publisher of the referenced program.

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
| PATCH | `/api/programs/{id}/days/{dayId}/exercises/reorder` | Required | Reorder exercises within a program day; body: `{ exerciseIds: string[] }` |
| POST | `/api/programs/{id}/apply-pattern` | Required | Copy/update pattern-week days using program start as source; preserves linked workout sessions |
| POST | `/api/programs/{id}/apply-pattern/{weeks}` | Required | Set repeat weeks to 1/2/3/4 and apply the pattern |
| POST | `/api/programs/{id}/apply-pattern/{weeks}/{months}` | Required | Set repeat weeks, cap fill range to 1–3 months; accepts `?fromDate=YYYY-MM-DD` to use a specific calendar date as pattern source instead of program start |

### Create Program Request

```json
{
  "trainerId": null,
  "athleteId": "guid",
  "title": "Strength Program",
  "description": "Optional notes",
  "startsOn": "2026-06-01",
  "endsOn": null,
  "templateId": null,
  "repeatPatternWeeks": 1
}
```

`endsOn` — nullable. Omit or send `null` for an indefinite (süresiz) program with no fixed end date.

`repeatPatternWeeks` — `null` (no repeat), `1`, `2`, `3`, or `4`. Programs are normally created with `null`; `POST /apply-pattern/{weeks}/{months}` lets the builder set and apply the repeat later. The `fromDate` query param makes the chosen calendar date the first day of the source cycle; without it the pattern starts from `startsOn`.

## Templates (`/api/templates`)

Template routes are active and trainer-scoped. Access is resolved from the real trainer profile, not only the current JWT role, so dual-role users in trainer UI mode can manage their trainer-owned templates. Templates are copied into programs/days as snapshots; later template edits do not mutate existing programs.

| Method | Path | Auth | Notes |
|--------|------|------|-------|
| GET | `/api/templates` | Required | List current trainer templates |
| GET | `/api/templates/{id}` | Required | Template detail with days/exercises |
| POST | `/api/templates` | Required | Create `DayTemplate` or `ProgramTemplate` from the Web UI; `PatternTemplate` is backend-compatible but not exposed in the current template page |
| PUT | `/api/templates/{id}` | Required | Update title/description |
| DELETE | `/api/templates/{id}` | Required | Delete template |
| POST | `/api/templates/{id}/days` | Required | Add template day |
| DELETE | `/api/templates/{id}/days/{dayId}` | Required | Remove template day |
| POST | `/api/templates/{id}/days/{dayId}/exercises` | Required | Add template exercise; optional `setWeights` array for per-set data |
| PUT | `/api/templates/{id}/days/{dayId}/exercises/{exerciseId}` | Required | Update template exercise; optional `setWeights` replaces existing per-set data |
| DELETE | `/api/templates/{id}/days/{dayId}/exercises/{exerciseId}` | Required | Remove template exercise |
| PATCH | `/api/templates/{id}/days/reorder` | Required | Reorder template days; body: `{ dayIds: string[] }` (full ordered list) |
| PATCH | `/api/templates/{id}/days/{dayId}/exercises/reorder` | Required | Reorder exercises within a template day; body: `{ exerciseIds: string[] }` |
| POST | `/api/templates/{id}/apply-to-day` | Required | Copy a day template into a program day (preserves per-set data) |
| POST | `/api/templates/{id}/apply-to-program` | Required | Copy a program template into a program (preserves per-set data); optional `fromDate` in body offsets day numbers so template day 1 lands on the chosen calendar date |

### Template/Pattern Error Messages

API error messages from template and pattern operations are returned as `{ "message": "..." }` in the response body. These messages are translated in the frontend by an `apiErr()` helper function present in both `TemplatesView` and `ProgramBuilderView`. Known translated messages:

| API message | i18n key |
|---|---|
| `no days in the pattern period to copy.` | `errNoDaysInPattern` |
| `repeat pattern must be 1, 2, 3, or 4 weeks.` | `errRepeatPatternInvalid` |
| `program has no repeat pattern set.` | `errNoRepeatPattern` |
| `template was not found.` | `errTemplateNotFound` |
| `program was not found.` | `errProgramNotFound` |

### Add/Update Exercise Request (Program Day)

```json
{
  "exerciseId": "guid",
  "sets": 4,
  "reps": "8-10",
  "targetWeightKg": 80.0,
  "setWeights": [
    { "setNumber": 1, "plannedWeightKg": 75.0, "plannedReps": "8", "plannedRpe": 7, "plannedRestSeconds": 120, "notes": null },
    { "setNumber": 2, "plannedWeightKg": 80.0, "plannedReps": "8", "plannedRpe": 8, "plannedRestSeconds": 120, "notes": null }
  ]
}
```

`setWeights` is optional. When provided, per-set planned weight/reps/RPE/rest/notes override the uniform exercise-level defaults in workout mode. Existing set weights are replaced on each PUT. Program and session exercise responses include `exerciseEquipment` so clients can apply dumbbell/barbell increment rules.

### Add/Update Template Exercise Request (Phase 5)

Same shape as program day exercises. `setWeights` is also supported for template exercises and is preserved when the template is applied to a program day or program via `apply-to-day` / `apply-to-program`.

The `reps` field is validated against the pattern `^\d+$|^\d+-\d+$|^\d+\+$|^AMRAP$` (case-insensitive, max 20 chars). Invalid values return 400. Null/empty reps are accepted (no reps planned).

Access rules:

- Trainers can create programs for accepted athletes.
- Athletes can create self-guided programs for themselves.
- Dual-role Athlete-JWT callers can operate through their trainer entity by email resolution.
- Admin can access all programs.
- Inactive programs are returned with `isActive: false`, remain readable in detail, and reject day/exercise write operations.
- Starting a workout session from an inactive program is forbidden.

## Program Sharing (`/api/published-programs`)

Published programs are snapshots of workout programs shared publicly or with connections. Snapshots contain plan structure only — no personal data (weights, logs, performance history).

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/published-programs` | Required | Publish a program; builds snapshot from current program state |
| GET | `/api/published-programs` | Required | Browse published programs (visibility-filtered); supports `?q=&sort=newest&role=trainer&duration=unlimited&page=1&pageSize=20` |
| GET | `/api/published-programs/{id}` | Required | Get detail with snapshot, like/save/start counts |
| DELETE | `/api/published-programs/{id}` | Required | Unpublish (soft-delete, owner only) |
| POST | `/api/published-programs/{id}/like` | Required | Toggle like; returns `{ liked, likeCount }` |
| GET | `/api/published-programs/{id}/comments` | Required | List comments (paginated); supports `?page=1&pageSize=20` |
| POST | `/api/published-programs/{id}/comments` | Required | Add comment; body: `{ text: string }` (max 1000 chars) |
| DELETE | `/api/published-programs/{id}/comments/{commentId}` | Required | Delete comment (author or program owner) |
| POST | `/api/published-programs/{id}/save` | Required | Copy program to caller's own programs (athlete required); increments `saveCount`; returns `{ id, skippedExercises? }` |
| GET | `/api/published-programs/{id}/stats` | Required | Analytics for program owner: saveCount, startCount, likeCount, commentCount, completionCount, completionRate |
| GET | `/api/users/{userId}/published-programs` | Required | List a user's published programs (visibility-filtered) |
| PATCH | `/api/programs/{id}/start` | Required | Set program start date; body: `{ startDate?: "2026-06-01" }` (defaults to today); calculates `endsOn` from duration; increments source published program's `startCount` |

### Browse Query Params

- `sort`: `newest` (default) | `popular` (likes+comments) | `liked` | `saved`
- `role`: `trainer` | `athlete` — filter by publisher role
- `duration`: `unlimited` | `timed` — filter by duration type

### Publish Request

```json
{
  "programId": "guid",
  "description": "Optional description",
  "visibility": "public",
  "durationType": "weeks",
  "durationValue": 8
}
```

`visibility` values: `public`, `connections`, `coach_only`, `private`.
- `coach_only` — visible only to users whose trainer is the publisher (coaching relationship required).

`durationType` values: `unlimited`, `weeks`, `months`, `years`. `durationValue` is required when `durationType` is not `unlimited`.

### Snapshot Security

Published program snapshots contain **only plan structure**: day number, day title, exercise name, sets, warm-up sets, reps, rest seconds, notes. The following are **never included**: `targetWeightKg`, `WorkoutSetLog` records, `WorkoutSession` performance history.

### Save Response

```json
{
  "id": "guid",
  "skippedExercises": ["ExerciseName1"]
}
```

`skippedExercises` is `null` if all exercises were copied successfully. Non-null means some exercises were not found in the caller's exercise library (global or owned) and were omitted from the copy.

### Reference Type in Messages

`referenceType: "PublishedProgram"` is supported in `POST /api/messages`. The sender must be the publisher of the referenced program. `GET /api/messages/{userId}/references` includes the caller's published programs for all connection types (coaching + social), in addition to program/exercise references which remain coaching-only.

## Sessions (`/api/sessions`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/sessions` | Required | List sessions, role-scoped and filterable |
| POST | `/api/sessions` | Required | Create completed manual session |
| POST | `/api/sessions/start` | Required | Start in-progress session from WorkoutMode |
| GET | `/api/sessions/{id}` | Required | Get session detail with exercises and sets |
| POST | `/api/sessions/{id}/complete` | Required | Complete in-progress session |
| DELETE | `/api/sessions/{id}` | Required | Cancel an InProgress session (sets status to Cancelled) |
| GET | `/api/sessions/{sessionId}/exercises` | Required | List session exercises |
| POST | `/api/sessions/{sessionId}/exercises` | Required | Add exercise to session |
| PATCH | `/api/sessions/{sessionId}/exercises/{exerciseId}/feeling` | Required | Update completion/feeling for exercise |
| PATCH | `/api/sessions/{sessionId}/exercises/{exerciseId}/note` | Required | Update trainer/athlete note on session exercise |
| POST | `/api/sessions/{sessionId}/exercises/{exerciseId}/sets` | Required | Add set log |
| PUT | `/api/sessions/{sessionId}/exercises/{exerciseId}/sets/{setId}` | Required | Update set log |
| DELETE | `/api/sessions/{sessionId}/exercises/{exerciseId}` | Required | Remove exercise from session |
| PATCH | `/api/sessions/{sessionId}/exercises/{exerciseId}/review` | Required | Trainer writes review note |

`SessionStatus` values: `InProgress`, `Completed`, `Cancelled`. Cancelling an already-cancelled session returns 409 Conflict.

When adding a set log (`POST …/sets`), warm-up set ordering is enforced: warm-up sets must have lower `setNumber` than any working set for the same exercise, and vice versa. Violations return 400 with a descriptive message.

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

## Media (`/api/media`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/media/profile/avatar` | Required | Upload avatar photo (multipart/form-data, field name `file`) |
| DELETE | `/api/media/profile/avatar` | Required | Delete current avatar photo |
| POST | `/api/media/profile/cover` | Required | Upload cover photo (multipart/form-data, field name `file`) |
| DELETE | `/api/media/profile/cover` | Required | Delete current cover photo |
| GET | `/api/media/{id}/content` | Public | Proxy/redirect to stored media content |

**Upload constraints:** Max 5 MB. Accepted MIME types: `image/jpeg`, `image/png`, `image/webp`. The request must be `multipart/form-data`; the file field must be named `file`.

**Avatar/cover upload behavior:** Old asset is soft-deleted (status → `Deleted`, `deleted_at` set) and removed from storage before the new asset is persisted. The user's `avatar_media_asset_id` or `cover_media_asset_id` FK is updated atomically with the new record.

**`GET /api/media/{id}/content`:** Public, no auth required. Returns 404 if the asset does not exist, is deleted (`deleted_at IS NOT NULL` or `status = Deleted`), or is restricted to an unsupported purpose (only `AvatarPhoto` and `CoverPhoto` are served). If `R2_PUBLIC_BASE_URL` is configured and the asset has a `public_url`, responds with `302 Redirect` to the CDN URL. Otherwise streams the binary from storage with the original `Content-Type` header.

**`GET /api/auth/me` additions (Sprint 1):** Includes `avatarPhoto` and `coverPhoto` objects (`{ id, url, mimeType }`) derived from the linked `MediaAsset`. The `url` field is the CDN URL if available, otherwise `/api/media/{id}/content` (relative). Frontend resolves relative URLs to absolute using the API base URL before display.

**Storage selection:** Controlled by `MEDIA_STORAGE_PROVIDER` env var. `CloudflareR2` is used when the var is set and R2 credentials (`R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_BUCKET`) are all present; otherwise falls back to `Local` (stored under `App_Data/media`). Binary data is never written to PostgreSQL.

## Export (`/api/export`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/export/body-metrics` | Required | Download caller's body measurement history |
| GET | `/api/export/sessions` | Required | Download caller's session + set log history |

Query parameter `format=csv` (default) returns a `text/csv` file download with `Content-Disposition: attachment`. `format=json` returns a JSON array. Only `Athlete` and dual-role `Trainer` callers with an athlete profile can export. Admin callers receive 400.

Body metrics CSV columns: `date, weight_kg, body_fat_pct, muscle_pct, height_cm, waist_cm, chest_cm, arms_cm, legs_cm, hips_cm, notes`

Sessions CSV columns: `session_date, session_title, program, status, duration_min, session_rpe, exercise, set_number, is_warmup, reps, weight_kg, set_rpe, is_completed, notes` — one row per set log (denormalized).

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
