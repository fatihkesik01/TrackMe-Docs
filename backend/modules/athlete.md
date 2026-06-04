# Athlete Module

## Purpose

Manages athlete profile, goals, availability, and athlete-facing workout data.

## Responsibilities

- Create and update athlete profile
- Store physical and training attributes
- List assigned programs
- List own workout history
- Show own analytics
- Manage featured exercise showcase list

## Main Entities

- Athlete
- AthleteFeaturedExercise

## Main Use Cases

- Get athlete profile
- Update athlete profile
- Review pending trainer requests
- Accept or reject trainer requests
- Get assigned programs
- Get own workout history
- Get own progress
- Add / remove exercises from featured list (unlimited, same exercise allowed multiple times)

## Business Rules

- Athlete profile belongs to one user.
- Athlete can edit only own profile unless admin.
- Athlete can create self-guided programs without a trainer.
- A coach can also be an athlete under another coach.
- Injury notes are private to athlete, related trainers, and admin.
- Athlete can have multiple active trainers.
- Pending trainer requests do not grant trainer access until the athlete accepts.
- Featured exercise list has no upper limit; the same exercise can appear multiple times with different sessions.
- Trainers with an accepted relationship can read (not modify) an athlete's featured exercise list.
