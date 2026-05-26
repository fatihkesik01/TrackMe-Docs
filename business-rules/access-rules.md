# Access Rules

## Current MVP Access

- Users authenticate with JWT bearer tokens.
- `Admin`, `Trainer`, and `Athlete` roles are represented in user claims.
- Trainer registration creates or reuses a matching `trainers` profile row.
- Athlete registration creates or reuses a matching `athletes` profile row.
- A trainer can also be represented as an athlete profile when another trainer coaches them.
- Athlete users can create self-guided programs without assigning a trainer.
- Dashboard, trainer, athlete, program, and session endpoints require authentication.
- Trainers cannot create athlete records directly; they send access requests.
- Relationship request creation requires a trainer profile and can target an existing athlete profile or an active trainer/athlete user by email.
- Relationship accept and reject actions require the matching athlete profile or matching athlete email. This allows a trainer who is coached by another trainer to respond as the athlete side.
- `GET /api/athletes` returns accepted athletes for trainers, own profile for athletes, and all athletes for admins.
- `GET /api/athletes/search` is the trainer/admin lookup path for relationship requests and prevents exposing the full athlete directory to trainers.
- `GET /api/trainers/me/athletes` returns accepted athletes for the current trainer.
- Trainer web program and session selectors use accepted athletes where possible.
- Athlete web program and session flows use the athlete's own profile for self-guided work.
- Trainer-created programs require the trainer's own `profileId` and an accepted relationship with the athlete.
- Trainer-created sessions require an accepted relationship with the athlete.
- Trainers cannot log sessions against another trainer's program.
- Athlete-created programs must be self-guided and must use the athlete's own `profileId`.
- Athlete-created sessions must use the athlete's own `profileId`.
- Program and session lists are scoped by role: admin sees all, trainers see allowed athlete data, athletes see their own data.

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
