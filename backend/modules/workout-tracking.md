# Workout Tracking Module

## Purpose

Stores actual performed workouts and set-level training history.

## Responsibilities

- Start workout session
- Add exercise logs
- Add set logs
- Track rest
- Complete workout
- Preserve historical workout data

## Main Entities

- WorkoutSession
- WorkoutSessionExercise
- WorkoutSetLog
- WorkoutNote
- RestLog

## Main Use Cases

- Start workout
- Add exercise to session
- Add set log
- Update set log
- Complete workout
- Get workout history

## Business Rules

- Athlete can create sessions only for self.
- Completed sessions are analytics source data.
- Workout end time cannot be before start time.
- Set fields must match exercise measurement type.
- Historical exercise name snapshot should be stored.
