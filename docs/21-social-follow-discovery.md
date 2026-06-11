# Social Follow & Program Discovery (Phase 3)

## Overview

Phase 3 extends TrackMe from a pure coaching tool into a social fitness network with program discovery. It introduces a **unilateral follow system** and **program discovery metadata** without breaking existing coaching, privacy, or versioning systems.

---

## Follow System vs Social Connections vs Coaching

| Concept | Table | Relationship | Effect on Privacy |
|---------|-------|-------------|------------------|
| **Follow** | `user_follows` | Unilateral: A→B (B doesn't need to follow back) | **None** — following does NOT open private or coach_only fields |
| **Social Connection** | `user_connections` | Bilateral: must be accepted by both parties | Opens `connections` visibility level |
| **Coaching** | `trainer_athlete_relationships` | Accepted coach-athlete pair | Opens `coach_only` visibility level |

**Key rule:** Following someone gives you their public feed only. To see their `connections` or `coach_only` content, a social connection or coaching relationship must exist. This is intentional and enforced in all endpoints.

---

## Follow Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/users/{userId}/follow` | Follow a user (idempotent-safe: returns 409 if already following) |
| `DELETE` | `/api/users/{userId}/follow` | Unfollow a user |
| `GET` | `/api/users/{userId}/followers` | Paginated list of this user's followers |
| `GET` | `/api/users/{userId}/following` | Paginated list of users this user follows |

All require authentication. Self-follow returns 400.

---

## Profile Social Fields

`GET /api/users/{userId}/profile` now includes:

```json
{
  "isFollowedByMe": true,
  "followerCount": 42,
  "followingCount": 17,
  "publishedProgramCount": 5
}
```

---

## Program Discovery Metadata

`published_programs` now has 4 optional discovery fields:

| Field | Column | Example values |
|-------|--------|----------------|
| `SportCategory` | `sport_category` | "Powerlifting", "Calisthenics", "Running" |
| `DifficultyLevel` | `difficulty_level` | "beginner", "intermediate", "advanced" |
| `EquipmentRequired` | `equipment_required` | "barbell,dumbbells" (comma-separated) |
| `Tags` | `tags` | "strength,hypertrophy,4-day" (comma-separated) |

Set when publishing or updating via `PublishProgramRequest`.

### Browse Filters

`GET /api/published-programs` now accepts:

| Query param | Matches |
|-------------|---------|
| `sportCategory` | Case-insensitive substring match on sport_category |
| `difficulty` | Case-insensitive exact match on difficulty_level |
| `equipment` | Case-insensitive substring match in equipment_required |
| `tag` | Case-insensitive substring match in tags |

---

## Following Feed

`GET /api/feed/following?page=1&pageSize=20`

Returns published programs from users the caller follows. Only shows `public` visibility programs (following does not grant access to connections/coach_only programs). Ordered by newest first.

---

## Frontend

- **UserProfileModal**: Shows follower/following/published program counts; Follow/Unfollow button (hidden for self).
- **PublishedProgramsView**: Two tabs — "Discover" (existing browse + new filters) and "Following" feed. Discovery filter chips include difficulty (Beginner/Intermediate/Advanced). Program cards show sport category, difficulty, equipment badges.
- **ProgramBuilderView**: Publish modal has sport category, difficulty (dropdown), equipment (comma-separated), tags fields.

---

## Database

Migration: `Phase3_UserFollows_ProgramMetadata` (migration #50)

- Drops `program_followers` (was future-infra placeholder, never had data)
- Creates `user_follows` with unique composite index on `(follower_user_id, followed_user_id)`
- Adds `sport_category`, `difficulty_level`, `equipment_required`, `tags` to `published_programs`
