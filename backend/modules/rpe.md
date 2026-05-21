# RPE Module

## Purpose

Tracks and analyzes Rate of Perceived Exertion at set and workout level.

## Responsibilities

- Validate RPE values
- Store set RPE
- Store workout RPE
- Compare planned and actual RPE
- Provide RPE trend data

## Main Data Sources

- WorkoutSetLog
- WorkoutSession
- WorkoutProgramExerciseSet

## Business Rules

- RPE must be between 1 and 10.
- RPE can be optional for some set logs.
- Workout RPE should be requested on completion.
- Planned vs actual RPE requires linked program data.

## Analytics Outputs

- Average workout RPE
- Average set RPE by exercise
- RPE trend by week
- High RPE warning candidates
