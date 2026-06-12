# Exercise Demo Videos

## Overview

Trainers (or admins) can attach a demo video to any exercise in the library.
Athletes see the video in the exercise picker and during WorkoutMode so they know correct form.

MediaPurpose.ExerciseVideo is already defined in `Enums.cs`.

## Tech stack context

- **API**: ASP.NET Core 10 Minimal API, EF Core 10, PostgreSQL 16
- **Storage**: Cloudflare R2 via `IMediaStorageProvider`
- **Frontend**: React 18 + Vite SPA

## Dependencies

Phase 9 (submission videos) must be complete — `MediaService.AllowedVideoTypes` and
the video upload pattern (`SaveSubmissionVideoAsync`) already exist and must be reused.

---

## Backend

### 1. Model change — `src/TrackMe.Api/Models/Exercise.cs`

Read the existing `Exercise.cs` first, then add one nullable FK property:

```csharp
public Guid? DemoVideoMediaAssetId { get; set; }
public MediaAsset? DemoVideoMediaAsset { get; set; }
```

---

### 2. DbContext — `src/TrackMe.Api/Data/TrackMeDbContext.cs`

Inside the `modelBuilder.Entity<Exercise>` block in `OnModelCreating`, add:

```csharp
entity.Property(e => e.DemoVideoMediaAssetId).HasColumnName("demo_video_media_asset_id");
entity.HasOne(e => e.DemoVideoMediaAsset)
    .WithMany()
    .HasForeignKey(e => e.DemoVideoMediaAssetId)
    .OnDelete(DeleteBehavior.SetNull);
```

---

### 3. Migration

```powershell
dotnet ef migrations add Phase11_ExerciseDemoVideo --project src/TrackMe.Api/TrackMe.Api.csproj
```

Commit all three generated files.

---

### 4. DTO changes — `src/TrackMe.Api/Models/Dtos.cs`

Find `ExerciseDto` and add `DemoVideoUrl`:

```csharp
public sealed record ExerciseDto(Guid Id, string Name, string Slug, string Category,
    string? PrimaryMuscles, string? Equipment, string? Difficulty, string? Instructions,
    bool IsActive, bool IsGlobal, Guid? OwnerId, string? OwnerName, DateTimeOffset CreatedAt,
    string? DemoVideoUrl = null);
```

---

### 5. MediaService — `src/TrackMe.Api/Services/MediaService.cs`

Add a new upload method for exercise demo videos.
`AllowedVideoTypes` dictionary already exists (added in Phase 9). Reuse it.

