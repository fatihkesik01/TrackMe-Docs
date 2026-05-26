# Phase 1 — Foundation & Core Workflows

Phase 1 covers Days 1–7 of TrackMe development.

Goal: deploy a fully authenticated, role-controlled backend with trainer-athlete management,
exercise library, workout programs, session tracking, set-level logging, and basic analytics.

---

## Deployment

| Service    | URL                                      |
|------------|------------------------------------------|
| API        | `http://187.77.92.30:5050`               |
| Web        | `http://187.77.92.30:8080`               |
| Scalar     | `http://187.77.92.30:5050/scalar/v1`     |
| PostgreSQL | Docker internal + SSH tunnel `127.0.0.1:15432` |

CI/CD: GitHub Actions auto-deploys API and Web on push to `main`.
Startup migration: `db.Database.MigrateAsync()` on app boot.

---

## Database Migrations

| # | Migration | Tables Created / Changed |
|---|-----------|--------------------------|
| 1 | `InitialCreate` | `trainers`, `athletes`, `workout_programs`, `workout_sessions` |
| 2 | `AddIdentityFoundation` | `users`, `refresh_tokens` |
| 3 | `AllowSelfGuidedPrograms` | `trainer_id` nullable on `workout_programs` |
| 4 | `AddTrainerAthleteRelationships` | `trainer_athlete_relationships` |
| 5 | `AddExerciseLibrary` | `exercises` |
| 6 | `AddSessionExerciseTracking` | `workout_session_exercises`, `workout_set_logs` |

---

## API Endpoints

### Auth (public)
| Method | Path | Notes |
|--------|------|-------|
| POST | `/api/auth/register` | Creates user + auto-creates Trainer/Athlete profile |
| POST | `/api/auth/login` | Returns access token + 30-day refresh token |
| POST | `/api/auth/refresh` | Token rotation; revokes old refresh token |
| POST | `/api/auth/logout` | Revokes refresh token server-side |

### Auth (requires JWT)
| Method | Path | Notes |
|--------|------|-------|
| GET | `/api/auth/me` | Returns current user + profileId |

### Dashboard
| Method | Path | Notes |
|--------|------|-------|
| GET | `/api/dashboard` | Total athletes, trainers, programs, 7d sessions, avg RPE |

### Trainers
| Method | Path | Role | Notes |
|--------|------|------|-------|
| GET | `/api/trainers` | All | All trainer list |
| POST | `/api/trainers` | Admin | Create trainer profile directly |
| GET | `/api/trainers/me/athletes` | Trainer | Accepted athletes only |

### Athletes
| Method | Path | Role | Notes |
|--------|------|------|-------|
| GET | `/api/athletes` | Admin/Trainer: all · Athlete: own only | Role-filtered list |
| POST | `/api/athletes` | Admin/Trainer | Create athlete; trainer auto-assigns self |

### Relationships
| Method | Path | Role | Notes |
|--------|------|------|-------|
| POST | `/api/relationships/requests` | Trainer | Send access request to athlete |
| GET | `/api/relationships/requests` | All | Scoped by role |
| POST | `/api/relationships/{id}/accept` | Athlete | Accept pending request |
| POST | `/api/relationships/{id}/reject` | Athlete | Reject pending request |

### Exercises
| Method | Path | Role | Notes |
|--------|------|------|-------|
| GET | `/api/exercises` | All | Active exercises only |
| GET | `/api/exercises/{id}` | All | Single active exercise |
| POST | `/api/exercises` | Admin/Trainer | Slug auto-generated |
| PUT | `/api/exercises/{id}` | Admin/Trainer | Full update |
| DELETE | `/api/exercises/{id}` | Admin/Trainer | Soft delete (sets `is_active = false`) |

### Workout Programs
| Method | Path | Role | Notes |
|--------|------|------|-------|
| GET | `/api/programs` | All | Role-scoped list |
| POST | `/api/programs` | All | Trainer: accepted athletes only · Athlete: self-guided only |

