# Authentication and Authorization

TrackMe uses JWT authentication, refresh tokens, and role based authorization.

## Supported Roles

- Admin
- Trainer
- Athlete

## Authentication Flow

1. User registers or logs in.
2. Backend validates credentials.
3. Backend returns access token and refresh token.
4. Mobile stores tokens securely.
5. API requests include access token.
6. Expired access tokens are renewed with refresh token.
7. Logout revokes refresh token.

## Security Requirements

- Passwords must be hashed with a strong password hashing algorithm.
- Refresh tokens must be stored hashed in the database.
- JWT secret must be stored in environment variables or secret manager.
- Access token lifetime should be short.
- Refresh token lifetime should be longer but revocable.
- All protected endpoints require HTTPS.
- Failed login attempts should be logged.

## Authorization Requirements

- Admin can manage platform-level resources.
- Trainer can access only related athletes and own programs.
- Athlete can access only own data and assigned programs.
- Ownership checks must happen in backend services.

## Suggested Policies

- RequireAdmin
- RequireTrainer
- RequireAthlete
- TrainerCanAccessAthlete
- AthleteOwnsWorkout
- TrainerOwnsProgram
- UserOwnsNotification
