# TrackMe Roadmap

Roadmap dört büyük fazdan oluşuyor. Her faz, bir öncekinin üzerine inşa ediliyor ve bağımsız olarak deploy edilebilir değer üretiyor.

---

## P0 — Core Coaching (Tamamlandı ✅)

**Amaç:** Trainer-athlete coaching iş akışını güvenilir, tekrarlanabilir ve production-ready hale getirmek.

**Başarı Kriteri:**
- Athlete programını sorunsuz uygular ve workout tamamlar
- Trainer program yazar, günler ve egzersizler ekler, athlete performansını takip eder
- Veriler kalıcı, migrationlar güvenli, sistem production'da çalışıyor

**Tamamlanan Özellikler:**
- JWT auth + refresh token rotation
- Trainer-athlete relationship lifecycle (Pending → Accepted → Ended)
- Program Builder (tekrar pattern, şablon sistemi, per-set ağırlıklar)
- Workout Mode (set-bazlı loglama, warm-up sets, RPE, rest timer)
- Session history + analytics (RPE trend, volume trend, consistency grid)
- Body metrics (9 ölçüm alanı, trend grafikleri)
- Exercise library (141 egzersiz, difficulty, kategori, özel egzersizler)
- In-app notifications + SignalR realtime
- Direct messaging (program referansı ile)
- Admin panel
- Dark mode + TR/EN i18n
- Personal records (UPSERT on session complete)
- Public programs (yayınla, beğen, yorum, kaydet, fork)
- Social connections + follow sistemi
- Program versioning (changelog, update notifications)
- Avatar/cover photo (Cloudflare R2 ile)
- Program cover photo
- Today's workout widget (Dashboard)
- Athlete analytics screen

---

## P1 — Media-Enabled Coaching

**Amaç:** Video, fotoğraf ve ses ile gerçek bir coaching feedback döngüsü kurmak.

**Başarı Kriteri:**
- Athlete form videosu veya progress fotoğrafı gönderebilir
- Trainer video, ses veya fotoğraf ile feedback verebilir
- Medya güvenli saklanır ve doğru kişilere görünür
- Admin raporlanan medyayı inceleyip moderasyon kararı verebilir

**Öncelikli Görevler:**

| Görev | Bağımlılık | Durum |
|-------|-----------|-------|
| Progress photo upload (athlete) | MediaAsset | ⬜ |
| Progress photo visibility settings | Progress photos | ⬜ |
| Progress photo timeline (ProfileView) | Progress photos | ⬜ |
| Before/after comparison modal | Progress photo timeline | ⬜ |
| Trainer access to shared progress photos | Visibility settings | ⬜ |
| Athlete submission video upload | MediaAsset | ⬜ |
| Trainer feedback video | Submission video | ⬜ |
| Audio feedback (record + playback) | MediaAsset | ⬜ |
| Exercise demo video attachment | MediaAsset | ⬜ |
| Media reporting (report flag on MediaAsset) | MediaAsset | ⬜ |
| Admin media moderation queue | Media reporting | ⬜ |

**Milestone:** A trainer can record and send a video feedback to an athlete who submitted a form video — all from the web app.

---

## P2 — Gym & Community

**Amaç:** TrackMe'yi birebir coaching'den gym/club topluluklarına genişletmek.

**Başarı Kriteri:**
- Bir gym kendi üyelerini, coach'larını, feed'ini ve leaderboard'unu yönetebilir
- Global leaderboard doğrulanmış PR'ları gösterir

**Görevler:**

| Görev | Bağımlılık | Öncelik |
|-------|-----------|---------|
| Gym entity (create, logo/cover, visibility) | MediaAsset | P2-1 |
| Multi-gym membership + invite flow | Gym | P2-2 |
| Gym coach role + permissions | Membership | P2-3 |
| Gym feed (post, media, comment, moderation) | Gym + MediaAsset | P2-4 |
| Gym leaderboard (metrics, periods) | Personal Records | P2-5 |
| Global leaderboard + eligibility rules | Personal Records | P2-6 |
| PR evidence video submission + verification | MediaAsset + Leaderboard | P2-7 |

**Risk:** Erken topluluk karmaşıklığı core coaching'i geri plana itebilir. P2'ye geçişten önce P1 tamamlanmalı.

---

## P3 — AI, Growth & Monetization

**Amaç:** AI destekli üretkenlik, büyüme kanalları ve gelir modeli.

**Başarı Kriteri:**
- Trainer daha hızlı program üretir (AI draft)
- Platform sürdürülebilir gelir üretir
- Mobil uygulama olgunlaşmış

**Görevler:**

| Görev | Bağımlılık | Öncelik |
|-------|-----------|---------|
| AI program draft (OpenAI entegrasyonu) | Standartlaşmış program şeması | P3-1 |
| AI coaching suggestion (load progression, missed workouts) | Workout history | P3-2 |
| Subscription model (trainer plans, gym plans) | Auth + billing | P3-3 |
| Ad placements (feed/discovery only) | Subscription baseline | P3-4 |
| Mobile app MVP (React Native) | Stable API contracts | P3-5 |
| Mobile camera + resumable upload | Mobile MVP | P3-6 |

---

## Dependencies & Critical Path

```
MediaAsset altyapısı ✅
    └── Progress photos
            └── Before/after comparison
            └── Trainer progress visibility
    └── Submission videos
            └── Trainer feedback videos
            └── Audio feedback
    └── Exercise videos
    └── Media moderation

Personal Records ✅
    └── Gym leaderboard
    └── Global leaderboard
            └── PR evidence videos

Program schema ✅
    └── AI program draft

Mobile API contracts
    └── Mobile MVP
```

## Current Migration Count

**53 migrations** — last: `Phase7_ProgramCoverPhoto`

See [database/migrations.md](../database/migrations.md) for full history.
