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

- [ ] Add `User` entity.
- [ ] Add `Role` or enum-based role model.
- [ ] Add password hash fields.
- [ ] Add refresh-token-ready structure, even if refresh endpoint is not fully used on Day 1.
- [ ] Add EF Core configuration for identity tables.
- [ ] Create migration for identity tables.
- [ ] Add register endpoint: `POST /api/auth/register`.
- [ ] Add login endpoint: `POST /api/auth/login`.
- [ ] Add current user endpoint: `GET /api/auth/me`.
- [ ] Add JWT generation service.
- [ ] Add JWT authentication middleware.
- [ ] Add role/identity claims to generated tokens.
- [ ] Protect at least one test endpoint with `[Authorize]` or minimal API authorization.
- [ ] Show auth endpoints in Scalar.

## Web Tasks

- [ ] Add login page.
- [ ] Add register page or a simple register panel.
- [ ] Add auth API client functions.
- [ ] Store access token safely enough for MVP.
- [ ] Add authenticated layout state.
- [ ] Show current user in the UI after login.
- [ ] Add logout action.
- [ ] Prevent dashboard API calls from silently failing when logged out.
- [ ] Keep current dashboard, athlete, and session screens usable after login.

## Database Tasks

- [ ] Confirm identity migration applies on VPS through GitHub Actions.
- [ ] Verify new tables in DBeaver.
- [ ] Insert or register the first admin/trainer user.
- [ ] Confirm existing MVP tables are not dropped or recreated.

## Docs Tasks

- [ ] Update API analysis with implemented auth endpoints.
- [ ] Update database design with actual identity tables after migration is finalized.
- [ ] Update deployment notes if new environment variables are added.
- [ ] Record any temporary MVP decisions clearly.

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

## Suggested Work Order

1. Implement API identity model and JWT settings.
2. Generate and review EF Core migration.
3. Implement auth endpoints.
4. Verify locally with Scalar or curl.
5. Add web login/register UI.
6. Push API and Web changes.
7. Verify VPS deploy, Scalar, Web, and DBeaver.
8. Update docs with final endpoint/table names.
