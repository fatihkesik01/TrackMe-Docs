# Task Specs

Her dosya, başka bir agent'ın doğrudan implement edebileceği seviyede detaylı spec içerir.
Entity tanımından endpoint mantığına, frontend bileşenlerine kadar tüm adımlar mevcuttur.

## Aktif Spec Dosyaları

| Dosya | Feature | Agent | Zorluk |
|-------|---------|-------|--------|
| [spec-gym-community.md](spec-gym-community.md) | Phase 19 — Gym & Community | Diğer agent | L |

Diğer adaylar için bkz: [backlog.md](../backlog.md)

## Tamamlanan Spec'ler (dosyalar silindi)

| Feature | Phase | Durum |
|---------|-------|-------|
| Submission & Feedback Videos | Phase 9 | ✅ |
| Nutrition Tracking A (daily log + goal) | Phase 10 | ✅ |
| Exercise Demo Videos | Phase 11 | ✅ |
| Personal Records display | – (frontend only) | ✅ |
| Nutrition Meals B (FoodItem, Meal, MealEntry) | Phase 12 | ✅ |
| Body Metric Linking to Progress Photos | Phase 14 | ✅ |
| Missed Workout & Nutrition Notifications | Phase 15 | ✅ |
| Per-user Media Storage Quota | – (migration yok) | ✅ |

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
9. **Enum pattern**: Tüm enum'lar `Models/Enums.cs`'te, entity dosyasında tanımlanmaz
10. **Frontend API**: `authFetch` helper, multipart için `fetch` + FormData + `Authorization` header
11. **i18n**: Her string için hem TR hem EN key ekle
12. **Docs güncelleme**: Her feature sonunda şunları güncelle:
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
    Data/
      TrackMeDbContext.cs    — DbSet + OnModelCreating (her entity için)
      ExerciseSeeder.cs      — global egzersiz seeding
      FoodItemSeeder.cs      — global TR yemek seeding
    Endpoints/               — Endpoint dosyaları (birer static class)
    Models/
      Enums.cs               — Tüm enum'lar burada
      Dtos.cs                — Tüm DTO record'ları burada
      <EntityName>.cs        — Her entity ayrı dosyada
    Services/
      MediaService.cs        — R2 upload/delete metodları
      OrphanMediaCleanupService.cs  — 24h GC background service
      RefreshTokenCleanupService.cs — 24h token prune background service
    Program.cs               — DI kayıt + endpoint map + seeder çağrıları

TrackMe-Web/src/
  views/                     — Her view ayrı .jsx dosyası
  components/                — Paylaşılan bileşenler
  services/api.js            — Tüm API çağrıları
  i18n.js                    — TR + EN string'ler
  App.jsx                    — Nav config, routing, view render
```

## Mevcut migration sayısı

**Phase 20 sonrası: 65 migration**

## Production bilgileri

- **API**: http://187.77.92.30:5050
- **Scalar docs**: http://187.77.92.30:5050/scalar/v1
- **Web**: http://187.77.92.30:8080
- **Deploy**: VPS'te `docker compose up -d --build` — migrations startup'ta otomatik çalışır
