# PR Display in Analytics Screen

## Overview

Personal Records (PRs) are already tracked in the database and returned by the API.
This task is **frontend-only** — display them in the athlete analytics view.

Backend endpoint is fully live: `GET /api/analytics/athletes/{id}/prs`

## Dependencies

None — backend is complete.

---

## Backend (no changes needed)

Endpoint already exists: `GET /api/analytics/athletes/{athleteId}/prs`

Returns `PersonalRecordDto[]`:
```json
[
  {
    "exerciseId": "...",
    "exerciseName": "Bench Press",
    "maxWeightKg": 100,
    "estimatedOneRmKg": 115.33,
    "maxVolumeSessionKg": 2400,
    "recordSessionId": "...",
    "recordedAt": "2026-06-01T..."
  }
]
```

Sorted by `exerciseName` ascending. Returns empty array if no PRs yet.

---

## Frontend

### 1. `src/services/api.js` — already exists

`api.getAthleteAnalyticsPrs(athleteId)` — check if this function exists.
If not, add:
```js
getAthleteAnalyticsPrs: (athleteId) =>
  authFetch(`/api/analytics/athletes/${athleteId}/prs`),
```

---

### 2. `src/i18n.js` — add new keys

```js
// TR
personalRecords: 'Kişisel Rekorlar',
prMaxWeight: 'Maks. Ağırlık',
prEstimated1RM: 'Tahmini 1RM',
prMaxVolume: 'Maks. Oturum Hacmi',
prRecordedAt: 'Kayıt tarihi',
noPrs: 'Henüz kişisel rekor yok',

// EN
personalRecords: 'Personal Records',
prMaxWeight: 'Max Weight',
prEstimated1RM: 'Est. 1RM',
prMaxVolume: 'Max Session Volume',
prRecordedAt: 'Recorded',
noPrs: 'No personal records yet',
```

---

### 3. PR display — add to `AthleteAnalyticsView.jsx`

The analytics view is at `src/views/AthleteAnalyticsView.jsx`. Add a "Kişisel Rekorlar" section.

**Where to add it:** at the bottom of the view, after the existing charts/sections.

**Data fetching:** Call `api.getAthleteAnalyticsPrs(athleteId)` alongside the other analytics calls (use `Promise.all` or add to the existing `useEffect`).

**Display as a table or card list:**

```
| Exercise      | Max Weight | Est. 1RM | Max Session Vol. | Date |
|---------------|-----------|----------|-----------------|------|
| Bench Press   | 100 kg    | 115 kg   | 2 400 kg        | Jun 1|
| Squat         | 140 kg    | 155 kg   | 4 200 kg        | Jun 5|
```

- Show weight in `kg` (no unit conversion needed for now)
- `estimatedOneRmKg` → round to 1 decimal
- `maxVolumeSessionKg` → format as integer with `.toLocaleString()`
- `recordedAt` → show as short date (e.g. "Jun 1, 2026")
- Empty state: Trophy icon (lucide-react `Trophy`) + `t('noPrs')`
- No pagination needed — athletes rarely have >50 PR entries

**Section heading:** `t('personalRecords')` with a `Trophy` icon.

---

### 4. Trainer view

If the analytics view is also shown to trainers (for their athlete), the `athleteId` prop is already passed — no additional changes needed.

---

## Docs to update when done

- `TrackMe-Docs/tasks/backlog.md` — mark "Personal Records — display in analytics screen" ✅
- No migration, no API changes — skip other docs

---

## Testing checklist

- [ ] After completing a session with weights → PR appears in analytics
- [ ] PR table shows with correct exercise name, weight, 1RM, volume, date
- [ ] Empty state shown when athlete has no PRs
- [ ] Trainer sees same PR table when viewing athlete analytics
