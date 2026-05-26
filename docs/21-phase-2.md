# Phase 2 - Program Builder, Web Workflow & Production Hardening

Phase 2 closes the current web-first coaching workflow. Mobile is intentionally deferred to
Phase 3 because the product is currently being validated from the web app first.

Status: complete for API + Web.

---

## Phase 2 Scope

- Complete program day and planned exercise structure.
- Ship web UI for session exercise logging and analytics panels.
- Add pagination and rate limiting.
- Add in-app notification foundation.
- Add user profile and password management.
- Clean up architecture and deferred risks from Phase 1.
- Defer React Native mobile skeleton to Phase 3.

---

## API Tasks

### Program Structure
- [x] Add `WorkoutProgramDay` entity - program_id, day_number, title, notes
- [x] Add `WorkoutProgramExercise` entity - day_id, exercise_id, order_index, sets, reps, target_rpe, rest_seconds, notes
- [x] EF Core migration for program structure tables
- [x] `GET /api/programs/{id}` - program detail with days and planned exercises
- [x] `POST /api/programs/{id}/days` - add day to program
- [x] `PUT /api/programs/{id}/days/{dayId}` - update day
- [x] `DELETE /api/programs/{id}/days/{dayId}` - remove day
- [x] `POST /api/programs/{id}/days/{dayId}/exercises` - add planned exercise to day
- [x] `PUT /api/programs/{id}/days/{dayId}/exercises/{exerciseId}` - update planned exercise
- [x] `DELETE /api/programs/{id}/days/{dayId}/exercises/{exerciseId}` - remove planned exercise
- [x] `GET /api/sessions/{id}` - session detail with exercises and set logs
- [x] `PUT /api/sessions/{sessionId}/exercises/{exerciseId}/sets/{setId}` - update a set log
- [x] `DELETE /api/sessions/{sessionId}/exercises/{exerciseId}` - remove exercise from session

### Pagination
- [x] Add pagination to `GET /api/athletes`
- [x] Add pagination to `GET /api/trainers`
- [x] Add pagination to `GET /api/exercises`
- [x] Add pagination to `GET /api/programs`
- [x] Add pagination to `GET /api/sessions`
- [x] Add pagination to `GET /api/relationships/requests`
- [x] Standardize page response envelope: `{ data, page, pageSize, total }`

### Rate Limiting
- [x] Add rate limiting middleware
- [x] Stricter limit on `POST /api/auth/login` - 10 req/min per IP
- [x] General API limit - 120 req/min per IP

### User Profile Management
- [x] `PATCH /api/auth/profile` - update full name, goal, bio
- [x] `POST /api/auth/change-password` - current password + new password
- [x] Validate current password before allowing change

### Notification Foundation
- [x] Add `Notification` entity - user_id, type, title, body, is_read, created_at, read_at
- [x] EF migration for notifications table
- [x] `GET /api/notifications` - paginated list for current user
- [x] `POST /api/notifications/{id}/read` - mark as read
- [x] `POST /api/notifications/read-all` - mark all as read
- [x] Trigger notification on relationship request received
- [x] Trigger notification on relationship accepted
- [x] Trigger notification on program assigned to athlete

### Maintenance
- [x] Add background job to prune expired/revoked refresh tokens every 24 hours
- [x] Add `GET /api/health` detail endpoint - db ping, version, uptime

---

## Web Tasks

### Analytics Panel
- [x] Add athlete analytics section to dashboard
- [x] Show weekly sessions, monthly sessions, avg RPE, total duration
- [x] Show latest session card with title, date, RPE, duration
- [x] Show empty analytics state when no sessions exist
- [x] Call `api.athleteAnalytics(athleteId)` for the current athlete

### Session Exercise Logging UI
- [x] Add session detail modal from the session list
- [x] Show exercise list for a session
- [x] Add exercise selector from the exercise library
- [x] Add set rows per exercise - set number, reps, weight, RPE, completed toggle
- [x] Save set log inline
- [x] Show logged sets in session history/detail

### Program Builder UI
- [x] Add program detail modal with day list and planned exercises
- [x] Add day creation inside a program
- [x] Add exercise selector per day
- [x] Show planned sets, reps, target RPE, rest fields
- [x] Athlete view supports own/self-guided program management and read view

### Notifications UI
- [x] Add notification bell icon in topbar
- [x] Show unread count badge
- [x] Dropdown/panel for recent notifications
- [x] Mark as read on click
- [x] Mark all as read action

### General Improvements
- [x] Add pagination controls to athlete and session lists
- [x] Add search/filter to exercise library
- [x] Improve error surfacing in modals and top-level alerts

### Relationship & Access Flow Improvements (delivered in Phase 2 bug-fix pass)
- [x] Athletes can invite a trainer (athlete-initiated relationship request)
- [x] Trainers can also be added as athletes by another trainer (trainer-as-athlete flow)
- [x] `POST /api/relationships/invite` — athlete invites trainer; trainer accepts/rejects
- [x] `GET /api/trainers/search` — autocomplete trainer search for athletes and trainers
- [x] `InitiatedByAthlete` column on relationships table tracks who initiated (migration added)
- [x] `SetStatusAsync` respects `InitiatedByAthlete`: athlete responds to trainer-initiated; trainer responds to athlete-initiated
- [x] RelationshipsView shows invite-trainer panel for athletes and trainers
- [x] AthletesView shows "Add athlete" shortcut button for trainers (navigates to Relationships)
- [x] ProgramsView: athletes always create self-guided programs (trainerId forced null, trainer selector hidden for athletes)

---

## Mobile Tasks

Mobile development has not started in Phase 2 by decision. These tasks are moved to Phase 3.

- [ ] Initialize React Native project in `TrackMe-Mobile`
- [ ] Set up navigation
- [ ] Add auth screens
- [ ] Add secure JWT storage
- [ ] Add session log flow
- [ ] Connect to `TrackMe-Api`

---

## Database Tasks

- [x] Program structure migration exists and is used by API auto-migrate
- [x] Notifications migration exists and is used by API auto-migrate
- [x] Refresh token pruning service is registered
- [x] Pagination queries are implemented with bounded page size
- [x] `Phase2_RelationshipInitiator` migration: `initiated_by_athlete` column on `trainer_athlete_relationships`

---

## Architecture Tasks

- [x] Extract endpoint groups from `Program.cs` into separate files
- [x] Move entity classes to `Models/`
- [x] Move services to `Services/`
- [x] Move `TrackMeDbContext` and model config to `Data/`

---

## Acceptance Criteria

Phase 2 is complete when:

- A trainer can build a structured program with days and planned exercises.
- An athlete can create and manage a self-guided program.
- A trainer can log a session with per-exercise set data.
- Athletes can view their own program/session data from the web app.
- All list endpoints support pagination.
- Login endpoint is rate limited.
- Notifications appear for relationship events and program assignments.
- Web shows analytics and session exercise detail.
- `Program.cs` is split into logical files.
- `npm run build` passes for web.
- `dotnet build` passes for API.

---

## Out Of Scope For Phase 2

- React Native mobile app - Phase 3
- Push notifications (FCM) - Phase 3
- AI workout suggestions - Phase 3
- Payment or subscription - Phase 3
- Program templates marketplace - Phase 3
- Wearable integration - Phase 3
- Full admin panel - Phase 3
- OAuth / social login - Phase 3
