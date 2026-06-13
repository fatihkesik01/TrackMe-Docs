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
- Frontend API helper'ı `authFetch` değil, `services/api.js` içindeki mevcut `request(...)` ve multipart için `uploadFile(...)` fonksiyonlarıdır
- Frontend React Router kullanmıyor; navigasyon `App.jsx` içindeki `view` state + `window.location.hash` ile yapılır

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
    string? MyRole, string? MyStatus, DateTimeOffset CreatedAt);

public sealed record GymMemberDto(
    Guid UserId, string FullName, string? AvatarUrl, string? AvatarEmoji,
    string Role, string Status, DateTimeOffset JoinedAt);

public sealed record GymPostDto(
    Guid Id, Guid AuthorUserId, string AuthorName, string? AuthorAvatarUrl,
    string Body, string? MediaUrl, int ReactionCount, int CommentCount,
    bool MyReaction, IReadOnlyList<GymPostCommentDto> Comments,
    DateTimeOffset CreatedAt);

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

`GymPostDto.Comments`, silinmemiş yorumları `CreatedAt ASC` sırasıyla içerir. Ayrı bir comment-list endpoint'i yoktur; böylece toplam endpoint sayısı **20** kalır ve `GymPostCard` yorum panelini doğrudan feed response'undan açabilir.

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

Toplam: **20 endpoint** (5 CRUD + 2 medya + 6 üyelik + 3 feed + 3 sosyal + 1 leaderboard).

### Access Gate Yardımcısı

`GymEndpoints` içinde private static helper:

```csharp
private static async Task<GymMembership?> GetMembershipAsync(TrackMeDbContext db, Guid gymId, Guid userId)
    => await db.GymMemberships.FirstOrDefaultAsync(m => m.GymId == gymId && m.UserId == userId);

private static bool CanModerate(GymMembership? m)
    => m is { Status: GymMemberStatus.Active, Role: GymRole.Owner or GymRole.Coach };

private static bool IsOwner(GymMembership? m)
    => m is { Status: GymMemberStatus.Active, Role: GymRole.Owner };

private static bool IsActiveMember(GymMembership? m)
    => m is { Status: GymMemberStatus.Active };

private static int RoleRank(GymRole role) => role switch
{
    GymRole.Owner => 3,
    GymRole.Coach => 2,
    _ => 1,
};
```

Tüm handler'ların ilk ortak kuralları:
- `ClaimsReader.GetUserId(principal)` null ise `Results.Unauthorized()`.
- Gym sorgularında her zaman `!g.IsDeleted` filtresi kullan.
- Caller'ın membership kaydı `Banned` ise gym Public olsa bile `EndpointHelpers.Forbidden("banned members cannot access this gym.")` döndür.
- Kaynak başka gym'e aitse `404`; yalnızca ID ile post/comment bulup işlem yapma.
- Request enum string'lerini `Enum.TryParse(..., ignoreCase: true, out ...)` ile doğrula; geçersiz değer `400`.

### Endpoint Davranışları

**`CreateGym`**
- Request body: `CreateGymRequest`
- Name trimlenmiş halde 2–100 karakter olmalı; Description en fazla 2000 karakter
- `SlugGenerator.Create(request.Name)` kullan; sonuç boşsa 400. Slug doluysa aynı slug varken `-{Guid.NewGuid():N}` değerinin ilk 8 karakterini suffix olarak ekle
- `Gym` oluştur + `GymMembership { Role = Owner, Status = Active }` oluştur
- `SaveChangesAsync` → `Results.Created($"/api/gyms/{gym.Id}", GymDetailDto(...))`

**`GetMyGyms`**
- `db.GymMemberships.Where(m => m.UserId == userId && m.Status == Active).Include(m => m.Gym)`
- `GymDto` listesi döndür; `IsDeleted` olanları filtrele

**`GetGym`**
- `gym.Visibility == Private` ise → aktif membership kontrolü (üye değilse 404 döndür, varlığını gizle)
- Public gym'i üye olmayan authenticated kullanıcı okuyabilir; `MyRole` ve `MyStatus` null olur
- `GymDetailDto` döndür; `MemberCount` yalnızca aktif üyeleri sayar

**`UpdateGym`**
- Owner kontrolü gerekir
- Sadece null olmayan alanları güncelle; Create ile aynı trim/uzunluk/enum validasyonlarını uygula
- Name değişirse slug'ı değiştirme; mevcut paylaşılan bağlantıları kırmamak için slug immutable kalır

