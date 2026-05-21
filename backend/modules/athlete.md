# Athlete Module

## Purpose

Manages athlete profile, goals, availability, and athlete-facing workout data.

## Responsibilities

- Create and update athlete profile
- Store physical and training attributes
- List assigned programs
- List own workout history
- Show own analytics

## Main Entities

- AthleteProfile
- ProgressRecord

## Main Use Cases

- Get athlete profile
- Update athlete profile
- Get assigned programs
- Get own workout history
- Get own progress

## Business Rules

- Athlete profile belongs to one user.
- Athlete can edit only own profile unless admin.
- Injury notes are private to athlete, related trainers, and admin.
- Athlete can have multiple active trainers.
