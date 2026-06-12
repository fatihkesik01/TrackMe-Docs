# Task Specs

Her dosya, başka bir agent'ın doğrudan implement edebileceği seviyede detaylı spec içerir.
Entity tanımından endpoint mantığına, frontend bileşenlerine kadar tüm adımlar mevcuttur.

## Aktif Spec Dosyaları

| Dosya | Kapsam | Öncelik | Zorluk |
|-------|--------|---------|--------|
| [pr-display.md](pr-display.md) | PR tablosu athlete analytics'e eklenir — backend yok, sadece frontend | P2 — Hemen | S |
| [exercise-demo-videos.md](exercise-demo-videos.md) | Egzersizlere demo video ekleme (upload, picker, WorkoutMode) | P1 — Planlandı | M |

## Tamamlanan Spec'ler (silindi)

| Feature | Phase | Durum |
|---------|-------|-------|
| Submission & Feedback Videos | Phase 9 | ✅ Tamamlandı |
| Nutrition Tracking A (daily log + goal) | Phase 10 | ✅ Tamamlandı |

---

## Genel codebase kuralları (tüm spec'ler için geçerli)

1. **Migration**: Asla elle yazma. Her zaman CLI:
   ```powershell
   dotnet ef migrations add Phase<N>_<Açıklama> --project src/TrackMe.Api/TrackMe.Api.csproj
   ```
2. **Sütun adları**: Tüm DB sütunları snake_case — `HasColumnName("snake_case")` ile tanımlanmalı
3. **Endpoint yapısı**: `public static class XxxEndpoints` + `MapXxxEndpoints(this IEndpointRouteBuilder app)` extension method
4. **Access gate**: `EndpointHelpers.HasAcceptedRelationshipAsync(db, trainerId, athleteId)` — coaching erişim kontrolü
5. **Notification**: `EndpointHelpers.QueueNotificationAsync(...)` → `db.SaveChangesAsync()` → `EndpointHelpers.PushNotificationAsync(hubContext, notification)`
6. **Forbidden**: `EndpointHelpers.Forbidden("message")` → HTTP 403
7. **Dual-role user**: Trainer JWT ile athlete profiline erişim → email lookup ile `Athletes` tablosunda arama
8. **DTO pattern**: `sealed record` in `Models/Dtos.cs`
9. **Frontend API**: `authFetch` helper'ı kullan, multipart için `fetch` + FormData ile `Authorization` header ekle
10. **i18n**: Her string için hem TR hem EN key ekle — `i18n.js` içindeki mevcut yapıyı takip et
11. **Docs güncelleme**: Her feature sonunda şunları güncelle:
    - `TrackMe-Docs/tasks/phases.md` — phase entry + migration count
    - `TrackMe-Docs/tasks/backlog.md` — task'ları ✅ yap, Completed section'a ekle
    - `TrackMe-Docs/architecture/overview.md` — feature status tablosu
    - `TrackMe-Docs/database/migration-strategy.md` — migration detayları
    - `TrackMe-Api/README.md` — migration count + endpoint listesi

---

## Proje yapısı

```
TrackMe-Api/
  src/TrackMe.Api/
    Data/TrackMeDbContext.cs     — DbSet + OnModelCreating (her entity için)
    Endpoints/                   — Endpoint dosyaları (birer static class)
    Models/
      Enums.cs                   — Tüm enum'lar burada
      Dtos.cs                    — Tüm DTO record'ları burada
      <EntityName>.cs            — Her entity ayrı dosyada
    Services/
      MediaService.cs            — R2 upload/delete metodları
      IMediaStorageProvider.cs   — Storage abstraction
    Program.cs                   — DI kayıt + endpoint map

TrackMe-Web/src/
  views/                         — Her view ayrı .jsx dosyası
  components/                    — Paylaşılan bileşenler
  services/api.js                — Tüm API çağrıları
  i18n.js                        — TR + EN string'ler
  App.jsx                        — Nav config, routing, view render
```

## Mevcut migration sayısı

**Phase 10 sonrası: 56 migration**

## Production bilgileri

- **API**: http://187.77.92.30:5050
- **Scalar docs**: http://187.77.92.30:5050/scalar/v1
- **Web**: http://187.77.92.30:8080
- **Deploy**: VPS'te `docker compose up -d --build` — migrations startup'ta otomatik çalışır
