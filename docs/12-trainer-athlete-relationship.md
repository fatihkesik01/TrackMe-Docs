# Trainer-Athlete Relationship System

## Overview

The `trainer_athlete_relationships` table is the access gate between trainer and athlete data. A trainer can only view, manage programs for, or view analytics of an athlete when an `Accepted` relationship exists between them.

## Relationship Directions

Either side can initiate:

| Initiator | Endpoint                        | `InitiatedByAthlete` | Who accepts |
|-----------|---------------------------------|---------------------|-------------|
| Trainer   | `POST /api/coaching/requests`      | `false`          | Athlete     |
| Athlete   | `POST /api/coaching/invite`        | `true`           | Trainer     |

Both endpoints accept either an ID or an email address for the target user. If no matching profile entity exists, one is created lazily.

## Status Lifecycle

```
             Trainer sends request
                    │
                    ▼
              [Pending]
                 / \
         accept   reject
           /         \
      [Accepted]   [Rejected]
          |
        end
          |
       [Ended]
```

Only `Pending` relationships can be accepted or rejected. Attempting to respond to an already-resolved relationship returns `409 Conflict`.

`Accepted` relationships can be ended by either side with `DELETE /api/coaching/{id}`. Ending a relationship keeps the audit row, changes the status to `Ended`, removes trainer access, and **locks** all trainer-created programs for that trainer-athlete pair (sets `locked_at` = now, `locked_reason` = `"coaching_ended"`). Locked programs remain visible and can still be used for workouts, but their content (exercises, structure) cannot be edited by anyone except Admin.

## Access Implications of Accepted Status

When a relationship is `Accepted`, the trainer can:

- List the athlete in `GET /api/trainers/me/athletes`
- View the athlete's programs via `GET /api/programs`
- Create programs for the athlete via `POST /api/programs`
- View the athlete's sessions via `GET /api/sessions`
- View all analytics endpoints for the athlete
- View body metrics for the athlete
- Write trainer review notes on session exercises

The athlete continues to own all their data; the trainer gets read-and-program-write access only.

When a relationship is `Ended`, the trainer immediately loses access because all access checks require `Accepted` status.

## Auto Social Connection

When a coaching relationship becomes `Accepted`, the system automatically creates or upgrades a `UserConnection` between the trainer's `AppUser` and the athlete's `AppUser` to `Accepted` status. This means accepting a coaching request also grants social connection visibility — programs published with `"connections"` visibility become visible to both sides. The reverse is not true: a social connection does not grant coaching access.

## Duplicate Prevention

A unique index on `(trainer_id, athlete_id)` prevents creating two relationship rows for the same pair. `Pending` and `Accepted` duplicates return `409 Conflict`. `Rejected` or `Ended` rows can be reused by sending a new request/invite, which moves the existing row back to `Pending`. When that request is accepted, locked trainer-created programs for the same pair are unlocked (clears `locked_at` and `locked_reason`).

## Multi-Coach Support

An athlete can have multiple simultaneous active coaches (e.g., a strength coach, a running coach, and a nutrition coach). The `trainer_athlete_relationships` table uses a unique constraint on `(trainer_id, athlete_id)` pairs, not on `athlete_id` alone. The legacy `Athlete.trainer_id` denormalized FK has been removed as of Migration 48; all coach lookups go through this relationship table.

## Dual-Role Resolution

Users can appear in both the `trainers` and `athletes` tables with the same email. The relationship logic always resolves entities by email when the JWT role and the target entity type differ:

```
Athlete JWT + email "coach@example.com"
→ db.Trainers.Where(t => t.Email == "coach@example.com")
→ if found: trainerEntity.Id is used in HasAcceptedRelationshipAsync()
```

This allows an `Athlete` JWT holder to use trainer features when they also have a trainer entity.

## `canRespond` Logic

```
if relationship.InitiatedByAthlete:
    canRespond = caller is trainer (by profileId or email match)
else:
    canRespond = caller is athlete (by profileId or email match)
```

Email match is a fallback for dual-role users whose JWT role does not directly match the expected entity type.

## Notifications

| Event             | Recipient          | Type                    |
|-------------------|--------------------|-------------------------|
| Request sent      | Target user        | `RelationshipRequest`   |
| Invite sent       | Target trainer     | `RelationshipRequest`   |
| Request accepted  | Initiating side    | `RelationshipAccepted`  |
| Request rejected  | Initiating side    | `RelationshipRejected`  |
| Relationship ended | Other side        | `RelationshipEnded`     |

## Program Locking on End

Ending an accepted relationship locks trainer-created programs for that pair:

- `locked_at` is set to the current timestamp.
- `locked_reason` is set to `"coaching_ended"`.
- `is_active` remains `true` — programs stay visible and usable for workouts.

Self-guided programs are not affected. Locked programs are read-only for everyone except Admin; the athlete can still reschedule days and start sessions. If the same trainer-athlete pair re-establishes their relationship (moves back to Accepted), all previously locked programs for that pair are automatically unlocked.

## Frontend Behavior

`RelationshipsView` has two tabs — **Sosyal Bağlantılar** and **Koçluk İlişkileri**.

The coaching tab uses `uiRole` to determine which panel to show:

- `uiRole === 'Trainer'` → shows "Send request" panel (search athletes, send request) + incoming athlete invites
- `uiRole === 'Athlete'` → shows "Invite trainer" panel (search trainers, send invite) + incoming trainer requests

Accepted relationships show an "End relationship" action. The Web app displays a confirmation prompt because ending a relationship also locks linked trainer programs.

Rejected and ended relationships show a "Reconnect relationship" action. It sends a new request/invite for the same trainer-athlete pair and reuses the existing relationship row.

Relationship notifications are delivered through SignalR. When the Web client receives a relationship notification, it refreshes app data so both sides see the latest relationship status and related program active/passive state without reloading the browser.

## Relationship vs Social Connection

Coaching relationships (`trainer_athlete_relationships` / `/api/coaching`) are **strictly separate** from social connections (`user_connections` / `/api/connections`). An accepted coaching relationship grants all coaching permissions. An accepted social connection grants only messaging and profile viewing — never coaching permissions. A role change (athlete → trainer) does NOT convert a social connection into a coaching relationship. See `19-social-connections.md` for the social connection system.
