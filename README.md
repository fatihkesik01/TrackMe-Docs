# TrackMe — Documentation

TrackMe is a coach-athlete training management platform. Trainers manage athlete programs and track progress. Athletes log workouts, track body metrics, and follow their programs.

## Repositories

| Repo | URL |
|------|-----|
| TrackMe-Docs | https://github.com/fatihkesik01/TrackMe-Docs |
| TrackMe-Api | https://github.com/fatihkesik01/TrackMe-Api |
| TrackMe-Web | https://github.com/fatihkesik01/TrackMe-Web |
| TrackMe-Mobile | https://github.com/fatihkesik01/TrackMe-Mobile (planned) |

## Stack

| Layer | Technology |
|-------|-----------|
| Web App | React 18 + Vite |
| Backend API | ASP.NET Core 10 Minimal API |
| Database | PostgreSQL 16 |
| ORM | Entity Framework Core 10 |
| Auth | JWT + Refresh tokens |
| Icons | Lucide React |
| Charts | Recharts |
| Hosting | Hostinger VPS + Docker Compose |
| API Docs | Scalar (OpenAPI) |

## Live Endpoints

| Service | URL |
|---------|-----|
| Web App | http://187.77.92.30:8080 |
| API | http://187.77.92.30:5050 |
| Health check | http://187.77.92.30:5050/health |
| Scalar API reference | http://187.77.92.30:5050/scalar/v1 |
| OpenAPI JSON | http://187.77.92.30:5050/openapi/v1.json |
| PostgreSQL (SSH tunnel) | 127.0.0.1:15432 |

---

## Documentation Index

### System

- [Project Overview](docs/00-project-overview.md)
- [System Architecture](docs/02-system-architecture.md)
- [Backend Architecture](docs/03-backend-architecture.md)
- [Web App Architecture](docs/05-web-architecture.md)

### Data

- [Database Design](docs/06-database-design.md)
- [ERD Diagram](database/erd.md)

### API & Auth

- [API Route Reference](docs/07-api-analysis.md)
- [Authentication & Authorization](docs/10-auth-authorization.md)
- [Deployment](docs/17-deployment.md)
- [Security and Validation](docs/18-security-validation.md)

### Domain

- [Trainer-Athlete Relationship System](docs/12-trainer-athlete-relationship.md)

## Roles

| Role | Description |
|------|-------------|
| Admin | Full system access — user management, exercise library |
| Trainer | Manages athletes, creates programs, views progress |
| Athlete | Logs sessions, follows programs, tracks body metrics |

> **Dual-role users**: An account registered as Athlete can also function as a Trainer if a Trainer entity with the same email exists. The frontend `uiRole` localStorage value controls which UI is active. The backend resolves the trainer entity by email when needed.

## Core Principles

- Athlete-centric architecture: all content flows through athlete profiles
- Trainer manages athletes; athletes manage themselves
- Programs are created per athlete, built day-by-day in the builder
- Sessions log actual performed work; program days log planned work
- Analytics computed from session data; body metrics tracked separately
- JWT auth with role-based access; data ownership enforced per endpoint
