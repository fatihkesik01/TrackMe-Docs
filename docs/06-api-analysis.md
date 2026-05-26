# API Analysis

The API should be designed around role-based access, ownership validation, and predictable resource boundaries.

## Current MVP API

The deployed MVP API is an ASP.NET Core 10 minimal API with EF Core 10 and PostgreSQL.

Runtime URLs:

- API base URL: `http://187.77.92.30:5050`
- Health: `GET /health`
- Scalar API reference: `GET /scalar/v1`
- OpenAPI JSON: `GET /openapi/v1.json`

Currently implemented resource endpoints:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/auth/me`
- `GET /api/dashboard`
- `GET /api/trainers`
- `GET /api/trainers/me/athletes`
- `POST /api/trainers`
- `GET /api/athletes`
- `POST /api/athletes`
- `POST /api/relationships/requests`
- `GET /api/relationships/requests`
- `POST /api/relationships/{id}/accept`
- `POST /api/relationships/{id}/reject`
- `GET /api/programs`
- `POST /api/programs`
- `GET /api/sessions`
- `POST /api/sessions`

The sections below describe the target API shape for the full product.

## Current MVP Authentication

Authentication uses JWT bearer tokens.

Implemented fields:

- User id
- Profile id for trainer and athlete users
- Full name
- Email
- Role: `Admin`, `Trainer`, or `Athlete`
- Password hash
- Active status

Password hashes use PBKDF2-SHA256. Refresh-token storage exists in the database model, but refresh token rotation is not active yet.

`GET /api/auth/me` is protected and validates the JWT.

Trainer and athlete registrations automatically create a matching MVP profile row in `trainers` or `athletes`. MVP dashboard, trainer, athlete, program, and session endpoints currently require a valid JWT.

Programs can be trainer-led or self-guided. Self-guided programs use `trainerId: null` and still require an `athleteId`.

Program list responses include `athleteId` and `trainerId` so clients can connect sessions to the correct program.

Relationship requests are JWT protected. Trainers create requests from their trainer `profileId`; athletes accept or reject requests from their athlete `profileId`.

Current relationship behavior:

- `POST /api/relationships/requests` requires a trainer role and creates a pending request.
- `GET /api/relationships/requests` returns scoped relationship rows for trainer, athlete, or admin users.
- `POST /api/relationships/{id}/accept` requires the matching athlete profile.
- `POST /api/relationships/{id}/reject` requires the matching athlete profile.
- `GET /api/trainers/me/athletes` returns accepted athletes for the current trainer.
- Duplicate trainer-athlete relationship rows are blocked.

## API Design Principles

- REST-style endpoints
- JSON request and response bodies
- JWT authentication
- Role-based authorization
- Ownership validation in application services
- Pagination for list endpoints
- Filtering for analytics endpoints
- Consistent error envelope

## Main API Groups

- Auth
- Users
- Trainers
- Athletes
- Relationships
- Exercises
- Workout Programs
- Workout Tracking
- RPE
- Analytics
- Notifications
- Admin

## Endpoint Summary

### Auth

- POST /api/auth/register
- POST /api/auth/login
- POST /api/auth/refresh
- POST /api/auth/logout
- GET /api/auth/me

### Users

- GET /api/users/me
- PATCH /api/users/me
- PATCH /api/users/me/password

### Trainers

- GET /api/trainers/me/athletes
- GET /api/trainers/me/programs
- GET /api/trainers/me/notifications

### Athletes

- GET /api/athletes/me/profile
- PUT /api/athletes/me/profile
- GET /api/athletes/me/programs
- GET /api/athletes/me/workouts

### Relationships

- POST /api/relationships/requests
- GET /api/relationships/requests
- POST /api/relationships/{id}/accept
- POST /api/relationships/{id}/reject
- DELETE /api/relationships/{id}

### Exercises

- GET /api/exercises
- GET /api/exercises/{id}
- POST /api/exercises
- PUT /api/exercises/{id}
- DELETE /api/exercises/{id}

### Workout Programs

- POST /api/workout-programs
- GET /api/workout-programs/{id}
- PUT /api/workout-programs/{id}
- POST /api/workout-programs/{id}/assignments
- DELETE /api/workout-programs/{id}/assignments/{athleteId}

### Workout Tracking

- POST /api/workout-sessions
- GET /api/workout-sessions/{id}
- PATCH /api/workout-sessions/{id}
- POST /api/workout-sessions/{id}/complete
- POST /api/workout-sessions/{id}/exercises
- POST /api/workout-session-exercises/{id}/sets
- PATCH /api/workout-set-logs/{id}
- DELETE /api/workout-set-logs/{id}

### Analytics

- GET /api/analytics/athletes/{athleteId}/overview
- GET /api/analytics/athletes/{athleteId}/strength
- GET /api/analytics/athletes/{athleteId}/volume
- GET /api/analytics/athletes/{athleteId}/rpe
- GET /api/analytics/athletes/{athleteId}/consistency

### Notifications

- GET /api/notifications
- POST /api/notifications/{id}/read
- POST /api/notifications/read-all

## Authorization Matrix

| Resource | Admin | Trainer | Athlete |
| --- | --- | --- | --- |
| Users | Full | Own user only | Own user only |
| Exercise library | Full | Read, suggest optional | Read |
| Athlete profile | Full | Related athletes | Own profile |
| Workout program | Full | Own programs | Assigned programs |
| Workout session | Full | Related athletes | Own sessions |
| Analytics | Full | Related athletes | Own analytics |
| Notifications | Full audit | Own notifications | Own notifications |
