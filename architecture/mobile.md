# Mobile Architecture

TrackMe's mobile application (React Native) is planned but not yet started. This document captures the architecture decisions so implementation can begin without re-deriving constraints.

## Guiding Principles

- **Coaching-first, mobile-native.** Workout Mode, camera capture, and push notifications are mobile-primary experiences — design them for mobile first, then adapt to web.
- **Offline-tolerant sessions.** An active workout must survive a network outage. Draft state persists locally; sync happens when connectivity resumes.
- **Secure token storage.** Never use AsyncStorage for JWTs on mobile. Use `expo-secure-store` or the platform keychain.
- **Single API.** The same ASP.NET Core API serves both Web and Mobile. No separate mobile backend.

## Recommended Stack

| Layer | Choice |
|-------|--------|
| Framework | React Native (Expo managed workflow) |
| Navigation | React Navigation v6 (stack + bottom tabs) |
| State | React Context or Zustand (no Redux) |
| Token storage | `expo-secure-store` (Keychain/Keystore) |
| HTTP | Fetch or Axios with JWT interceptor |
| Real-time | SignalR `@microsoft/signalr` |
| Camera | `expo-camera` + `expo-image-picker` |
| Push notifications | FCM (Android) + APNs (iOS) via Expo Notifications |

## Project Structure

```
TrackMe-Mobile/
├── app/                    # Screens (Expo Router) or src/screens/
│   ├── auth/               # Login, Register, Onboarding
│   ├── athlete/            # Dashboard, Program, Workout, Analytics, Profile
│   ├── trainer/            # Dashboard, Athletes, Programs, Relationships
│   └── shared/             # Notifications, Messages, PublishedPrograms
├── components/             # Shared UI components
│   ├── WorkoutMode/        # Set logging, rest timer, exercise nav
│   └── UserAvatar/         # Photo > emoji > initials
├── services/
│   ├── api.ts              # All HTTP calls (mirrors web api.js)
│   ├── auth.ts             # Token storage + refresh logic
│   └── notifications.ts    # Push token registration
├── store/                  # Global state (auth, currentUser, offline draft)
└── utils/
```

## Role-Based Navigation

### Athlete Bottom Tabs
```
Dashboard | My Program | Sessions | Analytics | Profile
```

### Trainer Bottom Tabs
```
Dashboard | My Athletes | Programs | Relationships | Profile
```

### Shared Tabs (accessible from both)
- Notifications (badge count)
- Messages
- Published Programs

## Screen Inventory

### Auth
- Login
- Register
- Forgot Password
- Onboarding (role selection)

### Athlete
- Dashboard (TodayWorkoutCard, stats, PRs)
- My Program (program list, program detail)
- **Workout Mode** (set-by-set logging — primary mobile experience)
- Session History
- Analytics (RPE trend, volume, consistency, PRs)
- Body Metrics (log + history)
- Progress Photos (upload, timeline, before/after)
- Profile + Privacy Settings

### Trainer
- Dashboard (athlete stats, sessions this week)
- My Athletes (list → Athlete Detail)
- Athlete Detail (tabs: Overview, Programs, Sessions, Progress)
- Program Builder (limited on mobile — view/assign, full builder on web)
- Relationships (send/accept/reject)

### Shared
- Notifications
- Messages (contact list → thread)
- Published Programs (browse, detail, save)
- User Profile (public view)

## Offline-Tolerant Workout Draft

The active workout state must survive:
- App backgrounded mid-workout
- Network loss mid-set
- Device restart

**Draft model:**
```json
{
  "sessionId": "...",
  "programId": "...",
  "dayId": "...",
  "startedAt": "2026-06-12T10:30:00Z",
  "exercises": [
    {
      "exerciseId": "...",
      "exerciseName": "Squat",
      "sets": [
        { "setNumber": 1, "reps": 5, "weightKg": 100, "rpe": 8, "isWarmUp": false, "completedAt": "..." }
      ]
    }
  ]
}
```

- Persisted in `expo-secure-store` (small) or SQLite (large)
- Synced to API on `Complete Workout`
- Draft auto-resumed if app reopened mid-workout

## Media Upload Strategy

For progress photos and submission videos on mobile:

1. **Compress before upload** — resize images to max 1280px, videos to 720p
2. **Chunked/resumable upload** — use multipart or S3 multipart for videos
3. **Background upload** — `expo-background-fetch` or `expo-task-manager`
4. **Progress indicator** — upload progress shown in UI before navigating away

## Push Notifications

| Type | Trigger |
|------|---------|
| RelationshipRequest | Trainer/athlete sent request |
| ConnectionRequest | Social connection request |
| ProgramAssigned | Trainer assigned program |
| WorkoutCompleted | Athlete completed workout (trainer sees) |
| NewMessage | New direct message |
| NewFollower | Someone followed the user |
| ProgramUpdateAvailable | Publisher released new version |

FCM/APNs device token stored in `users.fcm_token` (column to be added when mobile starts).

## Deep Links

| Notification | Target screen |
|-------------|--------------|
| RelationshipRequest | Relationships → Requests tab |
| ConnectionRequest | Social → Requests tab |
| ProgramAssigned | My Program |
| NewMessage | Messages → thread |
| ProgramUpdateAvailable | My Program → update banner |

## Security Notes

- JWTs stored in `expo-secure-store` — never in AsyncStorage
- HTTPS required for all API calls
- Certificate pinning recommended before public release
- Camera permission requested only on demand (lazy)
