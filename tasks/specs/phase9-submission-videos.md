# Phase 9 — Submission & Feedback Videos

## Overview

Athletes upload short video clips of their exercise form (linked to a session or exercise).
Trainers receive a notification, watch the clip, and respond with a video or audio feedback.
Athletes are notified when feedback arrives and can mark it viewed.

## Tech stack context

- **API**: ASP.NET Core 10 Minimal API, EF Core 10, PostgreSQL 16
- **Storage**: Cloudflare R2 via `IMediaStorageProvider` (same pattern as progress photos)
- **Frontend**: React 18 + Vite SPA
- **Repos**: `TrackMe-Api` (backend) · `TrackMe-Web` (frontend)
- **Working dir (API)**: `TrackMe-Api/`
- **Working dir (Web)**: `TrackMe-Web/src/`

## Dependencies

Phase 8 (progress photos) must be complete — the `MediaService` / `IMediaStorageProvider`
pattern is already established and must be followed identically.

---

## Backend

### 1. New enum values — `src/TrackMe.Api/Models/Enums.cs`

Add to `NotificationType`:
```
SubmissionReceived, FeedbackReceived
```

The file already has `AthleteSubmissionVideo`, `TrainerFeedbackVideo`, `AudioFeedback`
in `MediaPurpose` — do **not** add them again.

After change the enum line looks like:
```csharp
public enum NotificationType { RelationshipRequest, RelationshipAccepted, RelationshipRejected,
    RelationshipEnded, ProgramAssigned, WorkoutCompleted, NewMessage, ConnectionRequest,
    ConnectionAccepted, ConnectionRejected, ConnectionEnded, ProgramUpdateAvailable,
    NewFollower, SubmissionReceived, FeedbackReceived }
```

---

### 2. New entity — `src/TrackMe.Api/Models/VideoSubmission.cs`

```csharp
namespace TrackMe.Api.Models;

public sealed class VideoSubmission
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid AthleteId { get; set; }
    public Athlete Athlete { get; set; } = null!;
    public Guid MediaAssetId { get; set; }
    public MediaAsset MediaAsset { get; set; } = null!;
    public Guid? SessionId { get; set; }
    public WorkoutSession? Session { get; set; }
    public Guid? SessionExerciseId { get; set; }
    public WorkoutSessionExercise? SessionExercise { get; set; }
    public string? Title { get; set; }
    public string? Notes { get; set; }
    public MediaVisibility Visibility { get; set; } = MediaVisibility.CoachOnly;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public List<VideoFeedback> Feedbacks { get; set; } = [];
}
```

---

### 3. New entity — `src/TrackMe.Api/Models/VideoFeedback.cs`

```csharp
namespace TrackMe.Api.Models;

public sealed class VideoFeedback
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid SubmissionId { get; set; }
    public VideoSubmission Submission { get; set; } = null!;
    public Guid TrainerId { get; set; }
    public Trainer Trainer { get; set; } = null!;
    public Guid MediaAssetId { get; set; }
    public MediaAsset MediaAsset { get; set; } = null!;
    public string? Notes { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? ViewedAt { get; set; }
}
```

---

### 4. DbContext — `src/TrackMe.Api/Data/TrackMeDbContext.cs`

Add DbSet properties (after `ProgressPhotos`):
```csharp
public DbSet<VideoSubmission> VideoSubmissions => Set<VideoSubmission>();
public DbSet<VideoFeedback> VideoFeedbacks => Set<VideoFeedback>();
```

Add to `OnModelCreating`:

```csharp
modelBuilder.Entity<VideoSubmission>(entity =>
{
    entity.ToTable("video_submissions");
    entity.HasKey(e => e.Id);
    entity.Property(e => e.Id).HasColumnName("id");
    entity.Property(e => e.AthleteId).HasColumnName("athlete_id").IsRequired();
    entity.Property(e => e.MediaAssetId).HasColumnName("media_asset_id").IsRequired();
    entity.Property(e => e.SessionId).HasColumnName("session_id");
    entity.Property(e => e.SessionExerciseId).HasColumnName("session_exercise_id");
    entity.Property(e => e.Title).HasColumnName("title").HasMaxLength(200);
    entity.Property(e => e.Notes).HasColumnName("notes").HasMaxLength(2000);
    entity.Property(e => e.Visibility).HasColumnName("visibility").HasConversion<int>().IsRequired();
    entity.Property(e => e.CreatedAt).HasColumnName("created_at").IsRequired();
    entity.HasOne(e => e.Athlete).WithMany().HasForeignKey(e => e.AthleteId).OnDelete(DeleteBehavior.Cascade);
    entity.HasOne(e => e.MediaAsset).WithMany().HasForeignKey(e => e.MediaAssetId).OnDelete(DeleteBehavior.Cascade);
    entity.HasOne(e => e.Session).WithMany().HasForeignKey(e => e.SessionId).OnDelete(DeleteBehavior.SetNull);
    entity.HasOne(e => e.SessionExercise).WithMany().HasForeignKey(e => e.SessionExerciseId).OnDelete(DeleteBehavior.SetNull);
    entity.HasIndex(e => new { e.AthleteId, e.CreatedAt });
});

modelBuilder.Entity<VideoFeedback>(entity =>
{
    entity.ToTable("video_feedbacks");
    entity.HasKey(e => e.Id);
    entity.Property(e => e.Id).HasColumnName("id");
    entity.Property(e => e.SubmissionId).HasColumnName("submission_id").IsRequired();
    entity.Property(e => e.TrainerId).HasColumnName("trainer_id").IsRequired();
    entity.Property(e => e.MediaAssetId).HasColumnName("media_asset_id").IsRequired();
    entity.Property(e => e.Notes).HasColumnName("notes").HasMaxLength(2000);
    entity.Property(e => e.CreatedAt).HasColumnName("created_at").IsRequired();
    entity.Property(e => e.ViewedAt).HasColumnName("viewed_at");
    entity.HasOne(e => e.Submission).WithMany(s => s.Feedbacks).HasForeignKey(e => e.SubmissionId).OnDelete(DeleteBehavior.Cascade);
    entity.HasOne(e => e.Trainer).WithMany().HasForeignKey(e => e.TrainerId).OnDelete(DeleteBehavior.Restrict);
    entity.HasOne(e => e.MediaAsset).WithMany().HasForeignKey(e => e.MediaAssetId).OnDelete(DeleteBehavior.Cascade);
    entity.HasIndex(e => e.SubmissionId);
});
```

---

### 5. Migration

**NEVER write migrations by hand.** Run:
```powershell
dotnet ef migrations add Phase9_SubmissionVideos --project src/TrackMe.Api/TrackMe.Api.csproj
```

Commit all three generated files: `<timestamp>_Phase9_SubmissionVideos.cs`, `.Designer.cs`, and the updated `TrackMeDbContextModelSnapshot.cs`.

---

### 6. New DTOs — `src/TrackMe.Api/Models/Dtos.cs`

Add after the progress photo DTOs section:

```csharp
// ─── Video Submissions ────────────────────────────────────────────────────────
public sealed record VideoSubmissionDto(
    Guid Id,
    Guid AthleteId,
    Guid MediaAssetId,
    string VideoUrl,
    Guid? SessionId,
    Guid? SessionExerciseId,
    string? Title,
    string? Notes,
    string Visibility,
    int FeedbackCount,
    bool HasUnviewedFeedback,
    DateTimeOffset CreatedAt);

public sealed record VideoFeedbackDto(
    Guid Id,
    Guid SubmissionId,
    Guid TrainerId,
    string TrainerName,
    Guid MediaAssetId,
    string MediaUrl,
    string MediaType,
    string? Notes,
    DateTimeOffset CreatedAt,
    DateTimeOffset? ViewedAt);

public sealed record UploadSubmissionRequest(
    string? Title,
    string? Notes,
    string? Visibility,
    Guid? SessionId,
    Guid? SessionExerciseId);

public sealed record UploadFeedbackRequest(
    string? Notes);
```

---

### 7. MediaService additions — `src/TrackMe.Api/Services/MediaService.cs`

Add video and audio allowed types (near the top, alongside `AllowedImageTypes`):

