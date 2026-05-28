# Trainer Module

## Purpose

Provides trainer-specific workflows for managing athletes, programs, notes, and performance review.
Also supports Athlete-JWT users who operate in Trainer uiMode via email-based trainer entity resolution.

## Responsibilities

- List trainer athletes (by trainer entity email, works for any JWT role)
- Review athlete workout history
- Review athlete analytics
- Manage trainer-owned programs
- Expose trainer search for relationship requests

## Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/api/trainers` | List all trainer entities (paginated) |
| `GET` | `/api/trainers/me/athletes` | Accepted athletes for current caller's trainer entity (email-based) |
| `GET` | `/api/trainers/search` | Search trainers by name/email for relationship requests |

## Email-Based Resolution

`GET /api/trainers/me/athletes` resolves the caller's trainer entity by **email**, not by JWT role.
This means:

- Trainer-JWT users → their trainer entity by email
- Athlete-JWT users in Trainer uiMode → their trainer entity by email (if exists)
- Returns empty array if no trainer entity exists for the caller's email

Other endpoints that support email-based fallback for dual-role users:
- `POST /api/programs` — creates / reuses trainer entity on first use
- `DELETE /api/programs/{id}` — email fallback authorization

## Business Rules

- Trainer can access only accepted athletes.
- Trainer cannot view athlete data through pending relationships.
- Trainer can manage only own programs unless admin.
- A trainer can also be coached by another trainer and therefore may have an athlete profile.
- An athlete user can operate as a trainer via Trainer uiMode — their trainer entity is
  lazily created on first program creation if it does not yet exist.

## Trainer Entity Lifecycle

1. **Trainer-JWT registration**: `EnsureProfileAsync` creates the trainer entity immediately.
2. **Athlete-JWT in Trainer uiMode**: trainer entity created lazily via `EnsureTrainerEntityAsync`
   when the user first creates a program for another athlete.
3. Entity is always looked up by `Email` to avoid duplicates across registration paths.
