# Spec: Phase 19 — Gym & Community

Bağımlılık yok. Hemen uygulanabilir.

**Migration adı:** `Phase19_GymCommunity`  
**Tahmini migration sayısı:** 65 (Phase 18 sonrası 64)

---

## Codebase Kuralları (oku, sonra başla)

- Migration **asla elle yazılmaz**: `dotnet ef migrations add Phase19_GymCommunity --project src/TrackMe.Api/TrackMe.Api.csproj`
- Tüm sütun adları snake_case → `HasColumnName("snake_case")`
- Endpoint dosyası: `public static class GymEndpoints` + `MapGymEndpoints(this IEndpointRouteBuilder)` extension
- DTO'lar: `sealed record` → `Models/Dtos.cs`
- Enum'lar: `Models/Enums.cs`
- `EndpointHelpers.Forbidden("mesaj")` → HTTP 403
- `ClaimsReader.GetUserId(principal)` → `Guid?` current user ID
- `ClaimsReader.IsRole(principal, UserRole.Admin)` → bool

---

## 1. Yeni Enum'lar — `Models/Enums.cs`

Mevcut dosyaya ekle:

```csharp
public enum GymVisibility { Private, Public }
public enum GymRole { Owner, Coach, Member }
public enum GymMemberStatus { Active, Banned }
```

`MediaPurpose` enum'una iki değer ekle (mevcut listeye append et):

```csharp
// Var olan: ..., ProgramCoverPhoto
// Ekle:
GymLogo, GymCover
```

---

## 2. Entity Dosyaları — `Models/`

### `Models/Gym.cs`

```csharp
namespace TrackMe.Api.Models;

public class Gym
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
    public string Slug { get; set; } = "";
    public string? Description { get; set; }
    public GymVisibility Visibility { get; set; } = GymVisibility.Private;
    public Guid OwnerUserId { get; set; }
    public AppUser? OwnerUser { get; set; }
    public Guid? LogoMediaAssetId { get; set; }
    public MediaAsset? LogoMediaAsset { get; set; }
    public Guid? CoverMediaAssetId { get; set; }
    public MediaAsset? CoverMediaAsset { get; set; }
    public bool IsDeleted { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public List<GymMembership> Memberships { get; set; } = [];
}
```

### `Models/GymMembership.cs`

```csharp
namespace TrackMe.Api.Models;

public class GymMembership
{
    public Guid Id { get; set; }
    public Guid GymId { get; set; }
    public Gym? Gym { get; set; }
    public Guid UserId { get; set; }
    public AppUser? User { get; set; }
    public GymRole Role { get; set; } = GymRole.Member;
    public GymMemberStatus Status { get; set; } = GymMemberStatus.Active;
    public DateTimeOffset JoinedAt { get; set; } = DateTimeOffset.UtcNow;
}
```

### `Models/GymInvite.cs`

```csharp
namespace TrackMe.Api.Models;

public class GymInvite
{
    public Guid Id { get; set; }
    public Guid GymId { get; set; }
    public Gym? Gym { get; set; }
    public string InvitedEmail { get; set; } = "";
    public string Token { get; set; } = "";
    public GymRole Role { get; set; } = GymRole.Member;
    public DateTimeOffset ExpiresAt { get; set; }
    public DateTimeOffset? AcceptedAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
```

### `Models/GymPost.cs`

```csharp
namespace TrackMe.Api.Models;

public class GymPost
{
    public Guid Id { get; set; }
    public Guid GymId { get; set; }
    public Gym? Gym { get; set; }
    public Guid AuthorUserId { get; set; }
    public AppUser? AuthorUser { get; set; }
    public string Body { get; set; } = "";
    public Guid? MediaAssetId { get; set; }
    public MediaAsset? MediaAsset { get; set; }
    public bool IsDeleted { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public List<GymPostComment> Comments { get; set; } = [];
    public List<GymPostReaction> Reactions { get; set; } = [];
}
```

### `Models/GymPostComment.cs`

