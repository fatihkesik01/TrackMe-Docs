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
| API authorization | unchanged (JWT role) | unchanged (JWT role) |

> **Note:** The role switch is a **client-side UI preference only**. It does not change the
> user's JWT role or backend access rights. A true role change is not supported — users
> register once with a fixed backend role.

### On mobile (≤ 480px)

Labels are hidden, only icons are shown in the toggle to save space.

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
