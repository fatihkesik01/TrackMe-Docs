# Security and Validation

Security must be designed into every TrackMe module.

## Security Principles

- Passwords must be hashed.
- Users can only access their own data.
- Role validation is required.
- Ownership validation is required.
- HTTPS is required once the application is served through a real public domain.
- JWT secrets must be secure.
- Input validation is required.
- Sensitive actions must be logged.

## Current MVP Security Notes

- The current VPS deployment is IP-and-port based while the domain is pending.
- PostgreSQL is not exposed publicly; DBeaver access uses SSH tunnel through the `deploy` user.
- Secrets live in server-side `.env` files and GitHub Actions secrets, not in repositories.
- CORS is restricted to the deployed web origin.

## Validation Areas

- Registration
- Login
- Profile updates
- Relationship requests
- Exercise creation
- Program creation
- Workout logging
- RPE entry
- Notification updates

## Input Validation Examples

- Email must be valid and unique.
- Password must meet minimum strength rules.
- RPE must be between 1 and 10.
- Rest time cannot be negative.
- Reps cannot be negative.
- Weight cannot be negative.
- Exercise name cannot be empty.
- Workout end time cannot be before start time.

## Authorization Failure Examples

- Trainer attempts to access unrelated athlete.
- Athlete attempts to edit trainer program.
- User attempts to read another user's notification.
- Pending relationship used as if accepted.

## Audit Logging

Audit these actions:

- Login failures
- Role changes
- Admin user changes
- Exercise library changes
- Relationship changes
- Program assignment changes
- Suspicious authorization failures
