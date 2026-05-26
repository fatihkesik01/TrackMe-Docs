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

- [ ] Add `GET /api/analytics/athletes/{athleteId}/overview`.
- [ ] Add weekly session count.
- [ ] Add average RPE.
- [ ] Add total workout duration.
- [ ] Add latest session summary.
- [ ] Enforce trainer access to accepted athletes only.
- [ ] Enforce athlete access to own analytics only.
- [ ] Add admin bypass if needed or document deferral.

## Web Tasks

- [ ] Add analytics summary section.
- [ ] Show weekly sessions, average RPE, and total duration.
- [ ] Show latest session.
- [ ] Show empty analytics state.
- [ ] Keep dashboard dense and operational, not marketing-style.
- [ ] Verify mobile-sized layout.

## Database Tasks

- [ ] Verify all Week 1 migrations in `__EFMigrationsHistory`.
- [ ] Verify analytics queries against test data.
- [ ] Verify DBeaver connection still works through SSH tunnel.
- [ ] Confirm no production-breaking test cleanup is needed.

## Docs Tasks

- [ ] Update analytics module docs.
- [ ] Update API analysis with analytics endpoints.
- [ ] Update database design if analytics fields changed.
- [ ] Add Week 1 completion summary.
- [ ] Create Week 2 roadmap.
- [ ] Record known risks and deferred work.

## Release Tasks

- [ ] Run API build.
- [ ] Run Web build.
- [ ] Push API changes.
- [ ] Push Web changes.
- [ ] Push Docs changes.
- [ ] Verify GitHub Actions success.
- [ ] Verify API health.
- [ ] Verify Web loads.
- [ ] Verify Scalar loads.

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
