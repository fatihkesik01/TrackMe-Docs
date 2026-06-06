# EF Core Migration Strategy

TrackMe uses PostgreSQL, but the application schema is managed from the `TrackMe-Api` repository with Entity Framework Core migrations.

## Source Of Truth

- Entity classes and `TrackMeDbContext` configuration define the model.
- EF Core migration files define schema history.
- Hand-written SQL schema files are not used as the source of truth.

## Auto-Apply on Startup

The API calls `db.Database.MigrateAsync()` at startup (up to 10 retries, 3s apart). **No manual `dotnet ef database update` is needed in production.** Just deploy and restart — pending migrations apply automatically.

## Adding a New Migration — ALWAYS Use the CLI

**Never write migration files by hand.** Always use:

```powershell
dotnet ef migrations add Phase<N>_<Description> --project .\src\TrackMe.Api\TrackMe.Api.csproj --startup-project .\src\TrackMe.Api\TrackMe.Api.csproj
```

This generates three files correctly:
| File | Purpose |
|------|---------|
| `Migrations/<timestamp>_<Name>.cs` | Up/Down SQL with correct table/column names |
| `Migrations/<timestamp>_<Name>.Designer.cs` | EF Core metadata for this migration point |
| `Migrations/TrackMeDbContextModelSnapshot.cs` | Updated compiled model snapshot |

**All three files must be committed together.** Do not edit only one of them.

If the latest migration is wrong and has not been applied to any shared/production database, remove it with the CLI before regenerating:

```powershell
dotnet ef migrations remove --project .\src\TrackMe.Api\TrackMe.Api.csproj --startup-project .\src\TrackMe.Api\TrackMe.Api.csproj --force
```

If a wrong migration may already be applied to a shared/production database, do not rewrite it. Create a new corrective migration.

If a migration partially ran in production and created objects but did not write to `__EFMigrationsHistory`, treat it as an incident:

- Do not drop production data casually.
- Make the pending migration idempotent for the already-created objects, or create a carefully reviewed repair migration if the pending migration is already recorded.
- Verify the next API startup writes the migration history row and `/api/health` reports the database as reachable.

### Why manual migration files crash the API

EF Core 9+ throws `PendingModelChangesWarning` as a fatal exception when the compiled model doesn't match the snapshot. A manually written migration will:
- Use wrong table/column names (this project uses snake_case via explicit `HasColumnName()`)
- Produce an inconsistent snapshot
- Cause the API to enter a crash/restart loop on every startup

### Column naming convention

All columns use **snake_case** (e.g. `athlete_id`, `order_index`), configured via `HasColumnName()` in `TrackMeDbContext.OnModelCreating()`. The CLI reads this and generates correct names automatically.

## Workflow Checklist When Adding a Field

1. Add property to the model class
2. Add `HasColumnName("snake_case_name")` + FK/index config to `TrackMeDbContext.OnModelCreating()`
3. Run `dotnet ef migrations add Phase<N>_<Description> --project .\src\TrackMe.Api\TrackMe.Api.csproj --startup-project .\src\TrackMe.Api\TrackMe.Api.csproj`
4. Run `dotnet ef database update --project .\src\TrackMe.Api\TrackMe.Api.csproj` against the local development database
5. Commit all three generated files plus the model/DbContext changes
6. Push — production migrations apply automatically on next API startup

## Local Workflow

```powershell
# Add migration
dotnet ef migrations add <Name> --project .\src\TrackMe.Api\TrackMe.Api.csproj --startup-project .\src\TrackMe.Api\TrackMe.Api.csproj

# Apply locally
dotnet ef database update --project .\src\TrackMe.Api\TrackMe.Api.csproj
```

## Migration History (Phase 3)

`Phase3_RepeatPattern_SetWeights_EquipmentIncrements` adds:
- `workout_programs.repeat_pattern_weeks` (nullable int) — 1/2/3/4 week repeat cycle
- `workout_program_days.pattern_week_number` (nullable int) — which week-within-cycle the day belongs to
- `workout_program_exercise_sets` table — per-set planned weights for program exercises
- `workout_session_exercises.planned_set_weights_json` (varchar 4000) — JSON snapshot of per-set weights copied from program at session start
- `app_users.dumbbell_increment_kg` (numeric 5,2 default 2.0) — athlete dumbbell weight increment
- `app_users.barbell_plate_per_side_kg` (numeric 5,2 default 2.5) — athlete barbell plate increment per side

Repeat-pattern application is a data-preserving update path: it may create or update generated program days/exercises, but it must not delete workout sessions already linked to generated days.

## Migration History (Phase 4)

`Phase4_TemplateTypes_WarmupSets` adds:
- `program_templates.template_type` (int, no default) — `0` = DayTemplate, `1` = ProgramTemplate, `2` = PatternTemplate (`TemplateType` enum). No `HasDefaultValue()` — sentinel conflict with enum CLR default 0. `PatternTemplate` reuses the same column and does not need a new migration.
- `workout_program_exercises.warm_up_sets` (int, default 0) — planned warm-up sets per exercise in a program day
- `workout_session_exercises.planned_warm_up_sets` (int, default 0) — snapshot of warm-up sets taken at session start
- `workout_set_logs.is_warm_up` (bool, default false) — marks a logged set as a warm-up (excluded from compliance)
- `program_template_exercises.warm_up_sets` (int, default 0) — warm-up sets for template exercises
- `program_template_exercises.target_weight_kg` (numeric 7,3, nullable) — target weight for template exercises

Total migrations: 23.

## Rules

- **Never write migration files manually** — always use `dotnet ef migrations add`
- Do not hand-edit only the migration `.cs`, `.Designer.cs`, or snapshot; keep generated files in sync through the EF CLI
- Do not edit production database structure manually (except as emergency hotfix, documented)
- Review generated migrations before commit
- Apply migrations locally before pushing schema changes
- Do not run `dotnet ef database update` in GitHub Actions or directly on the VPS for normal deploys
- Keep destructive migrations explicit and planned
- Back up production data before schema changes

## Current Production Access

PostgreSQL is available to the API through Docker networking with:

```text
Host=postgres;Port=5432;Database=trackme;Username=trackme
```

For DBeaver, use an SSH tunnel to the VPS and connect to:

```text
Host=localhost
Port=15432
Database=trackme
Username=trackme
```

The database port is bound to `127.0.0.1` on the VPS only. It is not exposed publicly.
