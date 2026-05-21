# Analytics Module

## Purpose

Converts workout history into useful progress and coaching insight.

## Responsibilities

- Strength progression
- Volume progression
- Workout consistency
- Workout frequency
- RPE trends
- Exercise history

## Main Data Sources

- WorkoutSession
- WorkoutSessionExercise
- WorkoutSetLog
- ProgressRecord
- WorkoutProgramAssignment

## Main Use Cases

- Get athlete overview
- Get strength progression
- Get volume progression
- Get RPE trend
- Get workout consistency

## Business Rules

- Use completed workouts by default.
- Exclude cancelled sessions.
- Respect measurement type when calculating metrics.
- Trainers can analyze only accepted athletes.
- Athletes can analyze only own data.
