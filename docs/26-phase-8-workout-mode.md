# Phase 8 — Active Workout Mode & Program Builder

Phase 8 adds two high-impact UX features: an immersive full-screen workout tracker
and an Excel-like program builder for trainers.

Status: **complete**.

---

## Feature 1: Active Workout Mode

When an athlete taps "Start" on a program day, the entire screen transitions into a
dedicated workout tracker that feels like a separate app.

### UX Flow

```
ProgramsView → [Başla] → WorkoutMode (full-screen overlay)
    ↓
  Quick Mode  ──  Emoji rating (😵 😟 😐 😊 💪) per exercise
  Detailed Mode── Per-set kg/reps/RPE table
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
| Mode toggle | Quick (emoji per exercise) ↔ Detailed (sets table) — persists per session |
| Timer | Starts when overlay opens, displayed in header |
| Draft persistence | `localStorage` key per session id — survives page refresh |
| Confirmation on exit | `window.confirm` prevents accidental loss |
| Auto-complete | `POST /api/sessions/{id}/complete` with elapsed minutes + overall RPE |

### Backend: new endpoints

| Endpoint | Purpose |
|---|---|
| `POST /api/sessions/start` | Create InProgress session, pre-populate exercises from program day |
| `POST /api/sessions/{id}/complete` | Set Status=Completed, DurationMinutes, Rpe, CompletedAt |
| `PATCH /api/sessions/{id}/exercises/{exerciseId}/feeling` | Quick-mode done + emoji (1-5) |

### Model changes

**WorkoutSession**
- `Status SessionStatus` (InProgress / Completed) — default Completed for backward compat
- `CompletedAt DateTimeOffset?` — nullable; null = in-progress

**WorkoutSessionExercise**
- `IsCompleted bool` (default true)
- `FeelingRating int?` (1–5, maps to 😵→💪)

### Migration

`Phase8_WorkoutMode`

---

## Feature 2: Program Builder (Excel-style)

Replaces the cramped modal-based builder with a full-page, spreadsheet-style
layout designed for fast keyboard editing.

### Layout

```
┌────────────────────────────────────────┐
│  ← Programs  |  "Push A"   Program Builder  │
├─────────────┬──────────────────────────────┤
│  Day 1 [3] │  Day 1: Upper Body           │
│  Day 2 [5] │  ┌────────────┬─────┬────────┤
│  Day 3 [0] │  │ Exercise   │Sets │Reps…   │
│  ──────────│  ├────────────┼─────┼────────┤
│  + Add Day │  │ Bench Press│  3  │  8-10  │
│            │  │ Incline DB │  4  │  10-12 │
│            │  ├────────────┴─────┴────────┤
│            │  │ [search] 3  8-10  –  90  +│
└────────────┴──────────────────────────────┘
```

### Key Behaviours

| Behaviour | Detail |
|---|---|
| Left panel | Day list with exercise count badges; click to select |
| Inline editing | Sets/Reps/RPE/Rest columns are `<input>` cells; `onBlur` → PUT API |
| Exercise add | Search dropdown; pick exercise, fill columns, press + |
| Day add | Inline form in left panel (no modal) |
| Navigation | Back button returns to programs grid; state preserved in App.jsx |

### State: App.jsx

```jsx
const [programBuilderProgramId, setProgramBuilderProgramId] = useState(null);
// null = show ProgramsView; set = show ProgramBuilderView
```

---

## Frontend Components

| File | Role |
|---|---|
| `src/views/WorkoutMode.jsx` | Full-screen overlay; Quick + Detailed mode |
| `src/views/ProgramBuilderView.jsx` | Excel-like builder page |
| `src/views/ProgramsView.jsx` | Added "Başla" (Start) per day for athletes; pencil icon for trainer builder |
| `src/App.jsx` | `activeWorkoutSession`, `programBuilderProgramId` states + handlers |
| `src/services/api.js` | `startSession`, `completeSession`, `updateExerciseFeeling`, `addSet` |
| `src/i18n.js` | 22 new keys (TR + EN) for workout mode and builder |
| `src/styles.css` | `workout-overlay`, `quick-mode-panel`, `detailed-mode-panel`, `builder-layout`, `builder-day-panel`, `builder-ex-table` |
