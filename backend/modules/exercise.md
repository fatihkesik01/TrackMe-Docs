# Exercise Module

## Purpose

Maintains the centralized exercise library.

## Responsibilities

- Create exercises
- Update exercises
- Prevent duplicate exercise names
- Search and filter exercises
- Provide measurement type metadata

## Main Entity

- Exercise

## Measurement Types

- weight_reps
- reps_only
- duration
- distance
- time_distance
- bodyweight
- machine_level
- hold_time
- amrap

## Business Rules

- Exercise name is required.
- Normalized exercise name must be unique.
- Slug must be unique.
- Measurement type controls valid set fields.
- Exercises used by historical workouts should not be hard deleted.
