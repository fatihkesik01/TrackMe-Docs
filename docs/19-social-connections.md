# Social Connections & Profile Privacy

## Overview

The social connection system (`user_connections` table, `/api/connections` endpoints) allows any two users to connect with each other. An accepted social connection grants:

- **Messaging** — both sides can message each other
- **Profile viewing** — `GET /api/users/{userId}/profile` returns privacy-filtered fields

A social connection **never** grants coaching permissions (program access, session viewing, analytics, body metrics list). Only an accepted coaching relationship (`trainer_athlete_relationships`) provides those.

A user can have both a social connection and a coaching relationship with the same person simultaneously — they are fully independent.

## `user_connections` Table

| Column           | Type         | Notes                                      |
|------------------|--------------|--------------------------------------------|
| `id`             | uuid PK      |                                            |
| `requester_id`   | uuid FK      | → `users`, restrict delete                 |
| `recipient_id`   | uuid FK      | → `users`, restrict delete                 |
| `status`         | varchar(20)  | `Pending` / `Accepted` / `Rejected` / `Ended` |
| `created_at`     | timestamptz  |                                            |
| `responded_at`   | timestamptz? |                                            |

Unique index: `(requester_id, recipient_id)` — enforced at the DB level.

## Endpoints

| Method   | Path                              | Auth | Description                             |
|----------|-----------------------------------|------|-----------------------------------------|
| `POST`   | `/api/connections`                | JWT  | Send connection request                 |
| `GET`    | `/api/connections`                | JWT  | List caller's connections (paginated)   |
| `POST`   | `/api/connections/{id}/accept`    | JWT  | Accept (recipient only)                 |
| `POST`   | `/api/connections/{id}/reject`    | JWT  | Reject (recipient only)                 |
| `DELETE` | `/api/connections/{id}`           | JWT  | End or withdraw (either party)          |
| `GET`    | `/api/users/{userId}/profile`     | JWT  | Privacy-filtered public profile         |

### `POST /api/connections`

Request body: `{ "email": "user@example.com" }` or `{ "userId": "guid" }`

Rules:
- Self-connection → 400
- Existing `Pending` or `Accepted` → 409
- Existing `Rejected` or `Ended` → resets the row to `Pending` (reuses slot, no duplicate)
- Sends a `ConnectionRequest` notification to the recipient

### `GET /api/users/{userId}/profile`

Returns a `UserPublicProfileDto`. Each field is filtered by the target user's privacy settings:

| Visibility level | Visible to                                    |
|-----------------|-----------------------------------------------|
| `public`        | Everyone (any authenticated user)             |
| `connections`   | Accepted social connection OR accepted coaching |
| `coach_only`    | Accepted coaching relationship only           |
| `private`       | Nobody (field omitted from response)          |

Response includes:
- `connectionStatus` — `"None"` | `"Pending"` | `"Accepted"` | `"PendingFromThem"`
- `coachingStatus` — same values, for the coaching relationship

## Profile Privacy

The `users` table has a `profile_privacy_json` column (varchar 2000, nullable). It stores a JSON object with visibility levels for each profile field.

### Default values (when null or field missing)

| Field         | Default         |
|---------------|-----------------|
| `bio`         | `"connections"` |
| `goal`        | `"connections"` |
| `age`         | `"public"`      |
| `profession`  | `"public"`      |
| `sports`      | `"public"`      |
| `bodyMetrics` | `"coach_only"`  |

### Valid visibility values

`"public"` | `"connections"` | `"coach_only"` | `"private"`

### Updating privacy settings

`PATCH /api/auth/profile` accepts a `profilePrivacy` field:

```json
{
  "profilePrivacy": {
    "bio": "connections",
    "goal": "private",
    "age": "public",
    "profession": "connections",
    "sports": "public",
    "bodyMetrics": "coach_only"
  }
}
```

All 6 fields must be valid visibility strings or the request is rejected with 400.

## Notification Types

| Event               | Recipient   | `NotificationType`       |
|---------------------|-------------|--------------------------|
| Request sent        | Recipient   | `ConnectionRequest`      |
| Request accepted    | Requester   | `ConnectionAccepted`     |
| Request rejected    | Requester   | `ConnectionRejected`     |
| Connection ended    | Other side  | `ConnectionEnded`        |

## Messaging Access

`POST /api/messages/send` checks:
1. Accepted coaching relationship (trainer↔athlete), **OR**
2. Accepted social connection (any direction)

If neither exists → 403.

`GET /api/messages/contacts` returns all users the caller can message: coaching contacts + social connection contacts.

## Security Notes

- Social connections grant **no coaching permissions**. The coaching access gate (`HasAcceptedRelationshipAsync` in `EndpointHelpers`) is not affected by social connection status.
- Role changes (athlete → trainer) do not convert existing social connections.
- Program/session/analytics/body-metrics list endpoints all require an accepted coaching relationship — never a social connection.

## Frontend

`RelationshipsView.jsx` has two tabs:

**Tab: Sosyal Bağlantılar**
- Search any user → send connection request
- Incoming requests → accept / reject
- Active connections → remove + "View Profile" button
- Outgoing pending requests → withdraw

**Tab: Koçluk İlişkileri**
- Existing coaching UI (unchanged)

**UserProfileModal** (inline in `RelationshipsView.jsx`): fetches `GET /api/users/{userId}/profile`, shows privacy-filtered fields, body metrics summary, and connection/coaching status badges.

**ProfileView.jsx** — Privacy Settings section: 6 fields, each with 4 visibility toggle buttons. Saved via `PATCH /api/auth/profile`.
