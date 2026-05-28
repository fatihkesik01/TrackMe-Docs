# Authentication and Authorization

## JWT Authentication

TrackMe uses JWT Bearer tokens with HMAC-SHA256 signing (symmetric key).

### Token configuration

| Setting              | Value                        | Config key                   |
|----------------------|------------------------------|------------------------------|
| Issuer               | TrackMe                      | `Jwt:Issuer`                 |
| Audience             | TrackMe.Clients              | `Jwt:Audience`               |
| Access token TTL     | 120 minutes                  | `Jwt:AccessTokenMinutes`     |
| Refresh token TTL    | 30 days                      | `Jwt:RefreshTokenDays`       |
| Clock skew           | 1 minute                     | hardcoded                    |

### JWT claims

| Claim                      | Value                                   |
|----------------------------|-----------------------------------------|
| `sub` / NameIdentifier     | `user.Id` (Guid)                        |
| `name`                     | `user.FullName`                         |
| `email`                    | `user.Email`                            |
| `role`                     | `user.Role` (Admin / Trainer / Athlete) |
| `profile_id`               | Trainer or Athlete profile GUID (nullable for Admin) |

## Authentication Flow

```
Client                          API
  │                              │
  ├─ POST /api/auth/login ──────▶│ validate email + password
  │                              │ create refresh token (SHA-256 hash stored in DB)
  │◀─ { accessToken, refreshToken, user } ─┤
  │                              │
  ├─ GET /api/xxx ──────────────▶│ validate JWT: issuer, audience, signature, expiry
  │  Authorization: Bearer <AT>  │ extract claims
  │◀─ 200 ───────────────────────┤
  │                              │
  │ (access token expires)       │
  ├─ POST /api/auth/refresh ────▶│ SHA-256 hash lookup, check not revoked or expired
  │  { refreshToken: "..." }     │ revoke old token, issue new token pair
  │◀─ { new accessToken, new refreshToken } ─┤
  │                              │
  ├─ POST /api/auth/logout ─────▶│ set revokedAt on refresh token
  │  { refreshToken: "..." }     │
  │◀─ 204 ───────────────────────┤
```

## Password Security

- Stored with `PasswordHasher` (PBKDF2 with salt)
- Minimum length: 8 characters enforced at registration and reset
- Password reset: time-limited token (30 min), single-use, stored as SHA-256 hash

## Refresh Token Design

- Raw token: 32 cryptographically random bytes, Base64-encoded
- Stored value: SHA-256 hash of raw token (never stored in plaintext)
- On use: old token is revoked (`revokedAt` set), new token issued
- On password change: all existing refresh tokens revoked
- Cleanup: `RefreshTokenCleanupService` periodically deletes expired/revoked rows

## Rate Limiting

| Limiter  | Limit           | Applied to                   |
|----------|-----------------|------------------------------|
| `login`  | 10 req/min/IP   | `POST /api/auth/login`       |
| global   | 120 req/min/IP  | all other endpoints          |

Exceeding the limit returns `429 Too Many Requests`.

## Role System

| Role    | JWT `role` claim | Profile entity   |
|---------|-----------------|------------------|
| Admin   | `Admin`         | None (profileId = null) |
| Trainer | `Trainer`       | `trainers` row   |
| Athlete | `Athlete`       | `athletes` row   |

Roles are fixed at registration and can only be changed by an Admin via `PUT /api/admin/users/{id}`.

## Dual-Role User

An account registered as `Athlete` can also function as a `Trainer` if:
- A `trainers` row with the same email exists (created lazily by `UserProfileSync.EnsureTrainerEntityAsync`)
- The frontend `uiRole` is set to `'Trainer'`

The JWT still says `role: "Athlete"`. The backend resolves the trainer entity by email in any endpoint that needs to act in trainer context:

```
JWT.role = "Athlete"
JWT.profile_id = athleteProfileId
JWT.email = "coach@example.com"

→ db.Trainers.Where(t => t.Email == "coach@example.com").FirstOrDefault()
→ returns trainerEntity if it exists
→ trainerEntity.Id used for relationship checks, program assignments, etc.
```

## Authorization Rules

### Endpoint access check order

1. Is the user Admin? → allow, skip all other checks
2. Is the requested resource owned by the caller's `profileId`? → allow
3. Does the caller have an email-matched trainer entity with an accepted relationship to the target athlete? → allow
4. Otherwise → `403 Forbidden`

### Program write access

A caller can write to a program if:
- They are Admin
- Their `profileId == program.TrainerId` (pure Trainer JWT)
- They are Athlete JWT and `profileId == program.AthleteId` (own self-guided program)
- They are Athlete JWT and their trainer entity (by email) is `program.TrainerId` (dual-role acting as trainer)

### Session write access

A caller can write to a session if:
- They are Admin
- `profileId == session.AthleteId`
- Trainer with accepted relationship to `session.AthleteId`
- Dual-role Athlete JWT whose trainer entity has accepted relationship

### Relationship accept/reject

Determined by `InitiatedByAthlete` flag:

| `InitiatedByAthlete` | Who can respond |
|---------------------|-----------------|
| `true`              | Trainer (trainer invited by athlete must accept/reject) |
| `false`             | Athlete (trainer sent request; athlete decides) |

Matching is done by both `profileId` and email to support dual-role users.

## CORS Configuration

Allowed origins are configured in `appsettings.json`:

```json
{
  "Cors": {
    "AllowedOrigins": ["http://187.77.92.30:8080", "http://localhost:5173"]
  }
}
```

## Required Environment Variables / Configuration

| Key                                  | Required | Description                          |
|--------------------------------------|----------|--------------------------------------|
| `ConnectionStrings:Postgres`         | Yes      | PostgreSQL connection string         |
| `Jwt:Secret`                         | Yes      | Symmetric signing key (≥32 bytes)    |
| `Jwt:Issuer`                         | No       | Default: "TrackMe"                   |
| `Jwt:Audience`                       | No       | Default: "TrackMe.Clients"           |
| `Jwt:AccessTokenMinutes`             | No       | Default: 120                         |
| `Jwt:RefreshTokenDays`               | No       | Default: 30                          |
| `Cors:AllowedOrigins`                | No       | Array of allowed origins             |
| `Auth:RequireVerifiedEmail`          | No       | Default: false                       |
| `Auth:ExposeResetTokenForDevelopment`| No       | Default: false — set true in dev only|
