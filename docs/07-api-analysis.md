# API Route Reference

Base URL: `http://187.77.92.30:5050`

All endpoints under `/api/` require JWT Bearer authentication unless marked as public.

---

## Health

| Method | Path          | Auth | Description                            |
|--------|--------------|------|----------------------------------------|
| GET    | /health       | Public | Basic health ping                   |
| GET    | /api/health   | Public | Detailed health with DB latency, uptime |

---

## Auth (`/api/auth`)

| Method | Path                       | Auth     | Rate limit | Description                              |
|--------|---------------------------|----------|------------|------------------------------------------|
| POST   | /api/auth/register         | Public   |            | Register new user, returns auth response |
| POST   | /api/auth/login            | Public   | 10/min/IP  | Login, returns auth response             |
| GET    | /api/auth/me               | Required |            | Returns current user from DB (includes `preferredUiRole`) |
| POST   | /api/auth/refresh          | Public   |            | Rotate refresh token, returns new auth   |
| POST   | /api/auth/logout           | Public   |            | Revoke refresh token                     |
| POST   | /api/auth/forgot-password  | Public   |            | Generate reset token (dev: returned)     |
| POST   | /api/auth/reset-password   | Public   |            | Reset password with token                |
| PATCH  | /api/auth/profile          | Required |            | Update full_name, bio, goal              |
| PATCH  | /api/auth/preferred-role   | Required |            | Set preferred UI role (Athlete/Trainer)  |
| POST   | /api/auth/change-password  | Required |            | Change password, revokes all sessions    |

### Register request
```json
{ "fullName": "Ali Yılmaz", "email": "ali@example.com", "password": "secret123", "role": "Athlete" }
```

### Auth response (login / register / refresh)
```json
{
  "accessToken": "eyJ...",
  "accessExpiresAt": "2026-05-28T16:00:00Z",
  "refreshToken": "raw-token-string",
  "refreshExpiresAt": "2026-06-27T14:00:00Z",
  "user": { "id": "...", "profileId": "...", "fullName": "Ali Yılmaz", "email": "ali@example.com", "role": "Athlete" }
}
```

---

## Users (`/api/users`)

| Method | Path                   | Auth     | Description                    |
|--------|------------------------|----------|--------------------------------|
| GET    | /api/users/search      | Required | Search users by name or email  |

---

## Trainers (`/api/trainers`)

| Method | Path                      | Auth            | Description                             |
|--------|--------------------------|-----------------|---------------------------------------------|
| GET    | /api/trainers             | Required        | List trainers (Admin sees all, others see relevant) |
| GET    | /api/trainers/search      | Required        | Search trainers by name or email        |
| GET    | /api/trainers/me/athletes | Required        | List accepted athletes for current trainer |
| GET    | /api/trainers/candidates  | Required        | Trainer candidate search with relationship status |

---

## Athletes (`/api/athletes`)

| Method | Path                  | Auth     | Description                                       |
|--------|-----------------------|----------|---------------------------------------------------|
| GET    | /api/athletes         | Required | List athletes (Trainer = accepted; Admin = all)   |
| POST   | /api/athletes         | Required | Create athlete profile                             |
| GET    | /api/athletes/search  | Required | Search athletes by name or email                   |
| GET    | /api/athletes/{id}    | Required | Get one athlete by ID                             |

---

## Relationships (`/api/relationships`)

| Method | Path                              | Auth     | Description                                         |
|--------|-----------------------------------|----------|-----------------------------------------------------|
| POST   | /api/relationships/requests       | Required | Trainer sends access request to athlete (by id or email) |
| POST   | /api/relationships/invite         | Required | Athlete invites trainer to coach them (by id or email) |
| GET    | /api/relationships/requests       | Required | List relationships for current user (paginated)     |
| POST   | /api/relationships/{id}/accept    | Required | Accept a pending request (recipient only)           |
| POST   | /api/relationships/{id}/reject    | Required | Reject a pending request (recipient only)           |

### Trainer sends request to athlete
```json
{ "athleteId": "guid", "email": "athlete@example.com" }
```
Either `athleteId` or `email` is required. If `email` is provided, auto-creates an athlete entity for that user.

### Athlete invites trainer
```json
{ "trainerId": "guid", "email": "trainer@example.com" }
```
Either `trainerId` or `email` is required.

### RelationshipDto
```json
{
  "id": "...",
  "trainerId": "...", "trainerName": "...", "trainerEmail": "...",
  "athleteId": "...", "athleteName": "...", "athleteEmail": "...",
  "status": "Pending",
  "initiatedByAthlete": false,
  "createdAt": "...", "respondedAt": null
}
```

**canRespond rule:**
- `initiatedByAthlete = true` → only the trainer can accept/reject
- `initiatedByAthlete = false` → only the athlete can accept/reject

---

## Exercises (`/api/exercises`)

