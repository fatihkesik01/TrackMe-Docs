# Access Rules

## Current MVP Access

- Users authenticate with JWT bearer tokens.
- `Admin`, `Trainer`, and `Athlete` roles are represented in user claims.
- Trainer registration creates or reuses a matching `trainers` profile row.
- Athlete registration creates or reuses a matching `athletes` profile row.
- A trainer can also be represented as an athlete profile when another trainer coaches them.
- Athlete users can create self-guided programs without assigning a trainer.
- Dashboard, trainer, athlete, program, and session endpoints require authentication.
- Relationship request creation requires a trainer profile.
- Relationship accept and reject actions require the matching athlete profile.
- `GET /api/trainers/me/athletes` returns accepted athletes for the current trainer.
- Trainer web program and session selectors use accepted athletes where possible.
- Athlete web program and session flows use the athlete's own profile for self-guided work.
- Fine-grained ownership checks are planned after the Day 1 auth baseline is verified.

## Target Access Model

- Every protected endpoint requires authentication.
- Role validation is mandatory.
- Ownership validation is mandatory.
- Admin can access platform-wide resources.
- Trainer can access only accepted athletes.
- Athlete can access only own data.
- Trainer and athlete responsibilities can overlap for the same person.
- Pending relationship requests do not grant data access.
- Removed relationships do not grant new access.
