# EF Core Migration Strategy

TrackMe uses PostgreSQL, but the application schema is managed from the `TrackMe-api` repository with Entity Framework Core migrations.

## Source Of Truth

- Entity classes and `TrackMeDbContext` configuration define the model.
- EF Core migration files define schema history.
- Hand-written SQL schema files are not used as the source of truth.

## Local Workflow

```powershell
dotnet ef migrations add InitialCreate --project .\src\TrackMe.Api\TrackMe.Api.csproj
dotnet ef database update --project .\src\TrackMe.Api\TrackMe.Api.csproj
```

## Deployment Workflow

- Build API and web containers.
- Start PostgreSQL with persistent volume.
- Apply reviewed EF Core migrations as a controlled release step.
- Start or restart API and web containers.

## Rules

- Do not edit production database structure manually.
- Review generated migrations before commit.
- Keep destructive migrations explicit and planned.
- Back up production data before schema changes.
