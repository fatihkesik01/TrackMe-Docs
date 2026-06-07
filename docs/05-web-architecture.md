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
      MessagesView.jsx
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
| messages      | MessagesView       |
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
| messages      | MessagesView       |
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
| `unreadMessageCount`      | number    | Unread direct message badge count              |
| `realtimeMessage`         | object?   | Latest SignalR direct message payload          |

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
7. If `preferredUiRole` is null after login/register, onboarding asks for the initial UI role plus weight/height unit preferences
8. Role selection saves to backend via `PATCH /api/auth/preferred-role`; unit preferences save via `PATCH /api/auth/profile`; role is also cached in localStorage
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
| `showOnboarding === true`           | Role selection plus measurement-unit setup card |
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
- The Web app listens for `message.created`
- Incoming notifications are added to `notifications` state and surfaced with a toast
- `NewMessage` notifications increment the Messages badge and notification clicks route to `MessagesView`.
- `message.created` carries the direct message DTO. `MessagesView` appends it to the active thread when open, updates the conversation row, marks the active thread read, and refreshes the unread badge.
- `/api/notifications` remains the recovery path on boot/reconnect or manual refresh
- The topbar dropdown hides read notifications after `currentUser.readNotificationRetentionDays` days; unread notifications are always shown.
- `NotificationsView` is available to Trainer and Athlete navigation and shows the full loaded notification list without applying the topbar retention filter.
- `NotificationsView` includes a full-width client-side search across localized notification title/body, sender metadata, type label, and original stored title/body. This supports searching by trainer, athlete, program, or notification text when that data exists in the notification.
- Notification rows display sender metadata (`senderName`/`senderRole`) when present and infer it for older known message patterns when possible.
- The profile screen separates account/profile editing from General Settings. General Settings manages `readNotificationRetentionDays` (default 3), `weightUnit` (`kg`/`lbs`), and `heightUnit` (`cm`/`ft-in`) in a dedicated modal.
- API values remain canonical (`weightKg`, `heightCm`); Web views convert values for display and convert user input back before saving.

## Direct Messages

- Trainer and Athlete navigation includes `messages`.
- `MessagesView` loads existing conversations from `/api/messages` and accepted relationship contacts from `/api/messages/contacts`, so a conversation can be started even before the first message exists.
- Message threads load through `/api/messages/{userId}` and mark that thread read through `/api/messages/{userId}/read`.
- Program and exercise references for the selected contact load through `/api/messages/{userId}/references`.
- The composer can attach one structured reference to a program or program-day exercise, then send it with `/api/messages`.
- Message bubbles render attached references as compact cards with type, label, and detail text.
- Sending a message posts to `/api/messages`, creates a `NewMessage` notification, and the recipient sees a realtime toast/badge through SignalR.

## Component Responsibilities

| Component            | Responsibility                                                                 |
|----------------------|--------------------------------------------------------------------------------|
| `DashboardView`      | Stats cards for trainer or athlete based on `uiRole`                           |
| `AthletesView`       | Athlete list, create athlete, navigate to AthleteDetailView                    |
| `AthleteDetailView`  | Tabs: Overview, Programs, Sessions, Progress for one athlete                   |
| `ProgramsView`       | Full-width program row list, create program (w/ duration selector), open builder/viewer |
| `ProgramBuilderView` | Day + exercise editor (read/write); has a dedicated preparation tools panel for day/program/pattern templates and repeat-pattern apply/propagation; per-exercise quick buttons for +weight/+reps/+sets; optional per-set planned weights; `LastPerfBanner` per exercise row shows per-set actual vs planned |
| `WorkoutMode`        | Full-screen workout overlay; prev/next nav and dots inside the exercise card; set logging uses planned per-set weights, warm-up rows, set notes, and athlete equipment increments for +weight |
| `SessionsView`       | Session history (list or calendar view toggle), manual session log form        |
| `BodyMetricsView`    | 9-field measurement form, weight/fat/muscle trend charts                       |
| `NotificationsView`  | Full notification history; mark-one and mark-all-read actions                  |
| `MessagesView`       | Direct message conversations for accepted trainer-athlete relationships        |
| `RelationshipsView`  | Send requests, accept/reject pending, search users                             |
| `ExercisesView`      | Exercise library, category/equipment/difficulty filters, create/delete         |
| `AdminView`          | User management, exercise audit (Admin role only)                              |
| `ProfileView`        | Update name, bio, goal, age, profession, sports list with per-sport experience years; separate General Settings modal for notification retention, measurement units, and athlete-owned dumbbell/barbell increment settings |
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

## Repeat Pattern And Set Weights

Programs are created without a selected repeat by default. `ProgramBuilderView` can later apply a 1, 2, 3, or 4 week pattern through `/api/programs/{id}/apply-pattern/{weeks}`; the API updates/reuses generated days and must preserve any workout sessions already linked to those days. Trainer-owned day/program/pattern templates are managed on the Templates page, which uses list/detail views, multi-select exercise adding, warm-up counts, shared plan fields, and trainer-facing guidance text.

Exercise rows support quick increment buttons:

| Button | Behaviour |
|--------|-----------|
| +W | Uses exercise equipment: dumbbell uses `currentUser.dumbbellIncrementKg`, barbell uses `currentUser.barbellPlatePerSideKg * 2`, other equipment uses +1 kg. If per-set weights exist, all planned set weights increment together. |
| +R | Single numeric reps increment by 1; time values such as `30s` increment by 5 seconds; ranges and text values stay unchanged. |
| +S | Adds one set and copies the last planned set weight when per-set weights are present. |

## Program Edit Permissions (Frontend)

`canEditCard` in `ProgramsView`:
```js
const canEditCard = canEditAsTrainer || (isActingAsAthlete && !p.trainerId);
```
Athletes only see the edit (pencil) button for programs without a trainer (`trainerId == null`). Trainer-created programs show a view-only (eye) button for athletes.
