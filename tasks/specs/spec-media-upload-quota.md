# Spec: Media Upload Size Limits (Per-User Storage Quota)

**Durum**: ⬜ Yapılabilir  
**Zorluk**: M (Medium — yarım gün)  
**Migration**: YOK — mevcut `media_assets.file_size_bytes` sütunu kullanılıyor  
**Bağımlılık**: Yok — Phase 17 sonrası hemen alınabilir

---

## Amaç

Her kullanıcı için R2'ye yükleyebileceği toplam dosya boyutuna bir üst limit koy.
Upload yapılmadan önce mevcut kullanım kontrol edilir; limit aşılıyorsa `413 Payload Too Large` döner.
Ayrıca kullanıcının kendi kotasını görebileceği `GET /api/media/quota` endpoint'i eklenir.

---

## Kota Limitleri

`MediaService.cs` içinde sabit olarak tanımlanır:

```csharp
public const long QuotaAthleteBytes  = 500L  * 1024 * 1024;  // 500 MB
public const long QuotaTrainerBytes  = 2000L * 1024 * 1024;  // 2 GB
public const long QuotaAdminBytes    = long.MaxValue;         // sınırsız
```

Rol → limit eşlemesi:
| Rol | Limit |
|-----|-------|
| Athlete | 500 MB |
| Trainer | 2 GB |
| Admin | Sınırsız |

---

## Backend Değişiklikleri

### 1. `MediaService.cs` — Yeni helper + sabitler

`MaxProfileImageBytes` satırlarının altına sabit ekle:

```csharp
public const long QuotaAthleteBytes = 500L  * 1024 * 1024;
public const long QuotaTrainerBytes = 2000L * 1024 * 1024;
public const long QuotaAdminBytes   = long.MaxValue;
```

Yeni private async helper (inject gerekmez, `db` parametreli):

```csharp
private static async Task<string?> CheckQuotaAsync(
    TrackMeDbContext db, Guid ownerUserId, UserRole role, long incomingBytes,
    CancellationToken cancellationToken = default)
{
    var limit = role switch
    {
        UserRole.Admin   => QuotaAdminBytes,
        UserRole.Trainer => QuotaTrainerBytes,
        _                => QuotaAthleteBytes,
    };

    if (limit == long.MaxValue) return null; // admin: skip check

    var usedBytes = await db.MediaAssets
        .Where(m => m.OwnerUserId == ownerUserId
                 && m.DeletedAt == null
                 && m.Status != MediaStatus.Deleted)
        .SumAsync(m => m.FileSizeBytes, cancellationToken);

    if (usedBytes + incomingBytes > limit)
    {
        var limitMb = limit / 1024 / 1024;
        var usedMb  = usedBytes / 1024 / 1024;
        return $"storage quota exceeded. Used: {usedMb} MB / {limitMb} MB limit.";
    }

    return null;
}
```

### 2. `MediaService.cs` — Her `Save*` metoduna quota check ekle

Her metodun başında (boyut ve tip doğrulamasından hemen sonra) şu kalıbı uygula:

```csharp
var quotaError = await CheckQuotaAsync(db, user.Id, user.Role, file.Length, cancellationToken);
if (quotaError is not null) return (null, quotaError);
```

