# Web App Architecture

Repository: `TrackMe-Web`

React 18 + Vite SPA. Single-page application with hash-based routing, no router library.

## Actual Project Structure

```text
TrackMe-Web/
  src/
    services/
      api.js              — all API calls + auth token management
    components/
      Modal.jsx
      Toast.jsx
      RpeTrendChart.jsx
      VolumeTrendChart.jsx
      ConsistencyGrid.jsx
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
| profile       | ProfileView        |

### ATHLETE_NAV
| id            | View               |
|---------------|--------------------|
| dashboard     | DashboardView      |
| myProgram     | ProgramsView + ProgramBuilderView |
| sessions      | SessionsView       |
| bodyMetrics   | BodyMetricsView    |
| relationships | RelationshipsView  |
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
6. `uiRole` is read from `trackme_ui_role` localStorage on boot

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

## Component Responsibilities

| Component          | Responsibility                                              |
|--------------------|-------------------------------------------------------------|
| `DashboardView`    | Stats cards for trainer or athlete based on `uiRole`        |
| `AthletesView`     | Athlete list, create athlete, navigate to AthleteDetailView |
| `AthleteDetailView`| Tabs: Overview, Programs, Sessions, Progress for one athlete |
| `ProgramsView`     | Program cards list, create program, open builder/viewer     |
| `ProgramBuilderView` | Day + exercise editor (read/write) for a program          |
| `WorkoutMode`      | Full-screen set-by-set workout logging overlay              |
| `SessionsView`     | Session history list, manual session log form               |
| `BodyMetricsView`  | 9-field measurement form, weight/fat/muscle trend charts    |
| `RelationshipsView`| Send requests, accept/reject pending, search users          |
| `ExercisesView`    | Exercise library list, create/delete                        |
| `AdminView`        | User management, exercise audit (Admin role only)           |
| `ProfileView`      | Update name, bio, goal, change password                     |
