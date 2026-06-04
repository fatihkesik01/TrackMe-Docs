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
dotnet ef migrations add Phase<N>_<Description> --project .\src\TrackMe.Api\TrackMe.Api.csproj
```

This generates three files correctly:
| File | Purpose |
|------|---------|
| `Migrations/<timestamp>_<Name>.cs` | Up/Down SQL with correct table/column names |
| `Migrations/<timestamp>_<Name>.Designer.cs` | EF Core metadata for this migration point |
| `Migrations/TrackMeDbContextModelSnapshot.cs` | Updated compiled model snapshot |

**All three files must be committed together.**

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
3. Run `dotnet ef migrations add Phase<N>_<Description> --project .\src\TrackMe.Api\TrackMe.Api.csproj`
4. Run `dotnet ef database update --project .\src\TrackMe.Api\TrackMe.Api.csproj` against the local development database
5. Commit all three generated files plus the model/DbContext changes
6. Push — production migrations apply automatically on next API startup

## Local Workflow

```powershell
# Add migration
dotnet ef migrations add <Name> --project .\src\TrackMe.Api\TrackMe.Api.csproj

# Apply locally
dotnet ef database update --project .\src\TrackMe.Api\TrackMe.Api.csproj
```

## Rules

- **Never write migration files manually** — always use `dotnet ef migrations add`
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
