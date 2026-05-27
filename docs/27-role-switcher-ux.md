# Role Switcher & Registration UX

## Overview

TrackMe supports two end-user roles: **Sporcu** (Athlete) and **Antrenör** (Trainer).
Admin accounts are created separately (not via the public registration UI).

---

## Registration — Role Cards

The registration form no longer shows a dropdown asking for Admin / Trainer / Athlete.
Instead, users see two large clickable cards:

```
┌──────────────────┐  ┌──────────────────┐
│   🏋️  Sporcu      │  │   👥  Antrenör    │
│  Antrenman kaydet│  │  Sporcularını    │
│  ilerlemeyi takip│  │  yönet ve programla│
└──────────────────┘  └──────────────────┘
```

- The last selected card is saved in `localStorage` key `trackme_reg_role`.
- On revisit, the previously selected role is pre-highlighted.
- No Admin option is shown in the public registration UI.

---

## Role Mode Switcher (Topbar)

After login, a compact pill toggle appears in the topbar (next to the language button):

```
[ 🏋️ Sporcu | 👥 Antrenör ]
```

- Switching changes the **UI display mode** stored in `localStorage` key `trackme_ui_role`.
- The mode persists across page refreshes and sessions.
- On first login, the mode automatically matches the user's registered role.
- On logout, the stored mode is cleared.

### What changes with the mode switch

| Feature | Sporcu mode | Antrenör mode |
|---|---|---|
| Nav: Sporcular | hidden | visible |
| Nav: Şablonlar | hidden | visible |
| Nav: Egzersizler | hidden | visible |
| Nav: Vücut ölçüleri | visible | hidden |
| API authorization | unchanged (JWT role) | unchanged (JWT role) |

> **Note:** The role switch is a **client-side UI preference only**. It does not change the
> user's JWT role or backend access rights. A Trainer in Sporcu mode can still call
> trainer-only API endpoints (e.g., analytics for their athletes). A true role change
> is not supported — users register once with a fixed role.

### On mobile (≤ 480px)

Labels are hidden, only icons are shown in the toggle to save space.

---

## Persistence Summary

| Key | Value | When set | When cleared |
|---|---|---|---|
| `trackme_reg_role` | `'Athlete'` or `'Trainer'` | On registration card click | Never (UI default) |
| `trackme_ui_role` | `'Athlete'` or `'Trainer'` | On login / mode switch | On logout |
| `trackme_auth` | JWT + user object | On login | On logout |

---

## Admin Role

Admin accounts are **not** accessible via the public registration form.
- Admins must be created by an existing admin via the admin panel.
- Admin users see the Admin nav item and cannot switch to Sporcu/Antrenör mode
  (the role toggle is hidden for Admin users).