```csharp
namespace TrackMe.Api.Models;

public class GymPostComment
{
    public Guid Id { get; set; }
    public Guid PostId { get; set; }
    public GymPost? Post { get; set; }
    public Guid AuthorUserId { get; set; }
    public AppUser? AuthorUser { get; set; }
    public string Body { get; set; } = "";
    public bool IsDeleted { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
```

### `Models/GymPostReaction.cs`

```csharp
namespace TrackMe.Api.Models;

public class GymPostReaction
{
    public Guid Id { get; set; }
    public Guid PostId { get; set; }
    public GymPost? Post { get; set; }
    public Guid UserId { get; set; }
    public AppUser? User { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
```

---

## 3. DbContext Konfigürasyonu — `Data/TrackMeDbContext.cs`

`DbSet`'leri ekle (diğer DbSet'lerin yanına):

```csharp
public DbSet<Gym> Gyms { get; set; }
public DbSet<GymMembership> GymMemberships { get; set; }
public DbSet<GymInvite> GymInvites { get; set; }
public DbSet<GymPost> GymPosts { get; set; }
public DbSet<GymPostComment> GymPostComments { get; set; }
public DbSet<GymPostReaction> GymPostReactions { get; set; }
```

`OnModelCreating` içine ekle:

```csharp
modelBuilder.Entity<Gym>(entity =>
{
    entity.ToTable("gyms");
    entity.HasKey(g => g.Id);
    entity.Property(g => g.Id).HasColumnName("id");
    entity.Property(g => g.Name).HasColumnName("name").HasMaxLength(100).IsRequired();
    entity.Property(g => g.Slug).HasColumnName("slug").HasMaxLength(100).IsRequired();
    entity.HasIndex(g => g.Slug).IsUnique();
    entity.Property(g => g.Description).HasColumnName("description").HasMaxLength(2000);
    entity.Property(g => g.Visibility).HasColumnName("visibility").HasConversion<string>().HasMaxLength(20).IsRequired();
    entity.Property(g => g.OwnerUserId).HasColumnName("owner_user_id");
    entity.Property(g => g.LogoMediaAssetId).HasColumnName("logo_media_asset_id");
    entity.Property(g => g.CoverMediaAssetId).HasColumnName("cover_media_asset_id");
    entity.Property(g => g.IsDeleted).HasColumnName("is_deleted").HasDefaultValue(false);
    entity.Property(g => g.CreatedAt).HasColumnName("created_at");
    entity.HasOne(g => g.OwnerUser).WithMany().HasForeignKey(g => g.OwnerUserId).OnDelete(DeleteBehavior.Restrict);
    entity.HasOne(g => g.LogoMediaAsset).WithMany().HasForeignKey(g => g.LogoMediaAssetId).OnDelete(DeleteBehavior.SetNull);
    entity.HasOne(g => g.CoverMediaAsset).WithMany().HasForeignKey(g => g.CoverMediaAssetId).OnDelete(DeleteBehavior.SetNull);
});

modelBuilder.Entity<GymMembership>(entity =>
{
    entity.ToTable("gym_memberships");
    entity.HasKey(m => m.Id);
    entity.Property(m => m.Id).HasColumnName("id");
    entity.Property(m => m.GymId).HasColumnName("gym_id");
    entity.Property(m => m.UserId).HasColumnName("user_id");
    entity.Property(m => m.Role).HasColumnName("role").HasConversion<string>().HasMaxLength(20).IsRequired();
    entity.Property(m => m.Status).HasColumnName("status").HasConversion<string>().HasMaxLength(20).IsRequired();
    entity.Property(m => m.JoinedAt).HasColumnName("joined_at");
    entity.HasOne(m => m.Gym).WithMany(g => g.Memberships).HasForeignKey(m => m.GymId).OnDelete(DeleteBehavior.Cascade);
    entity.HasOne(m => m.User).WithMany().HasForeignKey(m => m.UserId).OnDelete(DeleteBehavior.Cascade);
    entity.HasIndex(m => new { m.GymId, m.UserId }).IsUnique();
});

modelBuilder.Entity<GymInvite>(entity =>
{
    entity.ToTable("gym_invites");
    entity.HasKey(i => i.Id);
    entity.Property(i => i.Id).HasColumnName("id");
    entity.Property(i => i.GymId).HasColumnName("gym_id");
    entity.Property(i => i.InvitedEmail).HasColumnName("invited_email").HasMaxLength(220).IsRequired();
    entity.Property(i => i.Token).HasColumnName("token").HasMaxLength(100).IsRequired();
    entity.HasIndex(i => i.Token).IsUnique();
    entity.Property(i => i.Role).HasColumnName("role").HasConversion<string>().HasMaxLength(20).IsRequired();
    entity.Property(i => i.ExpiresAt).HasColumnName("expires_at");
    entity.Property(i => i.AcceptedAt).HasColumnName("accepted_at");
    entity.Property(i => i.CreatedAt).HasColumnName("created_at");
    entity.HasOne(i => i.Gym).WithMany().HasForeignKey(i => i.GymId).OnDelete(DeleteBehavior.Cascade);
});

modelBuilder.Entity<GymPost>(entity =>
{
    entity.ToTable("gym_posts");
    entity.HasKey(p => p.Id);
    entity.Property(p => p.Id).HasColumnName("id");
    entity.Property(p => p.GymId).HasColumnName("gym_id");
    entity.Property(p => p.AuthorUserId).HasColumnName("author_user_id");
    entity.Property(p => p.Body).HasColumnName("body").HasMaxLength(5000).IsRequired();
    entity.Property(p => p.MediaAssetId).HasColumnName("media_asset_id");
    entity.Property(p => p.IsDeleted).HasColumnName("is_deleted").HasDefaultValue(false);
    entity.Property(p => p.CreatedAt).HasColumnName("created_at");
    entity.HasOne(p => p.Gym).WithMany().HasForeignKey(p => p.GymId).OnDelete(DeleteBehavior.Cascade);
    entity.HasOne(p => p.AuthorUser).WithMany().HasForeignKey(p => p.AuthorUserId).OnDelete(DeleteBehavior.Restrict);
    entity.HasOne(p => p.MediaAsset).WithMany().HasForeignKey(p => p.MediaAssetId).OnDelete(DeleteBehavior.SetNull);
    entity.HasIndex(p => new { p.GymId, p.CreatedAt });
});

modelBuilder.Entity<GymPostComment>(entity =>
{
    entity.ToTable("gym_post_comments");
    entity.HasKey(c => c.Id);
    entity.Property(c => c.Id).HasColumnName("id");
    entity.Property(c => c.PostId).HasColumnName("post_id");
    entity.Property(c => c.AuthorUserId).HasColumnName("author_user_id");
    entity.Property(c => c.Body).HasColumnName("body").HasMaxLength(1000).IsRequired();
    entity.Property(c => c.IsDeleted).HasColumnName("is_deleted").HasDefaultValue(false);
    entity.Property(c => c.CreatedAt).HasColumnName("created_at");
    entity.HasOne(c => c.Post).WithMany(p => p.Comments).HasForeignKey(c => c.PostId).OnDelete(DeleteBehavior.Cascade);
    entity.HasOne(c => c.AuthorUser).WithMany().HasForeignKey(c => c.AuthorUserId).OnDelete(DeleteBehavior.Restrict);
});

modelBuilder.Entity<GymPostReaction>(entity =>
{
    entity.ToTable("gym_post_reactions");
    entity.HasKey(r => r.Id);
    entity.Property(r => r.Id).HasColumnName("id");
    entity.Property(r => r.PostId).HasColumnName("post_id");
    entity.Property(r => r.UserId).HasColumnName("user_id");
    entity.Property(r => r.CreatedAt).HasColumnName("created_at");
    entity.HasOne(r => r.Post).WithMany(p => p.Reactions).HasForeignKey(r => r.PostId).OnDelete(DeleteBehavior.Cascade);
    entity.HasOne(r => r.User).WithMany().HasForeignKey(r => r.UserId).OnDelete(DeleteBehavior.Cascade);
    entity.HasIndex(r => new { r.PostId, r.UserId }).IsUnique();
});
```

