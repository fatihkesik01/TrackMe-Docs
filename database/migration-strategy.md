# EF Core Migration Strategy

TrackMe uses PostgreSQL, but the application schema is managed from the `TrackMe-Api` repository with Entity Framework Core migrations.

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

- GitHub Actions SSHs into the VPS as `deploy`.
- The API repository is updated under `/opt/trackme/TrackMe-Api`.
- PostgreSQL is started with the persistent Docker volume.
- The workflow runs `dotnet restore` and `dotnet ef database update` in a .NET 10 SDK container on the `trackme-network` Docker network.
- The API container is rebuilt and restarted after migrations complete.

## Rules

- Do not edit production database structure manually.
- Review generated migrations before commit.
- Keep destructive migrations explicit and planned.
- Back up production data before schema changes.

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
