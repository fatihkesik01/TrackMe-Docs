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

- [ ] Verify `GET /api/relationships/requests` for trainer, athlete, and admin roles.
- [ ] Verify `POST /api/relationships/requests` blocks duplicate pairs.
- [ ] Verify accepted relationships appear in `GET /api/trainers/me/athletes`.
- [ ] Add or confirm ownership checks for trainer-created programs.
- [ ] Add or confirm ownership checks for trainer-created sessions.
- [ ] Return clearer `400`, `403`, and `404` messages for relationship errors.
- [ ] Confirm athlete users can create self-guided programs for only their own profile.
- [ ] Confirm auth middleware returns `401` without a token.
- [ ] Confirm forbidden role actions return `403`.

## Web Tasks

- [ ] Test login and register as trainer.
- [ ] Test login and register as athlete.
- [ ] Test trainer request access flow.
- [ ] Test athlete accept request flow.
- [ ] Test athlete reject request flow.
- [ ] Verify trainer program selector shows accepted athletes only.
- [ ] Verify trainer session selector shows accepted athletes only.
- [ ] Verify athlete self-guided program flow still works.
- [ ] Add clearer empty states for no accepted athletes.
- [ ] Add clearer empty state for no requestable athletes.

## Database Tasks

- [ ] Verify relationship rows and statuses in DBeaver.
- [ ] Verify no orphaned trainer-athlete relationship rows.
- [ ] Verify migration history includes Day 1 and Day 2 migrations.
- [ ] Confirm test data can be safely identified or removed later.

## Docs Tasks

- [ ] Add Day 3 completion notes.
- [ ] Update access rules with any hardened checks.
- [ ] Update API analysis if endpoint errors or DTOs change.
- [ ] Update relationship module notes with tested behavior.
- [ ] Record remaining MVP shortcuts.

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
