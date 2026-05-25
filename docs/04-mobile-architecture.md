# Mobile Architecture

The mobile app should be built with React Native for Android and iOS.

Repository: `TrackMe-Mobile`

The mobile architecture should prioritize fast workout logging, simple UI, low friction, quick set entry, and a smooth workout experience.

## Recommended Pattern

- Component-based React Native architecture
- Feature-based folder structure
- Dependency injection
- Typed API clients
- Local secure token storage
- Offline-tolerant workout draft storage
- Navigation service

## Suggested Project Structure

```text
TrackMe-Mobile/
  src/
    app/
    features/
      auth/
      dashboard/
      athletes/
      programs/
      workout/
      exercises/
      progress/
      notifications/
      profile/
    components/
    services/
      api/
      auth/
      storage/
      notifications/
      workoutDrafts/
    navigation/
    store/
    types/
  assets/
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
