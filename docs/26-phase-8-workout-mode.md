# Phase 8 — Active Workout Mode & Program Builder

Phase 8 adds two high-impact UX features: an immersive full-screen workout tracker
and an Excel-like program builder for trainers.

Status: **complete** (updated in Phase 9 with set-level fail/drop logging).

---

## Feature 1: Active Workout Mode

When an athlete taps "Start" on a program day, the entire screen transitions into a
dedicated workout tracker that feels like a separate app.

### UX Flow

```
ProgramsView → [Başla] → WorkoutMode (full-screen overlay)
    ↓
  Plan hint (📋 sets × reps @ kg · RPE) — shown if trainer set a plan
    ↓
  Per-set table: Set# | Reps | kg | RPE | [✗ Fail]
    ├── Normal set: fill reps, kg, RPE → Log Sets
    └── Failed set: press ✗ → red strikethrough → "Düşürdüm: X kg × Y tekrar" row
    ↓
  Exercise navigation (← prev · dots · next →)
    ↓
  Finish panel → overall RPE → [Antrenmanı Tamamla]
    ↓
  Success animation → back to programs
```

### Key Behaviours

| Behaviour | Detail |
|---|---|
| Full-screen overlay | `position: fixed; z-index: 1000` over the entire shell |
| Single mode | Only detailed set-table mode — no Quick/Detailed toggle |
| Plan hint | If `plannedSets/plannedReps/plannedWeightKg/plannedRpe` present, shown above table |
| Pre-filled rows | `defaultRows(exercise)` pre-fills weight/reps/RPE from planned values |
| Fixed set count | Set count = `plannedSets` from the program plan; athlete cannot add/remove sets |
| Per-set fail toggle | ✗ button turns row red/strikethrough; reveals drop sub-row |
| Drop set logging | After failing: enter `dropKg` and `dropReps` — saved as `notes: "Drop: Xkg × Y tekrar"`, `isCompleted: false` |
| Timer | Starts when overlay opens, displayed in header |
| Draft persistence | `localStorage` key per session id — survives page refresh |
| Confirmation on exit | `window.confirm` prevents accidental loss |
| Auto-complete | `POST /api/sessions/{id}/complete` with elapsed minutes + overall RPE |
| **Başla visibility** | All roles (Athlete, Trainer, Admin) see the Start button |
| **Edit protection** | Athletes can only edit self-guided programs (`trainerId == null`) |

### Set Logging Detail

Each `addSet` call sends:
```json
{
  "setNumber": 1,
  "reps": 8,
  "weightKg": 80,
  "rpe": 8,
  "isCompleted": true,
  "notes": null
}
```

Failed set with drop:
```json
{
  "setNumber": 2,
  "reps": null,
  "weightKg": 80,
  "rpe": null,
  "isCompleted": false,
  "notes": "Drop: 60kg × 10 tekrar"
}
```

### Backend: new endpoints

| Endpoint | Purpose |
|---|---|
| `POST /api/sessions/start` | Create InProgress session, pre-populate exercises from program day |
| `POST /api/sessions/{id}/complete` | Set Status=Completed, DurationMinutes, Rpe, CompletedAt |
| `PATCH /api/sessions/{id}/exercises/{exerciseId}/feeling` | Mark exercise done/undone |

### Model changes

**WorkoutSession**
- `Status SessionStatus` (InProgress / Completed) — default Completed for backward compat
- `CompletedAt DateTimeOffset?` — nullable; null = in-progress

**WorkoutSessionExercise (Phase 9 additions)**
- `PlannedSets int?` — snapshot from program day at session start
- `PlannedReps string?` — e.g. "8-10", "AMRAP"
- `PlannedWeightKg decimal?`
- `PlannedRpe int?`
- `PlannedRestSeconds int?`

**WorkoutSetLog**
- `IsCompleted bool` — false = athlete couldn't complete the set
- `Notes string?` — used to record drop-set info: `"Drop: 60kg × 10 tekrar"`

### Migrations

| Migration | Purpose |
|---|---|
| `Phase8_WorkoutMode` | Status + CompletedAt on sessions, IsCompleted + FeelingRating on session exercises |
| `Phase8b_RepsAsString` | Convert `reps` column from int → varchar(20) on program and template exercises |
| `Phase9_TargetWeightAndPlannedFields` | `target_weight_kg` on program exercises; 5 planned fields on session exercises |

---

## Feature 2: Program Builder (Excel-style)

Replaces the cramped modal-based builder with a full-page, spreadsheet-style
layout designed for fast keyboard editing.

### Layout

```
┌────────────────────────────────────────────────────────┐
│  ← Programs  |  "Push A"   Program Builder             │
├─────────────┬──────────────────────────────────────────┤
│  Day 1 [3] │  Day 1: Upper Body                       │
│  Day 2 [5] │  ┌──────────┬─────┬──────┬────┬─────┬──┐│
│  Day 3 [0] │  │ Exercise │Sets │Reps  │ kg │RPE  │  ││
│  ──────────│  ├──────────┼─────┼──────┼────┼─────┼──┤│
│  + Add Day │  │ Bench    │  3  │ 8-10 │ 80 │  8  │🗑││
│            │  │ Son: 3×8 @ 75kg · 2026-05-20        ││
│            │  ├──────────┴─────┴──────┴────┴─────┴──┤│
│            │  │ [search]  3  8-10  kg  –   90     +  ││
└────────────┴──────────────────────────────────────────┘
```

### Key Behaviours

| Behaviour | Detail |
|---|---|
| Left panel | Day list with exercise count badges; click to select |
| Inline editing | Sets / Reps / **Target kg** / RPE / Rest columns are `<input>` cells; `onBlur` → PUT API |
| Last performance hint | Per row: "Son: 3×8 @ 80kg · 2026-05-20" fetched from `GET .../last-performance` |
| Exercise add | Search dropdown (fixed position to escape overflow clipping); fill columns, press + |
| Day add | Inline form in left panel (no modal) |
| Navigation | Back button returns to programs grid; state preserved in App.jsx |

### Last Performance Fetch

On day selection change, `ProgramBuilderView` batch-fetches last performance for
every exercise in that day via `Promise.all`:

```js
api.exerciseLastPerformance(athleteId, ex.exerciseId)  // GET .../last-performance
```

Result: `{ date, sessionTitle, sets: [{ reps, weightKg, rpe, ... }] }`

The best-weight set is summarised as `3×8 @ 80kg` and shown below each row.

---

## Frontend Components

| File | Role |
|---|---|
| `src/views/WorkoutMode.jsx` | Full-screen overlay; set-level fail + drop logging |
| `src/views/ProgramBuilderView.jsx` | Excel-like builder with target-kg column + last-perf hints |
| `src/views/ProgramsView.jsx` | "Başla" per day for all roles; edit protection for athletes |
| `src/App.jsx` | `activeWorkoutSession`, `programBuilderProgramId` states + handlers |
| `src/services/api.js` | `startSession`, `completeSession`, `updateExerciseFeeling`, `addSet`, `exerciseLastPerformance` |
| `src/i18n.js` | TR + EN keys: workout mode, builder, fail/drop, plan/last-perf |
| `src/styles.css` | `workout-overlay`, `set-panel`, `set-fail-btn`, `set-drop-row`, `plan-hint`, `builder-ex-last-perf` |