```csharp
private static readonly Dictionary<string, string> AllowedVideoTypes = new(StringComparer.OrdinalIgnoreCase)
{
    ["video/mp4"] = ".mp4",
    ["video/webm"] = ".webm",
};

private static readonly Dictionary<string, string> AllowedAudioTypes = new(StringComparer.OrdinalIgnoreCase)
{
    ["audio/mpeg"] = ".mp3",
    ["audio/webm"] = ".webm",
    ["audio/ogg"] = ".ogg",
};

public const long MaxVideoBytes = 200L * 1024 * 1024;  // 200 MB
public const long MaxAudioBytes = 20L * 1024 * 1024;   // 20 MB
```

Add method `SaveSubmissionVideoAsync`:

```csharp
public async Task<(MediaAsset? Asset, VideoSubmission? Submission, string? Error)> SaveSubmissionVideoAsync(
    TrackMeDbContext db,
    AppUser owner,
    Athlete athlete,
    IFormFile file,
    string? title,
    string? notes,
    MediaVisibility visibility,
    Guid? sessionId,
    Guid? sessionExerciseId,
    CancellationToken cancellationToken = default)
{
    if (file.Length <= 0) return (null, null, "file is required.");
    if (file.Length > MaxVideoBytes) return (null, null, "video must be 200 MB or smaller.");
    if (!AllowedVideoTypes.TryGetValue(file.ContentType, out var extension))
        return (null, null, "only MP4 and WebM videos are supported.");

    var mediaId = Guid.NewGuid();
    var objectKey = $"athletes/{athlete.Id}/submissions/{mediaId}{extension}";

    await using var stream = file.OpenReadStream();
    var stored = await storage.SaveAsync(stream, objectKey, file.ContentType, cancellationToken);

    var asset = new MediaAsset
    {
        Id = mediaId,
        OwnerUserId = owner.Id,
        MediaType = MediaType.Video,
        Purpose = MediaPurpose.AthleteSubmissionVideo,
        Visibility = visibility,
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

    var submission = new VideoSubmission
    {
        AthleteId = athlete.Id,
        MediaAssetId = asset.Id,
        SessionId = sessionId,
        SessionExerciseId = sessionExerciseId,
        Title = string.IsNullOrWhiteSpace(title) ? null : title.Trim(),
        Notes = string.IsNullOrWhiteSpace(notes) ? null : notes.Trim(),
        Visibility = visibility
    };

    db.MediaAssets.Add(asset);
    db.VideoSubmissions.Add(submission);
    await db.SaveChangesAsync(cancellationToken);

    return (asset, submission, null);
}
```

Add method `SaveFeedbackMediaAsync` (trainer upload — video or audio):

```csharp
public async Task<(MediaAsset? Asset, VideoFeedback? Feedback, string? Error)> SaveFeedbackMediaAsync(
    TrackMeDbContext db,
    AppUser owner,
    Trainer trainer,
    VideoSubmission submission,
    IFormFile file,
    string? notes,
    CancellationToken cancellationToken = default)
{
    bool isVideo = AllowedVideoTypes.ContainsKey(file.ContentType);
    bool isAudio = AllowedAudioTypes.ContainsKey(file.ContentType);

    if (!isVideo && !isAudio)
        return (null, null, "only MP4, WebM (video) or MP3, WebM, OGG (audio) are supported.");

    long maxBytes = isAudio ? MaxAudioBytes : MaxVideoBytes;
    if (file.Length <= 0) return (null, null, "file is required.");
    if (file.Length > maxBytes)
        return (null, null, isAudio ? "audio must be 20 MB or smaller." : "video must be 200 MB or smaller.");

    var mimeToExt = isVideo ? AllowedVideoTypes : AllowedAudioTypes;
    mimeToExt.TryGetValue(file.ContentType, out var extension);
    var mediaId = Guid.NewGuid();
    var objectKey = $"trainers/{trainer.Id}/feedback/{mediaId}{extension}";

    await using var stream = file.OpenReadStream();
    var stored = await storage.SaveAsync(stream, objectKey, file.ContentType, cancellationToken);

    var purpose = isAudio ? MediaPurpose.AudioFeedback : MediaPurpose.TrainerFeedbackVideo;
    var asset = new MediaAsset
    {
        Id = mediaId,
        OwnerUserId = owner.Id,
        MediaType = isAudio ? MediaType.Audio : MediaType.Video,
        Purpose = purpose,
        Visibility = MediaVisibility.CoachOnly,
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

    var feedback = new VideoFeedback
    {
        SubmissionId = submission.Id,
        TrainerId = trainer.Id,
        MediaAssetId = asset.Id,
        Notes = string.IsNullOrWhiteSpace(notes) ? null : notes.Trim()
    };

    db.MediaAssets.Add(asset);
    db.VideoFeedbacks.Add(feedback);
    await db.SaveChangesAsync(cancellationToken);

    return (asset, feedback, null);
}
```

