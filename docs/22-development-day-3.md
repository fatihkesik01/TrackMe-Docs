# Development Day 3

Day 3 goal is to test the Day 1 and Day 2 foundation end to end, then tighten the parts that could cause incorrect trainer-athlete access.

The focus is QA, ownership hardening, clearer validation, and keeping the web workflows predictable before new training features are added.

## Current Baseline

- Users can register and login with JWT.
- Trainer and athlete profile ids are included in auth responses.
- Trainer-athlete relationship requests exist.
- Accepted relationships drive trainer athlete selectors in the web app.
- API, Web, and Docs auto deploy from GitHub Actions.

## Day 3 Scope

- Verify the full trainer-athlete request flow.
- Harden trainer access around accepted relationships.
- Improve API errors for common bad requests.
- Clean up web empty states and relationship edge cases.
- Record test accounts, test scenarios, and deferred risks.

## API Tasks

- [x] Verify `GET /api/relationships/requests` for trainer and athlete roles.
- [x] Verify `POST /api/relationships/requests` blocks duplicate pairs.
- [x] Verify accepted relationships appear in `GET /api/trainers/me/athletes`.
- [x] Add or confirm ownership checks for trainer-created programs.
- [x] Add or confirm ownership checks for trainer-created sessions.
- [x] Return clearer `400`, `403`, and `404` messages for relationship and ownership errors.
- [x] Confirm athlete users can create self-guided programs for only their own profile.
- [x] Confirm auth middleware returns `401` without a token.
- [x] Confirm forbidden role actions return `403`.
- [x] Verify admin relationship list behavior with an admin user.

## Web Tasks

- [x] Test register as trainer through deployed API.
- [x] Test register as athlete through deployed API.
- [x] Test trainer request access flow through deployed API.
- [x] Test athlete accept request flow through deployed API.
- [x] Test athlete reject request flow through deployed API.
- [ ] Verify login/register manually in the deployed browser UI.
- [ ] Verify trainer program selector shows accepted athletes only in the deployed browser UI.
- [ ] Verify trainer session selector shows accepted athletes only in the deployed browser UI.
- [x] Verify athlete self-guided program flow through deployed API.
- [x] Add clearer empty states for no accepted athletes.
- [x] Add clearer empty state for no requestable athletes.

## Database Tasks

- [x] Verify relationship rows and statuses through PostgreSQL.
- [x] Verify no orphaned trainer-athlete relationship rows.
- [x] Verify migration history includes Day 1 and Day 2 migrations.
- [x] Confirm test data can be safely identified or removed later.

## Docs Tasks

- [x] Add Day 3 completion notes.
- [x] Update access rules with any hardened checks.
- [x] Update API analysis if endpoint errors or DTOs change.
- [x] Update relationship module notes with tested behavior.
- [x] Record remaining MVP shortcuts.

## Acceptance Criteria

Day 3 is complete when:

- Trainer and athlete accounts complete the relationship request flow in the deployed web app.
- Relationship rows are visible in DBeaver.
- Accepted relationships drive trainer program and session choices.
- Unauthorized and forbidden cases behave predictably.
- Day 3 docs reflect what was tested and what was deferred.

## Out Of Scope For Day 3

- Exercise library implementation.
- Structured workout program days and exercises.
- Full admin panel.
- Email invitations.
- Mobile implementation.

## Completion Notes

- API ownership hardening was implemented and deployed in `TrackMe-Api` commit `073cb8a`.
- Web empty state cleanup was implemented and deployed in `TrackMe-Web` commit `58ce205`.
- No EF Core migration was required for Day 3 because no schema changed.
- Deployed API test data uses emails prefixed with `day3.` and can be filtered later.
- Tested accepted relationship flow, duplicate request blocking, trainer program/session ownership, athlete self-guided ownership, unauthenticated `401`, and forbidden `403` cases against the deployed API.
- Tested rejected relationship flow and admin relationship list behavior against the deployed API.
- PostgreSQL verification confirmed Day 1 and Day 2 migrations are present, relationship statuses are queryable, and orphan relationship count is `0`.
- Remaining Day 3 manual work is browser UI confirmation for login/register and selector behavior.
