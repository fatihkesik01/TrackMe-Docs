# Phase 3 - Web Admin, Templates, Analytics & Production Scale

Phase 3 is complete for the current web-first scope. Mobile is intentionally not part of this
phase; the web app remains the primary responsive client and the native mobile app will be
started later with Expo/React Native.

Status: complete for API + Web.

---

## Phase 3 Scope

- Ship an Admin panel for user, exercise, and system management.
- Add advanced analytics endpoints suitable for charts.
- Add program templates and periodization foundation.
- Add public-ready auth foundation with password reset and email verification readiness.
- Improve production reliability, observability, and backup posture.
- Keep Expo/React Native mobile out of this phase.

---

## API Tasks

### Admin Panel API
- [x] `GET /api/admin/users` - paginated user list with role/search/status filters
- [x] `PATCH /api/admin/users/{id}` - update full name, active state, role
- [x] `DELETE /api/admin/users/{id}` - soft deactivate user and revoke refresh tokens
- [x] `GET /api/admin/stats` - system-wide stats
- [x] `GET /api/admin/exercises` - all exercises including inactive
- [x] `POST /api/admin/exercises/{id}/restore` - restore soft-deleted exercise
- [x] Require Admin role on all `/api/admin/*` routes

### Program Templates
- [x] Add `ProgramTemplate` entity
- [x] Add `ProgramTemplateDay` and `ProgramTemplateExercise` entities
- [x] EF migration for template tables
- [x] `GET /api/templates` - list public templates + own templates
- [x] `GET /api/templates/{id}` - template detail with days and planned exercises
- [x] `POST /api/templates` - create template from scratch
- [x] `POST /api/templates/{id}/days` - add day to template
- [x] `POST /api/templates/{id}/days/{dayId}/exercises` - add exercise to template day
- [x] `POST /api/programs` extended with `templateId` clone support
- [x] `POST /api/templates/{id}/publish` - make template public

### Advanced Analytics
- [x] `GET /api/analytics/athletes/{athleteId}/rpe-trend`
- [x] `GET /api/analytics/athletes/{athleteId}/volume`
- [x] `GET /api/analytics/athletes/{athleteId}/exercise/{exerciseId}/progress`
- [x] `GET /api/analytics/athletes/{athleteId}/consistency`
- [x] `GET /api/analytics/trainers/me/overview`

### Public-Ready Auth
- [x] Add `email_verified_at` field to users
- [x] Email verification readiness via `Auth:RequireVerifiedEmail` config flag
- [x] `POST /api/auth/forgot-password` - create reset token
- [x] `POST /api/auth/reset-password` - consume reset token and set new password
- [x] Revoke active refresh tokens after password reset/change

### Performance & Reliability
- [x] Add short response cache header for `GET /api/exercises`
- [x] Add analytics index on workout sessions: `athlete_id + completed_at`
- [x] Extend health check with db latency and memory usage
- [x] Add structured request duration logging
- [x] Keep API auto-migration on startup for VPS Docker deploy

---

## Web Tasks

### Admin Panel
- [x] Add Admin-only navigation item
- [x] Admin dashboard stats: total users, active users, sessions last 30d, inactive exercises
- [x] User list with role filter and search
- [x] User active toggle and deactivation action
- [x] User role selector and save action
- [x] Exercise audit list with active/inactive filter
- [x] Restore inactive exercises from admin panel

### Templates UI
- [x] Add Templates navigation item
- [x] Program template list
- [x] Template creation modal
- [x] Template detail modal
- [x] Add day to template
- [x] Add exercise to template day
- [x] Admin publish template control
- [x] Clone template into athlete program from program creation flow

### Analytics UI
- [x] Existing dashboard analytics remains available for athletes
- [x] API now exposes chart-ready endpoints for the next visual pass
- [x] Trainer overview API is ready for dashboard cards

---

## Database Tasks

- [x] Add `email_verified_at` column to users
- [x] Add `password_reset_tokens` table
- [x] Add `program_templates`, `program_template_days`, `program_template_exercises` tables
- [x] Add analytics index on `workout_sessions(athlete_id, completed_at)`
- [x] EF migrations generated for Phase 3 schema
- [x] Auto-migrate remains enabled on API startup

---

## Architecture Tasks

- [x] Add admin endpoint group
- [x] Add template endpoint group
- [x] Keep authorization rules role-based and endpoint-local
- [x] Keep notification and auth side effects isolated in endpoint helpers/services
- [x] Add web smoke checklist through build verification

---

## Infrastructure Tasks

- [x] Docker deploy remains compatible with API auto-migration
- [x] Health endpoint now exposes DB latency and memory
- [x] Request duration logging available in container logs
- [x] Domain/HTTPS remains deferred until domain is available
- [x] Native mobile remains deferred until Expo phase starts

---

## Acceptance Criteria

Phase 3 web-first is complete when:

- [x] Admin can view users, filter/search them, toggle active state, and change role.
- [x] Admin can see system stats and audit inactive exercises.
- [x] Admin can restore inactive exercises.
- [x] Advanced analytics endpoints return chart-ready data.
- [x] Program templates can be created, published, and cloned into programs.
- [x] Password reset and email verification readiness are available.
- [x] Health and logging posture is improved.
- [x] `npm run build` passes for web.
- [x] `dotnet build` passes for API.

---

## Out Of Scope For This Phase 3 Run

- Expo/React Native mobile app.
- Push notifications (FCM/APNs).
- AI-generated workout plans.
- Wearable integration.
- Marketplace or monetization.
- Live video coaching.
- Competition or event management.
