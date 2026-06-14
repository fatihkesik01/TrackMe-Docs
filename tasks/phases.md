# Development Phases

## Current State

**Phase 20 complete.** 65 EF Core migrations. Trainers can now request AI-generated program drafts (via Groq — free tier), review the day/exercise structure, and accept to create a real `WorkoutProgram`. Phase 19 (Gym & Community) is skipped for now — will be implemented separately.

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

### Phase 8 — Progress Photos

- `ProgressPhoto` entity (`athlete_id`, `media_asset_id`, `taken_on`, `notes`, `visibility`, `weight_kg_snapshot`)
- `MediaPurpose.ProgressPhoto` — R2 key: `athletes/{id}/progress/{mediaId}{ext}`
- `POST /api/progress-photos` — multipart upload with metadata fields
- `GET /api/progress-photos` — own paginated list
- `GET /api/athletes/{athleteId}/progress-photos` — trainer view (CoachOnly + Public, requires accepted coaching relationship)
- `PATCH /api/progress-photos/{id}` — update metadata
- `DELETE /api/progress-photos/{id}` — delete from DB + R2
- ProgressPhotosView: date-grouped timeline grid, upload modal, lightbox (keyboard nav), before/after comparison modal
- Inline visibility change per photo card and in lightbox

### Phase 9 — Submission & Feedback Videos

- `VideoSubmission` entity with optional `session_id` / `session_exercise_id` links
- `VideoFeedback` entity with trainer media, notes, and `viewed_at`
- `POST /api/submissions` — athlete multipart upload (MP4/WebM, max 200 MB)
- `GET /api/submissions` — athlete own paginated list
- `GET /api/athletes/{athleteId}/submissions` — trainer view, accepted relationship required, Private hidden
- `GET /api/submissions/{id}` — detail with feedbacks
- `POST /api/submissions/{id}/feedback` — trainer video/audio feedback
- `PATCH /api/submissions/{id}/feedback/{feedbackId}/viewed` — athlete marks feedback viewed
- `DELETE /api/submissions/{id}` and `DELETE /api/submissions/{id}/feedback/{feedbackId}`
- Notifications: `SubmissionReceived`, `FeedbackReceived`
- Web: Athlete Submissions view + trainer Videos tab in Athlete Detail

### Phase 10 — Nutrition Tracking MVP

- `NutritionGoal` entity for active calorie/protein/carbs/fat targets
- `DailyNutritionLog` entity with unique `(athlete_id, date)` and API upsert behavior
- Nutrition endpoints: goals, logs, athlete history, trainer history, and summary
- Athlete Nutrition view: today progress bars, log modal, 30-day adherence grid
- Trainer Athlete Detail Nutrition tab: set/update goal and last-30-day adherence list
- Dashboard Nutrition Today card for athletes with an active goal

### Phase 11 — Exercise Demo Videos

- Nullable `exercises.demo_video_media_asset_id` FK to `media_assets`
- Trainer upload/delete for owned private exercises; admin upload/delete for global exercises
- MP4/WebM validation through the existing Phase 9 video media pipeline
- Public media proxy playback for `MediaPurpose.ExerciseVideo`
- Demo video controls in the exercise library, program exercise picker, and WorkoutMode

### Phase 12 — Nutrition Meals

- `FoodItem`, `Meal`, and `MealEntry` entities with fully snake_case PostgreSQL mappings
- Searchable global/custom food library with barcode uniqueness and 52 seeded Turkish staples
- Breakfast, lunch, dinner, and snack containers with gram-based macro calculation at save time
- Athlete meal CRUD and computed day totals without overwriting manual `DailyNutritionLog` values
- Trainer read-only daily meal history guarded by accepted coaching relationships
- Athlete meal cards, food search/custom food modal, date navigation, and trainer meal view

### Phase 13 — Admin Audit Log

- `AdminAuditLog` entity (`actor_user_id`, `action`, `target_user_id`, `target_email`, `detail`, `ip_address`, `created_at`)
- Logged actions: `user.update`, `user.deactivate`, `exercise.restore`, `exercise.seed`, `data.reset`
- `GET /api/admin/audit-log` — paginated list, filterable by `action`
- Admin panel: Audit Log card with action filter dropdown
- IP address captured per request; logs saved atomically within each admin action

### Phase 14 — Progress Photo Body Metric Linking

- Nullable `progress_photos.body_metric_id` FK with `ON DELETE SET NULL`
- Upload and patch ownership validation for athlete body metrics
- Full nine-field body metric snapshots in athlete and trainer photo lightboxes
- Before/after comparison includes per-field metric deltas
- Upload modal can select from the athlete's existing dated body measurements

### Phase 15 — Missed Activity Notifications

- `MissedActivityAlert` entity records trainer, athlete, alert type, and sent timestamp
- Daily `MissedActivityAlertService` checks accepted coaching relationships
- Workout alerts require an active program and no completed session for more than 7 days
- Nutrition alerts require an active goal and no daily log for more than 3 days
- Per trainer/athlete/type suppression prevents duplicate workout alerts for 7 days and nutrition alerts for 3 days
- Notifications are persisted and pushed through the existing SignalR notification channel

### Phase 16 — Media Reporting & Moderation

- `ReportedByUserId`, `ReportedAt`, `ReportReason` nullable fields added to `media_assets`
- `POST /api/media/{id}/report` — any authenticated user can flag media they don't own
- Cannot report own media, already-rejected, or already-hidden assets
- `GET /api/admin/media/reported` — paginated list of all reported assets with owner and reporter names
- `PATCH /api/admin/media/{id}/moderate` — admin sets moderation status to `Approved`, `Rejected`, or `Hidden`; audit-logged as `media.moderate`
- Admin panel: new Media Moderation card with inline approve/hide/reject buttons

