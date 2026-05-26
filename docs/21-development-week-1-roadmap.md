# Development Week 1 Roadmap

Week 1 turns TrackMe from an infrastructure MVP into a usable coaching workflow.

The week starts with authentication and relationship foundations, then moves into exercises, program building, workout logging, and the first analytics-ready release.

## Week Goal

- Trainers and athletes can use authenticated web flows.
- Trainer-athlete access is explicit and testable.
- Coaches can build real workout programs from an exercise library.
- Athletes can log structured workout sessions.
- The database is ready for basic RPE and consistency analytics.
- Docs, API, Web, migrations, and deploy workflows stay aligned every day.

## Day Plan

- [x] Day 1: Authentication, JWT, roles, and deployed login baseline.
- [x] Day 2: Trainer-athlete relationship requests and accepted access.
- [ ] Day 3: End-to-end QA, ownership hardening, and workflow cleanup.
- [ ] Day 4: Exercise library foundation.
- [ ] Day 5: Workout program builder foundation.
- [ ] Day 6: Structured workout tracking foundation.
- [ ] Day 7: Basic analytics, release hardening, and week closeout.

## Daily Rules

- Every API change needs a migration decision.
- Every user-facing API change needs Web updates or an explicit deferral note.
- Every completed feature needs docs updates in the same day.
- Every day ends with build verification and deploy verification.
- Day files are the source of truth for what is done, pending, or deferred.

## Current Runtime

- Web: `http://187.77.92.30:8080`
- API: `http://187.77.92.30:5050`
- Scalar: `http://187.77.92.30:5050/scalar/v1`
- PostgreSQL: Docker network plus SSH tunnel access through `127.0.0.1:15432` on the VPS.

## Week 1 Acceptance

Week 1 is complete when:

- A trainer can register, login, and request athlete access.
- An athlete can register, login, accept trainer access, and keep self-guided flows.
- A trainer can create exercises and use them in a workout program.
- A trainer can create a structured program for an accepted athlete.
- An athlete can log workout sessions against a program or as a free session.
- RPE, duration, and completion data can be queried for basic analytics.
- Web and API auto deploy successfully from GitHub Actions.
- DBeaver confirms the final Week 1 schema.
- Docs reflect the implemented API and database behavior.
