# Product Backlog

Items are organized by epic and phase. Status: ✅ Done · ⬜ Pending · 🔲 Future

---

## P1 — Media-Enabled Coaching

### Progress Photos

| Task | Status |
|------|--------|
| Progress photo upload (athlete → ProgressPhotosView) | ✅ |
| Progress photo visibility settings (Private / CoachOnly / Public) | ✅ |
| Progress photo timeline (date-grouped grid) | ✅ |
| Before/after comparison modal (side-by-side viewer) | ✅ |
| Trainer access to athlete's shared progress photos | ✅ |
| Body metric linking (attach metric snapshot to photo) | ⬜ |

### Submission & Feedback Videos

| Task | Status |
|------|--------|
| Athlete submission video upload (linked to session/exercise) | ✅ |
| Trainer notification: new submission video received | ✅ |
| Trainer feedback video (record + upload) | ✅ |
| Athlete notification: new video feedback received | ✅ |
| Trainer audio feedback (record + upload + playback) | ✅ |
| Feedback viewed/read status | ✅ |

### Exercise Videos

Spec: [tasks/specs/exercise-demo-videos.md](specs/exercise-demo-videos.md)

| Task | Status |
|------|--------|
| Exercise demo video (link to exercise, official vs user-generated) | ⬜ |
| Video display in exercise picker | ⬜ |
| Video display in WorkoutMode | ⬜ |
| Thumbnail generation (server or R2 Transform) | ⬜ |

### Media Infrastructure

| Task | Status |
|------|--------|
| Media upload size limits (per-user quota enforcement) | ⬜ |
| Video compression plan (pre-upload, server, or transcoding) | ⬜ |
| Orphan asset cleanup job (GC for uploaded-but-unlinked assets) | ⬜ |
| Media reporting (flag on `MediaAsset`) | ⬜ |
| Admin media moderation queue | ⬜ |

---

## P1.5 — Nutrition Tracking

İki aşamalı: önce hedef + günlük toplam log (A), sonra öğün + yemek bazlı takip (B).

### A — Günlük Hedef & Toplam Log (MVP)