Add delete helpers:

```csharp
public async Task DeleteVideoSubmissionAsync(TrackMeDbContext db, VideoSubmission submission, CancellationToken ct)
{
    var asset = await db.MediaAssets.FirstOrDefaultAsync(m => m.Id == submission.MediaAssetId, ct);
    db.VideoSubmissions.Remove(submission);
    if (asset is not null) { asset.Status = MediaStatus.Deleted; asset.DeletedAt = DateTimeOffset.UtcNow; }
    await db.SaveChangesAsync(ct);
    if (asset is not null) await storage.DeleteAsync(asset.ObjectKey, ct);
}

public async Task DeleteVideoFeedbackAsync(TrackMeDbContext db, VideoFeedback feedback, CancellationToken ct)
{
    var asset = await db.MediaAssets.FirstOrDefaultAsync(m => m.Id == feedback.MediaAssetId, ct);
    db.VideoFeedbacks.Remove(feedback);
    if (asset is not null) { asset.Status = MediaStatus.Deleted; asset.DeletedAt = DateTimeOffset.UtcNow; }
    await db.SaveChangesAsync(ct);
    if (asset is not null) await storage.DeleteAsync(asset.ObjectKey, ct);
}
```

---

### 8. Allow media purposes in GetContent — `src/TrackMe.Api/Endpoints/MediaEndpoints.cs`

Change the purpose filter in `GetContent` to:
```csharp
if (asset.Purpose is not (MediaPurpose.AvatarPhoto or MediaPurpose.CoverPhoto
    or MediaPurpose.ProgramCoverPhoto or MediaPurpose.ProgressPhoto
    or MediaPurpose.AthleteSubmissionVideo or MediaPurpose.TrainerFeedbackVideo
    or MediaPurpose.AudioFeedback))
    return Results.NotFound();
```

---

### 9. New endpoint file — `src/TrackMe.Api/Endpoints/SubmissionEndpoints.cs`

Access rules:
- **Upload submission**: athlete only (or dual-role user with athlete profile)
- **Get own submissions**: athlete only
- **Get athlete submissions** (trainer view): requires accepted coaching relationship; filters out `Private` visibility
- **Upload feedback**: trainer with accepted coaching relationship
- **Mark feedback viewed**: the athlete who owns the submission
- **Delete submission**: owner (athlete) or admin
- **Delete feedback**: the trainer who created it, or admin

**Notification pattern** (copy from existing endpoints, e.g. `CoachingEndpoints.cs`):
```csharp
// After SaveChangesAsync:
var notification = await EndpointHelpers.QueueNotificationAsync(db, recipientEmail, type, title, body, senderName, senderRole);
await db.SaveChangesAsync(ct);
if (notification is not null)
    await EndpointHelpers.SendNotificationAsync(hubContext, notification);
```

**Endpoint map**:
```
POST   /api/submissions                                    — Upload (multipart: file + [FromForm] fields)
GET    /api/submissions?page=&pageSize=                    — Own list
GET    /api/athletes/{athleteId}/submissions?page=&pageSize= — Trainer view
GET    /api/submissions/{id}                               — Detail (includes feedbacks)
DELETE /api/submissions/{id}                               — Delete own

POST   /api/submissions/{id}/feedback                      — Trainer upload (multipart)
GET    /api/submissions/{id}/feedback                      — List feedbacks
DELETE /api/submissions/{id}/feedback/{feedbackId}         — Delete own feedback
PATCH  /api/submissions/{id}/feedback/{feedbackId}/viewed  — Athlete marks viewed
```