**`DeleteGym`**
- Owner veya Admin gerekir
- `gym.IsDeleted = true; SaveChangesAsync()` — hard-delete kullanma

**`UploadLogo` / `UploadCover`**
- Sadece aktif Owner yükleyebilir; Admin membership olmadan medya yükleyemez
- Caller `AppUser` kaydı bulunur ve ilgili `MediaService` metodu çağrılır
- Başarıda `MediaService.ToDto(asset)` döndür
- Hata dönüşü `EndpointHelpers.UploadError(error, "upload failed.")` kullanır; kota aşımı böylece HTTP 413 olur

**`InviteMember`**
- Owner/Coach gerekir
- Owner `Coach` veya `Member`, Coach yalnızca `Member` rolüyle davet oluşturabilir; `Owner` request'i 400
- Mevcut aktif üyeye davet atma (zaten üye hata döndür)
- Aynı gym + normalize email için süresi dolmamış, kabul edilmemiş davet varsa yeni kayıt açmak yerine token'ı döndür
- `Token = Guid.NewGuid().ToString("N")`, `ExpiresAt = UtcNow + 7 gün`
- E-posta gönderimi: projeye e-posta servisi yoksa şimdilik token'ı response'da döndür
- `Results.Ok(new { Token = invite.Token })`

**`AcceptInvite`**
- Token'ı bul; süresi dolmuşsa veya zaten kabul edilmişse 400
- Caller'ın normalize e-postası (`Trim().ToLowerInvariant()`) = invite e-postası kontrolü yap
- Gym silinmişse 404; zaten aktif veya banned üyelik varsa 409
- `GymMembership` oluştur, `invite.AcceptedAt = UtcNow`; `SaveChangesAsync`; `GymDetailDto` döndür

**`GetMembers`**
- Caller aktif üye olmalı
- `db.GymMemberships.Where(m => m.GymId == id).Include(m => m.User)` → `GymMemberDto` listesi
- Sıra: Owner, Coach, Member; aynı rolde `FullName ASC`. Banned kayıtlar listede kalır ve status ile gösterilir

**`ChangeMemberRole`**
- Sadece Owner yapabilir
- Owner kendi rolünü değiştiremez
- Hedef üyelik aktif olmalı
- Request `Coach` veya `Member` ise rolü doğrudan güncelle
- Request `Owner` ise ownership transferidir: hedef membership `Owner`, caller membership `Coach`, `gym.OwnerUserId = target.UserId` aynı transaction/save içinde güncellenir

**`RemoveMember`**
- Owner/Coach yapabilir; Owner'ı kimse atamaz
- Kendi kendini çıkarmak için aynı endpoint kullanılabilir; Owner gym'den ayrılamaz, önce ownership transfer etmelidir
- Coach yalnızca Member çıkarabilir; Owner Coach veya Member çıkarabilir. Kendisinden eşit/yüksek role işlem yapılamaz
- Membership hard-delete edilir; geçmiş post/comment kayıtları user FK üzerinden korunur

**`ToggleBan`**
- Owner/Coach; Owner ban edilemez
- Coach yalnızca Member banlayabilir; Owner Coach veya Member banlayabilir. Caller kendisini banlayamaz
- `Status == Banned` ise `Active` yap, `Active` ise `Banned` yap

**`CreatePost`**
- Caller aktif üye olmalı (Banned → 403)
- Body trimlenmiş halde 1–5000 karakter olmalı
- Opsiyonel medya: multipart form değil, sadece metin. Medya için ayrı bir upload endpoint eklenebilir ama bu spec kapsam dışı bırakıyor — `MediaAssetId` nullable olarak saklı
- `Results.Created(..., GymPostDto(...))`

**`GetPosts`**
- Caller aktif üye olmalı
- `IsDeleted = false` filtresi
- Sabit sayfalama sözleşmesi: `?page=1&pageSize=20`; `page >= 1`, `pageSize` 1–50 aralığına clamp edilir; `PagedResult<GymPostDto>` döner
- Sıra `CreatedAt DESC`; her post için `ReactionCount`, silinmemiş `CommentCount`, `MyReaction` ve silinmemiş `Comments` (`CreatedAt ASC`, en fazla son 50) doldurulur

