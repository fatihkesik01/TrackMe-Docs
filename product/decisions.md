# Key Product & Architecture Decisions

Decisions are recorded here when they are non-obvious, constrain future work, or reflect a deliberate tradeoff. Day-to-day implementation details belong in feature docs.

---

## Coaching Relationship as Access Gate

**Decision:** An accepted `trainer_athlete_relationships` record is the single gate for coaching data access. Social connections grant only messaging and privacy-filtered profile viewing.

**Why:** Prevents accidental data exposure. A trainer cannot see an athlete's sessions, analytics, body metrics, or programs through a social follow or connection alone. The access boundary is unambiguous.

**Implication:** Any future "training groups" or "gym coaching" feature must define its own relationship primitive — it cannot reuse social connections.

---

## Single MediaAsset Model

**Decision:** Every binary file (avatar, cover, progress photo, submission video, feedback video, exercise demo) flows through one `MediaAsset` entity with a `MediaPurpose` enum.

**Why:** Unified ownership, visibility, lifecycle, and storage path. One `IMediaStorageProvider` interface works for all media types. Eliminates per-type storage tables.

**Implication:** Adding a new media type = add enum value + upload endpoint + purpose check in content delivery. No new tables.

---

## Cloudflare R2 over AWS S3

**Decision:** Cloudflare R2 for production object storage.

**Why:** No egress fees. Cost advantage at scale. S3-compatible API allows reuse of `AWSSDK.S3`.

**Known issue:** R2 does not support chunked transfer encoding → all SDK calls must set `UseChunkEncoding = false`.

---

## Dual-Role User via Email Lookup

**Decision:** A user account can have both a Trainer entity and an Athlete entity. The JWT role is fixed at registration. Backend resolves the trainer entity by `email` lookup on all trainer-scoped operations.

**Why:** Avoids account duplication for trainer-athletes. The JWT is not re-issued when the user switches context — `users.preferred_ui_role` stores the current view mode.

**Implication:** Any trainer-scoped endpoint must handle both `Trainer` JWT (profileId in claim) and `Athlete` JWT (email-based trainer resolution). Use `EnsureTrainerEntityAsync` for lazy creation.

---

## Workout History is Permanent

**Decision:** Completed workout sessions, set logs, and personal records are never deleted — not by the athlete, not by the trainer, not by program deletion.

**Why:** Analytics integrity. A coach's evaluation of an athlete's progress depends on permanent history. Deleting a program does not erase the workouts done under it.

**Implication:** Deleting a program sets `session.program_id = null`, not cascade-deletes sessions. Same for program days and exercises.

---

## Program Locking over Program Deletion on Coaching End

**Decision:** When a coaching relationship ends, trainer-created programs are **locked** (`locked_at` set), not deleted.

**Why:** The athlete ran those programs. Their session history references them. Deleting would break analytics context. The athlete can still see what program they were on.

**Implication:** Locked programs are read-only (structure only). Athletes can still start sessions from locked programs and can reschedule days. Re-accepting a coaching relationship unlocks them.

---

## Copied Programs Are Independent Forks

**Decision:** Saving a public program creates an independent `WorkoutProgram` copy. Changes to the original published program do NOT automatically propagate to saved copies.

**Why:** Data integrity. An athlete who saved a program and has been running it for 3 months should not have their program structure silently mutated by the publisher.

**Opt-in updates:** Publishers can publish a new version. Saved users receive a `ProgramUpdateAvailable` notification and choose to apply or dismiss.

---

## Server-Side JWT — localStorage Acceptable for MVP

**Decision:** Access tokens are stored in `localStorage` on the web client.

**Why:** Simpler to implement. The current deployment is not publicly marketed — it's an internal MVP.

**Must change before public release:** Move to `httpOnly` cookies or a secure token strategy to prevent XSS token theft.

---

## Soft Delete for Exercises

**Decision:** Exercises used in historical workouts must never be hard-deleted. Use `is_active = false`.

**Why:** Historical sessions reference `exercise_id`. Hard-deleting an exercise would orphan FK references and corrupt analytics.

**Implication:** Deactivated exercises still appear in historical session data but are hidden from the active library.

---

## Relative Media URLs in DTOs

**Decision:** DTOs expose media URLs as relative paths: `/api/media/{assetId}/content`.

**Why:** The API domain changes between environments (localhost, VPS IP, future CDN). Relative URLs let the client resolve against the base URL it already knows.

**Implication:** The frontend constructs absolute URLs by prepending `window.location.origin` or the API base URL. The `GetAvatarUrl(Guid? assetId)` helper in `EndpointHelpers` returns relative or null.

---

## PostgreSQL Only — No Redis, No Message Queue (MVP)

**Decision:** All persistent state lives in PostgreSQL. SignalR uses in-memory backplane (single-node). No Redis, no RabbitMQ.

**Why:** Simplicity for MVP. The current deployment is single-host Docker Compose.

**Must change at scale:** SignalR requires Redis backplane for multi-node. Background jobs (reminders, GC) need a proper queue. Address before horizontal scaling.

---

## Auto-Migrate at Startup

**Decision:** `db.Database.MigrateAsync()` runs at every API startup with up to 10 retries (3s apart).

**Why:** Zero-touch deployment. `docker compose up` applies pending migrations automatically.

**Risk:** Destructive migrations (column drops, type changes) run without a human approval step. Mitigate by always running `dotnet ef migrations script` to review before deploying.
