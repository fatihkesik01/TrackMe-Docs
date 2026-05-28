# Trainer-Athlete Relationship System

## Overview

The `trainer_athlete_relationships` table is the access gate between trainer and athlete data. A trainer can only view, manage programs for, or view analytics of an athlete when an `Accepted` relationship exists between them.

## Relationship Directions

Either side can initiate:

| Initiator | Endpoint                        | `InitiatedByAthlete` | Who accepts |
|-----------|---------------------------------|---------------------|-------------|
| Trainer   | `POST /api/relationships/requests` | `false`          | Athlete     |
| Athlete   | `POST /api/relationships/invite`   | `true`           | Trainer     |

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
```

Only `Pending` relationships can be accepted or rejected. Attempting to respond to an already-resolved relationship returns `409 Conflict`.

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

## Duplicate Prevention

A unique index on `(trainer_id, athlete_id)` prevents creating two relationship rows for the same pair. Attempting to create a duplicate returns `409 Conflict` with the existing status.

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

## Frontend Behavior

`RelationshipsView` uses `uiRole` to determine which panel to show:

- `uiRole === 'Trainer'` → shows "Send request" panel (search athletes, send request) + incoming athlete invites
- `uiRole === 'Athlete'` → shows "Invite trainer" panel (search trainers, send invite) + incoming trainer requests

The same view component handles both modes. Both TRAINER_NAV and ATHLETE_NAV include the `relationships` nav item.
