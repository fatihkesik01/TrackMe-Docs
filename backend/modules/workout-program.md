# Workout Program Module

## Purpose

Allows trainers to create, update, and assign structured workout programs.

## Responsibilities

- Create workout programs
- Manage weeks, days, exercises, and planned sets
- Assign programs to athletes
- Notify athletes about updates

## Main Entities

- WorkoutProgram
- WorkoutProgramWeek
- WorkoutProgramDay
- WorkoutProgramExercise
- WorkoutProgramExerciseSet
- WorkoutProgramAssignment

## Main Use Cases

- Create program
- Update program
- Add week
- Add day
- Add exercise
- Assign program
- Remove assignment

## Business Rules

- Only trainers can create programs.
- Programs can be assigned only to accepted athletes.
- Program exercises must reference library exercises.
- Target RPE must be between 1 and 10 when provided.
- Program update should notify assigned athletes.