### Workout Sessions
| Method | Path | Role | Notes |
|--------|------|------|-------|
| GET | `/api/sessions` | All | Role-scoped list |
| POST | `/api/sessions` | All | Creates simple session (title, duration, RPE) |
| GET | `/api/sessions/{sessionId}/exercises` | All | List exercises in a session |
| POST | `/api/sessions/{sessionId}/exercises` | All | Add exercise to session |
| POST | `/api/sessions/{sessionId}/exercises/{exerciseId}/sets` | All | Log a set (reps, weight, RPE) |

### Analytics
| Method | Path | Role | Notes |
|--------|------|------|-------|
| GET | `/api/analytics/athletes/{athleteId}/overview` | All | Total/weekly/monthly sessions, avg RPE, total duration, latest session |

---

## Security & Infrastructure

| Item | Status | Notes |
|------|--------|-------|
| JWT Bearer auth | ✅ | HMAC-SHA256, 2h access token |
| Refresh token rotation | ✅ | 30-day, SHA256 hashed in DB |
| PBKDF2-SHA256 passwords | ✅ | 100k iterations |
| Role-based authorization | ✅ | Admin / Trainer / Athlete |
| Email validation | ✅ | `MailAddress` RFC parse + 254 char limit |
| Global exception handler | ✅ | JSON 500 with traceId |
| Startup auto-migration | ✅ | `MigrateAsync` on boot |
| CORS configured | ✅ | Web origin + localhost |
| Scalar API docs | ✅ | `/scalar/v1` |
| Pagination | ❌ | Deferred to Phase 2 |
| Rate limiting | ❌ | Deferred to Phase 2 |
| Response envelope | ❌ | Deferred to Phase 2 |
| Soft delete (all entities) | ❌ | Only Exercise has it; others deferred |

---

## Completed ✅

### Infrastructure & Auth
- [x] Users table + role enum (Admin, Trainer, Athlete)
- [x] PBKDF2 password hashing
- [x] JWT generation service with profile_id claim
- [x] Auto-create Trainer/Athlete profile on register
- [x] POST /api/auth/register, login, me
- [x] Refresh token entity + rotation endpoint
- [x] Logout (server-side revocation)
- [x] Global exception handler middleware
- [x] Startup auto-migration

### Trainer-Athlete Management
- [x] TrainerAthleteRelationship entity (Pending / Accepted / Rejected)
- [x] Unique index trainer_id + athlete_id
- [x] Request / accept / reject endpoints
- [x] Trainer sees only accepted athletes in /trainers/me/athletes
- [x] Program and session ownership checks use accepted relationships
- [x] Role-filtered GET /api/athletes (Athlete: own only)
- [x] Admin-only POST /api/trainers

### Exercise Library
- [x] Exercise entity (name, slug, category, muscles, equipment, instructions, is_active)
- [x] Slug auto-generation + uniqueness enforcement
- [x] Full CRUD: GET list, GET by id, POST, PUT, DELETE (soft)
- [x] Admin/Trainer write; Athlete read-only

### Workout Programs
- [x] WorkoutProgram entity (title, description, starts_on, ends_on, trainer_id nullable)
- [x] Self-guided programs (trainerId = null)
- [x] Trainer can create programs for accepted athletes only
- [x] Athlete can create self-guided programs for own profile only

### Workout Sessions
- [x] WorkoutSession entity (title, notes, completed_at, duration_minutes, rpe)
- [x] Sessions optionally linked to programs
- [x] Role-scoped session list
- [x] Trainer accesses athlete sessions via accepted relationship
- [x] WorkoutSessionExercise entity (session ← exercise, order_index, notes)
- [x] WorkoutSetLog entity (reps, weight_kg, rpe, is_completed, notes)
- [x] GET/POST /api/sessions/{id}/exercises
- [x] POST /api/sessions/{id}/exercises/{exId}/sets

### Analytics
- [x] GET /api/analytics/athletes/{athleteId}/overview
  - Total sessions
  - Weekly sessions (last 7 days)
  - Monthly sessions (last 30 days)
  - Average RPE
  - Total duration (minutes)
  - Latest session summary

