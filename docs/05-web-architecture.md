# Web App Architecture

Repository: `TrackMe-Web`

React 18 + Vite SPA. Single-page application with hash-based routing, no router library.

## Actual Project Structure

```text
TrackMe-Web/
  src/
    services/
      api.js              — all API calls + auth token management
      realtime.js         — SignalR notification hub connection
    components/
      Modal.jsx
      ConfirmDialog.jsx    — global promise-based confirmation dialog provider built on Modal
      Toast.jsx
      RpeTrendChart.jsx
      VolumeTrendChart.jsx
      ConsistencyGrid.jsx  — thin wrapper, delegates to WorkoutCalendar
      WorkoutCalendar.jsx  — monthly grid calendar with session dot indicators
      DatePicker.jsx       — custom date picker: react-day-picker@8 + portal rendering (createPortal + position:fixed)
    views/
      DashboardView.jsx
      AthletesView.jsx
      AthleteDetailView.jsx   — tabs: Overview | Programs | Sessions | Progress
      ProgramsView.jsx
      ProgramBuilderView.jsx
      SessionsView.jsx
      WorkoutMode.jsx         — full-screen workout overlay
      ExercisesView.jsx
      RelationshipsView.jsx
      BodyMetricsView.jsx
      NotificationsView.jsx
      ProfileView.jsx
      AdminView.jsx
    App.jsx                   — AppInner: all state, nav, handlers, view routing
    LanguageContext.jsx       — React context: lang, toggleLang, t()
    i18n.js                   — TR/EN translation strings
    main.jsx
  public/
  index.html
```

## Navigation Structure

Navigation is driven by three arrays in `App.jsx`:

### TRAINER_NAV
| id            | View               |
|---------------|--------------------|
| dashboard     | DashboardView      |
| athletes      | AthletesView / AthleteDetailView |
| myPrograms    | ProgramsView + ProgramBuilderView |
| exercises     | ExercisesView      |
| relationships | RelationshipsView  |
| notifications | NotificationsView  |
| profile       | ProfileView        |

### ATHLETE_NAV
| id            | View               |
|---------------|--------------------|
| dashboard     | DashboardView      |
| myProgram     | ProgramsView + ProgramBuilderView |
| sessions      | SessionsView       |
| bodyMetrics   | BodyMetricsView    |
| relationships | RelationshipsView  |
| notifications | NotificationsView  |
| profile       | ProfileView        |

### ADMIN_NAV
| id        | View           |
|-----------|----------------|
| dashboard | DashboardView  |
| athletes  | AthletesView   |
| sessions  | SessionsView   |
| exercises | ExercisesView  |
| profile   | ProfileView    |
| admin     | AdminView      |

## Routing

- No router library — `window.location.hash` maps to `view` state variable
- `VALID_VIEWS` set validates hash values on page load and hash change events
- `navigate(id)` — sets `view`, updates hash, resets builder/athlete state

## State Management

All state lives in `AppInner`. No Redux or Zustand.

### Key state variables

| Variable                  | Type      | Purpose                                        |
|---------------------------|-----------|------------------------------------------------|
| `currentUser`             | object    | Authenticated user from `/api/auth/me`         |
| `uiRole`                  | string    | Display mode: 'Athlete' or 'Trainer'           |
| `view`                    | string    | Current active view                            |
| `selectedAthlete`         | object?   | When set, shows AthleteDetailView              |
| `programBuilderProgramId` | guid?     | When set, shows ProgramBuilderView             |
| `programBuilderReadOnly`  | bool      | View-only mode for program builder             |
| `activeWorkoutSession`    | object?   | When set, WorkoutMode overlay is shown         |
| `athletes`                | array     | All athletes (role-scoped by API)              |
| `trainerAthletes`         | array     | Trainer's accepted athletes                    |
| `programs`                | array     | All programs for current user                  |
| `sessions`                | array     | All sessions for current user                  |
| `relationships`           | array     | All relationships for current user             |
| `notifications`           | array     | In-app notifications                           |

### Derived values

| Variable                   | Derived from                                   |
|----------------------------|------------------------------------------------|
| `isTrainerUiMode`          | `uiRole === 'Trainer'`                         |
| `trainerProfileId`         | `currentUser.role === 'Trainer' ? currentUser.profileId : null` |
| `athleteProfileId`         | `currentUser.role === 'Athlete' ? currentUser.profileId : null` |
| `athleteOptions`           | `trainerAthletes` if trainer mode, else `athletes` |
| `navItems`                 | TRAINER_NAV / ATHLETE_NAV / ADMIN_NAV          |

## Auth Flow

1. `api.getAuth()` reads `trackme_auth` from localStorage
2. On app boot, `api.me()` validates the stored token
3. On login/register, `api.setAuth(auth)` stores the full auth response
4. All `api.*` calls include `Authorization: Bearer <token>` header
5. On 401, token is cleared and user is redirected to login
6. `uiRole` is sourced from `currentUser.preferredUiRole` returned by `/api/auth/me`
7. If `preferredUiRole` is null after login/register, onboarding role-selection screen is shown
8. Role selection saves to backend via `PATCH /api/auth/preferred-role` and caches in localStorage
9. Changing role from topbar uses the shared `ConfirmDialog`, then calls backend + `loadData()`

## LocalStorage Keys

