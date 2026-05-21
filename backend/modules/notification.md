# Notification Module

## Purpose

Manages in-app and push notifications.

## Responsibilities

- Create notifications
- Mark notifications as read
- Send push notifications
- Store notification history
- Handle push delivery failure

## Main Entity

- Notification

## Notification Types

- ProgramUpdated
- WorkoutReminder
- WorkoutCompleted
- TrainerNoteAdded
- AthleteMissedWorkout
- ConnectionRequestReceived
- ConnectionRequestAccepted

## Business Rules

- Notification belongs to one user.
- Users can read only own notifications.
- Push failure must not roll back main transactions.
- Important notifications must be stored in-app.
