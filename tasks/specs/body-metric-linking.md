# Spec: Body Metric Linking to Progress Photos

## Overview

Progress photos already have a `weight_kg_snapshot` field (entered manually at upload time).
This feature adds a proper FK link from a progress photo to the athlete's existing `BodyMetric`
entry for that date. When the link exists, the lightbox and before/after comparison modal show
all 9 body metric fields (weight, body fat, height, arms, chest, waist, hips, legs, muscle%)
without requiring the athlete to type them again.

**Priority:** P1 polish  
**Effort:** M  
**Migration:** `Phase14_ProgressPhotoBodyMetricLink` (migration #60)

---

## Dependencies

- Phase 8 (progress photos) and Phase 2 (body metrics) must be complete — both are.
- No dependency on any other pending spec.

---

## Backend

### 1. Update `ProgressPhoto` model

File: `src/TrackMe.Api/Models/ProgressPhoto.cs`

Add nullable FK and navigation property:

```csharp
public sealed class ProgressPhoto
{
    // ... existing fields ...
    public Guid? BodyMetricId { get; set; }
    public BodyMetric? BodyMetric { get; set; }
}
```

### 2. Update DbContext config

File: `src/TrackMe.Api/Data/TrackMeDbContext.cs`

Inside the `ProgressPhoto` entity block, add:

```csharp
entity.Property(p => p.BodyMetricId).HasColumnName("body_metric_id");
entity.HasOne(p => p.BodyMetric)
    .WithMany()
    .HasForeignKey(p => p.BodyMetricId)
    .OnDelete(DeleteBehavior.SetNull);
```

### 3. Migration

```powershell
dotnet ef migrations add Phase14_ProgressPhotoBodyMetricLink --project src/TrackMe.Api/TrackMe.Api.csproj
```

### 4. Update DTOs

File: `src/TrackMe.Api/Models/Dtos.cs`

Find `ProgressPhotoDto` and add `BodyMetricSnapshot?` field:

```csharp
// New nested DTO (add near BodyMetricDto):
public sealed record BodyMetricSnapshotDto(
    decimal? WeightKg,
    decimal? BodyFatPct,
    decimal? HeightCm,
    decimal? ArmsCm,
    decimal? ChestCm,
    decimal? WaistCm,
    decimal? HipsCm,
    decimal? LegsCm,
    decimal? MusclePct);

// Update existing ProgressPhotoDto to add:
// ... BodyMetricId, BodyMetricSnapshot as last two optional fields
```

The full updated `ProgressPhotoDto`:

```csharp
public sealed record ProgressPhotoDto(
    Guid Id,
    string ImageUrl,
    DateOnly TakenOn,
    string? Notes,
    string Visibility,
    decimal? WeightKgSnapshot,
    DateTimeOffset CreatedAt,
    Guid? BodyMetricId,
    BodyMetricSnapshotDto? BodyMetricSnapshot);
```

### 5. Update ProgressPhotoEndpoints.cs

File: `src/TrackMe.Api/Endpoints/ProgressPhotoEndpoints.cs`

**`POST /api/progress-photos`** — add optional `bodyMetricId` form field:

```csharp
// In the multipart form handler:
Guid? bodyMetricId = null;
if (form.TryGetValue("bodyMetricId", out var bmIdStr) && Guid.TryParse(bmIdStr, out var bmId))
{
    // Verify ownership: the BodyMetric must belong to this athlete
    var bodyMetricExists = await db.BodyMetrics.AnyAsync(b => b.Id == bmId && b.AthleteId == athlete.Id, ct);
    if (!bodyMetricExists)
        return Results.BadRequest(new { message = "bodyMetricId not found or does not belong to this athlete." });
    bodyMetricId = bmId;
}
```

Pass `bodyMetricId` to `MediaService.SaveProgressPhotoAsync` (or set it on the `ProgressPhoto` entity directly after creating it inside the endpoint — simplest approach).

**`PATCH /api/progress-photos/{id}`** — add optional `bodyMetricId` field to request body:

```csharp
public sealed record PatchProgressPhotoRequest(
    string? Notes,
    string? Visibility,
    decimal? WeightKgSnapshot,
    Guid? BodyMetricId);        // NEW — null = unlink, value = link
```

In the handler, if `request.BodyMetricId` is provided (even null explicitly), update the link:
```csharp
if (request.BodyMetricId.HasValue)
{
    // Link to a BodyMetric
    var exists = await db.BodyMetrics.AnyAsync(b => b.Id == request.BodyMetricId.Value && b.AthleteId == photo.AthleteId);
    if (!exists) return Results.BadRequest(new { message = "bodyMetricId not found." });
    photo.BodyMetricId = request.BodyMetricId.Value;
}
else
{
    photo.BodyMetricId = null; // unlink
}
```

Note: since `Guid?` is nullable, use a wrapper object to distinguish "not provided" from "null (unlink)":
```csharp
public sealed record PatchProgressPhotoRequest(
    string? Notes,
    string? Visibility,
    decimal? WeightKgSnapshot,
    Guid? BodyMetricId,
    bool UnlinkBodyMetric = false);
```
If `UnlinkBodyMetric = true` → set `photo.BodyMetricId = null`. If `BodyMetricId` has a value → link. Otherwise leave unchanged.

**DTO mapping** — when building `ProgressPhotoDto`, include the metric snapshot:

```csharp
BodyMetricSnapshotDto? metricSnapshot = null;
if (photo.BodyMetric is not null)
{
    metricSnapshot = new BodyMetricSnapshotDto(
        photo.BodyMetric.WeightKg,
        photo.BodyMetric.BodyFatPct,
        photo.BodyMetric.HeightCm,
        photo.BodyMetric.ArmsCm,
        photo.BodyMetric.ChestCm,
        photo.BodyMetric.WaistCm,
        photo.BodyMetric.HipsCm,
        photo.BodyMetric.LegsCm,
        photo.BodyMetric.MusclePct);
}
return new ProgressPhotoDto(..., photo.BodyMetricId, metricSnapshot);
```

**Queries that return photos** — add `.Include(p => p.BodyMetric)` to all queries that build `ProgressPhotoDto`:
- `GET /api/progress-photos` (athlete own list)
- `GET /api/athletes/{athleteId}/progress-photos` (trainer view)

### 6. New helper endpoint (optional but useful)

**`GET /api/body-metrics/dates`** — returns list of `DateOnly` values where the athlete has body metric entries. Used by the frontend to populate the "link metric" dropdown.

```
GET /api/body-metrics/dates
Auth: Athlete or Trainer (for athlete)
Response: DateOnly[]
```

Or simpler: just use the existing `GET /api/body-metrics` and filter client-side.

---

## Frontend

### api.js — new/updated methods

```js
// In the api export object:
uploadProgressPhoto: (formData) =>
  authFetch('/api/progress-photos', { method: 'POST', body: formData }),  // already exists
patchProgressPhoto: (id, body) =>
  authFetch(`/api/progress-photos/${id}`, { method: 'PATCH', body: JSON.stringify(body) }),  // already exists
getBodyMetrics: (athleteId) =>  // already exists but confirm it's here
  authFetch(`/api/body-metrics${athleteId ? `?athleteId=${athleteId}` : ''}`),
```

### i18n.js — add keys (TR + EN)

```js
// TR:
linkBodyMetric: 'Vücut ölçümü ekle',
linkedMetric: 'Bağlı ölçüm',
unlinkBodyMetric: 'Bağlantıyı kaldır',
noMetricLinked: 'Ölçüm bağlanmamış',
bodyMetricOn: 'Ölçüm tarihi',

// EN:
linkBodyMetric: 'Link body metric',
linkedMetric: 'Linked metric',
unlinkBodyMetric: 'Unlink metric',
noMetricLinked: 'No metric linked',
bodyMetricOn: 'Metric date',
```

### ProgressPhotosView.jsx — upload modal

File: `src/views/ProgressPhotosView.jsx`

In the upload modal, after the `weightKgSnapshot` field:

1. Load athlete's body metrics on modal open: `api.getBodyMetrics()` → store in state
2. Show a `<select>` for "Link body metric (optional)":
   - Options: each `BodyMetric` entry formatted as "Ağırlık: X kg · Tarih: YYYY-MM-DD"
   - Empty option: "— Seçme —" (no link)
3. Include `bodyMetricId` in the FormData if selected
4. After successful upload, if a metric was linked, the returned DTO has `bodyMetricSnapshot` populated

**Lightbox / photo detail** — when `photo.bodyMetricSnapshot` is present, show a compact metric grid below the photo notes:

```
Ağırlık: 82.5 kg  |  Vücut Yağı: 18%  |  Kol: 38 cm  ...
```

**Before/after comparison modal** — show metric diff between the two selected photos (if both have `bodyMetricSnapshot`):

```
Ağırlık: 82.5 → 78.0 kg (-4.5 kg)
Vücut Yağı: 18% → 15% (-3%)
```

### AthleteDetailView.jsx — trainer view

The trainer's "Progress Photos" tab already shows photos. Add the metric snapshot display below each photo in the lightbox (same as athlete view — just read from `bodyMetricSnapshot`).

---

## Docs to update after implementation

- `TrackMe-Docs/tasks/phases.md` — add Phase 14 entry, update migration count to 60
- `TrackMe-Docs/tasks/backlog.md` — mark "Body metric linking" ✅
- `TrackMe-Docs/architecture/overview.md` — no change needed
- `TrackMe-Docs/database/migration-strategy.md` — add Phase14 migration row
- `TrackMe-Api/README.md` — update migration count, update PATCH /api/progress-photos docs

---

## Testing checklist

- [ ] Upload a photo without a body metric link → `bodyMetricId: null`, `bodyMetricSnapshot: null`
- [ ] Upload a photo with a valid `bodyMetricId` → response includes snapshot data
- [ ] Upload with an invalid `bodyMetricId` (different athlete's metric) → 400 Bad Request
- [ ] PATCH to link an existing photo to a metric → snapshot appears in next GET
- [ ] PATCH with `unlinkBodyMetric: true` → `bodyMetricId` cleared
- [ ] Frontend: metric dropdown populates in upload modal
- [ ] Frontend: snapshot data shows in lightbox
- [ ] Frontend: before/after modal shows diff when both photos have snapshot
- [ ] Trainer view shows snapshot data in athlete photo lightbox
- [ ] Build: `dotnet build` 0 errors, `npm run build` succeeds
