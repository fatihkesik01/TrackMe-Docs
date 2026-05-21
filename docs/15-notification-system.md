# Notification System

Notifications are important for trainer-athlete communication.

## Notification Channels

- In-app notifications
- Push notifications through Firebase Cloud Messaging

## Notification Types

- Trainer updated your program
- Workout reminder
- Workout completed
- Trainer note added
- Athlete completed workout
- Athlete missed workout
- Connection request accepted
- Connection request received

## Notification Data

- User ID
- Type
- Title
- Message
- Related entity type
- Related entity ID
- Is read
- Created at

## Notification Rules

- Notification ownership is always per user.
- Read status belongs to the recipient.
- Failed push delivery should be logged.
- Failed push delivery should not roll back the main transaction.
- Important notifications should still appear in-app even if push fails.

## Event Sources

- Relationship request created
- Relationship request accepted
- Program assigned
- Program updated
- Workout completed
- Trainer note added
- Missed workout detected

## Background Jobs

Suggested background jobs:

- Workout reminder dispatcher
- Missed workout detector
- Push retry processor
- Notification cleanup or archival
