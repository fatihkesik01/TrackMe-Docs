# Product Backlog

Durum: ✅ Tamamlandı · ⬜ Yapılabilir (kod işi) · 🔲 Gelecek (plan)

---

## Yapılabilir — P1 (Hemen Alınabilir)

| Görev | Epic | Zorluk | Notlar |
|-------|------|--------|--------|
| Media upload size limits (per-user quota) | Media | M | Toplam `file_size_bytes` say; rol bazlı limit (ör. Athlete 500 MB, Trainer 2 GB) |
| Privacy: nutrition data varsayılan `coach_only` | Nutrition | S | Athlete profiline `nutrition_visibility` alanı ekle |
| Thumbnail generation for videos | Media | L | Cloudflare R2 Image Transform veya FFmpeg sidecar |
| Video compression plan | Media | M | Pre-upload client-side veya server-side transcode kararı |

---

## Yapılabilir — Infrastructure (DevOps, Kod Gerektirmez)

| Görev | Zorluk | Notlar |
|-------|--------|--------|
| Domain + HTTPS | S | Hostinger'da DNS + Nginx SSL (Let's Encrypt) |
| PostgreSQL scheduled backups | M | `pg_dump` cron + R2'ye yükleme, restore testi |
| Staging environment | M | Ayrı R2 bucket + DB + Docker Compose override |
| Product analytics events | M | Mixpanel veya PostHog entegrasyonu |
| Disable SSH password login on VPS | S | `/etc/ssh/sshd_config` → `PasswordAuthentication no` |

---

## Gelecek — P2: Gym & Community

> Bağımlılık: Phase 11 tamamlandı ✅ — başlanabilir

| Görev | Zorluk | Notlar |
|-------|--------|--------|
| Gym entity (isim, logo, kapak, görünürlük) | L | `Gym` + `GymMembership` entity; multi-gym üyelik |
| Gym davet akışı (e-posta ile) | S | Davet token, kabul/red akışı |
| Gym üye rol yönetimi (Owner / Coach / Member) | M | Enum + permission gate |
| Gym feed post (metin + medya) | L | `GymPost` entity, feed endpoint, web bileşeni |
| Feed yorumlar + reaksiyonlar | M | `GymPostComment`, `GymPostReaction` |
| Gym feed moderasyonu | S | Owner/Coach post silme, üye ban |
| Gym leaderboard (antrenman bazlı sıralama) | M | Üye bazlı hacim/oturum sayısı; haftalık/aylık |
| Global leaderboard (doğrulanmış PR'lar) | L | `verified_pr` flag; herkese açık liste |
| PR kanıt video gönderimi + doğrulama | L | Admin/trainer doğrulama kuyruğu |

---

## Gelecek — P3: AI Koçluk

> Bağımlılık: Phase 13 (audit log) + standart program şeması

| Görev | Zorluk | Notlar |
|-------|--------|--------|
| Program şeması AI prompt için standardize et | M | JSON schema + system prompt tasarımı |
| AI program taslağı (OpenAI) | L | Trainer isteği → AI draft → trainer düzenleyip kaydeder |
| AI koç önerileri (yük progresyonu) | L | Geçmiş oturumları analiz et → set/ağırlık öneri |
| Trainer onay kapısı | M | AI önerileri doğrudan uygulanmaz; trainer onaylar |

---

## Tamamlananlar ✅

### Altyapı & Auth
- JWT auth + refresh token rotasyonu
- E-posta doğrulama altyapısı
- Admin panel (kullanıcı yönetimi, egzersiz yönetimi, istatistik)
- Admin audit log (aktör, işlem, hedef, IP — Phase 13)
- Orphan media cleanup background servisi (24s GC)
- Media raporlama + admin moderasyon kuyruğu (Phase 16)

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

### Analitik & Profil
- Vücut metrikleri (9 alan, trend grafikleri)
- Egzersiz kütüphanesi (141+ egzersiz, global seeding)
- Athlete analitik ekranı
- Dark mode + TR/EN i18n
- Profil gizlilik ayarları
