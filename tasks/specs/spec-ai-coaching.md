# Spec: Phase 20 — AI Koçluk

**Bu spec benim (primary agent) içindir. Kullanıcı "başla" dediğinde uygulanır.**

**Bağımlılık:** Phase 13 ✅ — OpenAI API key env var olarak ayarlanmış olmalı.  
**Migration adı:** `Phase20_AiProgramDraft`  
**Tahmini migration sayısı:** 66 (Phase 19 sonrası 65)

---

## Amaç

Trainer, bir athlete için program üretmesini OpenAI'dan isteyebilir. AI'dan dönen taslak gün yapısı trainer tarafından gözden geçirilip düzenlenir; onaylayınca gerçek `WorkoutProgram` oluşur.

**AI direkt program oluşturmaz — trainer onaylamadan hiçbir şey kaydedilmez.**

---

## Codebase Kuralları

- Migration CLI: `dotnet ef migrations add Phase20_AiProgramDraft --project src/TrackMe.Api/TrackMe.Api.csproj`
- Tüm sütunlar snake_case → `HasColumnName()`
- Endpoint: `public static class AiEndpoints` + `MapAiEndpoints(this IEndpointRouteBuilder)`
- DTO'lar: `sealed record` → `Models/Dtos.cs`
- Enum'lar: `Models/Enums.cs`

---

## 1. Yeni Enum — `Models/Enums.cs`

```csharp
public enum AiDraftStatus { Pending, Accepted, Rejected }
```

---

## 2. Entity — `Models/AiProgramDraft.cs`

```csharp
namespace TrackMe.Api.Models;

public class AiProgramDraft
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid TrainerId { get; set; }
    public Trainer? Trainer { get; set; }
    public Guid AthleteId { get; set; }
    public Athlete? Athlete { get; set; }
    public string ContextJson { get; set; } = "";   // AI'ya gönderilen request özeti
    public string ResponseJson { get; set; } = "";  // AI'dan dönen ham JSON
    public AiDraftStatus Status { get; set; } = AiDraftStatus.Pending;
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? ReviewedAt { get; set; }
}
```

---

## 3. DbContext — `Data/TrackMeDbContext.cs`

DbSet ekle:
```csharp
public DbSet<AiProgramDraft> AiProgramDrafts { get; set; }
```

`OnModelCreating` ekle:
```csharp
modelBuilder.Entity<AiProgramDraft>(entity =>
{
    entity.ToTable("ai_program_drafts");
    entity.HasKey(d => d.Id);
    entity.Property(d => d.Id).HasColumnName("id");
    entity.Property(d => d.TrainerId).HasColumnName("trainer_id");
    entity.Property(d => d.AthleteId).HasColumnName("athlete_id");
    entity.Property(d => d.ContextJson).HasColumnName("context_json").IsRequired();
    entity.Property(d => d.ResponseJson).HasColumnName("response_json").IsRequired();
    entity.Property(d => d.Status).HasColumnName("status").HasConversion<string>().HasMaxLength(20).IsRequired();
    entity.Property(d => d.CreatedAt).HasColumnName("created_at");
    entity.Property(d => d.ReviewedAt).HasColumnName("reviewed_at");
    entity.HasOne(d => d.Trainer).WithMany().HasForeignKey(d => d.TrainerId).OnDelete(DeleteBehavior.Cascade);
    entity.HasOne(d => d.Athlete).WithMany().HasForeignKey(d => d.AthleteId).OnDelete(DeleteBehavior.Cascade);
    entity.HasIndex(d => new { d.TrainerId, d.CreatedAt });
});
```

---

## 4. Environment Variable

`Program.cs` içinde kayıt gerekmez — `IHttpClientFactory` zaten `AddHttpClient()` ile mevcut.  
`OPENAI_API_KEY` env var'dan okunacak: `builder.Configuration["OPENAI_API_KEY"]`.  

`.env.example` dosyasına ekle:
```
OPENAI_API_KEY=your-openai-key-here
```

---

## 5. AI Prompt Tasarımı

### Request JSON (AI'ya gönderilen)

```json
{
  "trainerRequest": {
    "goals": "Hipertrofi, üst vücut",
    "availableDays": 4,
    "fitnessLevel": "Intermediate",
    "notes": "Athlete sırt ağrısı yaşıyor, deadlift ağır olmasın"
  },
  "exerciseLibrary": [
    { "id": "uuid", "name": "Bench Press", "category": "Chest", "equipment": "Barbell" },
    ...
  ],
  "athleteHistory": {
    "avgWeeklyVolume": 12500,
    "avgRpe": 7.2,
    "completedSessions30Days": 14,
    "topExercises": ["Bench Press", "Squat", "Pull-up"]
  }
}
```

