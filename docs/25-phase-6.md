# Phase 6 — AI, Body Metrics & Advanced Platform

Phase 6 transforms TrackMe from a coaching tool into an intelligent training
platform.

Goal: add AI-assisted workout planning, body metric tracking, wearable
integration, and the foundation for a template marketplace.

Status: **not started**.

---

## Phase 6 Scope

- AI workout suggestion engine based on athlete analytics history.
- Body metrics tracking (weight, body fat %, measurements).
- Apple Health / Google Fit / Garmin Connect data import.
- Program template marketplace (trainers publish and share templates).
- Group and class session support.
- Subscription / monetization layer (optional, based on business model).

---

## API Tasks

### AI Suggestions
- [ ] `POST /api/ai/suggest-session` — given athlete id + recent history, return suggested exercises and sets
  - Use OpenAI / Azure OpenAI Chat Completions with structured output
  - Context: last 7 sessions, active program, avg RPE, recovery days
  - Return: `{ exercises: [{ exerciseId, sets, reps, targetRpe }] }`
- [ ] `POST /api/ai/suggest-program` — generate a full program from goal + duration + available equipment
- [ ] `GET /api/ai/recovery-score/{athleteId}` — simple fatigue score based on recent RPE + volume

### Body Metrics
- [ ] `BodyMetric` entity — (athlete_id, date, weight_kg, body_fat_pct, notes) + migration
- [ ] `POST /api/body-metrics` — log measurement
- [ ] `GET /api/body-metrics/{athleteId}` — paginated history
- [ ] `GET /api/analytics/athletes/{id}/body-trend` — weight + body fat trend for charts

### Wearables
- [ ] Apple Health: import daily steps, active calories, resting HR via HealthKit (mobile only)
- [ ] Garmin Connect: OAuth 2.0 flow, import completed activities as sessions
  - `POST /api/integrations/garmin/callback` — OAuth callback, persist tokens
  - `POST /api/integrations/garmin/sync` — pull latest activities and upsert sessions
- [ ] `UserIntegration` entity — (user_id, provider, access_token encrypted, refresh_token, last_synced_at)

### Marketplace
- [ ] Add `price_cents` and `is_marketplace` fields to `program_templates`
- [ ] `POST /api/templates/{id}/list-for-sale` — trainer lists template for sale
- [ ] `GET /api/marketplace/templates` — public browsable list with filters (category, price, rating)
- [ ] `POST /api/marketplace/templates/{id}/purchase` — create purchase record, grant access
- [ ] `TemplatePurchase` entity — (user_id, template_id, purchased_at, price_cents)

### Group Sessions
- [ ] `TrainingClass` entity — (trainer_id, title, scheduled_at, max_participants, program_id nullable)
- [ ] `ClassParticipant` entity — (class_id, athlete_id, joined_at, completed bool)
- [ ] `POST /api/classes` — trainer creates a class
- [ ] `POST /api/classes/{id}/join` — athlete joins
- [ ] `POST /api/classes/{id}/complete` — trainer marks class done; creates sessions for all participants

---

## Web Tasks

### AI Panel
- [ ] "AI Suggest" button on session log modal
  - Calls `/api/ai/suggest-session` and pre-fills exercise list
- [ ] "Generate Program" in program creation flow
  - Form: goal, weeks, sessions/week, equipment → calls `/api/ai/suggest-program`
- [ ] Recovery score badge on athlete dashboard (color: green / amber / red)

### Body Metrics
- [ ] Add Body Metrics section to athlete profile page
- [ ] Log weight / body fat form (date, weight, body fat %)
- [ ] Weight trend line chart (last 90 days)
- [ ] Body fat trend chart

### Marketplace
- [ ] Marketplace tab (public, no login needed to browse)
- [ ] Template cards with trainer name, price, rating
- [ ] Purchase flow (placeholder Stripe checkout or mock)
- [ ] "My Purchases" section in templates tab

### Group Sessions
- [ ] Classes tab or section in Sessions view
- [ ] Create class form (title, date/time, max participants)
- [ ] Athlete join button on class cards
- [ ] Trainer: class participant list + complete action

---

## Mobile Tasks

### AI
- [ ] AI suggest button on session log screen (same endpoint, mobile UI)
- [ ] Recovery score card on home screen

### Body Metrics
- [ ] Log metrics screen (weight, body fat, notes)
- [ ] Metrics history list
- [ ] Import from Apple Health (HealthKit) — `expo-health` or native module

### Wearables
- [ ] Garmin Connect OAuth flow in-app (WebView or expo-web-browser)
- [ ] Auto-sync on app foreground with background refresh

---

## Acceptance Criteria

Phase 6 is complete when:

- An athlete can tap "AI Suggest" and get a pre-filled session exercise list.
- A trainer can generate a full program structure using AI.
- Body weight and body fat can be logged and charted.
- Garmin Connect activities are importable as TrackMe sessions.
- Program templates can be listed, browsed, and purchased in the marketplace.
- Group class sessions can be created and joined.

---

## Out Of Scope For Phase 6

- Live video coaching — potential Phase 7
- Social feed / community — potential Phase 7
- Competitions and leaderboards — potential Phase 7
- Multi-language API responses — potential Phase 7
