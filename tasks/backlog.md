# Product Backlog

Durum: ✅ Tamamlandı · ⬜ Yapılabilir (kod işi) · 🔲 Gelecek (plan)

---

## ⬜ P1 — Hemen Alınabilir

| Görev | Epic | Zorluk | Notlar |
|-------|------|--------|--------|
| Thumbnail generation for videos | Media | L | Cloudflare R2 Image Transform veya FFmpeg sidecar |
| Video compression plan | Media | M | Pre-upload client-side veya server-side transcode kararı |

---

## 🔲 Phase 19 — Gym & Community

> **Bağımlılık yok** — hemen başlanabilir.

### Entities (migration gerekir)

| Entity | Alanlar |
|--------|---------|
| `Gym` | `id`, `name`, `slug` (unique), `description`, `visibility` (Public/Private), `owner_user_id` FK→users, `logo_media_asset_id` nullable FK, `cover_media_asset_id` nullable FK, `created_at` |
| `GymMembership` | `id`, `gym_id` FK, `user_id` FK, `role` (Owner/Coach/Member enum→string), `status` (Active/Banned), `joined_at` |
| `GymInvite` | `id`, `gym_id` FK, `invited_email`, `token` (unique), `role`, `expires_at`, `accepted_at` nullable, `created_at` |
| `GymPost` | `id`, `gym_id` FK, `author_user_id` FK, `body` varchar(5000), `media_asset_id` nullable FK, `created_at`, `is_deleted` bool |
| `GymPostComment` | `id`, `post_id` FK (cascade), `author_user_id` FK, `body` varchar(1000), `created_at`, `is_deleted` bool |
| `GymPostReaction` | `id`, `post_id` FK (cascade), `user_id` FK, unique(`post_id`,`user_id`) |

### Backend Endpoints

| Endpoint | Kural |
|----------|-------|
| `POST /api/gyms` | Gym oluştur; caller otomatik Owner GymMembership |
| `GET /api/gyms/my` | Kendi üyelik listesi (Active + role bilgisi ile) |
| `GET /api/gyms/{id}` | Gym detayı — Public gym herkese açık, Private sadece member |
| `PATCH /api/gyms/{id}` | İsim/açıklama/görünürlük güncelle (Owner only) |
| `DELETE /api/gyms/{id}` | Soft-delete veya hard-delete (Owner/Admin) |
| `POST /api/gyms/{id}/logo` | Logo yükle multipart (Owner; `MediaPurpose.GymLogo`) |
| `POST /api/gyms/{id}/cover` | Kapak fotoğrafı yükle (Owner; `MediaPurpose.GymCover`) |
| `POST /api/gyms/{id}/invite` | Email ile davet gönder (Owner/Coach) → token üret, email gönder |
| `POST /api/gyms/invites/{token}/accept` | Davet kabul — GymMembership oluştur, token'ı kapat |
| `GET /api/gyms/{id}/members` | Üye listesi (Active member görebilir) |
| `PATCH /api/gyms/{id}/members/{userId}/role` | Rol değiştir (Owner only, kendi rolünü değiştiremez) |
| `DELETE /api/gyms/{id}/members/{userId}` | Üye at (Owner/Coach; owner atılamaz) |
| `PATCH /api/gyms/{id}/members/{userId}/ban` | Ban / unban (Owner/Coach) |
| `POST /api/gyms/{id}/posts` | Post oluştur (Active member; opsiyonel medya) |
| `GET /api/gyms/{id}/posts` | Paginated feed — son post'tan geriye (Active member) |
| `DELETE /api/gyms/{id}/posts/{postId}` | Sil (yazar / Owner / Coach / Admin) |
| `POST /api/gyms/{id}/posts/{postId}/comments` | Yorum ekle (Active member) |
| `DELETE /api/gyms/{id}/posts/{postId}/comments/{id}` | Yorum sil (yazar / Owner / Coach / Admin) |
| `POST /api/gyms/{id}/posts/{postId}/reactions` | Toggle like (Active member; upsert + delete pattern) |
| `GET /api/gyms/{id}/leaderboard` | Bu ay workout hacmi + oturum sayısı sıralaması (member) |