**DTO mapping helpers** (define as private static methods at bottom of endpoint class):
```csharp
private static VideoSubmissionDto ToDto(VideoSubmission s, int feedbackCount, bool hasUnviewed) => new(
    s.Id, s.AthleteId, s.MediaAssetId, $"/api/media/{s.MediaAssetId}/content",
    s.SessionId, s.SessionExerciseId, s.Title, s.Notes, s.Visibility.ToString(),
    feedbackCount, hasUnviewed, s.CreatedAt);

private static VideoFeedbackDto ToFeedbackDto(VideoFeedback f) => new(
    f.Id, f.SubmissionId, f.TrainerId, f.Trainer?.FullName ?? "",
    f.MediaAssetId, $"/api/media/{f.MediaAssetId}/content",
    f.MediaAsset?.MediaType.ToString() ?? "Video",
    f.Notes, f.CreatedAt, f.ViewedAt);
```

Use the same `ResolveAthleteAsync` / `ValidateTrainerAccessAsync` helpers pattern from `ProgressPhotoEndpoints.cs` — copy and adapt.

---

### 10. Register in `src/TrackMe.Api/Program.cs`

Add after `app.MapProgressPhotoEndpoints();`:
```csharp
app.MapSubmissionEndpoints();
```

---

## Frontend

### 1. `src/services/api.js` additions

```js
// Submissions (athlete)
uploadSubmission: (file, { title, notes, visibility, sessionId, sessionExerciseId } = {}) => {
  const form = new FormData();
  form.append('file', file);
  if (title) form.append('title', title);
  if (notes) form.append('notes', notes);
  if (visibility) form.append('visibility', visibility);
  if (sessionId) form.append('sessionId', sessionId);
  if (sessionExerciseId) form.append('sessionExerciseId', sessionExerciseId);
  return fetch('/api/submissions', { method: 'POST', headers: { Authorization: `Bearer ${getToken()}` }, body: form }).then(handleResponse);
},
getMySubmissions: (page = 1, pageSize = 20) =>
  authFetch(`/api/submissions?page=${page}&pageSize=${pageSize}`),
getAthleteSubmissions: (athleteId, page = 1, pageSize = 20) =>
  authFetch(`/api/athletes/${athleteId}/submissions?page=${page}&pageSize=${pageSize}`),
getSubmission: (id) => authFetch(`/api/submissions/${id}`),
deleteSubmission: (id) => authFetch(`/api/submissions/${id}`, { method: 'DELETE' }),

// Feedback (trainer)
uploadFeedback: (submissionId, file, notes) => {
  const form = new FormData();
  form.append('file', file);
  if (notes) form.append('notes', notes);
  return fetch(`/api/submissions/${submissionId}/feedback`, { method: 'POST', headers: { Authorization: `Bearer ${getToken()}` }, body: form }).then(handleResponse);
},
getSubmissionFeedback: (submissionId) => authFetch(`/api/submissions/${submissionId}/feedback`),
deleteSubmissionFeedback: (submissionId, feedbackId) =>
  authFetch(`/api/submissions/${submissionId}/feedback/${feedbackId}`, { method: 'DELETE' }),
markFeedbackViewed: (submissionId, feedbackId) =>
  authFetch(`/api/submissions/${submissionId}/feedback/${feedbackId}/viewed`, { method: 'PATCH' }),
```

> Note: `authFetch` is the existing authenticated fetch helper already in api.js. `getToken()` is the existing localStorage token getter. Match the exact helper names used in the existing api.js file.

---

### 2. `src/i18n.js` new keys (add to both `tr` and `en` objects)

