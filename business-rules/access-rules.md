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
- Relationship request creation requires a trainer profile and can target an existing athlete profile
  or an active trainer/athlete user by email.
- Relationship accept and reject actions require the matching athlete profile or matching athlete
  email. This allows a trainer who is coached by another trainer to respond as the athlete side.
- Accepted relationships can be ended by either side. Ending the relationship removes trainer
  access and marks trainer-created programs for that trainer-athlete pair as inactive.
- Re-requesting a rejected or ended relationship moves the existing row back to `Pending`; accepting
  it again reactivates previously inactive trainer-created programs for that pair.
- `GET /api/athletes` returns accepted athletes for trainers, own profile for athletes, and all
  athletes for admins.
- `GET /api/athletes/search` is the trainer/admin lookup path for relationship requests and
  prevents exposing the full athlete directory to trainers.
- `GET /api/trainers/me/athletes` returns accepted athletes for the current caller's trainer entity,
  resolved by email — supports Athlete-JWT users in Trainer uiMode.
- `GET /api/programs` for Athlete-JWT users returns own athlete programs **plus** programs where
  the caller's trainer entity (matched by email) is the assigned trainer.
- Trainer web program and session selectors use accepted athletes where possible.
- Athlete web program and session flows use the athlete's own profile for self-guided work.

## Program Access

- Trainer-created programs require the trainer's own `profileId` and an accepted relationship
  with the athlete.
- `POST /api/programs` auto-resolves `trainerId` from the JWT `profile_id` claim when the caller
  is Trainer-JWT and omits `trainerId`.
- Athlete-JWT callers with a matching trainer entity can create trainer programs if they include
  (or the backend resolves) the correct `trainerId` and hold an accepted relationship with the
  athlete.
- Trainer-created sessions require an accepted relationship with the athlete.
- Trainers cannot log sessions against another trainer's program.
- Athlete-created programs must be self-guided and must use the athlete's own `profileId`.
- Athlete-created sessions must use the athlete's own `profileId`.
- Program and session lists are scoped by role: admin sees all, trainers see their own program data,
  athletes see their own data.
- Inactive programs remain visible in program lists with an inactive/passive state, but details are
  read-only. They cannot be edited and cannot be used to start new sessions.

## Program Deletion

- Admin can delete any program.
- Trainer-JWT can delete programs where `trainerId == profileId`.
- Athlete-JWT can delete self-guided programs where `athleteId == profileId && trainerId == null`.
- Email-based fallback: Athlete-JWT users acting as trainer can delete programs whose trainer
  entity email matches the caller's email.

## Dual-Role Users (Athlete-JWT in Trainer uiMode)

Certain backend endpoints support email-based trainer resolution for users who hold an
`Athlete` JWT but also operate a trainer entity (dual-role users):

| Endpoint | Behavior |
|---|---|
| `GET /api/trainers/me/athletes` | Resolved by caller email — works for any JWT role |
| `GET /api/programs` | Also includes programs where caller's trainer entity is the trainer |
| `POST /api/programs` | Auto-creates trainer entity if needed; validates accepted relationship |
| `DELETE /api/programs/{id}` | Email fallback allows deletion if trainer entity email matches |

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
