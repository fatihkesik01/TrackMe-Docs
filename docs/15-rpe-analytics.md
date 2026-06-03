# RPE and Analytics

RPE is a core feature of TrackMe.

## RPE Types

- Set RPE
- Workout RPE

## RPE Scale

RPE should be recorded from 1 to 10.

General interpretation:

- 1-3: very easy
- 4-6: moderate
- 7-8: hard but controlled
- 9: very hard
- 10: maximal effort

## RPE Use Cases

- Fatigue monitoring
- Program intensity analysis
- Recovery analysis
- Performance monitoring
- Load management

## Planned vs Actual RPE

Example:

```text
Planned RPE: 8
Actual RPE: 10
```

Possible interpretation: the program may be too difficult, the athlete may be under-recovered, or external stress may be affecting performance.

## Analytics

Possible analytics:

- Strength progression
- Workout consistency
- Workout frequency
- Volume progression
- Weight changes
- Exercise history
- RPE trends

## Metrics

### Volume

For weight and reps exercises:

```text
volume = weight * reps
```

### Estimated 1RM

Optional future metric:

```text
estimated_1rm = weight * (1 + reps / 30)
```

### Consistency

```text
completed_workouts / planned_workouts
```

## Analytics Guardrails

- Use completed workouts by default.
- Exclude cancelled workouts.
- Clearly mark estimated metrics.
- Do not compare incomplete set data as if it were complete logged performance.