```js
// TR
submissions: 'Gönderilen Videolar',
submissionsSubtitle: 'Antrenman videolarınızı paylaşın',
uploadSubmission: 'Video Gönder',
noSubmissions: 'Henüz video gönderilmedi',
submissionTitle: 'Video Başlığı',
submissionNotes: 'Notlar',
submissionVisibility: 'Görünürlük',
linkToSession: 'Seans bağla (opsiyonel)',
submissionFeedback: 'Geri Bildirim',
uploadFeedback: 'Geri Bildirim Gönder',
noFeedback: 'Henüz geri bildirim yok',
feedbackNotes: 'Geri bildirim notu',
markViewed: 'Görüldü olarak işaretle',
feedbackViewed: 'Görüldü',
deleteSubmission: 'Videoyu Sil',
confirmDeleteSubmission: 'Bu video silinecek. Emin misiniz?',
deleteFeedback: 'Geri bildirimi sil',

// EN (same keys)
submissions: 'Video Submissions',
submissionsSubtitle: 'Share your workout videos',
uploadSubmission: 'Upload Video',
noSubmissions: 'No videos submitted yet',
submissionTitle: 'Video Title',
submissionNotes: 'Notes',
submissionVisibility: 'Visibility',
linkToSession: 'Link to session (optional)',
submissionFeedback: 'Feedback',
uploadFeedback: 'Send Feedback',
noFeedback: 'No feedback yet',
feedbackNotes: 'Feedback note',
markViewed: 'Mark as viewed',
feedbackViewed: 'Viewed',
deleteSubmission: 'Delete video',
confirmDeleteSubmission: 'This video will be deleted. Are you sure?',
deleteFeedback: 'Delete feedback',
```

---

### 3. `SubmissionsView.jsx` — new file at `src/views/SubmissionsView.jsx`

Structure (athlete perspective):
- Paginated list of own submissions (cards with thumbnail, title, date, feedback count badge)
- Upload button → modal (file picker — accepts `video/mp4,video/webm`; title input; notes textarea; visibility select; optional session picker via dropdown from recent sessions)
- Clicking a submission card → detail modal: `<video controls src={url} />` + feedback list
- Each feedback item: `<video>` or `<audio>` player + notes + viewed status + "Mark viewed" button if not yet viewed
- Empty state with Video icon (lucide-react `Video`) and CTA

---

### 4. `App.jsx` changes

Add `Video` to lucide-react imports.

Add to `ATHLETE_NAV` (after `progressPhotos`):
```js
{ id: 'submissions', icon: Video }
```

Add `'submissions'` to `VALID_VIEWS` Set.

Add `submissions: t('submissions')` to `viewTitles`.

Add render: `{view === 'submissions' && <SubmissionsView currentUser={currentUser} t={t} />}`

Import: `import SubmissionsView from './views/SubmissionsView.jsx';`

---

### 5. AthleteDetailView — trainer side (optional, second step)

In `src/views/AthleteDetailView.jsx` (or wherever the trainer's athlete detail is rendered):
- Add a "Videolar" / "Videos" tab alongside the existing tabs (Programs, Body Metrics, etc.)
- Fetch `getAthleteSubmissions(athleteId)` when tab is active
- List submissions with play button and a "Geri Bildirim Gönder" action per item
- Feedback upload: file picker (video or audio), notes input, submit button

---

## Docs to update when done

- `TrackMe-Docs/tasks/phases.md` — mark Phase 9 complete, add migration count (55)
- `TrackMe-Docs/tasks/backlog.md` — mark submission/feedback tasks ✅
- `TrackMe-Docs/architecture/overview.md` — update feature status table
- `TrackMe-Docs/database/migration-strategy.md` — Phase 9 migration details
- `TrackMe-Api/README.md` — update migration count + endpoint list

---

## Testing checklist

- [ ] Athlete can upload MP4 video → appears in own list
- [ ] Trainer with accepted relationship can see `CoachOnly` submission → cannot see `Private`
- [ ] Trainer uploads video feedback → athlete receives `FeedbackReceived` notification
- [ ] Athlete uploads submission → trainer receives `SubmissionReceived` notification
- [ ] Athlete marks feedback as viewed → `viewed_at` set, badge disappears
- [ ] Delete submission → video removed from R2 and feedbacks cascade-deleted
- [ ] File too large (>200 MB) → 400 with error message
- [ ] Non-MP4/WebM → 400 with error message