| Key                | Value                                                  |
|--------------------|--------------------------------------------------------|
| `trackme_auth`     | JSON: `{ accessToken, refreshToken, user, ... }`       |
| `trackme_ui_role`  | `'Athlete'` or `'Trainer'`                             |
| `trackme_dark`     | `'true'` or `'false'`                                  |

## Screen States

| State                               | What renders                          |
|-------------------------------------|---------------------------------------|
| `booting === true`                  | Loading splash screen                 |
| `currentUser === null`              | Auth form (login/register)            |
| `showOnboarding === true`           | Role selection card                   |
| Normal                              | Full app shell with sidebar           |
| `activeWorkoutSession !== null`     | WorkoutMode overlay (full screen)     |

## Internationalization

- `LanguageContext.jsx` provides `lang` ('tr' / 'en'), `toggleLang`, and `t(key)` to all components
- `i18n.js` exports `{ tr: {...}, en: {...} }` translation maps
- Language is persisted in localStorage via `LanguageContext`

## API Service (`api.js`)

- `request(path, options)` — base fetch wrapper, injects Bearer token, throws on non-2xx
- `list(promise)` — unwraps `PagedResult<T>` envelope `{ data, page, pageSize, total }` → array
- All entity methods use `list()` for paginated list endpoints
- `api.setAuth(auth)` / `api.getAuth()` / `api.clearAuth()` — localStorage token management

## Realtime Notifications

- `realtime.js` creates the SignalR connection to `/hubs/notifications`
- The connection uses the stored JWT access token via `accessTokenFactory`
- The Web app listens for `notification.created`
- Incoming notifications are added to `notifications` state and surfaced with a toast
- `/api/notifications` remains the recovery path on boot/reconnect or manual refresh
- The topbar dropdown hides read notifications after `currentUser.readNotificationRetentionDays` days; unread notifications are always shown.
- `NotificationsView` is available to Trainer and Athlete navigation and shows the full loaded notification list without applying the topbar retention filter.
- `NotificationsView` includes a full-width client-side search across localized notification title/body, sender metadata, type label, and original stored title/body. This supports searching by trainer, athlete, program, or notification text when that data exists in the notification.
- Notification rows display sender metadata (`senderName`/`senderRole`) when present and infer it for older known message patterns when possible.
- The profile screen lets users set `readNotificationRetentionDays` (default 3).

## Component Responsibilities

| Component            | Responsibility                                                                 |
|----------------------|--------------------------------------------------------------------------------|
| `DashboardView`      | Stats cards for trainer or athlete based on `uiRole`                           |
| `AthletesView`       | Athlete list, create athlete, navigate to AthleteDetailView                    |
| `AthleteDetailView`  | Tabs: Overview, Programs, Sessions, Progress for one athlete                   |
| `ProgramsView`       | Full-width program row list, create program (w/ duration selector), open builder/viewer |
| `ProgramBuilderView` | Day + exercise editor (read/write); includes `ProgramCalendar` full-width below the layout showing program days (teal dots) and completed sessions (green dots); clicking a date opens the add-day form pre-filled; `LastPerfBanner` per exercise row shows per-set actual vs planned |
| `WorkoutMode`        | Full-screen workout overlay; prev/next nav and dots inside the exercise card   |
| `SessionsView`       | Session history (list or calendar view toggle), manual session log form        |
| `BodyMetricsView`    | 9-field measurement form, weight/fat/muscle trend charts                       |
| `NotificationsView`  | Full notification history; mark-one and mark-all-read actions                  |
| `RelationshipsView`  | Send requests, accept/reject pending, search users                             |
| `ExercisesView`      | Exercise library, category/equipment/difficulty filters, create/delete         |
| `AdminView`          | User management, exercise audit (Admin role only)                              |
| `ProfileView`        | Update name, bio, goal, age, profession, sports list, training years, notification dropdown retention |
| `WorkoutCalendar`    | Monthly calendar via `react-calendar` library; dark theme CSS override; session dot indicators via `tileContent`; green = completed, yellow = in-progress |
| `ConsistencyGrid`    | Wrapper: shows aggregate stats (streak, 7d, 30d) + WorkoutCalendar            |
| `ConfirmDialog`      | Shared confirmation modal used for destructive or state-changing actions instead of browser-native confirms |

## Program List Layout

Programs are displayed as full-width row cards (`program-row-card`) in both `ProgramsView` and `AthleteDetailView`. Each row shows: title, athlete/trainer badges, date range, and action buttons aligned to the right.

## Program Creation — Duration Selector

Both `ProgramsView` and `AthleteDetailView` include a duration selector:

| Selection  | Count input | Behaviour                                                        |
|------------|-------------|------------------------------------------------------------------|
| Haftalık   | "Kaç hafta?" (default 1) | `endsOn` = `startsOn` + count×7 days         |
| Aylık      | "Kaç ay?" (default 1)    | `endsOn` = `startsOn` + count×30 days        |
| Özel Tarih | —           | User picks both start and end dates manually                     |

Default: `startsOn` = today, `duration` = Haftalık, `count` = 1.

## Program Edit Permissions (Frontend)

`canEditCard` in `ProgramsView`:
```js
const canEditCard = canEditAsTrainer || (isActingAsAthlete && !p.trainerId);
```
Athletes only see the edit (pencil) button for programs without a trainer (`trainerId == null`). Trainer-created programs show a view-only (eye) button for athletes.
