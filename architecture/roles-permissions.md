# Kullanıcı Rolleri & İzinler

TrackMe'de üç kullanıcı tipi vardır: **Admin**, **Trainer** ve **Athlete**.  
Bir kullanıcı hem Trainer hem Athlete profiline sahip olabilir (*dual-role*) — JWT rolü kayıt sırasında sabitlenir, ama `preferred_ui_role` alanı ile arayüz bağlamı değiştirilebilir.

---

## Rol Özeti

|                     | Admin                 | Trainer                    | Athlete                    |
|---------------------|-----------------------|----------------------------|----------------------------|
| **DB tablosu**      | `users`               | `users` + `trainers`       | `users` + `athletes`       |
| **JWT rolü**        | `Admin`               | `Trainer`                  | `Athlete`                  |
| **Birincil amaç**   | Sistem yönetimi       | Koçluk, program tasarımı   | Antrenman, ilerleme takibi |

---

## Özellik Erişim Tablosu

Sembol anlamları: `✅` Tam erişim · `👁` Yalnızca görüntüleme · `—` Erişim yok

---

### 👤 Profil & Kimlik

| Özellik                                              | Admin | Trainer | Athlete |
|------------------------------------------------------|:-----:|:-------:|:-------:|
| Kendi profilini düzenle (bio, avatar, kapak)         |  ✅   |   ✅    |   ✅    |
| Profil gizlilik ayarları                             |  —    |   ✅    |   ✅    |
| Spor geçmişi / ekipman tercihleri                    |  —    |   ✅    |   ✅    |
| Birim tercihleri (kg/lbs, cm/ft)                     |  —    |   ✅    |   ✅    |
| Arayüz rolü değiştir (dual-role bağlamı)             |  —    |   ✅    |   ✅    |
| Herkese açık profil sayfası                          |  —    |   ✅    |   ✅    |

---

### 🛡️ Kullanıcı & Sistem Yönetimi

| Özellik                                              | Admin | Trainer | Athlete |
|------------------------------------------------------|:-----:|:-------:|:-------:|
| Tüm kullanıcıları listele / ara                      |  ✅   |   —     |   —     |
| Kullanıcı rolünü değiştir                            |  ✅   |   —     |   —     |
| Kullanıcıyı devre dışı bırak / yeniden etkinleştir  |  ✅   |   —     |   —     |
| Sistem istatistiklerini görüntüle                    |  ✅   |   —     |   —     |
| Admin audit log                                      |  ✅   |   —     |   —     |
| Eğitim verilerini sıfırla                            |  ✅   |   —     |   —     |
| Global egzersizleri yönet / seed et                  |  ✅   |   —     |   —     |

---

### 🤝 Koçluk İlişkisi

| Özellik                                              | Admin | Trainer | Athlete |
|------------------------------------------------------|:-----:|:-------:|:-------:|
| Koçluk ilişkisi teklifi gönder                       |  —    |   ✅    |   ✅    |
| Koçluk teklifini kabul / reddet                      |  —    |   ✅    |   ✅    |
| Aktif ilişkileri listele                             |  —    |   ✅    |   ✅    |
| İlişkiyi sonlandır                                   |  —    |   ✅    |   ✅    |
| Coached athlete listesi                              |  —    |   ✅    |   —     |
| Kendi trainer listesi                                |  —    |   —     |   ✅    |

---

### 🏋️ Program & Egzersiz

| Özellik                                              | Admin | Trainer | Athlete |
|------------------------------------------------------|:-----:|:-------:|:-------:|
| Global egzersiz kütüphanesini görüntüle              |  ✅   |   ✅    |   ✅    |
| Kendi özel egzersiz oluştur / düzenle                |  —    |   ✅    |   —     |
| Egzersiz demo videosu yükle (kendi egzersizleri)     |  —    |   ✅    |   —     |
| Global egzersiz demo videosu yükle / sil             |  ✅   |   —     |   —     |
| Athlete için program oluştur / düzenle               |  —    |   ✅    |   —     |
| Kendi programını görüntüle                           |  —    |   —     |   ✅    |
| Program şablonu oluştur / düzenle / kullan           |  —    |   ✅    |   ✅    |
| Genel program yayınla (marketplace)                  |  —    |   ✅    |   —     |
| Genel program beğen / kaydet / çatallayı al          |  —    |   ✅    |   ✅    |

---

### 📊 Antrenman & Analitik

| Özellik                                              | Admin | Trainer | Athlete |
|------------------------------------------------------|:-----:|:-------:|:-------:|
| Workout Mode (set-set kayıt)                         |  —    |   —     |   ✅    |
| Oturumu tamamla + PR güncelle                        |  —    |   —     |   ✅    |
| Kendi oturum geçmişi                                 |  —    |   —     |   ✅    |
| Coached athlete oturum geçmişi                       |  —    |   👁    |   —     |
| Kendi analitik ekranı (RPE, hacim, streak)           |  —    |   —     |   ✅    |
| Coached athlete analitiği                            |  —    |   👁    |   —     |
| Kişisel rekorlar görüntüle                           |  —    |   —     |   ✅    |
| Coached athlete PR'ları görüntüle                    |  —    |   👁    |   —     |