**`DeletePost`**
- Yazar VEYA Owner/Coach VEYA Admin silebilir
- `post.IsDeleted = true` — hard-delete değil

**`AddComment`** / **`DeleteComment`**
- Aktif üye yorum ekleyebilir; body trimlenmiş halde 1–1000 karakter olmalı; created `GymPostCommentDto` döner
- Yazar/Owner/Coach/Admin silebilir; `comment.PostId == postId` ve `post.GymId == gymId` doğrulanır
- Silme soft-delete (`IsDeleted = true`) yapar

**`ToggleReaction`**
- Aktif üye
- Zaten reaksiyon varsa sil (toggle), yoksa oluştur
- `Results.Ok(new { Liked = !wasLiked, ReactionCount = newCount })`

**`GetLeaderboard`**
- Aktif üye gerekir
- Takvim ayı kullanılır: UTC ayın ilk günü dahil, sonraki ayın ilk günü hariç. "Son 30 gün" kullanma
- `WorkoutSession.CompletedAt` tarihini ve `SessionStatus.Completed` filtresini kullan
- Hacim yalnızca `WorkoutSetLog.IsCompleted && !IsWarmUp && WeightKg != null && Reps != null` setlerinde `WeightKg * Reps` toplamıdır
- Mevcut şemada `athletes.user_id` yoktur. Eşleşme `GymMembership.User.Email` ↔ `Athlete.Email` (case-insensitive) üzerinden yapılır
- Uygulama kalıbı: aktif membership + user listesini çek; normalize email → user map oluştur; ay içindeki completed session'ları `Athlete` ve set loglarıyla sorgula; bellekte user bazında aggregate et
- Sıra: `TotalVolumeKg DESC`, sonra `SessionCount DESC`, sonra `FullName ASC`; ilk 50 kayıt. Ay içinde verisi olmayan aktif üyeler 0 değerleriyle listenin sonunda kalabilir

---

## 6. MediaService — Medya Upload

`Services/MediaService.cs` dosyasına aşağıdaki iki public metodu ve private ortak helper'ı ekle. Kod mevcut image validasyonu, per-user kota kontrolü, soft-delete ve storage silme davranışıyla uyumludur:

```csharp
public async Task<(MediaAsset? Asset, string? Error)> SaveGymLogoAsync(
    TrackMeDbContext db,
    AppUser owner,
    Gym gym,
    IFormFile file,
    CancellationToken cancellationToken = default)
    => await SaveGymImageAsync(
        db, owner, gym, file, MediaPurpose.GymLogo, "logo", cancellationToken);

public async Task<(MediaAsset? Asset, string? Error)> SaveGymCoverAsync(
    TrackMeDbContext db,
    AppUser owner,
    Gym gym,
    IFormFile file,
    CancellationToken cancellationToken = default)
    => await SaveGymImageAsync(
        db, owner, gym, file, MediaPurpose.GymCover, "cover", cancellationToken);

private async Task<(MediaAsset? Asset, string? Error)> SaveGymImageAsync(
    TrackMeDbContext db,
    AppUser owner,
    Gym gym,
    IFormFile file,
    MediaPurpose purpose,
    string objectSegment,
    CancellationToken cancellationToken)
{
    if (file.Length <= 0)
        return (null, "file is required.");
    if (file.Length > MaxProfileImageBytes)
        return (null, "file must be 5MB or smaller.");
    if (!AllowedImageTypes.TryGetValue(file.ContentType, out var extension))
        return (null, "only JPEG, PNG and WebP images are supported.");

    var quotaError = await CheckQuotaAsync(db, owner.Id, owner.Role, file.Length, cancellationToken);
    if (quotaError is not null)
        return (null, quotaError);

    var mediaId = Guid.NewGuid();
    var objectKey = $"gyms/{gym.Id}/{objectSegment}/{mediaId}{extension}";

    await using var stream = file.OpenReadStream();
    var stored = await storage.SaveAsync(stream, objectKey, file.ContentType, cancellationToken);

    var asset = new MediaAsset
    {
        Id = mediaId,
        OwnerUserId = owner.Id,
        MediaType = MediaType.Image,
        Purpose = purpose,
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

    var previousId = purpose == MediaPurpose.GymLogo
        ? gym.LogoMediaAssetId
        : gym.CoverMediaAssetId;
    var previous = previousId is null
        ? null
        : await db.MediaAssets.FirstOrDefaultAsync(m => m.Id == previousId, cancellationToken);

    if (purpose == MediaPurpose.GymLogo)
        gym.LogoMediaAssetId = asset.Id;
    else
        gym.CoverMediaAssetId = asset.Id;

    if (previous is not null && previous.DeletedAt is null)
    {
        previous.Status = MediaStatus.Deleted;
        previous.DeletedAt = DateTimeOffset.UtcNow;
        await storage.DeleteAsync(previous.ObjectKey, cancellationToken);
    }

    db.MediaAssets.Add(asset);
    await db.SaveChangesAsync(cancellationToken);
    return (asset, null);
}
```