### System Prompt

```
Sen deneyimli bir personal trainer asistanısın. Trainer'ın isteğine göre
haftalık antrenman programı taslağı üretiyorsun.

ZORUNLU KURALLAR:
- Sadece aşağıdaki exerciseLibrary listesindeki egzersiz ID'lerini kullan
- Yanıtını SADECE geçerli JSON olarak ver, başka metin ekleme
- Response şeması:
{
  "programTitle": "string",
  "description": "string",
  "days": [
    {
      "dayNumber": 1,
      "title": "string",
      "notes": "string | null",
      "exercises": [
        {
          "exerciseId": "uuid",
          "sets": 3,
          "reps": "8-10",
          "targetRpe": 7,
          "restSeconds": 90,
          "notes": "string | null"
        }
      ]
    }
  ]
}
```

### Exercise Library Sınırı

Tüm egzersizleri AI'ya gönderme — token israfı olur. Filtrele:
1. Trainer'ın kendi özel egzersizleri (tümü)
2. Global egzersizler — sadece ilk 80 (name + category + equipment ile sınırlı fields)

---

## 6. DTO'lar — `Models/Dtos.cs`

```csharp
// AI draft görüntüleme
public sealed record AiProgramDraftDto(
    Guid Id, Guid AthleteId, string AthleteName,
    string Status, string ResponseJson, DateTimeOffset CreatedAt);

// AI draft oluşturma isteği
public sealed record CreateAiDraftRequest(
    Guid AthleteId,
    string Goals,
    int AvailableDays,
    string FitnessLevel,
    string? Notes = null);

// Kabul — opsiyonel başlangıç tarihi
public sealed record AcceptAiDraftRequest(DateOnly? StartsOn = null);

// AI'dan dönen gün yapısı (deserialize için internal record)
internal sealed record AiExerciseItem(
    Guid ExerciseId, int Sets, string? Reps,
    int? TargetRpe, int? RestSeconds, string? Notes);

internal sealed record AiDayItem(
    int DayNumber, string Title, string? Notes,
    List<AiExerciseItem> Exercises);

internal sealed record AiResponsePayload(
    string ProgramTitle, string? Description, List<AiDayItem> Days);
```

---

## 7. Endpoint Dosyası — `Endpoints/AiEndpoints.cs`

```csharp
public static class AiEndpoints
{
    public static IEndpointRouteBuilder MapAiEndpoints(this IEndpointRouteBuilder app)
    {
        app.MapPost("/api/programs/ai-draft", CreateDraft).RequireAuthorization();
        app.MapGet("/api/programs/ai-draft", GetMyDrafts).RequireAuthorization();
        app.MapGet("/api/programs/ai-draft/{id:guid}", GetDraft).RequireAuthorization();
        app.MapPost("/api/programs/ai-draft/{id:guid}/accept", AcceptDraft).RequireAuthorization();
        app.MapPost("/api/programs/ai-draft/{id:guid}/reject", RejectDraft).RequireAuthorization();
        return app;
    }
```

---

### `CreateDraft` — AI Çağrısı