---

## 4. DTO'lar — `Models/Dtos.cs`

```csharp
// --- Gym DTOs ---
public sealed record GymDto(
    Guid Id, string Name, string Slug, string? Description, string Visibility,
    string? LogoUrl, string? CoverUrl, int MemberCount, DateTimeOffset CreatedAt);

public sealed record GymDetailDto(
    Guid Id, string Name, string Slug, string? Description, string Visibility,
    string? LogoUrl, string? CoverUrl, int MemberCount,
    string MyRole, string MyStatus, DateTimeOffset CreatedAt);

public sealed record GymMemberDto(
    Guid UserId, string FullName, string? AvatarUrl, string? AvatarEmoji,
    string Role, string Status, DateTimeOffset JoinedAt);

public sealed record GymPostDto(
    Guid Id, Guid AuthorUserId, string AuthorName, string? AuthorAvatarUrl,
    string Body, string? MediaUrl, int ReactionCount, int CommentCount,
    bool MyReaction, DateTimeOffset CreatedAt);

public sealed record GymPostCommentDto(
    Guid Id, Guid AuthorUserId, string AuthorName, string? AuthorAvatarUrl,
    string Body, DateTimeOffset CreatedAt);

public sealed record GymLeaderboardEntryDto(
    Guid UserId, string FullName, string? AvatarUrl, string? AvatarEmoji,
    int SessionCount, decimal TotalVolumeKg);

// --- Requests ---
public sealed record CreateGymRequest(string Name, string? Description, string Visibility = "Private");
public sealed record UpdateGymRequest(string? Name, string? Description, string? Visibility);
public sealed record GymInviteRequest(string Email, string Role = "Member");
public sealed record CreateGymPostRequest(string Body);
public sealed record CreateGymCommentRequest(string Body);
public sealed record ChangeMemberRoleRequest(string Role);
```