### Access gate kuralı
- `GymRole.Owner` > `GymRole.Coach` > `GymRole.Member`
- Banned üyeler tüm read/write işlemlerinden 403 alır
- Helper: `EndpointHelpers.GetGymMembershipAsync(db, gymId, userId)` → `GymMembership?`

### Frontend Views

| Bileşen | İçerik |
|---------|--------|
| `GymsView.jsx` | Üye olduğum gym listesi + "Gym Oluştur" butonu + "Davet var" banner |
| `GymDetailView.jsx` | Feed tab + Üyeler tab + Ayarlar tab (Owner) |
| `GymPostCard.jsx` | Body, medya, like butonu (sayı), yorum alanı (expand) |
| `GymLeaderboardCard.jsx` | Bu ayki top 10 üye, hacim + oturum |

### i18n keys (TR/EN)
`gymCreate`, `gymMyGyms`, `gymMembers`, `gymFeed`, `gymLeaderboard`, `gymInvite`, `gymSettings`, `gymBanned`, `gymPostDeleted`, `reactionLike`

---

## 🔲 Phase 20 — AI Koçluk

> **Bağımlılık**: Phase 13 (audit log) tamamlandı ✅ — başlanabilir.  
> OpenAI API key env var olarak eklenmeli: `OPENAI_API_KEY`.

### Entity (migration gerekir)