### Media içeriği ve orphan cleanup

İki ek entegrasyon zorunludur; aksi halde yükleme başarılı görünür ama medya 404 olur veya 24 saat sonra cleanup tarafından silinir:

1. `MediaEndpoints.GetContent` içindeki allowed-purpose kontrolüne `MediaPurpose.GymLogo` ve `MediaPurpose.GymCover` ekle.
2. `OrphanMediaCleanupService` sorgusuna şunları ekle:

```csharp
&& !db.Gyms.Any(g => g.LogoMediaAssetId == m.Id)
&& !db.Gyms.Any(g => g.CoverMediaAssetId == m.Id)
```

Gym DTO URL'leri mevcut convention ile `/api/media/{assetId}/content` biçiminde üretilir; `PublicUrl` doğrudan DTO'ya yazılmaz.

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
getMyGyms: () => request('/api/gyms/my'),
getGym: (id) => request(`/api/gyms/${id}`),
createGym: (data) => request('/api/gyms', { method: 'POST', body: JSON.stringify(data) }),
updateGym: (id, data) => request(`/api/gyms/${id}`, { method: 'PATCH', body: JSON.stringify(data) }),
deleteGym: (id) => request(`/api/gyms/${id}`, { method: 'DELETE' }),
uploadGymLogo: (id, file) => uploadFile(`/api/gyms/${id}/logo`, file),
uploadGymCover: (id, file) => uploadFile(`/api/gyms/${id}/cover`, file),
inviteGymMember: (id, data) => request(`/api/gyms/${id}/invite`, { method: 'POST', body: JSON.stringify(data) }),
acceptGymInvite: (token) => request(`/api/gyms/invites/${token}/accept`, { method: 'POST' }),
getGymMembers: (id) => request(`/api/gyms/${id}/members`),
changeGymMemberRole: (id, userId, data) => request(`/api/gyms/${id}/members/${userId}/role`, { method: 'PATCH', body: JSON.stringify(data) }),
removeGymMember: (id, userId) => request(`/api/gyms/${id}/members/${userId}`, { method: 'DELETE' }),
toggleGymMemberBan: (id, userId) => request(`/api/gyms/${id}/members/${userId}/ban`, { method: 'PATCH' }),
getGymPosts: (id, page = 1, pageSize = 20) => request(`/api/gyms/${id}/posts?page=${page}&pageSize=${pageSize}`),
createGymPost: (id, data) => request(`/api/gyms/${id}/posts`, { method: 'POST', body: JSON.stringify(data) }),
deleteGymPost: (id, postId) => request(`/api/gyms/${id}/posts/${postId}`, { method: 'DELETE' }),
addGymComment: (id, postId, data) => request(`/api/gyms/${id}/posts/${postId}/comments`, { method: 'POST', body: JSON.stringify(data) }),
deleteGymComment: (id, postId, commentId) => request(`/api/gyms/${id}/posts/${postId}/comments/${commentId}`, { method: 'DELETE' }),
toggleGymReaction: (id, postId) => request(`/api/gyms/${id}/posts/${postId}/reactions`, { method: 'POST' }),
getGymLeaderboard: (id) => request(`/api/gyms/${id}/leaderboard`),
```

### `views/GymsView.jsx`

- Üst: "Gym'lerim" başlığı + "Gym Oluştur" butonu
- Gym kartı: logo, isim, üye sayısı, rolüm, "Gör" linki
- Props: `currentUser`, `onOpenGym`, `t`
- Create modal: name, description, Public/Private segmented control; başarıda listeyi yenile ve `onOpenGym(created.id)` çağır
- Bekleyen davet varsa hash'in üçüncü parçasından (`#gyms/invite/{token}`) token alınabilir: "Daveti Kabul Et" banner → `acceptGymInvite(token)` → yenile
- Empty, loading ve API error state'leri görünür olmalı

