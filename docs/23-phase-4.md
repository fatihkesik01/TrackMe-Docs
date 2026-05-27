# Phase 4 — Analytics Charts, Calendar & UX Polish

Phase 4 builds on the complete Phase 1–3 foundation.

Goal: surface the chart-ready analytics data that already exists in the API, add a
calendar view for sessions, add profile pages, and apply a focused UX polish pass
across the web app. No new database entities are required; almost all work is
frontend.

Status: **not started**.

---

## Phase 4 Scope

- Render interactive analytics charts using existing API endpoints.
- Show session history on a monthly calendar.
- Add trainer and athlete profile pages.
- Add program compliance / adherence tracking.
- Improve session and exercise filtering and search.
- Production hardening: HTTPS, domain, and env-based config.

---

## API Tasks

The Phase 3 analytics endpoints already return chart-ready data.
No new endpoints are strictly required, but a few small additions would help.

### Analytics helpers
- [ ] `GET /api/analytics/athletes/{id}/exercise/{exerciseId}/progress` — already exists, verify response shape is correct for charting
- [ ] `GET /api/analytics/athletes/{id}/sessions-by-month` — monthly session count for heatmap (new)
- [ ] `GET /api/analytics/athletes/{id}/muscle-volume` — volume load split by muscle group (new, optional)

### Program compliance
- [ ] `GET /api/programs/{id}/compliance` — for each planned session day, return whether a session was logged matching the program (new)

### Sessions
- [ ] `GET /api/sessions?from=&to=` — date range filter on existing session list endpoint (extend existing)
- [ ] `GET /api/sessions?athleteId=` — admin/trainer can filter by athlete (extend existing)

---

## Web Tasks

### Analytics Charts (high priority)
- [ ] Add chart library — `recharts` (lightweight, React-native)
- [ ] RPE trend line chart — calls `GET /api/analytics/athletes/{id}/rpe-trend`
  - X-axis: date, Y-axis: avg RPE per session
  - Show for athlete on dashboard and trainer on athlete detail
- [ ] Volume trend bar chart — calls `GET /api/analytics/athletes/{id}/volume`
  - X-axis: week, Y-axis: total volume (sets × reps × weight)
- [ ] Exercise progress chart — `GET /api/analytics/athletes/{id}/exercise/{exerciseId}/progress`
  - Weight and reps over time for a selected exercise
  - Accessible from session detail when clicking an exercise name
- [ ] Consistency heatmap — `GET /api/analytics/athletes/{id}/consistency`
  - GitHub-style grid showing session days in last 30 days
  - Visible on athlete dashboard and trainer athlete detail

### Calendar View
- [ ] Add Calendar nav item (or embed in Sessions view as a tab)
- [ ] Monthly grid showing session count per day
- [ ] Click a day to jump to that session in the list
- [ ] Highlight today and days with sessions
- [ ] Date range selector (prev / next month)

### Profile Pages
- [ ] Athlete profile page — accessible by clicking athlete name anywhere in UI
  - Show: full name, email, goal, bio, trainer name, joined date
  - Show stat summary: total sessions, avg RPE, active program
  - Trainer can edit bio/goal for their athletes
  - Athlete can edit their own profile
- [ ] Trainer profile page — accessible by clicking trainer name
  - Show: full name, email, bio, athlete count, joined date
  - Trainer can edit their own profile
- [ ] `PATCH /api/auth/profile` already exists; connect UI

### Program Compliance Tracker
- [ ] Add "Compliance" tab or section on program detail modal
- [ ] Show planned days vs sessions logged against that program
- [ ] Percentage complete badge on program card
- [ ] Mark a program day as "skipped" (soft annotation, optional)

### Session Improvements
- [ ] Add date range filter to Sessions list (from/to date inputs)
- [ ] Add program filter to Sessions list (filter by program)
- [ ] Show session RPE as a colored badge (1–5 green, 6–8 amber, 9–10 red)
- [ ] Add session duration badge on list rows
- [ ] Allow editing session title, notes, RPE, duration from session detail

### Exercise Library Improvements
- [ ] Add muscle group filter chips (Chest, Back, Legs, etc.)
- [ ] Add equipment filter (Barbell, Dumbbell, Bodyweight…)
- [ ] Show exercise usage count (how many sessions it appears in)
- [ ] Exercise detail modal — show full instructions and progress chart for current user

### General UX
- [ ] Dark / light mode toggle with localStorage persist
- [ ] Add skeleton loaders to all remaining views that don't have them
- [ ] Empty state illustrations (SVG or Lucide-based) on all main views
- [ ] Keyboard shortcut: `N` to open log session modal, `P` to open create program modal
- [ ] Toast / snackbar for success actions (session saved, program created, etc.)
- [ ] Breadcrumb trail for modals (e.g., Program > Day 2 > Add Exercise)
- [ ] Responsive mobile-web layout pass (sidebar collapses to bottom tab bar on small screens)

---

## Infrastructure Tasks

- [ ] Set up HTTPS via Let's Encrypt (Nginx reverse proxy or Caddy)
- [ ] Move to a real domain (`trackme.yourdomain.com`)
- [ ] Move secrets (JWT secret, DB password) to `.env` file loaded by Docker Compose
- [ ] Add `VITE_API_BASE_URL` to production Docker Compose
- [ ] Configure CORS to restrict to production domain only
- [ ] Add Sentry or similar for error tracking (frontend and API)
- [ ] Set up automated daily Postgres backup (pg_dump + S3 or local volume copy)

---

## Acceptance Criteria

Phase 4 is complete when:

- An athlete can see their RPE trend and volume charts on the dashboard.
- A trainer can view an athlete's charts from the athlete detail / relationships view.
- The session list can be filtered by date range.
- A program detail shows compliance percentage (days done vs planned).
- Athlete and trainer profile pages are accessible and editable.
- The web app is served over HTTPS on a real domain.
- `npm run build` and `dotnet build` both pass with 0 errors.

---

## Out Of Scope For Phase 4

- React Native / Expo mobile app — Phase 5
- Push notifications (FCM) — Phase 5
- AI workout suggestions — Phase 6
- Body metrics tracking — Phase 6
- Wearable integration — Phase 6
- Marketplace / monetization — Phase 6
- Group / class sessions — Phase 6