```csharp
public async Task<(MediaAsset? Asset, string? Error)> SaveExerciseDemoVideoAsync(
    TrackMeDbContext db,
    AppUser owner,
    Exercise exercise,
    IFormFile file,
    CancellationToken cancellationToken = default)
{
    if (file.Length <= 0) return (null, "file is required.");
    if (file.Length > MaxVideoBytes) return (null, "video must be 200 MB or smaller.");
    if (!AllowedVideoTypes.TryGetValue(file.ContentType, out var extension))
        return (null, "only MP4 and WebM videos are supported.");

    var mediaId = Guid.NewGuid();
    var objectKey = $"exercises/{exercise.Id}/demo/{mediaId}{extension}";

    await using var stream = file.OpenReadStream();
    var stored = await storage.SaveAsync(stream, objectKey, file.ContentType, cancellationToken);

    var asset = new MediaAsset
    {
        Id = mediaId,
        OwnerUserId = owner.Id,
        MediaType = MediaType.Video,
        Purpose = MediaPurpose.ExerciseVideo,
        Visibility = MediaVisibility.Public,
        StorageProvider = stored.StorageProvider,
        Bucket = stored.Bucket,
        ObjectKey = stored.ObjectKey,
        Status = MediaStatus.Ready,
        ModerationStatus = MediaModerationStatus.None,
        MimeType = file.ContentType,
        FileSizeBytes = file.Length,
        OriginalFileName = Path.GetFileName(file.FileName),
        PublicUrl = stored.PublicUrl,
        CreatedAt = DateTimeOffset.UtcNow,
        UploadedAt = DateTimeOffset.UtcNow
    };

    // Delete previous demo video if any
    if (exercise.DemoVideoMediaAssetId is not null)
    {
        var previous = await db.MediaAssets.FirstOrDefaultAsync(
            m => m.Id == exercise.DemoVideoMediaAssetId, cancellationToken);
        if (previous is not null && previous.DeletedAt is null)
        {
            previous.Status = MediaStatus.Deleted;
            previous.DeletedAt = DateTimeOffset.UtcNow;
            await storage.DeleteAsync(previous.ObjectKey, cancellationToken);
        }
    }

    db.MediaAssets.Add(asset);
    exercise.DemoVideoMediaAssetId = asset.Id;
    await db.SaveChangesAsync(cancellationToken);
    return (asset, null);
}

public async Task DeleteExerciseDemoVideoAsync(
    TrackMeDbContext db, Exercise exercise, CancellationToken cancellationToken = default)
{
    if (exercise.DemoVideoMediaAssetId is null) return;
    var asset = await db.MediaAssets.FirstOrDefaultAsync(
        m => m.Id == exercise.DemoVideoMediaAssetId, cancellationToken);
    exercise.DemoVideoMediaAssetId = null;
    if (asset is not null) { asset.Status = MediaStatus.Deleted; asset.DeletedAt = DateTimeOffset.UtcNow; }
    await db.SaveChangesAsync(cancellationToken);
    if (asset is not null) await storage.DeleteAsync(asset.ObjectKey, cancellationToken);
}
```

---

### 6. ExerciseDto mapping

In `ExerciseEndpoints.cs` (or wherever `ExerciseDto` is mapped from an `Exercise` entity),
update the mapping to include `DemoVideoUrl`:

```csharp
// In the ToDto helper or wherever Exercise → ExerciseDto mapping happens:
DemoVideoUrl = exercise.DemoVideoMediaAssetId.HasValue
    ? $"/api/media/{exercise.DemoVideoMediaAssetId.Value}/content"
    : null
```

Also make sure `Include(e => e.DemoVideoMediaAsset)` is added where exercises are queried,
OR just use the FK id (no include needed if you only return the URL).

---

### 7. New endpoints — add to `src/TrackMe.Api/Endpoints/ExerciseEndpoints.cs`

Add two routes inside the existing `MapExerciseEndpoints` method:

```csharp
app.MapPost("/api/exercises/{id:guid}/demo-video", UploadDemoVideo)
    .RequireAuthorization()
    .DisableAntiforgery();
app.MapDelete("/api/exercises/{id:guid}/demo-video", DeleteDemoVideo)
    .RequireAuthorization();
```

**`UploadDemoVideo` handler logic:**
1. Resolve user from JWT (admin or trainer only — use `EndpointHelpers.CanManageExercises(principal)`)
2. Load exercise: `db.Exercises.FirstOrDefaultAsync(e => e.Id == id && e.IsActive)`
3. Check ownership: global exercises (IsGlobal=true) → admin only; user exercises → owner or admin
4. Call `media.SaveExerciseDemoVideoAsync(db, user, exercise, file, ct)`
5. Return 200 with updated `ExerciseDto`

**`DeleteDemoVideo` handler logic:**
1. Same access check as upload
2. Call `media.DeleteExerciseDemoVideoAsync(db, exercise, ct)`
3. Return 204 No Content

**Access rule detail:**
```csharp
// Global exercise: admin only
if (exercise.IsGlobal && !ClaimsReader.IsRole(principal, UserRole.Admin))
    return EndpointHelpers.Forbidden("only admins can modify global exercises.");

// User exercise: must be the owner
if (!exercise.IsGlobal && exercise.OwnerId != userId)
    return EndpointHelpers.Forbidden("you can only modify your own exercises.");
```

---

### 8. Allow ExerciseVideo in GetContent — `src/TrackMe.Api/Endpoints/MediaEndpoints.cs`