```csharp
private static async Task<IResult> CreateDraft(
    CreateAiDraftRequest request,
    ClaimsPrincipal principal,
    TrackMeDbContext db,
    IConfiguration config,
    IHttpClientFactory httpClientFactory,
    CancellationToken ct)
{
    // 1. Trainer doğrulama
    var profileId = ClaimsReader.GetProfileId(principal);
    var trainer = await db.Trainers.FindAsync([profileId], ct);
    if (trainer is null) return EndpointHelpers.Forbidden("trainer profile required.");

    // 2. Athlete erişim kontrolü (kabul edilmiş coaching ilişkisi)
    if (!await EndpointHelpers.HasAcceptedRelationshipAsync(db, trainer.Id, request.AthleteId))
        return EndpointHelpers.Forbidden("accepted coaching relationship required.");

    var athlete = await db.Athletes.FindAsync([request.AthleteId], ct);
    if (athlete is null) return Results.NotFound();

    // 3. Egzersiz kütüphanesini hazırla
    var exercises = await db.Exercises
        .Where(e => e.IsActive && (e.IsGlobal || e.OwnerId == trainer.Id))
        .OrderBy(e => e.IsGlobal)
        .Take(80)
        .Select(e => new { e.Id, e.Name, e.Category, e.Equipment })
        .ToListAsync(ct);

    // 4. Athlete geçmişini özetle (son 30 gün)
    var thirtyDaysAgo = DateTimeOffset.UtcNow.AddDays(-30);
    var sessionCount = await db.WorkoutSessions
        .CountAsync(s => s.AthleteId == request.AthleteId
            && s.Status == SessionStatus.Completed
            && s.StartedAt >= thirtyDaysAgo, ct);

    // 5. Prompt hazırla
    var contextObj = new
    {
        trainerRequest = new
        {
            goals = request.Goals,
            availableDays = request.AvailableDays,
            fitnessLevel = request.FitnessLevel,
            notes = request.Notes
        },
        exerciseLibrary = exercises,
        athleteHistory = new { completedSessions30Days = sessionCount }
    };
    var contextJson = JsonSerializer.Serialize(contextObj);

    var systemPrompt = """
        Sen deneyimli bir personal trainer asistanısın.
        Trainer'ın isteğine göre haftalık antrenman programı taslağı üretiyorsun.
        Sadece verilen exerciseLibrary listesindeki ID'leri kullan.
        Yanıtını SADECE geçerli JSON olarak ver, başka metin ekleme.
        JSON şeması: { "programTitle": "...", "description": "...", "days": [ { "dayNumber": 1, "title": "...", "notes": null, "exercises": [ { "exerciseId": "uuid", "sets": 3, "reps": "8-10", "targetRpe": 7, "restSeconds": 90, "notes": null } ] } ] }
        """;

    // 6. OpenAI isteği
    var apiKey = config["OPENAI_API_KEY"];
    if (string.IsNullOrWhiteSpace(apiKey))
        return Results.Problem("AI service not configured.", statusCode: 503);

    string responseJson;
    try
    {
        using var client = httpClientFactory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", apiKey);

        var payload = new
        {
            model = "gpt-4o-mini",
            temperature = 0.7,
            messages = new[]
            {
                new { role = "system", content = systemPrompt },
                new { role = "user", content = contextJson }
            }
        };

        var response = await client.PostAsJsonAsync(
            "https://api.openai.com/v1/chat/completions", payload, ct);

        if (!response.IsSuccessStatusCode)
            return Results.Problem("AI service returned an error.", statusCode: 502);

        using var doc = await JsonDocument.ParseAsync(
            await response.Content.ReadAsStreamAsync(ct), cancellationToken: ct);
        responseJson = doc.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString() ?? "{}";
    }
    catch (Exception)
    {
        return Results.Problem("AI service unavailable.", statusCode: 502);
    }

    // 7. Geçerli JSON mi kontrol et (parse test)
    try { JsonSerializer.Deserialize<AiResponsePayload>(responseJson); }
    catch { return Results.Problem("AI returned invalid JSON.", statusCode: 502); }

    // 8. Draft kaydet
    var draft = new AiProgramDraft
    {
        TrainerId = trainer.Id,
        AthleteId = request.AthleteId,
        ContextJson = contextJson,
        ResponseJson = responseJson,
        Status = AiDraftStatus.Pending
    };
    db.AiProgramDrafts.Add(draft);
    await db.SaveChangesAsync(ct);

    return Results.Created($"/api/programs/ai-draft/{draft.Id}",
        new AiProgramDraftDto(draft.Id, athlete.Id, athlete.FullName,
            draft.Status.ToString(), draft.ResponseJson, draft.CreatedAt));
}
```

---

### `GetMyDrafts`

```csharp
// Trainer kendi taslak listesi (son 20, Pending önce)
var drafts = await db.AiProgramDrafts
    .Where(d => d.TrainerId == trainer.Id)
    .Include(d => d.Athlete)
    .OrderByDescending(d => d.CreatedAt)
    .Take(20)
    .ToListAsync(ct);
```

---

### `GetDraft`

```csharp
// Trainer kendi taslağını görebilir; Admin tümünü
var draft = await db.AiProgramDrafts.Include(d => d.Athlete).FindAsync(...);
if (draft.TrainerId != trainer.Id && !isAdmin) return Results.Forbid();
return Results.Ok(new AiProgramDraftDto(...));
```

---

### `AcceptDraft`

AI taslağından gerçek `WorkoutProgram` oluştur:

```csharp
private static async Task<IResult> AcceptDraft(
    Guid id, AcceptAiDraftRequest request,
    ClaimsPrincipal principal, TrackMeDbContext db, CancellationToken ct)
{
    var trainer = ...; // trainer doğrula
    var draft = await db.AiProgramDrafts.FindAsync([id], ct);

    if (draft is null || draft.TrainerId != trainer.Id) return Results.NotFound();
    if (draft.Status != AiDraftStatus.Pending)
        return Results.BadRequest(new { message = "draft already reviewed." });

    // JSON'u parse et
    AiResponsePayload payload;
    try { payload = JsonSerializer.Deserialize<AiResponsePayload>(draft.ResponseJson)!; }
    catch { return Results.Problem("draft contains invalid JSON.", statusCode: 500); }

    // Egzersiz ID'lerini doğrula (hepsinin DB'de var olduğunu kontrol et)
    var requestedIds = payload.Days
        .SelectMany(d => d.Exercises.Select(e => e.ExerciseId))
        .Distinct()
        .ToList();
    var validIds = await db.Exercises
        .Where(e => requestedIds.Contains(e.Id) && e.IsActive)
        .Select(e => e.Id)
        .ToHashSetAsync(ct);

    // WorkoutProgram oluştur
    var program = new WorkoutProgram
    {
        TrainerId = trainer.Id,
        AthleteId = draft.AthleteId,
        Title = payload.ProgramTitle,
        Description = payload.Description,
        StartsOn = request.StartsOn,
        IsActive = true
    };
    db.WorkoutPrograms.Add(program);

    // Günler + egzersizler
    foreach (var day in payload.Days.OrderBy(d => d.DayNumber))
    {
        var programDay = new WorkoutProgramDay
        {
            ProgramId = program.Id,
            DayNumber = day.DayNumber,
            Title = day.Title,
            Notes = day.Notes
        };
        db.WorkoutProgramDays.Add(programDay);

        int order = 0;
        foreach (var ex in day.Exercises)
        {
            if (!validIds.Contains(ex.ExerciseId)) continue; // geçersiz ID'yi atla
            db.WorkoutProgramExercises.Add(new WorkoutProgramExercise
            {
                DayId = programDay.Id,
                ExerciseId = ex.ExerciseId,
                OrderIndex = order++,
                Sets = ex.Sets,
                Reps = ex.Reps ?? "10",
                TargetRpe = ex.TargetRpe,
                RestSeconds = ex.RestSeconds ?? 60,
                Notes = ex.Notes
            });
        }
    }

    // Draft status güncelle
    draft.Status = AiDraftStatus.Accepted;
    draft.ReviewedAt = DateTimeOffset.UtcNow;

    await db.SaveChangesAsync(ct);

    return Results.Ok(new { ProgramId = program.Id, message = "program created from AI draft." });
}
```

---

### `RejectDraft`

```csharp
draft.Status = AiDraftStatus.Rejected;
draft.ReviewedAt = DateTimeOffset.UtcNow;
await db.SaveChangesAsync(ct);
return Results.NoContent();
```

---

## 8. `Program.cs`

```csharp
app.MapAiEndpoints();
```

---

## 9. Frontend — `TrackMe-Web/src/`

### `services/api.js`

```js
createAiDraft: (data) => authFetch('/api/programs/ai-draft', { method: 'POST', body: JSON.stringify(data) }),
getMyAiDrafts: () => authFetch('/api/programs/ai-draft'),
getAiDraft: (id) => authFetch(`/api/programs/ai-draft/${id}`),
acceptAiDraft: (id, data) => authFetch(`/api/programs/ai-draft/${id}/accept`, { method: 'POST', body: JSON.stringify(data) }),
rejectAiDraft: (id) => authFetch(`/api/programs/ai-draft/${id}/reject`, { method: 'POST' }),
```

### `views/ProgramsView.jsx` — "AI ile Oluştur" Butonu

Mevcut program listesi sayfasında, sadece trainer kullanıcılara görünür:

```jsx
{isTrainer && (
  <button className="btn btn-secondary" onClick={() => setShowAiModal(true)}>
    ✨ {t('aiDraftCreate')}
  </button>
)}
{showAiModal && <AiDraftModal onClose={() => setShowAiModal(false)} onAccepted={handleProgramCreated} />}
```

### `components/AiDraftModal.jsx`

**Adım 1 — Form:**
```jsx
// athleteId seçimi (trainer'ın athlete listesinden)
// goals textarea
// availableDays: 2-6 number input
// fitnessLevel: Beginner / Intermediate / Advanced select
// notes textarea (opsiyonel)
// "Taslak Oluştur" butonu → api.createAiDraft() çağır
// Loading state: "AI programı oluşturuyor..." spinner
```