| Task | Status |
|------|--------|
| `NutritionGoal` entity — trainer athlete için günlük hedef koyar (kalori, protein, karb, yağ) | ✅ |
| `DailyNutritionLog` entity — athlete günlük toplamları girer | ✅ |
| `POST /api/nutrition/goals` — trainer hedef belirler | ✅ |
| `GET /api/nutrition/goals/{athleteId}` — aktif hedefi getir | ✅ |
| `POST /api/nutrition/logs` — athlete günlük toplamı kaydeder | ✅ |
| `GET /api/nutrition/logs/{athleteId}` — log geçmişi (tarih aralığı filtreli) | ✅ |
| Trainer: hedef vs gerçek uyum grafiği (son 30 gün) | ✅ |
| Athlete: günlük özet kart (Dashboard'a entegre) | ✅ |
| Bildirim: athlete günlük logu atladığında trainer'a uyarı (opsiyonel) | ⬜ |
| Privacy: nutrition data varsayılan `coach_only` | ⬜ |

### B — Öğün & Yemek Bazlı Takip

Bağımlılık: A tamamlanmış olmalı. Food database entegrasyonu gerektirir.

| Task | Status |
|------|--------|
| `Meal` entity — öğün (sabah / öğle / akşam / ara öğün) | 🔲 |
| `FoodItem` entity — yemek adı + besin değerleri (kalori, protein, karb, yağ, lif) | 🔲 |
| `MealEntry` entity — öğüne eklenen yemek + miktar (gram/porsiyon) | 🔲 |
| Food database seeding — manuel başlangıç listesi (TR yemekleri dahil) | 🔲 |
| OpenFoodFacts veya USDA API entegrasyonu (barcode lookup) | 🔲 |
| `GET /api/nutrition/foods?q=` — yemek arama | 🔲 |
| `POST /api/nutrition/foods` — özel yemek oluştur (trainer/athlete) | 🔲 |
| `POST /api/nutrition/meals` — öğün oluştur + yemek ekle | 🔲 |
| `GET /api/nutrition/meals/{athleteId}?date=` — günlük öğün detayı | 🔲 |
| Günlük toplam otomatik hesap (A logunu öğünlerden türet) | 🔲 |
| Öğün bazlı görünüm: athlete için sabah/öğle/akşam kartları | 🔲 |
| Trainer: athlete öğün geçmişini görebilir (coaching relationship gerekli) | 🔲 |
| Tarif / favori yemek kaydetme | 🔲 |

---

## P2 — Gym & Community

### Gym Entity

| Task | Status |
|------|--------|
| Gym create/edit (name, logo, cover, visibility) | 🔲 |
| Multi-gym membership (user belongs to multiple gyms) | 🔲 |
| Gym invite flow (owner invites by email) | 🔲 |
| Gym member role management (Owner / Coach / Member) | 🔲 |

### Gym Feed

| Task | Status |
|------|--------|
| Gym feed post (text + media) | 🔲 |
| Comments + reactions on feed posts | 🔲 |
| Gym feed moderation (admin + gym owner) | 🔲 |
| Gym feed notification (new post → members) | 🔲 |

### Leaderboards

Spec: [tasks/specs/pr-display.md](specs/pr-display.md) (frontend only — backend endpoint exists)

| Task | Status |
|------|--------|
| Personal Records — display in analytics screen | ✅ |
| Gym leaderboard (top lifts per exercise, per period) | 🔲 |
| Global leaderboard (verified PRs only) | 🔲 |
| PR evidence video submission + verification | 🔲 |
| Verified PR badge | 🔲 |

---

## P3 — AI, Growth & Monetization

### AI Features

| Task | Status |
|------|--------|
| Standardize program schema for AI prompt | 🔲 |
| AI program draft (OpenAI integration) — trainer edits before save | 🔲 |
| AI coaching suggestions (load progression, missed workout detection) | 🔲 |
| Trainer approval gate for AI suggestions | 🔲 |
| AI audit metadata (source tag on AI-generated programs) | 🔲 |

### Mobile App

| Task | Status |
|------|--------|
| React Native project setup (Expo managed workflow) | 🔲 |
| Auth flow + expo-secure-store token storage | 🔲 |
| Athlete Workout Mode (set-by-set logging) | 🔲 |
| Offline-tolerant session draft (SQLite / expo-secure-store) | 🔲 |
| Push notifications (FCM + APNs, device token storage) | 🔲 |
| Camera capture + gallery upload | 🔲 |
| Resumable + background upload for videos | 🔲 |

### Monetization

| Task | Status |
|------|--------|
| Subscription model (trainer plans, gym plans) | 🔲 |
| Storage quota policy per plan tier | 🔲 |
| Ad placement config (feed/discovery only; exclude WorkoutMode) | 🔲 |
| Export/download policy (data portability) | 🔲 |

---

## Infrastructure & Quality

| Task | Status |
|------|--------|
| Domain + HTTPS (currently IP:port) | ⬜ |
| PostgreSQL scheduled backups with restore verification | ⬜ |
| Staging environment (separate R2 bucket, DB) | ⬜ |
| Product analytics events (Mixpanel / PostHog) | ⬜ |
| Disable SSH password login on VPS | ⬜ |
| Structured audit log table for admin actions | ⬜ |

---

## Completed (P0 — Core Coaching)

✅ JWT auth + refresh token rotation  
✅ Trainer-athlete relationship lifecycle  
✅ Program Builder (repeat pattern, templates, per-set weights)  
✅ Workout Mode (set-by-set logging, warm-up sets, RPE)  
✅ Session history + analytics (RPE trend, volume, consistency, PRs)  
✅ Body metrics (9 fields, trend graphs)  
✅ Exercise library (141+ exercises, seeded)  
✅ In-app notifications + SignalR real-time  
✅ Direct messaging with program references  
✅ Admin panel  
✅ Dark mode + TR/EN i18n  
✅ Public programs (publish, like, save, fork, version)  
✅ Social connections + follow system  
✅ Program versioning + update notifications  
✅ Avatar + cover photo (Cloudflare R2)  
✅ Published program cover photo  
✅ Progress photos (upload, timeline, before/after, trainer view)  
✅ Submission & feedback videos (athlete upload + trainer video/audio feedback)  
✅ Nutrition tracking MVP (daily goals, logs, adherence graph, Dashboard card)  
✅ Today's workout widget (Dashboard)  
✅ Athlete analytics screen  