Etkilenen metodlar (hepsinde aynı kalıp):
- `SaveProfileImageAsync` — `user.Id`, `user.Role`
- `SaveProgramCoverAsync` — `user.Id`, `user.Role`
- `SaveExerciseDemoVideoAsync` — trainer/admin user ID ve rolü (parametre olarak `AppUser user` alıyor mu kontrol et; almıyorsa ekle veya UserId/Role'u al)
- `SaveProgressPhotoAsync` — athlete user
- `SaveSubmissionVideoAsync` — athlete user
- `SaveFeedbackMediaAsync` — trainer user

> **Not**: `AppUser.Role` alanı `UserRole` enum'ı içeriyor. Eğer metodlar `AppUser user` almıyorsa parametre olarak `UserRole role` ekle.

### 3. Yeni endpoint: `GET /api/media/quota`

`MediaEndpoints.cs` içine ekle:

```csharp
app.MapGet("/api/media/quota", GetQuota).RequireAuthorization();
```

Handler:

```csharp
private static async Task<IResult> GetQuota(
    ClaimsPrincipal principal, TrackMeDbContext db, CancellationToken cancellationToken)
{
    var userId = Guid.Parse(principal.FindFirstValue(ClaimTypes.NameIdentifier)!);
    var user = await db.Users.FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);
    if (user is null) return Results.NotFound();

    var usedBytes = await db.MediaAssets
        .Where(m => m.OwnerUserId == userId
                 && m.DeletedAt == null
                 && m.Status != MediaStatus.Deleted)
        .SumAsync(m => m.FileSizeBytes, cancellationToken);

    var limitBytes = user.Role switch
    {
        UserRole.Admin   => MediaService.QuotaAdminBytes,
        UserRole.Trainer => MediaService.QuotaTrainerBytes,
        _                => MediaService.QuotaAthleteBytes,
    };

    return Results.Ok(new MediaQuotaDto(
        usedBytes,
        limitBytes == long.MaxValue ? null : limitBytes,
        limitBytes == long.MaxValue ? null : (double)usedBytes / limitBytes * 100
    ));
}
```

### 4. `Dtos.cs` — Yeni DTO

```csharp
public sealed record MediaQuotaDto(long UsedBytes, long? LimitBytes, double? UsedPercent);
```

---

## Nerede Çağrılıyor: Upload Endpoint Haritası

| Endpoint | Metod | Dosya |
|----------|-------|-------|
| `POST /api/media/profile/avatar` | `SaveProfileImageAsync` | MediaEndpoints.cs |
| `POST /api/media/profile/cover` | `SaveProfileImageAsync` | MediaEndpoints.cs |
| `POST /api/media/programs/published/{id}/cover` | `SaveProgramCoverAsync` | MediaEndpoints.cs |
| `POST /api/progress-photos` | `SaveProgressPhotoAsync` | ProgressPhotoEndpoints.cs |
| `POST /api/submissions` | `SaveSubmissionVideoAsync` | SubmissionEndpoints.cs |
| `POST /api/submissions/{id}/feedback` | `SaveFeedbackMediaAsync` | SubmissionEndpoints.cs |
| `POST /api/exercises/{id}/demo-video` | `SaveExerciseDemoVideoAsync` | ExerciseEndpoints.cs |

Tümü `MediaService` üzerinden geçiyor — helper `MediaService`'e eklenmesi yeterli.

---

## Frontend Değişiklikleri

### 1. `services/api.js`

```js
mediaQuota: () => request('/api/media/quota'),
```

### 2. i18n.js — Yeni anahtarlar (TR + EN)

```js
// TR
storageUsage: 'Depolama Kullanımı',
storageUsed: 'kullanıldı',
storageOf: '/',
storageUnlimited: 'Sınırsız',
storageQuotaExceeded: 'Depolama kotanız doldu. Eski medyaları silerek yer açın.',

// EN
storageUsage: 'Storage Usage',
storageUsed: 'used',
storageOf: 'of',
storageUnlimited: 'Unlimited',
storageQuotaExceeded: 'Storage quota exceeded. Delete old media to free up space.',
```

### 3. `ProfileView.jsx` (veya Settings bölümü) — Kota göstergesi

`ProfileView.jsx`'te profil yüklendiğinde kota bilgisini de çek ve göster.
Mevcut profil yükleme Effect'inin içine ekle:

```js
const quota = await api.mediaQuota();
setQuota(quota);
```

Bileşen (kota state ve gösterim):

```jsx
{quota && (
  <div className="storage-usage-bar">
    <div className="storage-usage-label">
      <span>{t('storageUsage')}</span>
      <span>
        {quota.limitBytes
          ? `${formatBytes(quota.usedBytes)} ${t('storageOf')} ${formatBytes(quota.limitBytes)}`
          : `${formatBytes(quota.usedBytes)} (${t('storageUnlimited')})`}
      </span>
    </div>
    {quota.limitBytes && (
      <div className="storage-bar-track">
        <div
          className={`storage-bar-fill${(quota.usedPercent ?? 0) >= 90 ? ' storage-bar-warn' : ''}`}
          style={{ width: `${Math.min(100, quota.usedPercent ?? 0).toFixed(1)}%` }}
        />
      </div>
    )}
  </div>
)}
```

Yardımcı fonksiyon (`ProfileView.jsx` içine veya `utils/` altına):

```js
function formatBytes(bytes) {
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  if (bytes < 1024 * 1024 * 1024) return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
  return `${(bytes / 1024 / 1024 / 1024).toFixed(2)} GB`;
}
```

### 4. Upload hata yönetimi — 413 durumu

`api.js`'deki `request` helper'ı zaten `err.status` ve `err.message` dönüyor.
Upload yapan tüm bileşenler (`ProgressPhotosView`, `SubmissionsView`, profil upload, vb.)
şu hata mesajını zaten gösteriyor:

```js
addToast(err.message, 'error');
```

API `"storage quota exceeded..."` mesajını döndürdüğü için **ek bir frontend değişikliği gerekmez** — mevcut `err.message` toast'ı yeterli.

### 5. CSS — Depolama çubuğu

```css
.storage-usage-bar {
  margin-top: 16px;
}
.storage-usage-label {
  display: flex;
  justify-content: space-between;
  font-size: 0.78rem;
  color: var(--c-faint);
  margin-bottom: 4px;
}
.storage-bar-track {
  height: 6px;
  background: var(--c-border);
  border-radius: 3px;
  overflow: hidden;
}
.storage-bar-fill {
  height: 100%;
  background: var(--c-accent);
  border-radius: 3px;
  transition: width 0.3s;
}
.storage-bar-fill.storage-bar-warn {
  background: var(--c-danger);
}
```

CSS'i `ProfileView.jsx` ile ilgili mevcut style bloğuna veya `index.css`'e ekle.

---

## Kontrol Edilmesi Gerekenler

1. `AppUser` modelinde `Role` alanının `UserRole` enum olduğunu doğrula (`ClaimsReader.GetRole` veya `user.Role`)
2. `SaveExerciseDemoVideoAsync` parametrelerini kontrol et — `AppUser` alıyor mu, yoksa sadece `userId` mi? Gerekirse `UserRole role` parametresi ekle
3. `SaveFeedbackMediaAsync` de aynı şekilde kontrol et

---

## Dokümantasyon (Tamamlayınca)

- `TrackMe-Api/README.md` — yeni endpoint `GET /api/media/quota`
- `TrackMe-Docs/tasks/backlog.md` — "Media upload size limits" → ✅ taşı
- `TrackMe-Docs/architecture/overview.md` — özellik durumu güncellemesi gerekmez (zaten Live)
- `TrackMe-Docs/database/migration-strategy.md` — migration yok, güncelleme gerekmez

---

## Özet

| | Durum |
|-|-------|
| Migration | Yok |
| Yeni endpoint | `GET /api/media/quota` |
| Backend değişikliği | `MediaService.cs` — 3 sabit + 1 helper + her Save* metoduna 2 satır |
| Frontend değişikliği | `ProfileView.jsx` kota göstergesi + CSS + i18n |
| Mevcut upload hatası | `err.message` toast zaten çalışıyor |
