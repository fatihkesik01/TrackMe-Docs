# Admin System

## Overview

The admin system provides platform management, quality control, and operational oversight. All admin endpoints require `role: Admin` in the JWT. Admin actions bypass ownership checks — admins can operate on any user, program, exercise, or notification.

---

## Admin Capabilities

| Area | Operations |
|------|-----------|
| Users | Search, view detail, activate/deactivate, change role |
| Trainers | List, view athlete roster |
| Athletes | List, view programs and sessions |
| Exercises | Create, update, soft-delete, review duplicate candidates |
| Notifications | Send platform-wide or targeted notifications |
| Programs | View, delete any program |
| Reports | View system logs, relationship reports |

---

## User Management

### `GET /api/admin/users`

Query params: `q` (search by name/email), `role`, `isActive`, `page`, `pageSize`.

Returns paginated list with: `id`, `email`, `fullName`, `role`, `isActive`, `createdAt`, `lastLoginAt`.

### `GET /api/admin/users/{id}`

Full user detail including: trainer entity (if any), athlete entity (if any), notification count, session count.

### `PUT /api/admin/users/{id}`

Update user fields:
```json
{
  "isActive": true,
  "role": "Trainer"
}
```

Role changes take effect on the user's next login (JWT is not revoked, but the role in new tokens will reflect the change). When role changes, a new trainer or athlete profile entity is created lazily as needed.

### Deactivation

Setting `isActive = false` effectively bans the user. Their JWT tokens remain valid until expiry, but their account is flagged. (Future: revoke all refresh tokens on deactivation.)

---

## Exercise Management

`GET /api/admin/exercises/duplicates` — list exercises with normalized names within Levenshtein distance threshold of each other.

Admins can:
- Set `is_active = false` to hide an exercise from the active library
- Merge duplicates manually (via edit)
- Review trainer-submitted exercises before they appear globally (planned)

---

## Notifications

`POST /api/admin/notifications/broadcast` — send a notification to all users or a filtered subset.

```json
{
  "targetRole": "Athlete",
  "title": "System maintenance at 02:00 UTC",
  "body": "TrackMe will be down for 30 minutes for scheduled maintenance.",
  "type": "SystemBroadcast"
}
```

---

## Admin Guardrails

- All admin operations are logged (planned: structured audit log table).
- Hard delete is avoided for business records — use soft-delete (`is_active = false`) or status changes.
- Dangerous operations (role change, mass notification) should require frontend confirmation dialog.
- Admin endpoints are covered by the global rate limiter (120 req/min/IP).

---

## Frontend

### AdminView (`AdminView.jsx`)

Accessible only when `user.role === 'Admin'`. Shows in topbar nav.

**Tabs:**
- **Kullanıcılar** — paginated user table with search and role filter. Click user → detail modal with account info, trainer/athlete entity status, recent activity.
- **Egzersizler** — exercise management table. Edit inline. "Duplikatleri İncele" button opens duplicate review modal.
- **Raporlar** — planned (log viewer, relationship/abuse reports)

**User Detail Modal:**
- Edit role dropdown
- Active/deactivate toggle
- View trainer entity (if any): athlete count, accepted relationships
- View athlete entity (if any): program count, session count

### Admin Stats in Dashboard

The Admin user's Dashboard shows platform-level stats:
- Total users
- Active coaching relationships
- Sessions this week
- Published programs