### `views/GymDetailView.jsx`

Props: `gymId`, `currentUser`, `onBack`, `t`. Ayrı router yoktur; `App.jsx` `#gyms/{id}` hash'inden gymId geçirir.

Sekme yapısı:
- **Feed** — `GymPostCard` listesi + "Post Ekle" formu (aktif üyeler)
- **Üyeler** — `GymMemberDto` listesi; Owner/Coach için hiyerarşiye uygun Rol değiştir / At / Ban butonları
- **Ayarlar** (Owner only) — İsim/açıklama düzenle, logo/kapak yükle, gym sil
- **Leaderboard** — Bu ayki top 10 üye
- Tab state component içinde tutulur; gym detail, aktif tabın verisini yükler ve mutation sonrası yalnızca ilgili listeyi yeniler
- Logo/cover inputları `image/jpeg,image/png,image/webp`, client-side max 5 MB validasyonu uygular; API kota/413 mesajı mevcut toast ile gösterilir

### `components/GymPostCard.jsx`

```jsx
// Props: post, gymId, currentUserId, onDelete, canModerate
// İçerik: AuthorName + avatar, CreatedAt, Body, opsiyonel medya
// Alt: Heart ve MessageCircle lucide ikonlarıyla reactionCount/commentCount
// Expand açılınca: post.comments listesi + yorum ekleme inputu
// Sil butonu: post.authorUserId === currentUserId || canModerate
```

Reaction ve comment mutation'larında tüm feed'i zorunlu yeniden yüklemek yerine ilgili post state'i güncellenebilir; API hatasında optimistic değişiklik geri alınır.

### `components/GymLeaderboardCard.jsx`

- `entries`, `loading`, `t` props alır
- İlk 10 kaydı rank, avatar/emoji, ad, session count ve `formatWeight(totalVolumeKg, weightUnit)` ile gösterir
- Veri yoksa `gymLeaderboardEmpty`; sabit satır yüksekliği kullan, liste yüklenirken layout kaymasın

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
gyms: 'Gym\'ler',
gymRoleOwner: 'Sahip',
gymRoleCoach: 'Koç',
gymRoleMember: 'Üye',
gymMemberCount: 'üye',
gymLeave: 'Gym\'den Ayrıl',
gymTransferOwnership: 'Sahipliği Devret',
gymConfirmDelete: 'Bu gym ve topluluk akışı kapatılacak. Emin misin?',
gymNoGyms: 'Henüz üye olduğun bir gym yok',
gymNoPosts: 'Henüz paylaşım yok',
gymLoadMore: 'Daha Fazla Yükle',
gymLogo: 'Gym logosu',
gymCover: 'Gym kapak görseli',

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
gyms: 'Gyms',
gymRoleOwner: 'Owner',
gymRoleCoach: 'Coach',
gymRoleMember: 'Member',
gymMemberCount: 'members',
gymLeave: 'Leave Gym',
gymTransferOwnership: 'Transfer Ownership',
gymConfirmDelete: 'This gym and its community feed will be closed. Are you sure?',
gymNoGyms: 'You have not joined a gym yet',
gymNoPosts: 'No posts yet',
gymLoadMore: 'Load More',
gymLogo: 'Gym logo',
gymCover: 'Gym cover image',
```

### `App.jsx` — Hash/view entegrasyonu

- `Building2` lucide ikonunu import et
- `TRAINER_NAV`, `ATHLETE_NAV`, `ADMIN_NAV` dizilerine `{ id: 'gyms', icon: Building2 }` ekle
- `VALID_VIEWS` set'ine `'gyms'` ekle
- `selectedGymId` state ekle
- Hash parse sırasında `#gyms/{id}` ise `selectedGymId = id`; yalnız `#gyms` ise null yap
- `#gyms/invite/{token}` özel durumunda `selectedGymId` null kalır; token `GymsView` prop'una verilir veya view içinde hash'ten okunur. `invite` kelimesini gym ID sanma
- Liste açma: `window.location.hash = 'gyms'`
- Detay açma: `setSelectedGymId(id); window.location.hash = `gyms/${id}``
- Geri: `setSelectedGymId(null); window.location.hash = 'gyms'`
- Render:

