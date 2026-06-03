# Exercise Module

## Purpose

Maintains the centralized exercise library.

## Responsibilities

- Create exercises
- Update exercises
- Prevent duplicate exercise names
- Soft-delete exercises
- Search and filter exercises
- Provide category, muscle, equipment, difficulty, and instruction metadata

## Main Entity

- Exercise

## Current MVP Fields

- Name
- Slug
- Category
- Primary muscles
- Equipment
- Instructions
- Active status
- Created time

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
- Exercise category is required.
- Normalized exercise name must be unique.
- Slug must be unique.
- Measurement type controls valid set fields.
- Exercises used by historical workouts should not be hard deleted.
- Admin and trainer users can manage exercises.
- Athlete users can read active exercises.
- Muscles, equipment, and instructions are stored as editable text fields until a structured taxonomy is needed.
