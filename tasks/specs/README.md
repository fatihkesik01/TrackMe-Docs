# Task Specs

Her dosya, başka bir agent'ın doğrudan implement edebileceği seviyede detaylı spec içerir.
Entity tanımından endpoint mantığına, frontend bileşenlerine kadar tüm adımlar mevcuttur.

## Dosyalar

| Dosya | Kapsam | Öncelik |
|-------|--------|---------|
| [phase9-submission-videos.md](phase9-submission-videos.md) | Athlete submission video + trainer feedback video/audio | P1 — Sonraki |
| [p1.5a-nutrition-tracking.md](p1.5a-nutrition-tracking.md) | Günlük kalori/makro log + trainer goal | P1.5 — Planlandı |

## Genel codebase kuralları (tüm spec'ler için geçerli)

1. **Migration**: Asla elle yazma. `dotnet ef migrations add Phase<N>_<Açıklama> --project src/TrackMe.Api/TrackMe.Api.csproj`
2. **Sütun adları**: Tüm DB sütunları snake_case — `HasColumnName("snake_case")` ile tanımlanmalı
3. **Endpoint yapısı**: `public static class XxxEndpoints` + `MapXxxEndpoints(this IEndpointRouteBuilder app)` extension method
4. **Access gate**: `EndpointHelpers.HasAcceptedRelationshipAsync(db, trainerId, athleteId)` — trainer-athlete erişim kontrolü
5. **Notification gönderme**: `EndpointHelpers.QueueNotificationAsync(...)` → `db.SaveChangesAsync()` → `EndpointHelpers.SendNotificationAsync(hubContext, notification)`
6. **Forbidden**: `EndpointHelpers.Forbidden("message")` → 403
7. **Dual-role user**: Trainer JWT ile athlete profili erişimi → email lookup ile `Athletes` tablosunda arama
8. **DTO pattern**: `sealed record` in `Dtos.cs`
9. **Frontend API**: `authFetch` helper'ı kullan, `getToken()` ile token al — `api.js` içindeki mevcut helper'larla aynı deseni uygula
10. **i18n**: Her string için hem TR hem EN key ekle — `i18n.js` dosyasındaki mevcut yapıyı takip et
11. **Docs güncelleme**: Her feature sonunda `phases.md`, `backlog.md`, `architecture/overview.md`, `migration-strategy.md`, `TrackMe-Api/README.md` güncellenmeli

## Proje yapısı

```
TrackMe-Api/
  src/TrackMe.Api/
    Data/TrackMeDbContext.cs     — DbSet + OnModelCreating
    Endpoints/                   — Endpoint dosyaları
    Models/
      Enums.cs                   — Tüm enum'lar burada
      Dtos.cs                    — Tüm DTO record'ları burada
      <EntityName>.cs            — Her entity ayrı dosyada
    Services/
      MediaService.cs            — R2 upload/delete
      IMediaStorageProvider.cs   — Storage abstraction
    Program.cs                   — DI + endpoint registration

TrackMe-Web/src/
  views/                         — Her view ayrı .jsx dosyası
  components/                    — Paylaşılan bileşenler
  services/api.js                — Tüm API çağrıları
  i18n.js                        — TR + EN string'ler
  App.jsx                        — Nav, routing, view render
```

## Production bilgileri

- **API**: http://187.77.92.30:5050
- **Scalar docs**: http://187.77.92.30:5050/scalar/v1
- **Web**: http://187.77.92.30:8080
- **Deploy**: VPS'te `docker compose up -d --build` — migrations startup'ta otomatik çalışır
- **Migration sayısı**: Phase 8 sonunda **54 migration**
