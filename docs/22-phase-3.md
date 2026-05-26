# Phase 3 — Mobile, Push Notifications & Scale

Phase 3 completes the mobile experience, delivers push notifications, ships the admin panel,
and prepares TrackMe for public-facing production scale.

---

## Phase 3 Scope

- Full React Native mobile app for athletes and trainers.
- Firebase Cloud Messaging push notifications.
- Admin panel for user and system management.
- Program templates and periodization foundation.
- Advanced analytics with chart-ready data.
- Architecture and performance hardening for production scale.
- Public-ready auth features (email verification, password reset).

---

## API Tasks

### Push Notifications (FCM)
- [ ] Add `DeviceToken` entity — (user_id, token, platform, created_at, updated_at)
- [ ] EF migration for device tokens
- [ ] `POST /api/notifications/device-token` — register / update device token
- [ ] `DELETE /api/notifications/device-token` — unregister on logout
- [ ] Integrate Firebase Admin SDK
- [ ] Trigger FCM push on: relationship request, relationship accepted, program assigned, session reminder
- [ ] Handle FCM delivery failures (log, retry once, discard)

### Admin Panel API
- [ ] `GET /api/admin/users` — paginated user list with role filter
- [ ] `PATCH /api/admin/users/{id}` — update user active state, role
- [ ] `DELETE /api/admin/users/{id}` — soft delete user
- [ ] `GET /api/admin/stats` — system-wide stats (users, sessions last 30d, active trainers, active athletes)
- [ ] `GET /api/admin/exercises` — all exercises including inactive
- [ ] `POST /api/admin/exercises/{id}/restore` — restore soft-deleted exercise
- [ ] Require Admin role on all /api/admin routes

### Program Templates
- [ ] Add `ProgramTemplate` entity — (trainer_id, title, description, is_public, created_at)
- [ ] Add `ProgramTemplateDay` and `ProgramTemplateExercise` entities
- [ ] EF migration for template tables
- [ ] `GET /api/templates` — list public templates + own templates
- [ ] `POST /api/templates` — create template from scratch
- [ ] `POST /api/programs` extended — `templateId` field to clone from template
- [ ] `POST /api/templates/{id}/publish` — make template public (Admin or original author)

### Advanced Analytics
- [ ] `GET /api/analytics/athletes/{athleteId}/rpe-trend` — RPE per session over date range
- [ ] `GET /api/analytics/athletes/{athleteId}/volume` — total volume (sets × reps × weight) over date range
- [ ] `GET /api/analytics/athletes/{athleteId}/exercise/{exerciseId}/progress` — weight/reps trend for specific exercise
- [ ] `GET /api/analytics/athletes/{athleteId}/consistency` — session frequency and streak
- [ ] `GET /api/analytics/trainers/me/overview` — trainer dashboard: athlete count, active programs, avg RPE across all athletes

### Public-Ready Auth
- [ ] Email verification on register (send verification email, confirm token)
- [ ] `POST /api/auth/forgot-password` — send reset link to email
- [ ] `POST /api/auth/reset-password` — consume token, set new password
- [ ] Add `email_verified_at` field to users table
- [ ] Block unverified users from non-auth endpoints (configurable flag per environment)

### Performance & Reliability
- [ ] Add response caching for `GET /api/exercises` (short TTL, invalidate on write)
- [ ] Add connection pooling tuning for PostgreSQL
- [ ] Add health check with db latency, memory usage
- [ ] Add structured logging (request id, user id, duration per request)
- [ ] Add OpenTelemetry traces for slow endpoint detection

---

## Mobile Tasks (Full App)

### Auth
- [ ] Login screen
- [ ] Register screen (athlete / trainer toggle)
- [ ] Forgot password screen
- [ ] Secure token storage (Expo SecureStore or Keychain)
- [ ] Auto token refresh on 401 (interceptor)

### Athlete Screens
- [ ] Home: today's program or log free session CTA
- [ ] Session log screen: exercise picker, set rows, RPE slider, complete button
- [ ] Session history list
- [ ] Session detail screen (exercise + sets)
- [ ] Analytics screen: weekly sessions, RPE trend chart, consistency streak
- [ ] Program list screen
- [ ] Program detail screen (day list, planned exercises)
- [ ] Relationship screen: pending requests, accept/reject

### Trainer Screens
- [ ] Athlete roster screen with relationship status badges
- [ ] Athlete detail screen: analytics overview, recent sessions
- [ ] Program builder screen: day/exercise structure
- [ ] Session history for each athlete
- [ ] Relationship request screen (send invite to athlete)

### Shared
- [ ] Notification inbox screen (in-app + push)
- [ ] Profile screen (edit name, goal, change password)
- [ ] Exercise library browse screen
- [ ] Settings screen (logout, theme, notification toggles)

### Technical
- [ ] React Navigation (bottom tabs + stack)
- [ ] Zustand or React Query for state/cache
- [ ] Offline session draft support (log without network, sync later)
- [ ] iOS TestFlight build
- [ ] Android internal testing build

---

## Web Tasks (Admin Panel)

- [ ] Add Admin-only route guard in web app
- [ ] Admin dashboard: total users, sessions last 30d, system health
- [ ] User list with role filter, active toggle, search
- [ ] Exercise management with inactive exercises visible
- [ ] Relationship audit view (all pairs, status filter)
- [ ] Notification send panel (manual push to user or role group)

---

## Database Tasks

- [ ] Add `email_verified_at` column to users
- [ ] Add `device_tokens` table
- [ ] Add `program_templates`, `program_template_days`, `program_template_exercises` tables
- [ ] Add indexes for analytics queries (athlete_id + completed_at on workout_sessions)
- [ ] Review and optimize slow query candidates
- [ ] Set up automated DB backup (VPS cron + pg_dump)

---

## Architecture Tasks

- [ ] Migrate from single `Program.cs` to full layered structure
  ```
  TrackMe.Api/          — HTTP layer (endpoints, middleware)
  TrackMe.Application/  — use cases, services, validators
  TrackMe.Domain/       — entities, enums, business rules
  TrackMe.Infrastructure/ — EF Core, FCM, email, logging
  TrackMe.Contracts/    — request/response DTOs
  ```
- [ ] Add `INotificationService` abstraction (in-app + FCM implementations)
- [ ] Add `IEmailService` abstraction (SMTP or SendGrid)
- [ ] Add domain events for cross-module side effects
- [ ] Set up unit tests for core use cases
- [ ] Set up integration tests against test database

---

## Infrastructure Tasks

- [ ] Attach domain + configure Nginx reverse proxy
- [ ] Add HTTPS (Let's Encrypt via Certbot or Cloudflare)
- [ ] Set up staging environment (separate Docker stack, separate DB)
- [ ] Add automated DB backup to VPS cron
- [ ] Set up error alerting (Sentry or similar)
- [ ] Add uptime monitoring (UptimeRobot or similar)

---

## Acceptance Criteria

Phase 3 is complete when:

- Mobile app can log in, view programs, log a session with exercises and sets.
- Push notifications arrive on mobile for relationship and program events.
- Admin can view users, toggle active state, and see system stats.
- Email verification blocks unverified users in production config.
- Password reset flow works end to end.
- Analytics endpoints return trend data suitable for chart rendering.
- Trainers can create program templates and clone them into athlete programs.
- HTTPS is live on a real domain.
- Staging environment is separate from production.

---

## Out Of Scope For Phase 3

- AI-generated workout plans.
- Wearable or health platform integration (Apple Health, Google Fit, Garmin).
- Social feed or public athlete profiles.
- Marketplace or monetization.
- Live video coaching.
- Competition or event management.
