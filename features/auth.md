# Authentication & Authorization

## JWT Authentication

TrackMe uses JWT Bearer tokens with HMAC-SHA256 signing (symmetric key).

### Token Configuration

| Setting | Value | Config key |
|---------|-------|-----------|
| Issuer | TrackMe | `Jwt:Issuer` |
| Audience | TrackMe.Clients | `Jwt:Audience` |
| Access token TTL | 120 minutes | `Jwt:AccessTokenMinutes` |
| Refresh token TTL | 30 days | `Jwt:RefreshTokenDays` |
| Clock skew | 1 minute | hardcoded |

### JWT Claims

| Claim | Value |
|-------|-------|
| `sub` / NameIdentifier | `user.Id` (Guid) |
| `name` | `user.FullName` |
| `email` | `user.Email` |
| `role` | `Admin` / `Trainer` / `Athlete` |
| `profile_id` | Trainer or Athlete profile GUID (null for Admin) |

## Authentication Flow

```
POST /api/auth/login → validate credentials → issue access + refresh tokens
GET  /api/xxx        → validate JWT (issuer, audience, signature, expiry)
POST /api/auth/refresh → hash lookup, revoke old token, issue new pair
POST /api/auth/logout  → set revokedAt on refresh token
```

## Refresh Token Design

- Raw token: 32 cryptographically random bytes, Base64-encoded
- Stored in DB as SHA-256 hash (plaintext never stored)
- On use: old token revoked, new pair issued (rolling rotation)
- On password change: all existing refresh tokens revoked
- Cleanup: `RefreshTokenCleanupService` periodically purges expired/revoked rows

## Password Security

- Stored using `PasswordHasher` (PBKDF2 with salt)
- Minimum 8 characters enforced at registration and reset
- Password reset: 30-minute time-limited token, single-use, stored as SHA-256 hash

## Rate Limiting

| Limiter | Limit | Applied to |
|---------|-------|-----------|
| `login` | 10 req/min/IP | `POST /api/auth/login` |
| global | 120 req/min/IP | all other endpoints |
| `notifications` | 300 req/min/IP | notification endpoints |

Exceeding the limit returns `429 Too Many Requests`.

## Role System

| Role | JWT `role` claim | Profile entity |
|------|----------------|----------------|
| Admin | `Admin` | None (`profileId = null`) |
| Trainer | `Trainer` | `trainers` row |
| Athlete | `Athlete` | `athletes` row |

Roles are fixed at registration. Only an Admin can change a role via `PUT /api/admin/users/{id}`.

## Dual-Role Users

An `Athlete` JWT account can also function as a Trainer:

- A `trainers` row with the same email is created lazily by `UserProfileSync.EnsureTrainerEntityAsync`
- `users.preferred_ui_role` stores the active context
- `/api/auth/me` reads `preferred_ui_role` from DB (not JWT) for freshness
- Frontend switches via topbar toggle → `PATCH /api/auth/preferred-role`
- JWT still says `role: Athlete`. Backend resolves trainer entity by email:

```
JWT.email = "coach@example.com"
→ db.Trainers.Where(t => t.Email == email).FirstOrDefault()
→ trainerEntity used for relationship checks, program assignments, etc.
```

## Authorization Rules

### Endpoint Check Order

1. Admin? → allow (skip remaining checks)
2. Owned by caller's `profileId`? → allow
3. Has accepted coaching relationship to target athlete? → allow
4. Otherwise → `403 Forbidden`

### Program Write Access

| Condition | Access |
|-----------|--------|
| Admin | ✅ |
| `profileId == program.TrainerId` (Trainer JWT) | ✅ |
| `profileId == program.AthleteId && program.TrainerId == null` (Athlete JWT, self-guided) | ✅ |
| Athlete JWT + trainer entity email == `program.TrainerId.Email` (dual-role) | ✅ |

### Program Deletion

- Admin: any program
- Trainer JWT: programs where `trainerId == profileId`
- Athlete JWT: self-guided programs where `athleteId == profileId && trainerId == null`
- Email fallback for dual-role: trainer entity email matches

### Session Write Access

- Admin
- `profileId == session.AthleteId`
- Trainer with accepted relationship to `session.AthleteId`
- Dual-role Athlete JWT with trainer entity in accepted relationship

### Relationship Accept/Reject

Determined by `initiated_by_athlete` flag:

| `initiated_by_athlete` | Who can respond |
|------------------------|-----------------|
| `true` | Trainer (athlete initiated → trainer responds) |
| `false` | Athlete (trainer initiated → athlete responds) |

## CORS Configuration

```json
{
  "Cors": {
    "AllowedOrigins": ["http://187.77.92.30:8080", "http://localhost:5173"]
  }
}
```

## Security Hardening

### Current MVP State
- IP-and-port based deployment (domain pending)
- PostgreSQL not publicly exposed — DBeaver uses SSH tunnel
- Secrets in server-side `.env` + GitHub Actions secrets (never in repo)
- `fail2ban` on SSH, root login disabled
- Access tokens stored in `localStorage` (acceptable for internal MVP)

### Required Before Public Production
- Attach domain and enable HTTPS
- Close legacy SSH port 22 after port 22222 is stable
- Disable SSH password login (keys only)
- Move API behind Web reverse proxy (remove public `:5050`)
- Replace `localStorage` token storage with `httpOnly` cookie or stronger strategy
- Schedule PostgreSQL backups and verify restore procedure

## Input Validation

Validated at API boundary:

- Email: valid format + unique
- Password: ≥8 characters
- RPE: 1–10 range
- Reps: non-negative
- Weight: non-negative
- Rest time: non-negative
- Workout end time: must be after start time
- Exercise name: not empty
- Visibility settings: only valid enum values

## Authorization Failure Examples

- Trainer attempts to access athlete they have no accepted relationship with → 403
- Athlete attempts to edit a trainer-assigned program → 403
- User tries to read another user's notification → 403
- Pending relationship used as if accepted → 403

## Required Environment Variables

| Key | Required | Description |
|-----|----------|-------------|
| `ConnectionStrings:Postgres` | Yes | PostgreSQL connection string |
| `Jwt:Secret` | Yes | Symmetric signing key (≥32 bytes) |
| `Jwt:Issuer` | No | Default: `TrackMe` |
| `Jwt:Audience` | No | Default: `TrackMe.Clients` |
| `Jwt:AccessTokenMinutes` | No | Default: `120` |
| `Jwt:RefreshTokenDays` | No | Default: `30` |
| `Cors:AllowedOrigins` | No | Array of allowed origins |
| `Auth:RequireVerifiedEmail` | No | Default: `false` |
| `Auth:ExposeResetTokenForDevelopment` | No | Default: `false` — dev only |
