# Development Day 7

Day 7 goal is to close Week 1 with basic analytics and release hardening.

The focus is making the week testable, deployable, and ready for the next development phase.

## Current Baseline

- Auth and relationship flows are implemented.
- Exercise library, structured programs, and structured workout sessions are planned for Days 4-6.
- RPE and duration data exist from simple sessions and should expand with set logs.

## Day 7 Scope

- Add basic analytics endpoints.
- Add simple web analytics summaries.
- Verify all Week 1 migrations and deployed workflows.
- Clean up docs and known risks.
- Define Week 2 priorities.

## API Tasks

- [x] Add `GET /api/analytics/athletes/{athleteId}/overview`.
- [x] Add weekly session count.
- [x] Add average RPE.
- [x] Add total workout duration.
- [x] Add latest session summary.
- [x] Enforce trainer access to accepted athletes only.
- [x] Enforce athlete access to own analytics only.
- [x] Add admin bypass.

## Web Tasks

- [x] Add `api.athleteAnalytics()` method in api.js.
- [ ] Add analytics summary section in UI (Week 2 scope — web UI component pending).
- [ ] Show weekly sessions, average RPE, and total duration in UI.
- [ ] Show latest session in UI.
- [ ] Show empty analytics state in UI.

## Database Tasks

- [x] Migration `AddSessionExerciseTracking` added (`workout_session_exercises`, `workout_set_logs`).
- [x] Startup auto-migration added — app applies pending migrations on boot.
- [ ] Verify all Week 1 migrations in `__EFMigrationsHistory` after redeploy.
- [ ] Verify analytics queries against test data.
- [ ] Verify DBeaver connection still works through SSH tunnel.

## Docs Tasks

- [ ] Update analytics module docs.
- [ ] Update API analysis with analytics endpoints.
- [ ] Update database design if analytics fields changed.
- [ ] Add Week 1 completion summary.
- [ ] Create Week 2 roadmap.
- [ ] Record known risks and deferred work.

## Release Tasks

- [x] Run API build — succeeded (0 warnings, 0 errors).
- [x] Push API changes — pushed to main.
- [x] Push Web changes — pushed to main.
- [ ] Push Docs changes.
- [ ] Verify GitHub Actions success.
- [ ] Verify API health.
- [ ] Verify Web loads.
- [ ] Verify Scalar loads.

## Additional Completed (Beyond Day 7 Scope)

These were hardening fixes identified during Day 7 code review:

- [x] `POST /api/auth/refresh` — token rotation with 30-day refresh tokens.
- [x] `POST /api/auth/logout` — server-side refresh token revocation.
- [x] `POST /api/trainers` — restricted to Admin role only (was unprotected).
- [x] `GET /api/athletes` — role-based filtering (Athlete sees own profile only).
- [x] Email validation — replaced weak check with `MailAddress` RFC parse.
- [x] Global exception handler middleware — JSON 500 responses with traceId.
- [x] `GET/POST /api/sessions/{id}/exercises` — session exercise tracking.
- [x] `POST /api/sessions/{id}/exercises/{exId}/sets` — set log recording.

## Acceptance Criteria

Day 7 is complete when:

- Basic analytics can be queried from the API.
- The web app shows useful analytics summaries.
- Week 1 migrations are verified.
- GitHub Actions deploys API and Web successfully.
- Docs contain Week 1 completion notes.
- Week 2 work is ready to start.

## Out Of Scope For Day 7

- Advanced charts.
- AI summaries.
- Wearable data.
- Push notifications.
- Payment or subscription.
- Mobile implementation.
