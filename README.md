# TrackMe Documentation

Single source of truth for the TrackMe platform. Each doc covers one concern completely; nothing is duplicated across files.

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

## Product

| File | What's in it |
|------|-------------|
| [product/vision.md](product/vision.md) | What TrackMe is, target users, design principles, non-goals |
| [product/roadmap.md](product/roadmap.md) | P0–P3 phases with tasks, dependencies, success criteria |
| [product/decisions.md](product/decisions.md) | Key architectural & product decisions with rationale |

---

## Architecture

| File | What's in it |
|------|-------------|
| [architecture/overview.md](architecture/overview.md) | Stack diagram, deployment, startup sequence, feature status table |
| [architecture/backend.md](architecture/backend.md) | ASP.NET Core 10 layers, DI, EF Core, SignalR, patterns |
| [architecture/web.md](architecture/web.md) | React 18 + Vite SPA structure, routing, state, components |
| [architecture/mobile.md](architecture/mobile.md) | React Native plan, navigation, offline draft, push notifications |

---

## Features

Each file is the canonical reference for that feature: data model, business rules, endpoints, and frontend.

| File | Feature |
|------|---------|
| [features/auth.md](features/auth.md) | JWT auth, refresh tokens, roles, dual-role, CORS, rate limiting |
| [features/coaching.md](features/coaching.md) | Trainer-athlete relationship lifecycle, access rules |
| [features/programs.md](features/programs.md) | Workout programs, templates, locking, published programs, versioning |
| [features/workout.md](features/workout.md) | Session lifecycle, set logging, WorkoutMode, history |
| [features/analytics.md](features/analytics.md) | RPE, volume, consistency, PRs, last performance, today widget |
| [features/social.md](features/social.md) | Social connections, follow system, profile privacy, feed |
| [features/messaging.md](features/messaging.md) | Direct messages, program references, real-time delivery |
| [features/notifications.md](features/notifications.md) | All notification types, SignalR delivery, retention rules |
| [features/media.md](features/media.md) | MediaAsset model, R2 storage, avatar/cover/program cover |
| [features/exercises.md](features/exercises.md) | Exercise library, measurement types, seeding, CRUD rules |
| [features/admin.md](features/admin.md) | Admin capabilities, user management, exercise moderation |

---

## API

| File | What's in it |
|------|-------------|
| [api/reference.md](api/reference.md) | Full endpoint list, request/response shapes |
| [api/deployment.md](api/deployment.md) | Docker Compose, VPS setup, environment variables, deploy checklist |

---

## Database

| File | What's in it |
|------|-------------|
| [database/schema.md](database/schema.md) | All tables, columns, indexes, FK relationships |
| [database/migration-strategy.md](database/migration-strategy.md) | Migration rules, CLI commands, phase-by-phase history (53 migrations) |

---

## Tasks

| File | What's in it |
|------|-------------|
| [tasks/phases.md](tasks/phases.md) | Phase sequence (0–12), current state, next phases with effort |
| [tasks/backlog.md](tasks/backlog.md) | Prioritized task list by epic and phase (P1–P3 + infra) |

---

## Quick Navigation

**I want to understand the system** → [architecture/overview.md](architecture/overview.md)

**I'm implementing a new feature** → start with the relevant [features/](features/) doc, then check [database/migration-strategy.md](database/migration-strategy.md)

**I want to know what's next** → [tasks/backlog.md](tasks/backlog.md) or [product/roadmap.md](product/roadmap.md)

**I'm deploying** → [api/deployment.md](api/deployment.md)

**I made a design decision** → add it to [product/decisions.md](product/decisions.md)

**I'm adding a migration** → follow [database/migration-strategy.md](database/migration-strategy.md), never write migration files manually