---

## 5. Endpoint Dosyası — `Endpoints/GymEndpoints.cs`

```csharp
public static class GymEndpoints
{
    public static IEndpointRouteBuilder MapGymEndpoints(this IEndpointRouteBuilder app)
    {
        // Gym CRUD
        app.MapPost("/api/gyms", CreateGym).RequireAuthorization();
        app.MapGet("/api/gyms/my", GetMyGyms).RequireAuthorization();
        app.MapGet("/api/gyms/{id:guid}", GetGym).RequireAuthorization();
        app.MapPatch("/api/gyms/{id:guid}", UpdateGym).RequireAuthorization();
        app.MapDelete("/api/gyms/{id:guid}", DeleteGym).RequireAuthorization();

        // Medya
        app.MapPost("/api/gyms/{id:guid}/logo", UploadLogo).RequireAuthorization().DisableAntiforgery();
        app.MapPost("/api/gyms/{id:guid}/cover", UploadCover).RequireAuthorization().DisableAntiforgery();

        // Üyelik
        app.MapPost("/api/gyms/{id:guid}/invite", InviteMember).RequireAuthorization();
        app.MapPost("/api/gyms/invites/{token}/accept", AcceptInvite).RequireAuthorization();
        app.MapGet("/api/gyms/{id:guid}/members", GetMembers).RequireAuthorization();
        app.MapPatch("/api/gyms/{id:guid}/members/{userId:guid}/role", ChangeMemberRole).RequireAuthorization();
        app.MapDelete("/api/gyms/{id:guid}/members/{userId:guid}", RemoveMember).RequireAuthorization();
        app.MapPatch("/api/gyms/{id:guid}/members/{userId:guid}/ban", ToggleBan).RequireAuthorization();

        // Feed
        app.MapPost("/api/gyms/{id:guid}/posts", CreatePost).RequireAuthorization();
        app.MapGet("/api/gyms/{id:guid}/posts", GetPosts).RequireAuthorization();
        app.MapDelete("/api/gyms/{id:guid}/posts/{postId:guid}", DeletePost).RequireAuthorization();

        // Yorumlar & Reaksiyonlar
        app.MapPost("/api/gyms/{id:guid}/posts/{postId:guid}/comments", AddComment).RequireAuthorization();
        app.MapDelete("/api/gyms/{id:guid}/posts/{postId:guid}/comments/{commentId:guid}", DeleteComment).RequireAuthorization();
        app.MapPost("/api/gyms/{id:guid}/posts/{postId:guid}/reactions", ToggleReaction).RequireAuthorization();

        // Leaderboard
        app.MapGet("/api/gyms/{id:guid}/leaderboard", GetLeaderboard).RequireAuthorization();

        return app;
    }
```