Add `MediaPurpose.ExerciseVideo` to the allowed purposes in `GetContent`:

```csharp
if (asset.Purpose is not (MediaPurpose.AvatarPhoto or MediaPurpose.CoverPhoto
    or MediaPurpose.ProgramCoverPhoto or MediaPurpose.ProgressPhoto
    or MediaPurpose.AthleteSubmissionVideo or MediaPurpose.TrainerFeedbackVideo
    or MediaPurpose.AudioFeedback or MediaPurpose.ExerciseVideo))
    return Results.NotFound();
```

---

## Frontend

### 1. `src/services/api.js` additions

```js
uploadExerciseDemoVideo: (exerciseId, file) => {
  const form = new FormData();
  form.append('file', file);
  return fetch(`/api/exercises/${exerciseId}/demo-video`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${getToken()}` },
    body: form
  }).then(handleResponse);
},
deleteExerciseDemoVideo: (exerciseId) =>
  authFetch(`/api/exercises/${exerciseId}/demo-video`, { method: 'DELETE' }),
```

---

### 2. `src/i18n.js` new keys

```js
// TR
demoVideo: 'Demo Video',
uploadDemoVideo: 'Demo Video Yükle',
deleteDemoVideo: 'Demo Videoyu Sil',
confirmDeleteDemoVideo: 'Demo video silinecek. Emin misiniz?',
watchDemoVideo: 'Demo videoyu izle',
noDemoVideo: 'Demo video yok',

// EN
demoVideo: 'Demo Video',
uploadDemoVideo: 'Upload Demo Video',
deleteDemoVideo: 'Delete Demo Video',
confirmDeleteDemoVideo: 'The demo video will be deleted. Are you sure?',
watchDemoVideo: 'Watch demo video',
noDemoVideo: 'No demo video',
```

---

### 3. Exercise picker / list — `ExercisesView.jsx` or wherever exercises are listed

In the exercise list or detail panel, if a `demoVideoUrl` is present:
- Show a small "Demo Video" badge/button next to the exercise name
- Clicking opens a modal with `<video controls src={demoVideoUrl} style={{width:'100%'}} />`

For trainers/admins editing an exercise:
- Show "Upload Demo Video" button (file input accepts `video/mp4,video/webm`)
- If video exists: show player + "Delete Demo Video" button

---

### 4. WorkoutMode — show demo during workout

In the WorkoutMode overlay (wherever exercises are shown during an active session):
- If the exercise has `demoVideoUrl`, show a small "▶ Demo" button next to the exercise name
- Tapping opens a bottom sheet or modal with the video player

The exercise data in WorkoutMode comes from the session's exercise list (already loaded from the API).
The `demoVideoUrl` field should already be in the exercise DTO if the backend returns it.
Verify that the session exercise data includes the demo URL — if not, it may need to be included in `SessionExerciseDto`.

---

### 5. No new view needed — integrate into existing views

No new top-level view or nav entry required.

---

## Docs to update when done

- `TrackMe-Docs/tasks/phases.md` — add Phase 11 (or next number) entry, update migration count
- `TrackMe-Docs/tasks/backlog.md` — mark exercise video tasks ✅
- `TrackMe-Docs/architecture/overview.md` — update feature status table
- `TrackMe-Docs/database/migration-strategy.md` — Phase 11 migration details
- `TrackMe-Api/README.md` — update migration count + endpoints

---

## Testing checklist

- [ ] Admin uploads MP4 video for a global exercise → appears in exercise list
- [ ] Trainer uploads video for their own exercise → appears
- [ ] Trainer tries to upload video for a global exercise → 403
- [ ] Demo video plays in exercise picker modal
- [ ] Demo video "▶ Demo" button appears in WorkoutMode for exercises with a video
- [ ] Delete demo video → video removed from R2 + field cleared
- [ ] Exercises without demo video show no video button (no error)
- [ ] File >200 MB → 400 error
- [ ] Non-video file → 400 error
