# Media & File Storage

## Overview

TrackMe stores all binary content (photos, videos, audio) in Cloudflare R2 (S3-compatible). The API acts as a proxy — clients upload to the API, which writes to R2 and stores a `MediaAsset` reference in PostgreSQL. Clients retrieve content by requesting `/api/media/{assetId}/content`, which streams from R2.

---

## Data Model

### `media_assets` Table

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid PK | Also used as the R2 object key prefix |
| `owner_user_id` | uuid FK | → `users` |
| `purpose` | int | `MediaPurpose` enum |
| `file_name` | string | original filename |
| `content_type` | string | MIME type |
| `file_size_bytes` | long | |
| `r2_key` | string | full R2 object key |
| `created_at` | timestamptz | |

### MediaPurpose Enum

| Value | Int | Used for |
|-------|-----|----------|
| `AvatarPhoto` | 0 | User profile avatar |
| `CoverPhoto` | 1 | User profile cover photo |
| `ProgressPhoto` | 2 | Athlete progress photos (planned) |
| `ExerciseVideo` | 3 | Exercise demo video (planned) |
| `ProgramVideo` | 4 | Program intro video (planned) |
| `AthleteSubmissionVideo` | 5 | Athlete workout submission video (planned) |
| `TrainerFeedbackVideo` | 6 | Trainer video feedback (planned) |
| `AudioFeedback` | 7 | Trainer audio feedback (planned) |
| `ProgramCoverPhoto` | 8 | Published program cover image |

---

## Storage Architecture

```
Client → POST /api/media/... (multipart)
              ↓
          API validates (size, type, auth)
              ↓
          IMediaStorageProvider.SaveAsync()
              ↓
          CloudflareR2MediaStorageProvider
          (AWSSDK.S3 v4, UseChunkEncoding=false)
              ↓
          R2 bucket: trackme-media
          Object key: {purpose}/{entityId}/{assetId}{ext}

Client → GET /api/media/{assetId}/content
              ↓
          API reads MediaAsset row
          → purpose check (only public-safe purposes served)
          → streams from R2
```

### Key Bug Fix

Cloudflare R2 does not support chunked transfer encoding for `PUT` requests. All S3 SDK calls set `UseChunkEncoding = false` to avoid `InvalidChunkSizeError` errors.

---

## Endpoints

### Avatar & Cover Photo (User Profile)

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/media/users/me/avatar` | Upload user avatar (replaces existing) |
| `DELETE` | `/api/media/users/me/avatar` | Remove user avatar |
| `POST` | `/api/media/users/me/cover` | Upload user cover photo (replaces existing) |
| `DELETE` | `/api/media/users/me/cover` | Remove user cover photo |

Avatar path in R2: `avatars/{userId}/{assetId}{ext}`  
Cover path in R2: `covers/{userId}/{assetId}{ext}`

### Program Cover Photo

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/media/programs/published/{id}/cover` | Upload published program cover |
| `DELETE` | `/api/media/programs/published/{id}/cover` | Remove published program cover |

Program cover path in R2: `programs/{programId}/cover/{assetId}{ext}`

Only the program publisher can upload/delete their program's cover.

### Content Delivery

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/media/{assetId}/content` | Stream content from R2 |

Serves: `AvatarPhoto`, `CoverPhoto`, `ProgramCoverPhoto`. All other purposes return 404 (not yet publicly accessible).

---

## Upload Rules

- **Avatar**: replace-on-upload. Old asset is deleted from R2 and its DB row removed before the new one is saved.
- **Program cover**: same replace-on-upload behavior.
- Max file size enforced server-side (currently 10MB for photos).
- Accepted MIME types: `image/jpeg`, `image/png`, `image/webp` for photos.
- Auth required: caller must own the entity (or be Admin).

---

## URL Helper

`EndpointHelpers.GetAvatarUrl(Guid? assetId)` returns:
- `null` if `assetId` is null
- `"/api/media/{assetId}/content"` (relative URL) otherwise

This relative URL is included in all DTOs that expose a media asset (user profile, published program).

---

## Frontend

### UserAvatar Component (`UserAvatar.jsx`)

Renders user identity in priority order:
1. **Photo** — `<img src={avatarUrl}>` if `avatarUrl` is set
2. **Emoji** — rendered in a colored circle if `avatarEmoji` is set
3. **Initials** — first letter of first and last name, colored by hash

Used in: user profile headers, message threads, notification rows, athlete lists, relationship lists.

Import: `import { api } from '../services/api.js'` (named export — not default).

### Profile Cover Photo (ProfileView)

Users can upload/remove their own cover photo from their profile page. Cover spans full width at the top of the profile card (180px height). Upload button shows on hover (own profile only).

### Program Cover Photo (PublishedProgramsView)

Published program cards show a cover banner (140px height) at the top when `coverUrl` is set. Program detail modal shows cover at 180px height. Program owner sees upload/delete buttons; visitors see the cover read-only.

### API Methods

```js
// In services/api.js
uploadProgramCover: (programId, file) =>
  uploadFile(`/api/media/programs/published/${programId}/cover`, file),
deleteProgramCover: (programId) =>
  request(`/api/media/programs/published/${programId}/cover`, { method: 'DELETE' }),
```

---

## Planned Media Features

| Feature | MediaPurpose | Status |
|---------|-------------|--------|
| Progress photos | `ProgressPhoto` | 🔲 Phase 8 |
| Athlete submission videos | `AthleteSubmissionVideo` | 🔲 Future |
| Trainer video feedback | `TrainerFeedbackVideo` | 🔲 Future |
| Trainer audio feedback | `AudioFeedback` | 🔲 Future |
| Exercise demo videos | `ExerciseVideo` | 🔲 Future |