```jsx
{view === 'gyms' && !selectedGymId && (
  <GymsView currentUser={currentUser} onOpenGym={openGymDetail} t={t} />
)}
{view === 'gyms' && selectedGymId && (
  <GymDetailView
    gymId={selectedGymId}
    currentUser={currentUser}
    onBack={closeGymDetail}
    t={t}
  />
)}
```

---

## 9. Görev Sırası

1. `Enums.cs` — yeni enum değerleri + `MediaPurpose` güncelleme
2. 6 entity dosyası oluştur
3. `TrackMeDbContext.cs` — DbSet'ler + OnModelCreating konfigürasyonları
4. `MediaService.cs` — `SaveGymLogoAsync` + `SaveGymCoverAsync`
5. `MediaEndpoints.cs` allowed purpose + `OrphanMediaCleanupService.cs` gym referansları
6. Migration: `dotnet ef migrations add Phase19_GymCommunity --project src/TrackMe.Api/TrackMe.Api.csproj`
7. `Models/Dtos.cs` — yeni DTO'lar + request record'ları
8. `Endpoints/GymEndpoints.cs` — tam 20 endpoint
9. `Program.cs` — `app.MapGymEndpoints()`
10. Build: `dotnet build src/TrackMe.Api/TrackMe.Api.csproj`
11. Frontend: `api.js`, `GymsView.jsx`, `GymDetailView.jsx`, `GymPostCard.jsx`, `GymLeaderboardCard.jsx`, `i18n.js`, `App.jsx`, `styles.css`
12. Build: `npm.cmd run build`
13. Docs güncelle ve API/Web/Docs repolarını ayrı commit et; push atma

---

## 10. Docs Güncelleme (görev bitince)

- `TrackMe-Api/README.md` → migration count 64 → 65
- `TrackMe-Docs/tasks/specs/README.md` → migration count 64 → 65
- `TrackMe-Docs/tasks/phases.md` → Phase 19 "Planned" bölümünü "Complete" olarak güncelle
- `TrackMe-Docs/tasks/backlog.md` → Phase 19 Tamamlananlar'a taşı
- `TrackMe-Docs/database/migration-strategy.md` → Phase 19 migration history ekle
- `TrackMe-Docs/architecture/overview.md` → "Gym system + leaderboard" durumunu `✅ Live` yap
- `TrackMe-Web/README.md` → `GymsView`, `GymDetailView`, `GymPostCard`, `GymLeaderboardCard` ve hash navigasyonunu yaz
- `TrackMe-Api/README.md` → 20 endpoint'i gruplar halinde belgele; media purpose ve quota davranışını belirt
- `TrackMe-Docs/tasks/specs/README.md` → spec'i Completed tablosuna taşı ve bu dosyayı sil

Önerilen commit mesajları:

```text
TrackMe-Api: feat: Phase 19 gym community entities and endpoints
TrackMe-Web: feat: add gym community views and leaderboard
TrackMe-Docs: docs: Phase 19 gym community complete
```

---

## 11. Kabul Kriterleri

1. Migration CLI ile üretilmiş ve toplam migration sayısı 65.
2. Altı tablo ve tüm enum sütunları PostgreSQL'de snake_case/string conversion ile oluşuyor.
3. Aynı kullanıcı aynı gym'de ikinci membership veya aynı postta ikinci reaction kaydı oluşturamıyor.
4. Banned kullanıcı Public gym dahil feed, members, post, comment, reaction ve leaderboard endpoint'lerinden 403 alıyor.
5. Coach eşit/yüksek role işlem yapamıyor; owner transferi `gyms.owner_user_id` ile membership rollerini birlikte güncelliyor.
6. Logo/cover yüklemesi 5 MB/type/kota kontrolünden geçiyor; kota aşımı 413, content endpoint'i 404 vermiyor, orphan cleanup medyayı silmiyor.
7. Feed `PagedResult<GymPostDto>` dönüyor ve comment paneli ayrı GET endpoint olmadan çalışıyor.
8. Leaderboard takvim ayını, completed non-warmup set hacmini ve email tabanlı AppUser↔Athlete eşleşmesini kullanıyor.
9. `#gyms` ve `#gyms/{id}` doğrudan açıldığında doğru ekran render ediliyor; browser geri hareketi liste/detay durumunu bozmaz.
10. `dotnet build` ve `npm.cmd run build` başarılı; migration elle düzenlenmemiş; push yapılmamış.
