# Mobile State Management

## Recommended State Areas

- Auth state
- Current user state
- Role state
- Active workout draft
- Program cache
- Exercise library cache
- Notification unread count

## Secure Storage

Store securely:

- Access token
- Refresh token
- User ID

Do not store:

- Password
- JWT secret
- Sensitive server configuration

## Local Cache

Cache for usability:

- Exercise library
- Assigned programs
- Recent workouts
- Active workout draft

## Active Workout Draft

The active workout draft should survive:

- App backgrounding
- Temporary network loss
- Screen navigation
- App restart when possible

## Sync Rules

- Completed workouts should sync to backend.
- Draft sync conflicts should prefer explicit user confirmation.
- Failed sync should show recoverable state.
- The app should never silently discard workout logs.