### Web
- [x] Login + register UI
- [x] JWT stored in localStorage
- [x] Auth state boot from stored token
- [x] Dashboard stats (athletes, programs, 7d sessions, avg RPE)
- [x] Athlete create form
- [x] Program builder form
- [x] Session log form
- [x] Relationship request + accept/reject UI
- [x] Exercise library list + create form
- [x] Trainer athlete selector (accepted only)
- [x] Role-aware UI (canManageExercises, trainerProfileId, etc.)
- [x] api.js: refresh(), logout(), athleteAnalytics(), sessionExercises(), addSessionExercise(), addSetLog()
- [x] Logout calls api.logout() for server-side token revocation

---

## Pending ⏳ (Phase 1 Remaining Work)

### API
- [ ] `GET /api/programs/{id}` — program detail with day and exercise structure
- [ ] `WorkoutProgramDay` entity — structured day inside a program
- [ ] `WorkoutProgramExercise` entity — planned exercise inside a day (sets, reps, target RPE, rest)
- [ ] EF migration for program structure
- [ ] POST /api/programs/{id}/days
- [ ] POST /api/programs/{id}/days/{dayId}/exercises
- [ ] GET /api/sessions/{id} — single session detail with exercises and sets
- [ ] PUT /api/sessions/{id}/exercises/{exId}/sets/{setId} — update a logged set
- [ ] DELETE /api/sessions/{id}/exercises/{exId} — remove exercise from session

### Web UI
- [ ] Analytics display panel (weekly sessions, avg RPE, total duration, latest session)
- [ ] Session detail view (exercise list + set rows)
- [ ] Program detail view (day list + planned exercises)
- [ ] Add exercise to session (selector + inline set rows)

### Verification
- [ ] Confirm GitHub Actions deploy succeeds after Phase 1 push
- [ ] Verify all 6 migrations in `__EFMigrationsHistory` via DBeaver
- [ ] Verify `workout_session_exercises` and `workout_set_logs` tables in DBeaver
- [ ] Verify analytics endpoint returns correct data against test sessions
- [ ] Verify browser UI: login, register, session log, relationship flow

---

## Known Risks & Deferred Items

| Item | Risk | Decision |
|------|------|----------|
| Access token in localStorage | XSS exposure | Acceptable for internal MVP; revisit before public launch |
| No pagination on list endpoints | Performance at scale | Defer to Phase 2 |
| No rate limiting | Brute-force on login | Defer to Phase 2 |
| No response envelope | Inconsistent API shape | Defer to Phase 2 |
| Soft delete only on Exercise | Data loss possible on deletes | Defer to Phase 2 |
| Single Program.cs (1700+ lines) | Maintainability | Refactor to layered structure in Phase 2 |
| Rejected relationships are permanent | No re-request possible | Lifecycle expansion in Phase 2 |
| RefreshToken cleanup job | Table grows without pruning | Background job in Phase 2 |

---

## Phase 2 Starting Point

Phase 2 begins after Phase 1 remaining work is complete.

### Phase 2 Priorities

1. **Program structure** — complete WorkoutProgramDay + WorkoutProgramExercise (carries over from Phase 1 pending)
2. **Pagination** — cursor or offset on all list endpoints
3. **Rate limiting** — login endpoint at minimum
4. **Notification system** — in-app notifications (trainer invites, session reminders)
5. **Advanced analytics** — per-exercise trend, RPE trend, volume load chart data
6. **Mobile app** — React Native skeleton: auth, session log, trainer-athlete flow
7. **Admin panel** — user management, system stats, exercise management
8. **Program templates** — trainer creates reusable program templates
9. **Code architecture** — refactor Program.cs into layered structure (Application/Domain/Infrastructure)
10. **Refresh token cleanup** — background job to prune expired tokens
11. **User profile update** — PATCH /api/auth/profile (name, goal)
12. **Password change** — POST /api/auth/change-password
