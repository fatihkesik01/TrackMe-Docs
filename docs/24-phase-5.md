# Phase 5 — Mobile App (Expo / React Native)

Phase 5 ships the first native mobile client for TrackMe.

Goal: build an Expo (React Native) app that covers the full athlete workflow —
login, session logging with set tracking, program view — and a trimmed trainer
view for managing athletes on the go. Backed by the existing `TrackMe-Api`.

Status: **not started**.

---

## Phase 5 Scope

- Initialize the Expo project in `TrackMe-Mobile`.
- Auth flow (login, register, token refresh, logout).
- Athlete home: dashboard stats, active program card.
- Session logging with exercise and set tracking.
- Program view (read-only for athletes, edit for trainers).
- Relationships: athlete invites trainer, trainer sends request.
- Exercise library browser.
- Push notifications via Expo Push Notification service.
- Basic trainer view: athlete list, quick session log for athlete.

---

## Technical Choices

| Concern | Choice | Reason |
|---------|--------|--------|
| Framework | Expo SDK 52+ | Managed workflow, OTA updates, EAS Build |
| Navigation | Expo Router (file-based) | Clean, typed, easy deep links |
| State | Zustand + React Query | Simple global state + server cache |
| Storage | `expo-secure-store` | JWT tokens stored securely, never AsyncStorage |
| HTTP client | `fetch` + custom wrapper (mirrors web api.js) | Consistent with backend contract |
| Push | Expo Push Notifications + `expo-notifications` | No own FCM setup needed |
| Charts | `victory-native` | Works with React Native, matches recharts data shape |
| Forms | React Hook Form | Lightweight, works with RN TextInput |
| UI primitives | Custom components + `@expo/vector-icons` | No heavy UI lib dependency |

---

## API Tasks

Most endpoints already exist. Small additions needed for mobile-specific needs.

### Push Notifications
- [ ] Add `push_token` field to `users` table (expo push token, nullable varchar 300)
- [ ] `POST /api/auth/push-token` — register / update expo push token for current user
- [ ] Migration for `push_token` column
- [ ] Update `QueueNotificationAsync` to also send Expo push via HTTP API when token exists
- [ ] Background job to clean up invalid push tokens (integrate with RefreshTokenCleanupService)

### Session
- [ ] Verify `POST /api/sessions` + exercises + sets works from mobile over 4G (no changes needed, just test)

---

## Mobile Tasks

### Project Setup
- [ ] `npx create-expo-app TrackMe-Mobile --template tabs` (or blank with Expo Router)
- [ ] Configure `app.json` — bundle ID, version, icon, splash screen
- [ ] Set up EAS project (`eas init`)
- [ ] Configure environment: `EXPO_PUBLIC_API_BASE_URL` in `.env`
- [ ] Set up `src/services/api.ts` — mirrors web api.js, uses `expo-secure-store` for tokens
- [ ] Set up global error boundary

### Auth
- [ ] Login screen (email + password, error display)
- [ ] Register screen (full name, email, password, role picker)
- [ ] Token storage in `expo-secure-store` (access token + refresh token)
- [ ] Auto-refresh on 401 (axios interceptor or fetch wrapper)
- [ ] Logout clears secure store + calls `POST /api/auth/logout`
- [ ] Boot: check stored token → call `/api/auth/me` → redirect to home or login
- [ ] Persist auth across app restarts

### Navigation Structure

```
(auth)/          → login, register (not authenticated)
(app)/           → authenticated tab layout
  (tabs)/
    index        → Dashboard / Home
    sessions     → Session list + log session
    programs     → Programs list + program detail
    exercises    → Exercise library
    relationships → Relationships + invite/request
  athlete/[id]   → Athlete detail (trainer only)
  session/[id]   → Session detail with set logging
  program/[id]   → Program detail
```

### Home / Dashboard Tab
- [ ] Stats row: total sessions, weekly sessions, avg RPE
- [ ] Active program card (title, trainer name, progress bar)
- [ ] Recent sessions list (last 3)
- [ ] "Log session" FAB (Floating Action Button) bottom right
- [ ] Trainer home: athlete count, sessions this week, pending relationships

### Sessions Tab
- [ ] Session list with date, title, duration, RPE badge
- [ ] Pull-to-refresh
- [ ] Infinite scroll (page-based)
- [ ] "Log session" button top-right
- [ ] Tap session → Session Detail screen

### Session Detail Screen (`/session/[id]`)
- [ ] Show title, date, duration, RPE, notes
- [ ] Exercise list with set rows (reps, weight, RPE, completed toggle)
- [ ] Add exercise button → exercise picker sheet
- [ ] Add set row button per exercise
- [ ] Inline set editing (tap to edit reps/weight)
- [ ] Delete exercise swipe action

### Log Session Bottom Sheet / Screen
- [ ] Title, program picker, notes, date, duration, RPE inputs
- [ ] Save creates session → navigates to session detail to add exercises

### Programs Tab
- [ ] Program cards (title, athlete, trainer, date range)
- [ ] Pull-to-refresh
- [ ] Tap → Program detail screen
- [ ] Trainer: create program button

### Program Detail Screen (`/program/[id]`)
- [ ] Meta: athlete, trainer, dates
- [ ] Day accordion list
- [ ] Exercises per day with sets/reps/RPE/rest badges
- [ ] Trainer: add day, add exercise (inline forms or modal)

### Exercise Library Tab
- [ ] Searchable flat list
- [ ] Category filter chips (horizontal scroll)
- [ ] Tap → exercise detail sheet (instructions, progress chart)
- [ ] Trainer/Admin: create exercise FAB

### Relationships Tab
- [ ] Pending request list with accept / reject buttons
- [ ] Search trainer (athlete) or search athlete (trainer)
- [ ] Single autocomplete following same logic as web

### Push Notifications
- [ ] Request permission on first launch
- [ ] Register Expo push token → `POST /api/auth/push-token`
- [ ] Handle foreground notifications (in-app banner)
- [ ] Handle background tap → navigate to correct screen

### Offline Support (basic)
- [ ] React Query caches last successful responses
- [ ] Show stale data with "offline" indicator when no network
- [ ] Session log form saves to AsyncStorage draft if offline; syncs on reconnect

---

## Build & Release Tasks

- [ ] Configure EAS Build profile (development, preview, production)
- [ ] iOS: configure bundle ID, signing cert via EAS
- [ ] Android: configure package name, keystore via EAS
- [ ] Set up EAS Update for OTA JS bundle updates
- [ ] Submit to TestFlight (iOS) and Google Play internal track
- [ ] Build and install on physical iOS + Android device
- [ ] Smoke test: login → log session → view program → log out

---

## Acceptance Criteria

Phase 5 is complete when:

- An athlete can log in, log a session with exercises and sets, and view their program on a physical iOS and Android device.
- A trainer can view their athlete list and log a session for an athlete from the mobile app.
- Push notifications arrive on device for relationship requests and program assignments.
- JWT tokens are stored in `expo-secure-store`, not AsyncStorage.
- EAS Build produces a signed APK and IPA that install cleanly.
- `npx expo export` completes with 0 errors.

---

## Out Of Scope For Phase 5

- AI suggestions — Phase 6
- Body metrics tracking — Phase 6
- Wearable sync (Apple Health, Garmin) — Phase 6
- Marketplace / subscription — Phase 6
- Video coaching — Phase 6
- Group / class sessions — Phase 6
