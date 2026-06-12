# Development Phases

## Current State

**Phase 7 complete.** 53 EF Core migrations. All P0 features live in production.

---

## Phase Sequence

### Phase 0 — Project Bootstrap
- ASP.NET Core 10 + EF Core + PostgreSQL setup
- Docker Compose deployment
- JWT auth skeleton

### Phase 1 — Core Coaching MVP
- Trainer-athlete relationship lifecycle
- Program Builder (CRUD)
- Workout Mode (session + set logging)
- Exercise library seeding

### Phase 2 — Analytics & History
- RPE trend, volume trend
- Session history with filters
- Consistency grid + streak
- Personal records (UPSERT on complete)

### Phase 3 — Media Foundation
- Cloudflare R2 integration (`IMediaStorageProvider`)
- `MediaAsset` entity
- Avatar photo (upload + delete + proxy serve)
- Cover photo (upload + delete + proxy serve)
- `UserAvatar` component (photo → emoji → initials fallback)

### Phase 4 — Engagement & Social Discovery
- Follow / unfollow system
- Public programs (browse, like, save, fork)
- Program fork/copy with version tracking
- Today's workout widget (Dashboard)
- Athlete analytics screen
- `NewFollower` notification

### Phase 5 — Messaging & Notifications
- Direct messaging (with program references)
- Full notification center (all types, filter chips, retention)
- SignalR real-time push
- Program versioning + `ProgramUpdateAvailable`

### Phase 6 — Social Connections & UX Polish
- Social connections (`user_connections` table, bilateral accept/reject)
- Profile privacy settings (`profile_privacy_json`)
- Endpoint rename: `/api/relationships` → `/api/coaching`
- Multi-coach support (removed `athletes.trainer_id`)

### Phase 7 — Program Cover Photo
- `ProgramCoverPhoto` `MediaPurpose` enum value
- `cover_media_asset_id` FK on `published_programs`
- Upload/delete endpoints: `POST/DELETE /api/media/programs/published/{id}/cover`
- `CoverImageUrl` in `PublishedProgramDto` and `PublishedProgramDetailDto`
- ProgramCard cover banner + detail modal cover management

---

## Next Phases (Planned)

### Phase 8 — Progress Photos (P1)

Priority: high (next actionable P1 task)

| Task | Effort |
|------|--------|
| `ProgressPhoto` entity + migration | S |
| `POST /api/media/athletes/me/progress-photos` upload | M |
| Progress photo visibility toggle | S |
| ProfileView timeline (date-grouped grid) | M |
| Before/after comparison modal | M |
| Trainer access to shared photos | S |

### Phase 9 — Submission & Feedback Videos (P1)

Depends on: Phase 8 (media infra patterns)

| Task | Effort |
|------|--------|
| Athlete submission video (link to session/exercise) | M |
| Trainer feedback video | M |
| Audio feedback (record + playback) | M |
| Feedback read/viewed status | S |
| Trainer inbox for received submissions | M |

### Phase 10 — Mobile MVP (P3)

Depends on: Stable API, Phase 8–9 complete

| Task | Effort |
|------|--------|
| Expo project setup | S |
| Auth + secure token storage | M |
| Athlete Workout Mode | L |
| Offline session draft | M |
| Push notifications (FCM + APNs) | M |

### Phase 11 — Gym & Community (P2)

Depends on: Phase 9 or parallel

| Task | Effort |
|------|--------|
| Gym entity + membership | L |
| Gym coach permissions | M |
| Gym feed | L |
| Gym leaderboard | M |
| Global leaderboard | M |

### Phase 12 — AI (P3)

Depends on: Phase 11, standardized program schema

| Task | Effort |
|------|--------|
| AI program draft (OpenAI) | L |
| AI load progression suggestions | L |
| Trainer approval gate | M |

---

## Migration History Summary

| Phase | Key Migrations | Count |
|-------|---------------|-------|
| 0–1 | Initial schema, exercise, session, auth | 1–15 |
| 2 | Analytics, PRs, body metrics | 16–25 |
| 3 | MediaAsset, avatar, cover | 26–35 |
| 4 | Follow, published programs, fork | 36–44 |
| 5 | Messages, notifications, versioning | 45–48 |
| 6 | Connections, privacy, coaching rename | 49–52 |
| 7 | ProgramCoverPhoto | 53 |

Full list: [database/migration-strategy.md](../database/migration-strategy.md)

---

## Effort Legend

| Label | Meaning |
|-------|---------|
| S | Small — 1–3 hours |
| M | Medium — half to one day |
| L | Large — 1–3 days |
| XL | Extra large — 1+ week |
