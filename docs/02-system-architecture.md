# System Architecture

## Overview

TrackMe is a three-tier web application. A React SPA communicates with an ASP.NET Core 10 REST API that persists data in PostgreSQL 16.

```
Browser
  │   React 18 + Vite SPA
  │   HTTP + JWT Bearer
  ▼
ASP.NET Core 10 Minimal API  (port 5050)
  │   EF Core 10 + Npgsql
  ▼
PostgreSQL 16                (port 5432)
```

## Deployment

Hosted on a Hostinger VPS using Docker Compose.

| Service    | Container Port | Host Port |
|------------|---------------|-----------|
| Web App    | 80            | 8080      |
| API        | 5050          | 5050      |
| PostgreSQL | 5432          | 5432      |

## Live Endpoints

| Resource        | URL                                      |
|-----------------|------------------------------------------|
| Web App         | http://187.77.92.30:8080                 |
| API             | http://187.77.92.30:5050                 |
| Health check    | http://187.77.92.30:5050/health          |
| Detailed health | http://187.77.92.30:5050/api/health      |
| Scalar API docs | http://187.77.92.30:5050/scalar/v1       |
| OpenAPI JSON    | http://187.77.92.30:5050/openapi/v1.json |

## API Startup Sequence

On startup the API:

1. Runs `db.Database.MigrateAsync()` — applies all pending EF Core migrations automatically
2. Runs `ExerciseSeeder.SeedAsync(db)` — seeds the global exercise library if the table is empty
3. Starts `RefreshTokenCleanupService` (background hosted service) — periodically purges expired refresh tokens

## Security

| Concern          | Implementation                                           |
|------------------|----------------------------------------------------------|
| Authentication   | JWT Bearer (HMAC-SHA256, symmetric key)                  |
| Access token TTL | 120 minutes (configurable: `Jwt:AccessTokenMinutes`)     |
| Refresh token    | 30-day rolling token, stored as SHA-256 hash in DB       |
| Password hashing | PBKDF2-based `PasswordHasher` service                    |
| Rate limiting    | Login: 10 req/min per IP; Global: 120 req/min per IP     |
| CORS             | Configurable via `Cors:AllowedOrigins` in appsettings    |

## Data Ownership Model (Athlete-Centric)

All content flows through athlete profiles:

- Programs belong to an athlete (`AthleteId` FK required, `TrainerId` FK optional)
- Sessions belong to an athlete
- Body metrics belong to an athlete
- A trainer accesses athlete data only through an accepted `TrainerAthleteRelationship` record

## Dual-Role User

A single registered account can operate as both Trainer and Athlete. The JWT role is fixed at registration. The frontend switches display context via `uiRole` (`trackme_ui_role` in localStorage). The backend resolves a trainer entity for any user via email lookup — trainer and athlete profile entities are created lazily when needed.

## Frontend State Management

All application state is held in the `AppInner` component (no external state library). On login, nine parallel API calls populate global arrays passed as props to views. State is refreshed after every mutation via `loadData()`.

| State variable        | Source                                 |
|-----------------------|----------------------------------------|
| `currentUser`         | `GET /api/auth/me`                     |
| `dashboard`           | `GET /api/dashboard`                   |
| `athletes`            | `GET /api/athletes`                    |
| `trainerAthletes`     | `GET /api/trainers/me/athletes`        |
| `programs`            | `GET /api/programs`                    |
| `sessions`            | `GET /api/sessions`                    |
| `relationships`       | `GET /api/relationships/requests`      |
| `exercises`           | `GET /api/exercises`                   |
| `notifications`       | `GET /api/notifications`               |

## Middleware Pipeline (in order)

1. Exception handler — returns JSON `{ message, traceId }` on unhandled errors
2. CORS
3. Response caching
4. Request timing logger
5. Authentication (JWT Bearer)
6. Authorization
7. Rate limiter

## Background Services

| Service                    | Purpose                                |
|----------------------------|----------------------------------------|
| RefreshTokenCleanupService | Deletes expired/revoked refresh tokens |