**Adım 2 — Taslak Görüntüle (response gelince):**
```jsx
// programTitle + description göster
// Her gün için expandable kart: dayNumber, title, egzersiz listesi (name + sets + reps + RPE)
// "Kabul Et" → api.acceptAiDraft(id, { startsOn }) → modal kapat + programlar yenile
// "Reddet" → api.rejectAiDraft(id) → modal kapat
// "Yeniden Oluştur" → form'a dön
```

Egzersiz adını göstermek için response JSON'daki `exerciseId`'yi egzersiz listesiyle eşleştir:
```js
// Draft oluşturulunca parent'tan egzersiz listesini prop olarak al
// exerciseId → exercise.name map'i kur
```

### `i18n.js`

```js
// TR
aiDraftCreate: 'AI ile Program Oluştur',
aiDraftGoals: 'Hedefler',
aiDraftGoalsPlaceholder: 'Örn: Hipertrofi, üst vücut gücü',
aiDraftDays: 'Haftalık Antrenman Günü',
aiDraftLevel: 'Fitness Seviyesi',
aiDraftNotes: 'Notlar (opsiyonel)',
aiDraftGenerating: 'AI programı oluşturuyor...',
aiDraftResult: 'AI Taslağı',
aiDraftAccept: 'Kabul Et ve Oluştur',
aiDraftReject: 'Reddet',
aiDraftRetry: 'Yeniden Oluştur',
aiDraftBadge: 'AI Önerisi',
aiDraftStartsOn: 'Başlangıç Tarihi (opsiyonel)',
aiDraftAccepted: 'AI taslağından program oluşturuldu',
aiDraftRejected: 'Taslak reddedildi',
aiServiceUnavailable: 'AI servisi şu an kullanılamıyor',
// Seviyeler
aiLevelBeginner: 'Başlangıç',
aiLevelIntermediate: 'Orta',
aiLevelAdvanced: 'İleri',

// EN
aiDraftCreate: 'Create with AI',
aiDraftGoals: 'Goals',
aiDraftGoalsPlaceholder: 'e.g. Hypertrophy, upper body strength',
aiDraftDays: 'Training Days per Week',
aiDraftLevel: 'Fitness Level',
aiDraftNotes: 'Notes (optional)',
aiDraftGenerating: 'AI is generating a program...',
aiDraftResult: 'AI Draft',
aiDraftAccept: 'Accept & Create',
aiDraftReject: 'Reject',
aiDraftRetry: 'Generate Again',
aiDraftBadge: 'AI Suggestion',
aiDraftStartsOn: 'Start Date (optional)',
aiDraftAccepted: 'Program created from AI draft',
aiDraftRejected: 'Draft rejected',
aiServiceUnavailable: 'AI service is currently unavailable',
aiLevelBeginner: 'Beginner',
aiLevelIntermediate: 'Intermediate',
aiLevelAdvanced: 'Advanced',
```

---

## 10. Görev Sırası

1. `Enums.cs` — `AiDraftStatus` ekle
2. `Models/AiProgramDraft.cs` — entity oluştur
3. `Data/TrackMeDbContext.cs` — DbSet + OnModelCreating
4. Migration: `dotnet ef migrations add Phase20_AiProgramDraft --project src/TrackMe.Api/TrackMe.Api.csproj`
5. `Models/Dtos.cs` — yeni record'lar
6. `Endpoints/AiEndpoints.cs` — 5 endpoint
7. `Program.cs` — `app.MapAiEndpoints()`
8. `.env.example` — `OPENAI_API_KEY` ekle
9. Build: `dotnet build src/TrackMe.Api/TrackMe.Api.csproj`
10. Frontend: `api.js`, `AiDraftModal.jsx`, `ProgramsView.jsx` (butonu ekle), `i18n.js`
11. Docs güncelle: `phases.md`, `backlog.md`, `migration-strategy.md`, `specs/README.md`, `TrackMe-Api/README.md`

---

## 11. Dikkat Edilecekler

- `OPENAI_API_KEY` yoksa `503` döndür, crash etme
- AI geçersiz `exerciseId` üretebilir → `AcceptDraft`'ta validIds kontrolü var, geçersizler atlanır
- `gpt-4o-mini` model seçimi: ucuz + hızlı; kalite yetersizse `gpt-4o` ile değiştir
- Response zaman aşımı: `HttpClient.Timeout = TimeSpan.FromSeconds(60)` set et
- Çift accept engeli: `draft.Status != Pending` kontrolü var
