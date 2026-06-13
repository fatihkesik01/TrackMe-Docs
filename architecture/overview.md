# System Architecture Overview

## Stack

```
Browser / Mobile App
       │   React 18 + Vite SPA (Web)
       │   React Native (Mobile — planned)
       │   HTTP + JWT Bearer
       ▼
ASP.NET Core 10 Minimal API  (:5050 / :8080 internal)
       │   EF Core 10 + Npgsql
       │   SignalR (real-time notifications)
       ▼
PostgreSQL 16                (:5432 internal / :15432 SSH tunnel)
       │
Cloudflare R2                (media storage — S3-compatible)
```

## Deployment

Hostinger VPS, Docker Compose. Three containers on a shared Docker network:

| Container | Image | Internal Port | Host Port |
|-----------|-------|--------------|-----------|
| `trackme-web` | nginx + built SPA | 80 | 8080 |
| `trackme-api` | ASP.NET Core 10 | 8080 | 5050 |
| `trackme-postgres` | postgres:16-alpine | 5432 | 127.0.0.1:15432 |

The Web container proxies `/api/` and `/hubs/` to the API on the shared Docker network.

### Live URLs

| Resource | URL |
|----------|-----|
| Web App | http://187.77.92.30:8080 |
| API | http://187.77.92.30:5050 |
| Health check | http://187.77.92.30:5050/health |
| Scalar API docs | http://187.77.92.30:5050/scalar/v1 |
| OpenAPI JSON | http://187.77.92.30:5050/openapi/v1.json |

## API Startup Sequence

1. `db.Database.MigrateAsync()` — applies all pending EF Core migrations (up to 10 retries, 3s apart)
2. `ExerciseSeeder.SeedAsync(db)` — seeds global exercise library if table is empty
3. `FoodItemSeeder.SeedAsync(db)` — seeds the global Turkish food library when no global foods exist
4. `RefreshTokenCleanupService` starts — background service, purges expired/revoked refresh tokens every 24 h
5. `OrphanMediaCleanupService` starts — background service, soft-deletes and removes from R2 any `MediaAsset` rows not referenced by any entity (avatar, cover, progress photo, submission, feedback, exercise demo), with a 1-hour grace period; runs every 24 h
6. `MissedActivityAlertService` starts — after a 10-minute startup delay, checks accepted coaching pairs every 24 h and sends suppressed missed-workout/missed-nutrition notifications through the database and SignalR

## Core Roles & Navigation

| Role | Primary Views |
|------|--------------|
| **Admin** | Dashboard, Athletes, Sessions, Exercises, Admin panel |
| **Trainer** | Dashboard, My Athletes, My Programs, Exercises, Relationships, Profile |
| **Athlete** | Dashboard, My Program, Sessions, Analytics, Nutrition, Body Metrics, Progress Photos, Video Submissions, Relationships, Profile |

### Dual-Role User

A single account can operate as both Trainer and Athlete:
- JWT role is fixed at registration
- `users.preferred_ui_role` stores the active context (`"Trainer"` / `"Athlete"`)
- Backend resolves trainer entity by **email lookup** on any trainer-scoped operation
- Frontend toggles context via `uiRole` — shows confirm dialog, calls `PATCH /api/auth/preferred-role`

## Key Flows

### Program Flow
```
Trainer → Athlete Detail → Programs tab
→ Create Program → Program Builder (days → exercises → sets)
→ Athlete sees program in "Programım"
→ Athlete starts day → WorkoutMode overlay
→ Session recorded → analytics updated
```

### Coaching Relationship Flow
```
Trainer searches athlete OR athlete searches trainer
→ Send request (Pending)
→ Recipient accepts (Accepted) or rejects (Rejected)
→ Accepted: coaching access granted, programs become visible, messaging enabled
→ End: programs locked (not deleted), coaching access removed
```

### Session Flow
```
Athlete selects Program Day → Start Workout
→ WorkoutMode overlay
→ Log sets: reps + weight + RPE (warm-up sets excluded from analytics)
→ Complete → session saved, PRs auto-upserted, analytics updated
→ Completion summary shows duration/volume/new PRs
```

## Data Ownership (Athlete-Centric)

- Programs belong to an athlete (`athlete_id` FK required, `trainer_id` FK optional)
- Sessions, body metrics, nutrition goals, nutrition logs, meals, meal entries, and PRs belong to an athlete
- A trainer accesses athlete data only through an accepted `trainer_athlete_relationships` record
- Social connections grant messaging + privacy-filtered profile only — never coaching data

## Feature Status

| Feature | Status |
|---------|--------|
| Auth (JWT + refresh tokens) | ✅ Live |
| Trainer-Athlete relationships | ✅ Live |
| Social connections + follow | ✅ Live |
| Program builder + templates | ✅ Live |
| Program versioning | ✅ Live |
| Public programs (browse, like, save, fork) | ✅ Live |
| Workout Mode (set-by-set logging) | ✅ Live |
| Session history + filtering | ✅ Live |
| Analytics (RPE, volume, consistency, PRs) | ✅ Live |
| Body metrics (9 fields) | ✅ Live |
| Exercise library (141+ exercises) | ✅ Live |
| Exercise demo videos (library, picker, WorkoutMode) | ✅ Live |
| In-app notifications + SignalR realtime | ✅ Live |
| Direct messaging (with program refs) | ✅ Live |
| Media: avatar + cover photo + program cover | ✅ Live |
| Progress photos (upload, timeline, before/after, trainer view) | ✅ Live |
| Nutrition tracking MVP (goals, daily logs, adherence) | ✅ Live |
| Nutrition meals (food search, meal cards, trainer view) | ✅ Live |
| Missed workout and nutrition alerts | ✅ Live |
| Admin panel | ✅ Live |
| Dark mode + i18n (TR/EN) | ✅ Live |
| Submission/feedback videos | ✅ Live |
| Orphan media asset cleanup (background GC) | ✅ Live |
| Admin audit log (action history, IP tracking) | ✅ Live |
| Mobile app (React Native) | 🔲 Planned |
| Gym system + leaderboard | 🔲 Planned |
| AI coaching suggestions | 🔲 Planned |
