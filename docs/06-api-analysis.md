# API Analysis

The API should be designed around role-based access, ownership validation, and predictable resource boundaries.

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
