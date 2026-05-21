# Mobile Architecture

The mobile app should be built with .NET MAUI for Android and iOS.

The mobile architecture should prioritize fast workout logging, simple UI, low friction, quick set entry, and a smooth workout experience.

## Recommended Pattern

- MVVM
- Dependency injection
- Typed API clients
- Local secure token storage
- Offline-tolerant workout draft storage
- Navigation service

## Suggested Project Structure

```text
TrackMe.Mobile/
  Views/
    Auth/
    Dashboard/
    Athletes/
    Programs/
    Workout/
    Exercises/
    Progress/
    Notifications/
    Profile/
  ViewModels/
  Models/
  Services/
    Api/
    Auth/
    Storage/
    Notifications/
    WorkoutDrafts/
  Components/
  Resources/
```

## Mobile Responsibilities

- Render role-specific UI.
- Keep workout logging fast.
- Store tokens securely.
- Handle refresh token flow.
- Cache active workout drafts.
- Display notifications.
- Submit completed workouts.
- Show progress charts.

## Mobile Non-Responsibilities

- The app should not decide authorization.
- The app should not trust local role state without backend validation.
- The app should not calculate final analytics that must be authoritative.
- The app should not store passwords.

## Offline-Tolerant Drafts

Workout tracking should support temporary local drafts because athletes may train in low-connectivity environments.

Drafts may include:

- Active workout session
- Exercise logs
- Set logs
- Rest timer state
- Notes

When connection returns, the app should sync the completed workout to the API.

## UI Principles

- Minimize taps during set logging.
- Keep primary actions reachable with one hand.
- Use numeric inputs optimized for reps, weight, RPE, and rest time.
- Preserve unsaved workout data.
- Avoid blocking workout flow with non-critical prompts.

## Role-Based Navigation

- Admin: management, reports, exercise library, notifications
- Trainer: athletes, programs, history, progress, notes
- Athlete: dashboard, active program, start workout, progress, notifications