### Access Gate Yardımcısı

`GymEndpoints` içinde private static helper:

```csharp
private static async Task<GymMembership?> GetMembershipAsync(TrackMeDbContext db, Guid gymId, Guid userId)
    => await db.GymMemberships.FirstOrDefaultAsync(m => m.GymId == gymId && m.UserId == userId);

private static bool CanModerate(GymMembership? m)
    => m is { Status: GymMemberStatus.Active, Role: GymRole.Owner or GymRole.Coach };

private static bool IsOwner(GymMembership? m)
    => m is { Status: GymMemberStatus.Active, Role: GymRole.Owner };
```

### Endpoint Davranışları

**`CreateGym`**
- Request body: `CreateGymRequest`
- `Slug` = name'i küçük harfe çevir, boşlukları `-` yap, benzersizlik yoksa UUID suffix ekle
- `Gym` oluştur + `GymMembership { Role = Owner, Status = Active }` oluştur
- `SaveChangesAsync` → `Results.Created($"/api/gyms/{gym.Id}", GymDetailDto(...))`

**`GetMyGyms`**
- `db.GymMemberships.Where(m => m.UserId == userId && m.Status == Active).Include(m => m.Gym)`
- `GymDto` listesi döndür; `IsDeleted` olanları filtrele

**`GetGym`**
- `gym.Visibility == Private` ise → membership kontrolü (üye değilse 404 döndür, varlığını gizle)
- `GymDetailDto` döndür; `MyRole` = membership?.Role.ToString() ?? "None", `MemberCount` = aktif üye sayısı

**`UpdateGym`**
- Owner kontrolü gerekir
- Sadece null olmayan alanları güncelle

**`DeleteGym`**
- Owner veya Admin gerekir
- `gym.IsDeleted = true; SaveChangesAsync()` — hard-delete kullanma

**`InviteMember`**
- Owner/Coach gerekir
- Mevcut aktif üyeye davet atma (zaten üye hata döndür)
- `Token = Guid.NewGuid().ToString("N")`, `ExpiresAt = UtcNow + 7 gün`
- E-posta gönderimi: projeye e-posta servisi yoksa şimdilik token'ı response'da döndür
- `Results.Ok(new { Token = invite.Token })`

**`AcceptInvite`**
- Token'ı bul; süresi dolmuşsa veya zaten kabul edilmişse 400
- Caller'ın e-posta = `invite.InvitedEmail` kontrolü yap
- Zaten aktif üyeyse 409
- `GymMembership` oluştur, `invite.AcceptedAt = UtcNow`; `SaveChangesAsync`

**`GetMembers`**
- Caller aktif üye olmalı
- `db.GymMemberships.Where(m => m.GymId == id).Include(m => m.User)` → `GymMemberDto` listesi

