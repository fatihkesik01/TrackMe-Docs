# Development Day 1

Day 1 goal is to move TrackMe from deployed infrastructure to the first real product foundation.

The focus is authentication, user identity, and preparing the web app to work with real roles. Mobile stays parked for now and should reuse the same API later.

## Current Baseline

- API is deployed at `http://187.77.92.30:5050`.
- Web is deployed at `http://187.77.92.30:8080`.
- Scalar is available at `http://187.77.92.30:5050/scalar/v1`.
- PostgreSQL is running in Docker and can be accessed through DBeaver with SSH tunnel.
- API and Web auto deploy from GitHub Actions on push to `main`.

## Day 1 Scope

- Add real user identity foundation.
- Add JWT login/register flow.
- Prepare role model for `Admin`, `Trainer`, and `Athlete`.
- Add a basic web login screen.
- Keep existing trainer/athlete/program/session MVP endpoints working.

## API Tasks

- [x] Add `User` entity.
- [x] Add `Role` or enum-based role model.
- [x] Add password hash fields.
- [x] Add refresh-token-ready structure, even if refresh endpoint is not fully used on Day 1.
- [x] Add EF Core configuration for identity tables.
- [x] Create migration for identity tables.
- [x] Add register endpoint: `POST /api/auth/register`.
- [x] Add login endpoint: `POST /api/auth/login`.
- [x] Add current user endpoint: `GET /api/auth/me`.
- [x] Add JWT generation service.
- [x] Add JWT authentication middleware.
- [x] Add role/identity claims to generated tokens.
- [x] Protect at least one test endpoint with `[Authorize]` or minimal API authorization.
- [x] Show auth endpoints in Scalar.
- [x] Create matching trainer or athlete profile when a user registers with that role.
- [x] Require JWT for MVP dashboard, trainer, athlete, program, and session endpoints.

## Web Tasks

- [x] Add login page.
- [x] Add register page or a simple register panel.
- [x] Add auth API client functions.
- [x] Store access token safely enough for MVP.
- [x] Add authenticated layout state.
- [x] Show current user in the UI after login.
- [x] Add logout action.
- [x] Prevent dashboard API calls from silently failing when logged out.
- [x] Keep current dashboard, athlete, and session screens usable after login.
- [x] Send Bearer token with authenticated API requests.

## Database Tasks

- [ ] Confirm identity migration applies on VPS through GitHub Actions.
- [ ] Verify new tables in DBeaver.
- [ ] Insert or register the first admin/trainer user.
- [x] Confirm existing MVP tables are not dropped or recreated.

## Docs Tasks

- [x] Update API analysis with implemented auth endpoints.
- [x] Update database design with actual identity tables after migration is finalized.
- [x] Update deployment notes if new environment variables are added.
- [x] Record any temporary MVP decisions clearly.

## Acceptance Criteria

Day 1 is complete when:

- A user can register through the API.
- A user can login and receive a JWT.
- `GET /api/auth/me` returns the logged-in user when called with the token.
- Web can login and show authenticated state.
- GitHub Actions deploy succeeds after the auth changes.
- DBeaver confirms the new identity tables exist.
- Scalar shows the auth endpoints.

## Out Of Scope For Day 1

- Mobile app implementation.
- Full refresh token rotation.
- Email verification.
- Password reset.
- OAuth or social login.
- Full admin panel.
- Full trainer-athlete invitation flow.
- Payment or subscription logic.

## Day 1 Implementation Notes

- Passwords are hashed with PBKDF2-SHA256.
- Access tokens are JWT bearer tokens with user id, full name, email, and role claims.
- Trainer and athlete registrations automatically create a matching MVP profile row and return `profileId`.
- Refresh token table exists, but full refresh token rotation remains out of scope for Day 1.
- The web MVP stores the access token in localStorage. This is acceptable for the current internal MVP and should be revisited before public production launch.
- Current MVP data endpoints require a valid JWT. Stricter role and ownership rules will be added after the auth baseline is verified.

## Suggested Work Order

1. Implement API identity model and JWT settings.
2. Generate and review EF Core migration.
3. Implement auth endpoints.
4. Verify locally with Scalar or curl.
5. Add web login/register UI.
6. Push API and Web changes.
7. Verify VPS deploy, Scalar, Web, and DBeaver.
8. Update docs with final endpoint/table names.
