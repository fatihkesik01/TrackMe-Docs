# Coaching Relationships

## Overview

The `trainer_athlete_relationships` table is the coaching access gate. An accepted relationship grants a trainer access to an athlete's programs, sessions, analytics, body metrics, and media submissions. Nothing less than an accepted coaching relationship unlocks these.

## Relationship Lifecycle

```
[Trainer sends request]         → Pending  (initiated_by_athlete = false)
[Athlete sends invite]          → Pending  (initiated_by_athlete = true)
        │
        ├── Accepted by responding party
        │       → programs accessible, messaging enabled, social connection auto-created
        │
        ├── Rejected by responding party
        │       → no access; can be re-requested (moves back to Pending)
        │
        └── Ended by either party
                → trainer programs locked (not deleted), coaching access removed
                → if re-accepted: previously locked programs reactivated
```

## `trainer_athlete_relationships` Table

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid PK | |
| `trainer_id` | uuid FK | → `trainers` |
| `athlete_id` | uuid FK | → `athletes` |
| `status` | varchar(20) | `Pending` / `Accepted` / `Rejected` / `Ended` |
| `initiated_by_athlete` | bool | determines who can accept/reject |
| `created_at` | timestamptz | |
| `responded_at` | timestamptz? | |

Unique index: `(trainer_id, athlete_id)` — one row per pair, reused across lifecycle changes.

## Who Can Initiate

- **Trainer** searches for an athlete by email → sends access request
- **Athlete** searches for a trainer by email → sends coaching invite

Both actions create a `Pending` row. `initiated_by_athlete` determines which side must respond.

## Accept / Reject Rules

| `initiated_by_athlete` | Responding party |
|-----------------------|-----------------|
| `true` | Trainer responds (athlete initiated; trainer decides) |
| `false` | Athlete responds (trainer initiated; athlete decides) |

Matching is by `profileId` **and** email to support dual-role users.

## Effects of Accepted Status

- Trainer's athlete appears in `GET /api/trainers/me/athletes`
- Trainer can create programs for the athlete
- Trainer can view athlete sessions, analytics, and body metrics
- Trainer can send and receive direct messages with the athlete
- A social connection is auto-created (if not already present) so messaging works immediately

## Effects of Ending the Relationship

- All trainer-created programs for this pair are marked `is_active = false` (`locked_at` set)
- Locked programs remain visible (read-only) but cannot be edited or used for new sessions
- If the same relationship is accepted again, previously locked programs are reactivated
- Social connection is NOT automatically removed when coaching ends

## Re-request After Rejection or End

Sending a new request when a `Rejected` or `Ended` row exists moves the same row back to `Pending`. Accepting it again:
- Restores coaching access
- Reactivates locked programs from that trainer-athlete pair
- Does not create a new DB row

## Multi-Coach Support

An athlete can have accepted coaching relationships with multiple trainers simultaneously. Each trainer sees only their own programs and sessions for that athlete.

`athletes.trainer_id` column was removed in `Phase1_ArchAlignment` (migration #48). Multi-coach is now managed exclusively through `trainer_athlete_relationships`.

## Dual-Role Resolution

An `Athlete` JWT user operating as a trainer:
- Backend resolves trainer entity via `db.Trainers.Where(t => t.Email == callerEmail)`
- All relationship checks use the resolved trainer entity's ID
- `GET /api/trainers/me/athletes` works for any JWT role (resolved by email)

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/coaching/request` | Send coaching request |
| `POST` | `/api/coaching/{id}/accept` | Accept request |
| `POST` | `/api/coaching/{id}/reject` | Reject request |
| `DELETE` | `/api/coaching/{id}` | End relationship |
| `GET` | `/api/coaching/requests` | List incoming + outgoing requests |
| `GET` | `/api/coaching/connections` | List accepted coaching connections |

> **Note:** Endpoints were renamed from `/api/relationships` to `/api/coaching` in Phase 6.

## Notifications

| Event | Recipient | `NotificationType` |
|-------|-----------|-------------------|
| Request sent | Recipient | `RelationshipRequest` |
| Request accepted | Requester | `RelationshipAccepted` |
| Request rejected | Requester | `RelationshipRejected` |
| Relationship ended | Other side | `RelationshipEnded` |

## Access Rules Summary

| What | Requires |
|------|----------|
| View athlete programs | Accepted coaching relationship |
| Create program for athlete | Accepted coaching relationship |
| View athlete sessions | Accepted coaching relationship |
| View athlete analytics | Accepted coaching relationship |
| View athlete body metrics | Accepted coaching relationship |
| Send message | Accepted coaching OR social connection |
| View privacy-filtered profile | Any authenticated user (filtered by visibility) |

## Frontend

`RelationshipsView.jsx` — two tabs:

**Koçluk İlişkileri tab:**
- Search for trainer/athlete by email
- Incoming pending requests (accept/reject)
- Active coaching connections (end + "View Profile" button)
- Outgoing pending requests (withdraw)

**Sosyal Bağlantılar tab:** (separate feature — see [social.md](social.md))
