# Phase 3 - Web Admin, Analytics & Production Scale

Phase 3 is being executed as web-first. The mobile app is intentionally deferred; the current
web app already behaves well on mobile-sized screens, and native mobile will be started later
with Expo/React Native.

Status: in progress.

---

## Phase 3 Scope

- Ship an Admin panel for user, exercise, and system management.
- Add advanced analytics endpoints suitable for charts.
- Add program templates and periodization foundation.
- Add public-ready auth features such as password reset and email verification.
- Improve production reliability, observability, and backup posture.
- Keep Expo/React Native mobile out of this phase until explicitly started.

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
- [ ] Add `ProgramTemplate` entity - trainer_id, title, description, is_public, created_at
- [ ] Add `ProgramTemplateDay` and `ProgramTemplateExercise` entities
- [ ] EF migration for template tables
- [ ] `GET /api/templates` - list public templates + own templates
- [ ] `POST /api/templates` - create template from scratch
- [ ] `POST /api/programs` extended - `templateId` field to clone from template
- [ ] `POST /api/templates/{id}/publish` - make template public

### Advanced Analytics
- [ ] `GET /api/analytics/athletes/{athleteId}/rpe-trend` - RPE per session over date range
- [ ] `GET /api/analytics/athletes/{athleteId}/volume` - total volume over date range
- [ ] `GET /api/analytics/athletes/{athleteId}/exercise/{exerciseId}/progress` - exercise trend
- [ ] `GET /api/analytics/athletes/{athleteId}/consistency` - frequency and streak
- [ ] `GET /api/analytics/trainers/me/overview` - trainer dashboard overview

### Public-Ready Auth
- [ ] Email verification on register
- [ ] `POST /api/auth/forgot-password` - send reset token/link
- [ ] `POST /api/auth/reset-password` - consume token, set new password
- [ ] Add `email_verified_at` field to users table
- [ ] Block unverified users from non-auth endpoints when production flag is enabled

### Performance & Reliability
- [ ] Add response caching for `GET /api/exercises`
- [ ] Add connection pooling tuning for PostgreSQL
- [ ] Extend health check with db latency and memory usage
- [ ] Add structured request logging
- [ ] Add slow endpoint tracing/logging

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

### Analytics UI
- [ ] Add chart-ready athlete analytics panels
- [ ] Add trainer overview dashboard
- [ ] Add RPE trend card
- [ ] Add volume trend card
- [ ] Add consistency/streak card

### Templates UI
- [ ] Program template list
- [ ] Template builder using existing program day/exercise UI patterns
- [ ] Clone template into athlete program
- [ ] Publish/unpublish template controls

---

## Database Tasks

- [ ] Add indexes for analytics queries: athlete_id + completed_at on workout_sessions
- [ ] Add template tables
- [ ] Add email verification/reset token fields or table
- [ ] Review and optimize slow query candidates
- [ ] Set up automated DB backup

---

## Architecture Tasks

- [ ] Add `INotificationService` abstraction for in-app events
- [ ] Add `IEmailService` abstraction
- [ ] Add domain event style helpers for cross-module side effects
- [ ] Set up API integration tests for admin routes
- [ ] Set up web smoke test checklist for admin workflows

---

## Infrastructure Tasks

- [ ] Attach domain when available
- [ ] Add HTTPS when domain is ready
- [ ] Set up staging Docker stack
- [ ] Add automated DB backup to VPS cron
- [ ] Add uptime monitoring

---

## Deferred Mobile Scope

Mobile is not part of this Phase 3 run.

- [ ] Initialize Expo/React Native project in `TrackMe-Mobile`
- [ ] Login/register screens
- [ ] Secure token storage
- [ ] Native session log flow
- [ ] Native program detail and analytics screens
- [ ] iOS/Android build verification

---

## Acceptance Criteria

Phase 3 web-first is complete when:

- Admin can view users, filter/search them, toggle active state, and change role.
- Admin can see system stats and audit inactive exercises.
- Admin can restore inactive exercises.
- Advanced analytics endpoints return chart-ready data.
- Program templates can be created, published, and cloned into programs.
- Password reset and email verification are available for production readiness.
- Health, logging, and backup posture are documented and testable.
- `npm run build` passes for web.
- `dotnet build` passes for API.

---

## Out Of Scope For This Phase 3 Run

- Expo/React Native mobile app.
- Push notifications (FCM/APNs).
- AI-generated workout plans.
- Wearable integration.
- Marketplace or monetization.
- Live video coaching.
- Competition or event management.
