# Role Switcher & Registration UX

## Overview

TrackMe supports two end-user roles: **Sporcu** (Athlete) and **Antrenör** (Trainer).
Admin accounts are created separately (not via the public registration UI).

---

## Registration

The registration form collects only:
- Full name
- Email
- Password

No role selection during registration. All public-facing accounts default to `Athlete` at
the backend level. Trainers are provisioned by an admin via the admin panel.

> The UX display mode (Sporcu / Antrenör) is chosen separately via the **onboarding screen**
> that appears after first login — it is independent of the JWT role.

---

## Post-Login Onboarding Screen

After the very first login (or any login where `trackme_ui_role` has not yet been saved),
users see a full-screen welcome card with two choices:

```
┌──────────────────────────────────────────────────────┐
│                 Hoş geldin!                          │
│   Uygulamayı nasıl kullanmak istiyorsun?             │
│                                                      │
│  ┌───────────────┐   ┌───────────────┐              │
│  │  🏋️  Sporcu   │   │  👥 Antrenör   │              │
│  │ Antrenman     │   │ Sporcularını  │              │
│  │ kaydet…       │   │ yönet…        │              │
│  └───────────────┘   └───────────────┘              │
│                                                      │
│    Üst çubuktan istediğin zaman değiştirebilirsin.  │
└──────────────────────────────────────────────────────┘
```

- Clicking a card saves `trackme_ui_role` to localStorage and enters the main app.
- This screen is **not** shown on subsequent logins — the saved value is used directly.
- The selection **persists across logout/login** (not cleared on logout).

---

## Role Mode Switcher (Topbar)

After login, a compact pill toggle appears in the topbar (next to the language button):

```
[ 🏋️ Sporcu | 👥 Antrenör ]
```

- Switching changes the **UI display mode** stored in `localStorage` key `trackme_ui_role`.
- The mode persists across page refreshes and logout/login cycles.

### What changes with the mode switch

| Feature | Sporcu mode | Antrenör mode |
|---|---|---|
| Nav: Sporcular | hidden | visible |
| Nav: Şablonlar | hidden | visible |
| Nav: Egzersizler | hidden | visible |
| Nav: Vücut ölçüleri | visible | hidden |
| Athlete dropdown in Programs | locked to own profile | shows accepted athletes |
| Athlete dropdown in Sessions | locked to own profile | shows accepted athletes |
| Program delete / builder buttons | hidden | visible |
| Athlete row shortcuts | — | Programs + Sessions quick-nav icons |

---

## Dual-Role Backend Behavior

When an Athlete-JWT user switches to Trainer uiMode, certain API endpoints perform
**email-based trainer entity resolution** — the backend looks for a `Trainer` row whose
`Email` matches the caller's JWT email claim.

This enables Athlete-JWT users to act as trainers without re-issuing a new JWT:

| Endpoint | Dual-role behavior |
|---|---|
| `GET /api/trainers/me/athletes` | Resolves trainer by email for any JWT role |
| `GET /api/programs` | Also returns programs where caller's trainer entity is assigned |
| `POST /api/programs` | Auto-resolves / lazily creates trainer entity; validates accepted relationship |
| `DELETE /api/programs/{id}` | Email fallback: allows deletion if trainer entity email matches |

The trainer entity is lazily created on the first program creation if it does not yet exist.

> **Note:** JWT role and `profileId` claim are unchanged by the mode switch. The backend
> does not know about `uiRole` — it derives dual-role intent purely from context (e.g.,
> creating a program for an athlete other than yourself).

### Frontend computed values (App.jsx)

| Variable | Formula | Purpose |
|---|---|---|
| `trainerProfileId` | `role === 'Trainer' ? profileId : null` | Non-null only for Trainer-JWT |
| `athleteProfileId` | `role === 'Athlete' ? profileId : null` | Non-null only for Athlete-JWT |
| `isTrainerUiMode` | `uiRole === 'Trainer'` | Drives trainer-specific UI |
| `isActingAsAthlete` | `uiRole !== 'Trainer' && Boolean(athleteProfileId)` | Locks athlete fields |
| `athleteOptions` | `(trainerProfileId \|\| isTrainerUiMode) ? trainerAthletes : athletes` | Dropdown source |

In Trainer uiMode when the JWT role is Athlete (`trainerProfileId == null`), the frontend
looks up the caller's trainer entity from the `trainers` list by email to obtain the correct
`trainerId` for program creation.

---

## Persistence Summary

| Key | Value | When set | When cleared |
|---|---|---|---|
| `trackme_ui_role` | `'Athlete'` or `'Trainer'` | On onboarding / mode switch | **Never** (persists across logout) |
| `trackme_auth` | JWT + user object | On login | On logout |

---

## Admin Role

Admin accounts are **not** accessible via the public registration form.
- Admins must be created by an existing admin via the admin panel.
- Admin users see the Admin nav item and cannot switch to Sporcu/Antrenör mode
  (the role toggle is hidden for Admin users).
- Admins skip the onboarding screen entirely.