### Phase 17 — Athlete Templates

- `athlete_id` nullable FK added to `program_templates` (alongside existing `trainer_id`)
- Athletes can create their own day templates and program templates
- `GET /api/templates` — filters by caller's trainer ID **or** athlete ID; admin sees all
- `POST /api/templates` — athletes set `athlete_id`; trainers set `trainer_id`; admin leaves both null
- Full CRUD, day/exercise management, apply-to-day/apply-to-program — all ownership checks updated to support athletes
- `OwnerName` field replaces `TrainerName` in DTOs (shows trainer, athlete, or "System")
- `ResolveAthleteProfileIdAsync` helper added to `TemplateEndpoints`

### Phase 18 — Nutrition Privacy

- `nutrition_visibility` varchar(20) column added to `athletes` with default `CoachOnly`
- `NutritionVisibility` enum: `CoachOnly = 0` (default), `Private = 1`; stored as string in DB
- Trainer read access blocked when `Private`: `GetGoal`, `GetAthleteLogs` (NutritionEndpoints), `GetAthleteMeals` (MealEndpoints)
- Goal write (`SetGoal`, `UpdateGoal`) intentionally NOT blocked — coaching write actions remain accessible
- `PATCH /api/auth/profile` accepts optional `nutritionVisibility: "Private" | "CoachOnly"`
- `GET /api/auth/me` returns `nutritionVisibility` string for authenticated athletes
- ProfileView: athlete-only radio card (between Privacy Settings and Featured Exercises) with TR/EN i18n

---

## Next Phases (Planned)

### Phase 19 — Gym & Community (P2)

Bağımlılık yok — hemen başlanabilir.

**Yeni entities:** `Gym`, `GymMembership`, `GymInvite`, `GymPost`, `GymPostComment`, `GymPostReaction`

**Migration:** `Phase19_GymCommunity` — 6 yeni tablo + `MediaPurpose.GymLogo` + `MediaPurpose.GymCover` enum değerleri

**Backend endpoint grupları:**
- Gym CRUD: `POST /api/gyms`, `GET /api/gyms/my`, `GET /api/gyms/{id}`, `PATCH /api/gyms/{id}`, `DELETE /api/gyms/{id}`
- Medya: `POST /api/gyms/{id}/logo`, `POST /api/gyms/{id}/cover`
- Üyelik: `POST /api/gyms/{id}/invite`, `POST /api/gyms/invites/{token}/accept`, `GET /api/gyms/{id}/members`, `PATCH /api/gyms/{id}/members/{userId}/role`, `DELETE /api/gyms/{id}/members/{userId}`, `PATCH /api/gyms/{id}/members/{userId}/ban`
- Feed: `POST /api/gyms/{id}/posts`, `GET /api/gyms/{id}/posts`, `DELETE /api/gyms/{id}/posts/{postId}`
- Sosyal: `POST /api/gyms/{id}/posts/{postId}/comments`, `DELETE /api/gyms/{id}/posts/{postId}/comments/{id}`, `POST /api/gyms/{id}/posts/{postId}/reactions`
- Leaderboard: `GET /api/gyms/{id}/leaderboard` (bu ay workout hacmi + oturum)

**Access gate:** `GymMembership` varlığı + role kontrolü; Banned üyeler 403; yardımcı: `GetGymMembershipAsync(db, gymId, userId)`

**Frontend:** `GymsView.jsx`, `GymDetailView.jsx` (feed/üyeler/ayarlar tabları), `GymPostCard.jsx`, `GymLeaderboardCard.jsx`

---

### Phase 20 — AI Koçluk ✅

- `AiProgramDraft` entity — trainer, athlete, context JSON (prompt), response JSON (AI taslağı), status (Pending/Accepted/Rejected)
- **Groq API** kullanılır (ücretsiz, `llama-3.1-70b-versatile`); `GROQ_API_KEY` env var
- `POST /api/programs/ai-draft` — trainer egzersiz kütüphanesi + athlete geçmişi prompt'a eklenir, Groq'a gönderilir, taslak kaydedilir
- `GET /api/programs/ai-draft` — trainer kendi son 20 taslağı
- `GET /api/programs/ai-draft/{id}` — taslak detayı
- `POST /api/programs/ai-draft/{id}/accept` — taslaktan gerçek `WorkoutProgram` + günler + egzersizler oluşturulur
- `POST /api/programs/ai-draft/{id}/reject` — Status → Rejected
- Geçersiz `exerciseId` varsa atlanır (validIds kontrolü)
- Frontend: "AI ile Oluştur" butonu (trainer, ProgramsView), `AiDraftModal.jsx` iki adım (form → taslak görüntüle), Kabul/Reddet/Yeniden Oluştur

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
| 8 | ProgressPhotos | 54 |
| 9 | SubmissionVideos | 55 |
| 10 | NutritionTracking | 56 |
| 11 | ExerciseDemoVideo | 57 |
| 12 | NutritionMeals | 58 |
| 13 | AdminAuditLog | 59 |
| 14 | ProgressPhotoBodyMetricLink | 60 |
| 15 | MissedActivityNotification | 61 |
| 16 | MediaReporting | 62 |
| 17 | AthleteTemplates | 63 |
| 18 | NutritionVisibility | 64 |
| 20 | AiProgramDraft | 65 |

Full list: [database/migration-strategy.md](../database/migration-strategy.md)

---

## Effort Legend

| Label | Meaning |
|-------|---------|
| S | Small — 1–3 hours |
| M | Medium — half to one day |
| L | Large — 1–3 days |
| XL | Extra large — 1+ week |
