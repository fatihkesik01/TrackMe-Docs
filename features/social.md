# Social: Connections & Follow

## Two Independent Systems

TrackMe has two distinct social mechanisms:

| System | Table | Relationship type | What it grants |
|--------|-------|------------------|----------------|
| **Social Connection** | `user_connections` | Bilateral (both parties must accept) | Messaging + privacy-filtered profile viewing |
| **Follow** | `user_follows` | Unilateral (no acceptance needed) | Access to followed user's public programs feed |

**Key rule:** Neither social connections nor follows grant coaching permissions (program access, session data, analytics, body metrics). Only an accepted coaching relationship (`trainer_athlete_relationships`) unlocks those.

---

## Social Connections

### Purpose

Allow two users to connect socially — independent of any coaching relationship. An accepted social connection grants:
- **Messaging** — either side can send direct messages
- **Profile visibility** — `connections` level fields become visible in `GET /api/users/{id}/profile`

### `user_connections` Table

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid PK | |
| `requester_id` | uuid FK | → `users` |
| `recipient_id` | uuid FK | → `users` |
| `status` | varchar(20) | `Pending` / `Accepted` / `Rejected` / `Ended` |
| `created_at` | timestamptz | |
| `responded_at` | timestamptz? | |

Unique index: `(requester_id, recipient_id)`.

### Connection Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/connections` | Send connection request |
| `GET` | `/api/connections` | List caller's connections (paginated) |
| `POST` | `/api/connections/{id}/accept` | Accept (recipient only) |
| `POST` | `/api/connections/{id}/reject` | Reject (recipient only) |
| `DELETE` | `/api/connections/{id}` | End or withdraw |
| `GET` | `/api/users/{userId}/profile` | Privacy-filtered public profile |

### Connection Rules

- Self-connection → 400
- Existing `Pending` or `Accepted` → 409
- Existing `Rejected` or `Ended` → resets row to `Pending` (reuses slot)

### Messaging Access

`POST /api/messages/send` requires:
1. Accepted coaching relationship, **OR**
2. Accepted social connection

If neither exists → 403.

### Connection Notifications

| Event | Recipient | Type |
|-------|-----------|------|
| Request sent | Recipient | `ConnectionRequest` |
| Request accepted | Requester | `ConnectionAccepted` |
| Request rejected | Requester | `ConnectionRejected` |
| Connection ended | Other side | `ConnectionEnded` |

### Auto-Connection from Coaching

When a coaching relationship is accepted, a social connection is automatically created between the trainer and athlete (if one doesn't already exist). This ensures messaging is immediately available.

---

## Profile Privacy

Each user controls the visibility of their profile fields via `users.profile_privacy_json`.

### Privacy Levels

| Level | Visible to |
|-------|-----------|
| `public` | Any authenticated user |
| `connections` | Accepted social connection OR accepted coaching relationship |
| `coach_only` | Accepted coaching relationship only |
| `private` | Nobody |

### Configurable Fields

| Field | Default |
|-------|---------|
| `bio` | `connections` |
| `goal` | `connections` |
| `age` | `public` |
| `profession` | `public` |
| `sports` | `public` |
| `bodyMetrics` | `coach_only` |
| `avatarEmoji` | `public` |
| `featuredExercises` | `public` |

### Updating Privacy

`PATCH /api/auth/profile` with `profilePrivacy` object. All provided fields must be valid visibility strings.

---

## Follow System

### Purpose

Unilateral follow for program discovery. Following someone grants access to their **public programs** in the "Following" feed tab. It has no effect on privacy levels.

### `user_follows` Table

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid PK | |
| `follower_user_id` | uuid FK | → `users` |
| `followed_user_id` | uuid FK | → `users` |
| `created_at` | timestamptz | |

Unique index: `(follower_user_id, followed_user_id)`.

### Follow Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/users/{userId}/follow` | Follow a user |
| `DELETE` | `/api/users/{userId}/follow` | Unfollow |
| `GET` | `/api/users/{userId}/followers` | Paginated followers list |
| `GET` | `/api/users/{userId}/following` | Paginated following list |
| `GET` | `/api/feed/following` | Programs from followed users |

Self-follow → 400. Duplicate follow → 409. All require authentication.

### Follow vs Connection vs Coaching

| | Grants messaging | Opens connections fields | Opens coach_only fields | Grants coaching access |
|---|---|---|---|---|
| **Follow** | ❌ | ❌ | ❌ | ❌ |
| **Social Connection** | ✅ | ✅ | ❌ | ❌ |
| **Coaching** | ✅ | ✅ | ✅ | ✅ |

### Follow Notification

When A follows B, a `NewFollower` notification is created for B (in-DB + SignalR push).

### Public Profile with Follow Stats

`GET /api/users/{userId}/profile` returns:

```json
{
  "isFollowedByMe": true,
  "followerCount": 42,
  "followingCount": 17,
  "publishedProgramCount": 5,
  "connectionStatus": "Accepted",
  "coachingStatus": "None"
}
```

---

## Program Discovery (Following Feed)

`GET /api/feed/following?page=1&pageSize=20`

Returns published programs from users the caller follows. Only `public` visibility programs appear — following does not grant access to `connections` or `coach_only` programs.

### Program Discovery Metadata

Published programs can be tagged for discovery:

| Field | Column | Example |
|-------|--------|---------|
| `SportCategory` | `sport_category` | "Powerlifting", "Calisthenics" |
| `DifficultyLevel` | `difficulty_level` | "beginner", "intermediate", "advanced" |
| `EquipmentRequired` | `equipment_required` | "barbell,dumbbells" |
| `Tags` | `tags` | "strength,hypertrophy,4-day" |

Browse filters: `?sportCategory=`, `?difficulty=`, `?equipment=`, `?tag=`

---

## Frontend

`RelationshipsView.jsx` — two tabs:

**Sosyal Bağlantılar tab:**
- Search any user → send connection request
- Incoming requests → accept / reject
- Active connections → end + "View Profile" button
- Outgoing pending → withdraw

**UserProfileModal** (shared component): privacy-filtered profile, follow/unfollow button, follower/following/program counts, connection status badges.

`PublishedProgramsView.jsx`:
- "Discover" tab: browse all public programs, filter by difficulty/sport/equipment
- "Following" tab: feed from followed users
