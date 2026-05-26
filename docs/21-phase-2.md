# Phase 2 — Program Builder, Mobile Skeleton & Production Hardening

Phase 2 picks up where Phase 1 left off.

Goal: complete the core coaching workflow with a full program builder, close the remaining
Phase 1 web gaps, ship the first mobile skeleton, and harden the backend for production scale.

---

## Phase 2 Scope

- Complete program day and planned exercise structure.
- Ship web UI for session exercise logging and analytics panels.
- Add pagination and rate limiting.
- Add in-app notification foundation.
- Ship React Native mobile skeleton (auth + session log).
- Add user profile and password management.
- Clean up architecture and deferred risks from Phase 1.

---

## API Tasks

### Program Structure
- [x] Add `WorkoutProgramDay` entity — (program_id, day_number, title, notes)
- [x] Add `WorkoutProgramExercise` entity — (day_id, exercise_id, order_index, sets, reps, target_rpe, rest_seconds, notes)
- [x] EF Core migration for program structure tables
- [x] `GET /api/programs/{id}` — program detail with days and planned exercises
- [x] `POST /api/programs/{id}/days` — add day to program
- [x] `PUT /api/programs/{id}/days/{dayId}` — update day
- [x] `DELETE /api/programs/{id}/days/{dayId}` — remove day
- [x] `POST /api/programs/{id}/days/{dayId}/exercises` — add planned exercise to day
- [x] `PUT /api/programs/{id}/days/{dayId}/exercises/{exerciseId}` — update planned exercise
- [x] `DELETE /api/programs/{id}/days/{dayId}/exercises/{exerciseId}` — remove planned exercise
- [x] `GET /api/sessions/{id}` — session detail with exercises and set logs
- [x] `PUT /api/sessions/{sessionId}/exercises/{exerciseId}/sets/{setId}` — update a set log
- [x] `DELETE /api/sessions/{sessionId}/exercises/{exerciseId}` — remove exercise from session

### Pagination
- [x] Add cursor-based or offset pagination to `GET /api/athletes`
- [x] Add pagination to `GET /api/trainers`
- [x] Add pagination to `GET /api/exercises`
- [x] Add pagination to `GET /api/programs`
- [x] Add pagination to `GET /api/sessions`
- [x] Add pagination to `GET /api/relationships/requests`
- [x] Standardize page response envelope: `{ data, page, pageSize, total }`

### Rate Limiting
- [x] Add rate limiting middleware
- [x] Stricter limit on `POST /api/auth/login` (10 req/min per IP)
- [x] General API limit (120 req/min per IP)

### User Profile Management
- [x] `PATCH /api/auth/profile` — update full name, goal (athlete), bio
- [x] `POST /api/auth/change-password` — current password + new password
- [x] Validate current password before allowing change

### Notification Foundation
- [x] Add `Notification` entity — (user_id, type, title, body, is_read, created_at, read_at)
- [x] EF migration for notifications table
- [x] `GET /api/notifications` — paginated list for current user
- [x] `POST /api/notifications/{id}/read` — mark as read
- [x] `POST /api/notifications/read-all` — mark all as read
- [x] Trigger notification on: relationship request received, relationship accepted
- [x] Trigger notification on: program assigned to athlete

### Maintenance
- [x] Add background job to prune expired/revoked refresh tokens (runs every 24 h)
- [ ] Add `GET /api/health` detail endpoint (db ping, version, uptime)

---

## Web Tasks

### Analytics Panel
- [ ] Add athlete analytics section to dashboard
- [ ] Show weekly sessions, monthly sessions, avg RPE, total duration
- [ ] Show latest session card (title, date, RPE, duration)
- [ ] Show empty analytics state when no sessions exist
- [ ] Call `api.athleteAnalytics(athleteId)` for current athlete or selected athlete

### Session Exercise Logging UI
- [ ] Add session detail panel (expandable or new view)
- [ ] Show exercise list for a session
- [ ] Add exercise selector (search from exercise library)
- [ ] Add set rows per exercise (set number, reps, weight, RPE, completed toggle)
- [ ] Save set log inline
- [ ] Show logged sets in session history

### Program Builder UI
- [ ] Add program detail view (day list + planned exercises)
- [ ] Add day creation inside a program
- [ ] Add exercise selector per day
- [ ] Show planned sets, reps, target RPE, rest fields
- [ ] Athlete view: read-only program overview

### Notifications UI
- [ ] Add notification bell icon in topbar
- [ ] Show unread count badge
- [ ] Dropdown or panel for recent notifications
- [ ] Mark as read on click

### General Improvements
- [ ] Add pagination controls to athlete and session lists
- [ ] Add search/filter to exercise library
- [ ] Improve error messages (show field-level errors from API)

---

## Mobile Tasks (React Native Skeleton)

- [ ] Initialize React Native project in `TrackMe-Mobile`
- [ ] Set up navigation (React Navigation: stack + tabs)
- [ ] Add auth screens: login, register
- [ ] Add JWT storage (secure store, not AsyncStorage)
- [ ] Add home screen with session log form
- [ ] Add session list screen
- [ ] Add exercise picker screen
- [ ] Connect to `TrackMe-Api` endpoints
- [ ] Basic iOS and Android build verification

---

## Database Tasks

- [ ] Verify program structure migration in DBeaver after deploy
- [ ] Verify notifications table in DBeaver
- [ ] Verify refresh token pruning works
- [ ] Confirm pagination queries perform well on test data

---

## Architecture Tasks

- [x] Extract endpoint groups from `Program.cs` into separate files
  - `Endpoints/AuthEndpoints.cs`
  - `Endpoints/TrainerEndpoints.cs`
  - `Endpoints/AthleteEndpoints.cs`
  - `Endpoints/RelationshipEndpoints.cs`
  - `Endpoints/ExerciseEndpoints.cs`
  - `Endpoints/ProgramEndpoints.cs`
  - `Endpoints/SessionEndpoints.cs`
  - `Endpoints/AnalyticsEndpoints.cs`
  - `Endpoints/NotificationEndpoints.cs`
  - `Endpoints/EndpointHelpers.cs` (shared validation + notification helpers)
- [x] Move entity classes to `Models/` (individual files per entity)
- [x] Move services (`JwtTokenService`, `PasswordHasher`, etc.) to `Services/`
- [x] Move `TrackMeDbContext` + `OnModelCreating` config to `Data/`

---

## Acceptance Criteria

Phase 2 is complete when:

- A trainer can build a structured program with days and planned exercises.
- A trainer can log a session with per-exercise set data.
- All list endpoints support pagination.
- Login endpoint is rate limited.
- Notifications appear for relationship events and program assignments.
- React Native app can log in and submit a basic session.
- Web shows analytics and session exercise detail.
- `Program.cs` is split into logical files.

---

## Out Of Scope For Phase 2

- Push notifications (FCM) — Phase 3
- AI workout suggestions — Phase 3
- Payment or subscription — Phase 3
- Program templates marketplace — Phase 3
- Wearable integration — Phase 3
- Full admin panel — Phase 3
- OAuth / social login — Phase 3
