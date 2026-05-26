# Access Rules

## Current MVP Access

- Users authenticate with JWT bearer tokens.
- `Admin`, `Trainer`, and `Athlete` roles are represented in user claims.
- Trainer registration creates or reuses a matching `trainers` profile row.
- Athlete registration creates or reuses a matching `athletes` profile row.
- Dashboard, trainer, athlete, program, and session endpoints require authentication.
- Fine-grained ownership checks are planned after the Day 1 auth baseline is verified.

## Target Access Model

- Every protected endpoint requires authentication.
- Role validation is mandatory.
- Ownership validation is mandatory.
- Admin can access platform-wide resources.
- Trainer can access only accepted athletes.
- Athlete can access only own data.
- Pending relationship requests do not grant data access.
- Removed relationships do not grant new access.