---

### 📏 Vücut Metrikleri

| Özellik                                              | Admin | Trainer | Athlete |
|------------------------------------------------------|:-----:|:-------:|:-------:|
| Kendi vücut metriklerini gir / düzenle               |  —    |   —     |   ✅    |
| Coached athlete vücut metriklerini görüntüle         |  —    |   👁    |   —     |
| CSV export (vücut metrikleri)                        |  —    |   —     |   ✅    |

---

### 📸 İlerleme Fotoğrafları

| Özellik                                              | Admin | Trainer | Athlete |
|------------------------------------------------------|:-----:|:-------:|:-------:|
| Fotoğraf yükle (Private / CoachOnly / Public)        |  —    |   —     |   ✅    |
| Vücut ölçümü ile fotoğraf eşleştir                  |  —    |   —     |   ✅    |
| Kendi fotoğraflarını düzenle / sil                   |  —    |   —     |   ✅    |
| Coached athlete fotoğraflarını görüntüle             |  —    |   👁    |   —     |
| Lightbox'ta 9 alan ölçüm snapshot göster             |  —    |   👁    |   ✅    |

---

### 🎥 Submission & Geri Bildirim Videoları

| Özellik                                              | Admin | Trainer | Athlete |
|------------------------------------------------------|:-----:|:-------:|:-------:|
| Egzersiz submission videosu yükle                    |  —    |   —     |   ✅    |
| Submission videoları görüntüle                       |  —    |   👁    |   ✅    |
| Video / ses geri bildirimi yükle                     |  —    |   ✅    |   —     |
| Geri bildirimi görüldü olarak işaretle               |  —    |   —     |   ✅    |

---

### 🥗 Beslenme

| Özellik                                              | Admin | Trainer | Athlete |
|------------------------------------------------------|:-----:|:-------:|:-------:|
| Athlete için beslenme hedefi belirle                 |  —    |   ✅    |   —     |
| Günlük beslenme logu gir                             |  —    |   —     |   ✅    |
| Öğün oluştur / yemek ekle                            |  —    |   —     |   ✅    |
| Özel yemek oluştur                                   |  —    |   ✅    |   ✅    |
| Coached athlete beslenme loglarını görüntüle         |  —    |   👁    |   —     |
| Coached athlete öğünlerini görüntüle                 |  —    |   👁    |   —     |
| Beslenme uyum grafiği (son 30 gün)                   |  —    |   👁    |   ✅    |

---

### 💬 Sosyal & Mesajlaşma

| Özellik                                              | Admin | Trainer | Athlete |
|------------------------------------------------------|:-----:|:-------:|:-------:|
| Kullanıcı takip et / bırak                           |  —    |   ✅    |   ✅    |
| Sosyal bağlantı teklifi gönder / kabul et            |  —    |   ✅    |   ✅    |
| Bağlantıyla doğrudan mesaj gönder                    |  —    |   ✅    |   ✅    |
| Coached athlete ile mesajlaş                         |  —    |   ✅    |   ✅    |
| Bildirim merkezi                                     |  —    |   ✅    |   ✅    |

---

### 🖼️ Medya & Moderasyon

| Özellik                                              | Admin | Trainer | Athlete |
|------------------------------------------------------|:-----:|:-------:|:-------:|
| Avatar / kapak fotoğrafı yükle                       |  —    |   ✅    |   ✅    |
| Medya dosyasını şikayet et (kendi olmayan)           |  —    |   ✅    |   ✅    |
| Şikayet edilen medyaları listele                     |  ✅   |   —     |   —     |
| Medya durumunu modere et (onayla / reddet / gizle)   |  ✅   |   —     |   —     |

---

### 📤 Veri Dışa Aktarma

| Özellik                                              | Admin | Trainer | Athlete |
|------------------------------------------------------|:-----:|:-------:|:-------:|
| Vücut metrikleri CSV export                          |  —    |   —     |   ✅    |
| Oturum geçmişi CSV export                            |  —    |   —     |   ✅    |

---

## Erişim Kontrol Notları

**Coaching access gate** — Trainer, athlete verisine yalnızca `TrainerAthleteRelationship.Status = Accepted` ile erişir. İlişki sonlanınca programlar kilitlenir (silinmez), coaching veri erişimi kaldırılır.

**Social access** — Sosyal bağlantılar yalnızca profil görünümü + mesajlaşma sağlar; coaching verisi (oturum, beslenme, fotoğraf) paylaşılmaz.

**Visibility filter** — `Private` → yalnızca owner. `CoachOnly` → owner + accepted trainer. `Public` → herkes (authenticated).

**Dual-role** — Trainer rolündeki bir kullanıcı `POST /api/auth/preferred-role` ile Athlete bağlamına geçerek athlete özelliklerini kullanabilir.

**Global egzersiz** — `is_global = true` olan egzersizler herkes tarafından görüntülenebilir; yalnızca Admin değiştirebilir.

**Şablon sahipliği** — `program_templates.trainer_id` veya `athlete_id` sütunlarından biri dolu olur. Her kullanıcı yalnızca kendi şablonlarını görebilir ve düzenleyebilir. Admin tüm şablonları görür.
