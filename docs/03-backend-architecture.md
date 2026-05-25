# Backend Architecture

The backend is an ASP.NET Core 10 Web API responsible for authentication, authorization, workout management, trainer-athlete relationships, notifications, analytics, validation, and logging.

Repository: `TrackMe-api`

Current implementation starts as a single deployable API project and should evolve toward the layered structure below as modules grow.

## Recommended Project Structure

```text
src/
  TrackMe.Api/
    Controllers/
    Middleware/
    Filters/
    Program.cs
  TrackMe.Application/
    Auth/
    Users/
    Trainers/
    Athletes/
    Relationships/
    Exercises/
    WorkoutPrograms/
    WorkoutTracking/
    Rpe/
    Notifications/
    Analytics/
    Admin/
  TrackMe.Domain/
    Entities/
    Enums/
    ValueObjects/
    Rules/
    Events/
  TrackMe.Infrastructure/
    Persistence/
    Notifications/
    Security/
    Logging/
  TrackMe.Contracts/
    Requests/
    Responses/
```

## API Layer

Responsibilities:

- Accept HTTP requests
- Validate authentication
- Apply role policies
- Bind request models
- Return consistent response envelopes
- Avoid business logic

## Application Layer

Responsibilities:

- Implement use cases
- Coordinate domain logic
- Validate business workflows
- Check ownership and relationship rules
- Publish domain events
- Build response DTOs

## Domain Layer

Responsibilities:

- Core entities
- Enums
- Business invariants
- Domain events
- Value objects

## Infrastructure Layer

Responsibilities:

- PostgreSQL persistence
- Entity Framework Core 10 configuration
- Code-first migrations as the source of database schema changes
- Firebase Cloud Messaging integration
- JWT and password hashing services
- Logging providers
- Background jobs

## Backend Design Rules

- Controllers should stay thin.
- All write operations should validate ownership.
- All list endpoints should be paginated.
- All IDs should use UUID.
- All timestamps should be stored in UTC.
- Soft delete should be used for important business records.
- Audit fields should exist on core tables.
- Exercise names and slugs must be unique.
- Database tables should be changed through EF Core migrations, not hand-written deployment SQL.

## Suggested Middleware

- Global exception middleware
- Request logging middleware
- Correlation ID middleware
- Authentication and authorization middleware
- Rate limiting middleware

## Response Envelope

```json
{
  "success": true,
  "data": {},
  "errors": [],
  "traceId": "request-correlation-id"
}
```

## Error Strategy

- 400: validation error
- 401: unauthenticated
- 403: unauthorized role or ownership failure
- 404: resource not found
- 409: duplicate or conflicting state
- 500: unexpected server error