| Entity | Alanlar |
|--------|---------|
| `AiProgramDraft` | `id`, `trainer_id` FK→trainers, `athlete_id` nullable FK→athletes, `context_json` (text — prompt context), `response_json` (text — AI'dan dönen ham yapı), `status` (Pending/Accepted/Rejected enum→string), `created_at`, `reviewed_at` nullable |

### Backend

| Görev | Detay |
|-------|-------|
| OpenAI client kaydı | `builder.Services.AddHttpClient("openai")` + `OPENAI_API_KEY` env var |
| Program JSON schema | `ProgramDaySchema` — gün adı, egzersizler, set/tekrar/RPE/dinlenme alanları; AI prompt'a eklenir |
| System prompt | Trainer'ın egzersiz kütüphanesi (ilk 50 egzersiz) + athlete'in son 30 günlük hacim/RPE özeti + şema |
| `POST /api/programs/ai-draft` | Request: `{ athleteId, goals, availableDays, fitnessLevel }` → AI'ya gönder → `AiProgramDraft` kaydet → taslak yapıyı döndür |
| `GET /api/programs/ai-draft/{id}` | Taslak detayı (trainer kendi taslağını görebilir) |
| `POST /api/programs/ai-draft/{id}/accept` | Taslaktaki gün yapısını gerçek `WorkoutProgram` + günler + egzersizler olarak kaydet |
| `POST /api/programs/ai-draft/{id}/reject` | Status → Rejected |
| Audit log | `AiDraftAccepted` action admin audit log'a kaydedilsin |

### Frontend

| Bileşen | İçerik |
|---------|--------|
| Program Builder'da "AI ile Oluştur" butonu | Sadece trainer; form: hedef, gün sayısı, seviye |
| `AiDraftModal.jsx` | AI'dan dönen taslak — gün + egzersiz listesi; her egzersizi düzenlenebilir yap |
| Kabul / Reddet butonları | Kabul → `POST /accept` → Program Builder'a yönlendir |
| "AI Önerisi" badge | AI ile oluşturulan programlarda görünür |

### i18n keys (TR/EN)
`aiDraft`, `aiDraftCreate`, `aiDraftGoals`, `aiDraftDays`, `aiDraftLevel`, `aiDraftGenerating`, `aiDraftAccept`, `aiDraftReject`, `aiDraftBadge`

---

## 🔧 Infrastructure (DevOps, Kod Gerektirmez)

| Görev | Zorluk | Notlar |
|-------|--------|--------|
| PostgreSQL scheduled backups | M | `pg_dump` cron + R2'ye yükleme, restore testi |
| Staging environment | M | Ayrı R2 bucket + DB + Docker Compose override |
| Product analytics events | M | Mixpanel veya PostHog entegrasyonu |
| Disable SSH password login on VPS | S | `/etc/ssh/sshd_config` → `PasswordAuthentication no` |

---

## 🏁 En Son — Domain + HTTPS

> **Sıralama**: Her şey canlıya alınıp stabil olduktan sonra yapılır.

| Adım | Detay |
|------|-------|
| DNS | Hostinger panelinden A kaydı → VPS IP |
| Nginx reverse proxy | `nginx.conf`: 80→443 redirect, `/` → `localhost:8080`, `/api` → `localhost:5050` |
| SSL (Let's Encrypt) | `certbot --nginx -d yourdomain.com` |
| Docker Compose güncelleme | `CORS__AllowedOrigins__0=https://yourdomain.com` env, port 8080/5050 artık sadece localhost'a bağlanır |
| Web build | Vite `VITE_API_BASE_URL` → `https://yourdomain.com` |

---

## Tamamlananlar ✅

### Altyapı & Auth
- JWT auth + refresh token rotasyonu
- E-posta doğrulama altyapısı
- Admin panel (kullanıcı yönetimi, egzersiz yönetimi, istatistik)
- Admin audit log (aktör, işlem, hedef, IP — Phase 13)
- Orphan media cleanup background servisi (24s GC)
- Media raporlama + admin moderasyon kuyruğu (Phase 16)
- Media upload size limits — Athlete 500 MB, Trainer 2 GB, Admin sınırsız kota

### Koçluk Çekirdeği
- Trainer-athlete ilişki yaşam döngüsü (pending → accepted → ended)
- Program oluşturucu (gün yapısı, egzersiz, set, tekrar şablonu)
- Program şablonları — trainer **ve** athlete kendi şablonlarını oluşturabilir (Phase 17)
- Program versiyonlama + güncelleme bildirimleri
- Workout Mode (set-set kayıt, ısınma setleri, RPE)
- Oturum geçmişi + analitik (RPE trend, hacim, tutarlılık, PR'lar)
- Kişisel rekorlar (UPSERT — tamamlama anında)
- Bugünkü antrenman widget'ı (Dashboard)

### Sosyal & Keşif
- Sosyal bağlantılar + takip sistemi
- Genel programlar (yayınla, beğen, kaydet, çatallayı al)
- Doğrudan mesajlaşma (program referansları ile)
- Uygulama içi bildirimler + SignalR gerçek zamanlı

### Medya
- Avatar + kapak fotoğrafı (Cloudflare R2)
- Yayınlanan program kapak fotoğrafı
- İlerleme fotoğrafları (yükleme, zaman çizelgesi, önce/sonra, trainer görünümü)
- İlerleme fotoğrafı vücut ölçüm bağlantısı (9 alanlı snapshot + karşılaştırma — Phase 14)
- Submission ve geri bildirim videoları
- Egzersiz demo videoları (yükle, seç, Workout Mode'da göster)

### Beslenme
- Beslenme hedefi (kalori, protein, karb, yağ) + günlük log
- Beslenme takibi: öğün, yemek, porsiyon (52 TR yemek seeding)
- Eksik antrenman ve beslenme bildirimleri (7 gün / 3 gün — Phase 15)
- Beslenme gizliliği: athlete `nutrition_visibility` alanı (`CoachOnly` varsayılan, `Private` seçeneği — Phase 18)

### Analitik & Profil
- Vücut metrikleri (9 alan, trend grafikleri)
- Egzersiz kütüphanesi (141+ egzersiz, global seeding)
- Athlete analitik ekranı
- Dark mode + TR/EN i18n
- Profil gizlilik ayarları