| Method | Path                   | Auth     | Description                                          |
|--------|------------------------|----------|------------------------------------------------------|
| GET    | /api/exercises         | Required | List active exercises (global + caller's private)    |
| GET    | /api/exercises/{id}    | Required | Get one exercise                                     |
| POST   | /api/exercises         | Required | Create private exercise (any role); Admin creates global |
| PUT    | /api/exercises/{id}    | Required | Update exercise (owner or Admin)                     |
| DELETE | /api/exercises/{id}    | Required | Soft-delete exercise (owner or Admin)                |

**Query parameters for `GET /api/exercises`:**

| Param       | Example           | Notes                               |
|-------------|-------------------|-------------------------------------|
| `search`    | `?search=squat`   | Searches name, category, primaryMuscles |
| `category`  | `?category=Chest` | Exact match on category field       |
| `difficulty`| `?difficulty=Hard`| Exact match: Easy / Medium / Hard   |
| `page`      | `?page=1`         | default 1                           |
| `pageSize`  | `?pageSize=200`   | default 20, max 200                 |

### ExerciseDto
```json
{
  "id": "...",
  "name": "Bench Press",
  "slug": "bench-press",
  "category": "Chest",
  "primaryMuscles": "Chest, Triceps, Front Delts",
  "equipment": "Barbell",
  "difficulty": "Medium",
  "instructions": null,
  "isActive": true,
  "isGlobal": true,
  "ownerId": null,
  "ownerName": null,
  "createdAt": "..."
}
```

### Create/Update exercise request
```json
{
  "name": "My Exercise",
  "category": "Arms",
  "primaryMuscles": "Biceps",
  "equipment": "Dumbbell",
  "difficulty": "Easy",
  "instructions": "Curl to shoulder height"
}
```

---

## Programs (`/api/programs`)

| Method | Path                                                       | Auth     | Description                            |
|--------|------------------------------------------------------------|----------|----------------------------------------|
| GET    | /api/programs                                              | Required | List programs (paginated, role-scoped) |
| POST   | /api/programs                                              | Required | Create program for an athlete          |
| GET    | /api/programs/{id}                                         | Required | Get full program with days + exercises |
| DELETE | /api/programs/{id}                                         | Required | Delete program                         |
| POST   | /api/programs/{id}/days                                    | Required | Add a day to the program               |
| PUT    | /api/programs/{id}/days/{dayId}                            | Required | Update day title/notes                 |
| DELETE | /api/programs/{id}/days/{dayId}                            | Required | Remove a day                           |
| POST   | /api/programs/{id}/days/{dayId}/exercises                  | Required | Add exercise to day                    |
| PUT    | /api/programs/{id}/days/{dayId}/exercises/{exerciseId}     | Required | Update exercise parameters             |
| DELETE | /api/programs/{id}/days/{dayId}/exercises/{exerciseId}     | Required | Remove exercise from day               |

### Create program request
```json
{
  "trainerId": null,
  "athleteId": "guid",
  "title": "Güç Programı",
  "description": "12 haftalık güç programı",
  "startsOn": "2026-06-01T00:00:00Z",
  "endsOn": "2026-08-24T00:00:00Z",
  "templateId": null
}
```

**Access rules:**
- Trainer JWT: can create programs for their accepted athletes
- Athlete JWT: can create self-guided programs for themselves; if acting as trainer (via uiRole), can create for their athletes via email lookup
- Admin: no restrictions

**Write access rules for days and exercises (Phase 16):**
- Trainers can edit any program they own (`trainerId == callerProfileId`)
- Athletes can only edit programs where `trainerId IS NULL` (self-guided); trainer-created programs return 403
- Dual-role Athlete-JWT acting as trainer: resolved by email match against trainer entity

---

## Sessions (`/api/sessions`)

| Method | Path                                                          | Auth     | Description                                    |
|--------|---------------------------------------------------------------|----------|------------------------------------------------|
| GET    | /api/sessions                                                 | Required | List sessions (paginated, role-scoped, filterable by date) |
| POST   | /api/sessions                                                 | Required | Create completed session manually              |
| POST   | /api/sessions/start                                           | Required | Start an in-progress session (WorkoutMode)     |
| GET    | /api/sessions/{id}                                            | Required | Get session detail with exercises + sets       |
| POST   | /api/sessions/{id}/complete                                   | Required | Complete an in-progress session                |
| GET    | /api/sessions/{sessionId}/exercises                           | Required | List exercises for a session                   |
| POST   | /api/sessions/{sessionId}/exercises                           | Required | Add exercise to session                        |
| PATCH  | /api/sessions/{sessionId}/exercises/{exerciseId}/feeling      | Required | Mark exercise complete + feeling rating        |
| POST   | /api/sessions/{sessionId}/exercises/{exerciseId}/sets         | Required | Log a set                                      |
| PUT    | /api/sessions/{sessionId}/exercises/{exerciseId}/sets/{setId} | Required | Update a set                                   |
| DELETE | /api/sessions/{sessionId}/exercises/{exerciseId}              | Required | Remove exercise from session                   |
| PATCH  | /api/sessions/{sessionId}/exercises/{exerciseId}/review       | Required | Trainer writes a note on exercise              |

### Start session (WorkoutMode)
```json
{ "athleteId": "guid", "programId": "guid", "programDayId": "guid", "title": "Gün 1 - Bacak" }
```
Pre-populates exercises from the program day. Returns full session detail DTO.

### Complete session
```json
{ "durationMinutes": 65, "rpe": 7, "notes": "İyi bir antrenman" }
```

---

## Analytics (`/api/analytics`)

| Method | Path                                                              | Auth     | Description                                  |
|--------|-------------------------------------------------------------------|----------|----------------------------------------------|
| GET    | /api/dashboard                                                    | Required | System-wide stats (admin/public summary)     |
| GET    | /api/analytics/athletes/{athleteId}/overview                      | Required | Athlete session stats (total, weekly, monthly, avg RPE) |
| GET    | /api/analytics/athletes/{athleteId}/rpe-trend                     | Required | Daily average RPE over `?days=30`            |
| GET    | /api/analytics/athletes/{athleteId}/volume                        | Required | Daily total volume (kg) over `?days=30`      |
| GET    | /api/analytics/athletes/{athleteId}/exercise/{exerciseId}/progress| Required | Per-set weight/reps/RPE history              |
| GET    | /api/analytics/athletes/{athleteId}/consistency                   | Required | Session counts and current streak            |
| GET    | /api/analytics/athletes/{athleteId}/sessions-by-month             | Required | Monthly session counts over `?months=12`     |
| GET    | /api/analytics/athletes/{athleteId}/body-trend                    | Required | Body metric trend over `?days=90`            |
| GET    | /api/analytics/athletes/{athleteId}/exercises/{exerciseId}/last-performance | Required | Last logged sets + plannedSets/plannedReps/plannedWeightKg for planned vs actual comparison |
| GET    | /api/analytics/trainers/me/overview                               | Required | Trainer overview: athlete count, active programs, weekly sessions, avg RPE |
| GET    | /api/programs/{programId}/compliance                              | Required | Program completion rate per day              |

All analytics endpoints validate access: Athlete sees own data; Trainer sees data for accepted athletes; Admin sees all.

---

## Body Metrics (`/api/body-metrics`)

| Method | Path                         | Auth     | Description                                       |
|--------|------------------------------|----------|---------------------------------------------------|
| POST   | /api/body-metrics            | Required | Log measurement (athlete's own profile resolved by JWT) |
| GET    | /api/body-metrics/me         | Required | Resolve caller's athleteId (for frontend role-independence) |
| GET    | /api/body-metrics/{athleteId}| Required | List measurements for an athlete (paginated)      |
| DELETE | /api/body-metrics/{id}       | Required | Delete a measurement                              |

### Create body metric
```json
{
  "date": "2026-05-28",
  "weightKg": 82.5,
  "bodyFatPct": 18.2,
  "musclePct": 42.1,
  "heightCm": 178,
  "waistCm": 84,
  "chestCm": 102,
  "armsCm": 36,
  "legsCm": 58,
  "hipsCm": 98,
  "notes": "Sabah aç karnına"
}
```
At least one measurement field required.

---

## Notifications (`/api/notifications`)

| Method | Path                          | Auth     | Description                         |
|--------|-------------------------------|----------|-------------------------------------|
| GET    | /api/notifications            | Required | List notifications for current user |
| PATCH  | /api/notifications/{id}/read  | Required | Mark one notification as read       |
| POST   | /api/notifications/read-all   | Required | Mark all notifications as read      |

### Notification types
- `RelationshipRequest` — new trainer/athlete connection request
- `RelationshipAccepted` — a pending request was accepted
- `ProgramAssigned` — a new program was created for the athlete

---

## Admin (`/api/admin`)

| Method | Path                       | Auth           | Description                     |
|--------|----------------------------|----------------|---------------------------------|
| GET    | /api/admin/stats           | Admin only     | System-wide stats               |
| GET    | /api/admin/users           | Admin only     | List all users (paginated)      |
| PUT    | /api/admin/users/{id}      | Admin only     | Update user fullName, role, isActive |
| GET    | /api/admin/exercises       | Admin only     | List all exercises including inactive |
| DELETE | /api/admin/exercises/{id}  | Admin only     | Hard-delete an exercise         |

---

## Authorization Matrix

| Endpoint group    | Admin | Trainer            | Athlete                                   |
|-------------------|-------|--------------------|-------------------------------------------|
| Auth              | ✓     | ✓                  | ✓                                         |
| Users             | ✓     | Own user           | Own user                                  |
| Trainers          | ✓     | Self               | Can invite any trainer                    |
| Athletes          | ✓ (all) | Accepted athletes | Own profile only                        |
| Relationships     | ✓ (all) | Own relationships | Own relationships                        |
| Exercises         | ✓     | Read + own private | Read + own private                       |
| Programs          | ✓     | Own + accepted athletes' | Own athlete profile only          |
| Sessions          | ✓     | Accepted athletes' | Own athlete sessions                     |
| Analytics         | ✓     | Accepted athletes' | Own analytics                            |
| Body metrics      | ✗     | Own + accepted athletes' | Own profile                        |
| Notifications     | ✓     | Own               | Own                                        |
| Admin             | ✓     | ✗                  | ✗                                         |
