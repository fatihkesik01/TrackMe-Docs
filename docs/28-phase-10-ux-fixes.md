# Phase 10 — UX Fixes & Dual-Role Program Creation

Status: **complete**.

This phase addresses UX pain points found during internal testing and fixes the program
creation flow for Athlete-JWT users operating in Trainer uiMode.

---

## Changes

### 1. Athlete Dropdown Fix (Programs & Sessions)

**Problem:** In Trainer uiMode, the athlete selection field was locked to the user's own
name (disabled input) even when they needed to pick from their accepted athletes.

**Root cause:** `isActingAsAthlete` was computed as `Boolean(athleteProfileId)` — always true
for Athlete-JWT users — regardless of `uiRole`.

**Fix:** `isActingAsAthlete = uiRole !== 'Trainer' && Boolean(athleteProfileId)`

Affects: `ProgramsView.jsx`, `SessionsView.jsx`

---

### 2. Program Deletion

**New feature:** Trainers and Admins can now delete programs directly from the program card.

**Backend:** `DELETE /api/programs/{id}` with three-tier access control:
- Admin → always allowed
- Trainer-JWT → allowed if `trainerId == profileId`
- Athlete-JWT → allowed if self-guided program (`athleteId == profileId && trainerId == null`)
- Email fallback → allowed if trainer entity email matches caller (dual-role support)

**Cascade behavior:**
- Program days and day exercises are deleted.
- Workout sessions referencing the program have `programId` set to `null` (sessions preserved).

**Frontend:** Trash2 icon button on program cards (shown for Admin / Trainer mode). Triggers
`window.confirm` before calling delete. Shown for `trainerProfileId || isTrainerUiMode || isAdmin`.

---

### 3. Dual-Role Program Creation Fix

**Problem:** Athlete-JWT users in Trainer uiMode could not create programs for their athletes
because `trainerProfileId` is always `null` for Athlete-JWT users (JWT role is `Athlete`).
The backend also rejected requests because Athlete-JWT → `request.AthleteId != profileId` → 403.

**Fix (3 layers):**

**Frontend (`ProgramsView.jsx`):**
On submit, if `isTrainerUiMode && !trainerProfileId`, look up the trainer entity from the
`trainers` list by email:
```js
const myTrainerEntity = (isTrainerUiMode && !trainerProfileId)
  ? trainers.find(t => t.email?.toLowerCase() === currentUser?.email?.toLowerCase())
  : null;
const resolvedTrainerId = isActingAsAthlete
  ? null
  : (trainerProfileId || myTrainerEntity?.id || form.trainerId || null);
```

**Backend Create (`ProgramEndpoints.cs`):**
When `trainerId` is null:
- Trainer-JWT: auto-fill from JWT `profile_id`.
- Athlete-JWT creating for another athlete: look up trainer entity by email; lazily create
  via `EnsureTrainerEntityAsync` if not found.

**Backend Validation (`EndpointHelpers.cs`):**
For Athlete-JWT callers, if `request.TrainerId` matches the caller's trainer entity (email match),
validate as a trainer (accepted relationship check) rather than rejecting as "athlete creating for
someone else".

**Programs list (`ProgramEndpoints.GetAll`):**
For Athlete-JWT users, also include programs where their trainer entity is the assigned trainer
(in addition to programs where they are the athlete).

---

### 4. Athlete Page Shortcut Buttons

**New feature:** Each row in the Athletes view now has two quick-navigation icon buttons:

| Icon | Action |
|---|---|
| `Target` | Navigate to Programs view |
| `CalendarCheck` | Navigate to Sessions view |

These use `onNavigate` prop passed from `App.jsx → AthletesView`. The buttons appear for
all users who can see the Athletes page (Trainer mode and Admin).

---

## Files Changed

| File | Change |
|---|---|
| `TrackMe-Api/.../ProgramEndpoints.cs` | Added DELETE endpoint; trainerId auto-resolution in Create; email-based trainer filter in GetAll |
| `TrackMe-Api/.../EndpointHelpers.cs` | ValidateProgramWriteAccessAsync: Athlete-JWT + trainer entity path |
| `TrackMe-Web/src/App.jsx` | `handleDeleteProgram`; `uiRole` prop to Programs/Sessions; `onNavigate` to Athletes |
| `TrackMe-Web/src/views/ProgramsView.jsx` | `uiRole`, `onDeleteProgram` props; isActingAsAthlete fix; email-based trainer lookup; delete button |
| `TrackMe-Web/src/views/SessionsView.jsx` | `uiRole` prop; `isActingAsAthlete` fix for athlete dropdown |
| `TrackMe-Web/src/views/AthletesView.jsx` | `onNavigate` prop; Target + CalendarCheck shortcut buttons |
| `TrackMe-Web/src/services/api.js` | `deleteProgram(id)` |