**`ChangeMemberRole`**
- Sadece Owner yapabilir
- Owner kendi rolünü değiştiremez
- `GymRole.Owner` rolüne sadece başka bir Owner atayabilir (transfer mantığı: önceki owner Coach'a düşer)

**`RemoveMember`**
- Owner/Coach yapabilir; Owner'ı kimse atamaz
- Kendi kendini atmak için `DELETE /api/gyms/{id}/members/{myUserId}` kullanılabilir (her seviye kendi için geçerli)

**`ToggleBan`**
- Owner/Coach; Owner ban edilemez
- `Status == Banned` ise `Active` yap, `Active` ise `Banned` yap

**`CreatePost`**
- Caller aktif üye olmalı (Banned → 403)
- Opsiyonel medya: multipart form değil, sadece metin. Medya için ayrı bir upload endpoint eklenebilir ama bu spec kapsam dışı bırakıyor — `MediaAssetId` nullable olarak saklı
- `Results.Created(..., GymPostDto(...))`

**`GetPosts`**
- Caller aktif üye olmalı
- `IsDeleted = false` filtresi
- Sayfalama: `?cursor={lastCreatedAt}&limit=20` (cursor tabanlı) VEYA basit `?page=1&limit=20`
- Her post için: `ReactionCount`, `CommentCount`, `MyReaction` (caller'ın reaksiyonu var mı)

**`DeletePost`**
- Yazar VEYA Owner/Coach VEYA Admin silebilir
- `post.IsDeleted = true` — hard-delete değil

**`AddComment`** / **`DeleteComment`**
- Aynı kural: aktif üye yorum ekleyebilir; yazar/Owner/Coach/Admin silebilir

**`ToggleReaction`**
- Aktif üye
- Zaten reaksiyon varsa sil (toggle), yoksa oluştur
- `Results.Ok(new { Liked = !wasLiked, ReactionCount = newCount })`

**`GetLeaderboard`**
- Aktif üye gerekir
- Bu ayki oturum sayısı + toplam hacim (kg)
- Query:
```sql
SELECT m.user_id, SUM(sl.weight_kg * sl.reps) as volume, COUNT(DISTINCT s.id) as sessions
FROM gym_memberships m
JOIN workout_sessions s ON s.athlete_id = ... -- app_users → athletes FK üzerinden
JOIN workout_set_logs sl ON sl.session_id = s.id
WHERE m.gym_id = @gymId
  AND m.status = 'Active'
  AND s.started_at >= CURRENT_DATE - INTERVAL '30 days'
  AND s.status = 'Completed'
GROUP BY m.user_id
ORDER BY volume DESC
LIMIT 50
```
- **Dikkat:** `workout_sessions.athlete_id` → `athletes` tablosu; athlete'in `user_id`'si üzerinden `gym_memberships.user_id` ile join gerekir

---

## 6. MediaService — Medya Upload

`Services/MediaService.cs` dosyasına iki yeni metod ekle (mevcut `SaveProgressPhotoAsync` kalıbını takip et):

```csharp
public async Task<(MediaAsset? Asset, string? Error)> SaveGymLogoAsync(
    Gym gym, AppUser owner, IFormFile file, TrackMeDbContext db, CancellationToken ct)
{
    // Sadece image kabul et (AllowedImageTypes)
    // CheckQuotaAsync çağır
    // R2 key: $"gyms/{gym.Id}/logo/{mediaId}{extension}"
    // MediaPurpose.GymLogo
    // Eski logo varsa R2'den sil + MediaAsset sil
    // gym.LogoMediaAssetId = asset.Id; SaveChangesAsync
}

public async Task<(MediaAsset? Asset, string? Error)> SaveGymCoverAsync(
    Gym gym, AppUser owner, IFormFile file, TrackMeDbContext db, CancellationToken ct)
{
    // Aynı yapı, MediaPurpose.GymCover, key: gyms/{gym.Id}/cover/{mediaId}{ext}
}
```

---

## 7. Program.cs

`MapGymEndpoints()` çağrısını diğer `Map...Endpoints()` satırlarına ekle:

```csharp
app.MapGymEndpoints();
```

---

## 8. Frontend — `TrackMe-Web/src/`

### `services/api.js` — yeni metodlar

```js
getMyGyms: () => authFetch('/api/gyms/my'),
getGym: (id) => authFetch(`/api/gyms/${id}`),
createGym: (data) => authFetch('/api/gyms', { method: 'POST', body: JSON.stringify(data) }),
updateGym: (id, data) => authFetch(`/api/gyms/${id}`, { method: 'PATCH', body: JSON.stringify(data) }),
deleteGym: (id) => authFetch(`/api/gyms/${id}`, { method: 'DELETE' }),
inviteGymMember: (id, data) => authFetch(`/api/gyms/${id}/invite`, { method: 'POST', body: JSON.stringify(data) }),
acceptGymInvite: (token) => authFetch(`/api/gyms/invites/${token}/accept`, { method: 'POST' }),
getGymMembers: (id) => authFetch(`/api/gyms/${id}/members`),
changeMemberRole: (id, userId, data) => authFetch(`/api/gyms/${id}/members/${userId}/role`, { method: 'PATCH', body: JSON.stringify(data) }),
removeMember: (id, userId) => authFetch(`/api/gyms/${id}/members/${userId}`, { method: 'DELETE' }),
toggleBan: (id, userId) => authFetch(`/api/gyms/${id}/members/${userId}/ban`, { method: 'PATCH' }),
getGymPosts: (id, cursor) => authFetch(`/api/gyms/${id}/posts${cursor ? `?cursor=${cursor}` : ''}`),
createGymPost: (id, data) => authFetch(`/api/gyms/${id}/posts`, { method: 'POST', body: JSON.stringify(data) }),
deleteGymPost: (id, postId) => authFetch(`/api/gyms/${id}/posts/${postId}`, { method: 'DELETE' }),
addComment: (id, postId, data) => authFetch(`/api/gyms/${id}/posts/${postId}/comments`, { method: 'POST', body: JSON.stringify(data) }),
deleteComment: (id, postId, commentId) => authFetch(`/api/gyms/${id}/posts/${postId}/comments/${commentId}`, { method: 'DELETE' }),
toggleReaction: (id, postId) => authFetch(`/api/gyms/${id}/posts/${postId}/reactions`, { method: 'POST' }),
getGymLeaderboard: (id) => authFetch(`/api/gyms/${id}/leaderboard`),
```

### `views/GymsView.jsx`

- Üst: "Gym'lerim" başlığı + "Gym Oluştur" butonu
- Gym kartı: logo, isim, üye sayısı, rolüm, "Gör" linki
- Bekleyen davet varsa (query param `?invite={token}`): "Daveti Kabul Et" banner → `acceptGymInvite(token)` → yenile

### `views/GymDetailView.jsx`

Route: `/gyms/:id`

Sekme yapısı:
- **Feed** — `GymPostCard` listesi + "Post Ekle" formu (aktif üyeler)
- **Üyeler** — `GymMemberDto` listesi; Owner/Coach için Rol değiştir / At / Ban butonları
- **Ayarlar** (Owner only) — İsim/açıklama düzenle, logo/kapak yükle, gym sil
- **Leaderboard** — Bu ayki top 10 üye

### `components/GymPostCard.jsx`

```jsx
// Props: post, gymId, currentUserId, onDelete, canModerate
// İçerik: AuthorName + avatar, CreatedAt, Body, opsiyonel medya
// Alt: ❤️ {reactionCount} butonu (toggle), 💬 {commentCount} (expand)
// Expand açılınca: yorum listesi + yorum ekleme inputu
// Sil butonu: post.authorUserId === currentUserId || canModerate
```

### `i18n.js` — Yeni TR/EN key'ler

```js
// TR
gymMyGyms: 'Gym\'lerim',
gymCreate: 'Gym Oluştur',
gymName: 'Gym Adı',
gymDescription: 'Açıklama',
gymVisibilityPublic: 'Herkese Açık',
gymVisibilityPrivate: 'Gizli',
gymMembers: 'Üyeler',
gymFeed: 'Akış',
gymLeaderboard: 'Sıralama',
gymSettings: 'Ayarlar',
gymInvite: 'Davet Gönder',
gymInviteEmail: 'E-posta adresi',
gymAcceptInvite: 'Daveti Kabul Et',
gymBanned: 'Banlı',
gymKick: 'Üyeyi At',
gymBan: 'Banla',
gymUnban: 'Banı Kaldır',
gymPostPlaceholder: 'Bir şeyler paylaş...',
gymPostDelete: 'Postu Sil',
gymCommentPlaceholder: 'Yorum yaz...',
gymLeaderboardEmpty: 'Bu ay henüz antrenman kaydı yok',
gymCreated: 'Gym oluşturuldu',
gymDeleted: 'Gym silindi',
gymInviteSent: 'Davet gönderildi',
gymInviteAccepted: 'Gym\'e katıldın',

// EN
gymMyGyms: 'My Gyms',
gymCreate: 'Create Gym',
gymName: 'Gym Name',
gymDescription: 'Description',
gymVisibilityPublic: 'Public',
gymVisibilityPrivate: 'Private',
gymMembers: 'Members',
gymFeed: 'Feed',
gymLeaderboard: 'Leaderboard',
gymSettings: 'Settings',
gymInvite: 'Invite Member',
gymInviteEmail: 'Email address',
gymAcceptInvite: 'Accept Invite',
gymBanned: 'Banned',
gymKick: 'Remove Member',
gymBan: 'Ban',
gymUnban: 'Unban',
gymPostPlaceholder: 'Share something...',
gymPostDelete: 'Delete Post',
gymCommentPlaceholder: 'Write a comment...',
gymLeaderboardEmpty: 'No workouts recorded this month',
gymCreated: 'Gym created',
gymDeleted: 'Gym deleted',
gymInviteSent: 'Invite sent',
gymInviteAccepted: 'Joined gym',
```

### `App.jsx` — Yeni route ekle

```jsx
// Nav'a Gyms linki ekle (giriş yapmış tüm kullanıcılar)
{ path: '/gyms', label: t('gymMyGyms'), component: GymsView }
// GymDetail route
{ path: '/gyms/:id', component: GymDetailView }
```

---

## 9. Görev Sırası

1. `Enums.cs` — yeni enum değerleri + `MediaPurpose` güncelleme
2. 6 entity dosyası oluştur
3. `TrackMeDbContext.cs` — DbSet'ler + OnModelCreating konfigürasyonları
4. `MediaService.cs` — `SaveGymLogoAsync` + `SaveGymCoverAsync`
5. Migration: `dotnet ef migrations add Phase19_GymCommunity --project src/TrackMe.Api/TrackMe.Api.csproj`
6. `Models/Dtos.cs` — yeni DTO'lar + request record'ları
7. `Endpoints/GymEndpoints.cs` — tüm endpoint'ler
8. `Program.cs` — `app.MapGymEndpoints()`
9. Build: `dotnet build src/TrackMe.Api/TrackMe.Api.csproj`
10. Frontend: `api.js`, `GymsView.jsx`, `GymDetailView.jsx`, `GymPostCard.jsx`, `i18n.js`, `App.jsx`
11. Docs güncelle: `phases.md`, `backlog.md`, `migration-strategy.md`, `specs/README.md`, `TrackMe-Api/README.md`

---

## 10. Docs Güncelleme (görev bitince)

- `TrackMe-Api/README.md` → migration count 64 → 65
- `TrackMe-Docs/tasks/specs/README.md` → migration count 64 → 65
- `TrackMe-Docs/tasks/phases.md` → Phase 19 "Planned" bölümünü "Complete" olarak güncelle
- `TrackMe-Docs/tasks/backlog.md` → Phase 19 Tamamlananlar'a taşı
- `TrackMe-Docs/database/migration-strategy.md` → Phase 19 migration history ekle
