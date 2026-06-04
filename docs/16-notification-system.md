# Notification System

Notifications are important for trainer-athlete communication.

## Notification Channels

- In-app notifications stored in PostgreSQL
- Realtime web delivery through SignalR (`/hubs/notifications`)

Push notifications through Firebase Cloud Messaging are not active in the current Web/API deployment.

## Notification Types

- `RelationshipRequest`
- `RelationshipAccepted`
- `ProgramAssigned`
- `WorkoutCompleted`

## Notification Data

- User ID
- Type
- Title
- Body
- Is read
- Created at
- Read at

## Notification Rules

- Notification ownership is always per user.
- Read status belongs to the recipient.
- New in-app notifications are sent to active Web clients through SignalR after the database transaction succeeds.
- Realtime delivery failure should not roll back the main transaction.
- Clients still load `/api/notifications` on boot, so missed realtime events are recovered from the database.
- Notifications are not physically deleted by the user retention setting.
- `users.read_notification_retention_days` controls only the top-right Web notification dropdown. Read notifications older than this value are hidden from that dropdown; unread notifications are never hidden by age.
- The dedicated Notifications page shows the full loaded notification history regardless of dropdown retention.

## Event Sources

- Relationship request created
- Relationship request accepted
- Program assigned
- Athlete completes an in-progress workout from WorkoutMode; the trainer who owns the linked program receives `WorkoutCompleted`

## Web Delivery Flow

1. The API creates an `AppNotification` row.
2. After `SaveChangesAsync()` succeeds, the API sends `notification.created` to `Clients.User(userId)`.
3. The Web app connects to `/hubs/notifications` with the JWT access token.
4. Incoming notifications are prepended to Web notification state and show a toast.
5. If the browser was offline or disconnected, the next `/api/notifications` fetch restores the current state.
6. The topbar dropdown applies read-notification retention locally; the Notifications page does not.

## Background Jobs

Suggested background jobs:

- Workout reminder dispatcher
- Missed workout detector
- Push retry processor
- Notification archival, if a long-term storage policy is needed later

## Future Enhancements

- Add related entity metadata (`relatedEntityType`, `relatedEntityId`, `actionUrl`) so notification clicks can deep-link to the exact program, relationship, session, or note.
- Add FCM/mobile push delivery after the mobile app is active.
- Add admin/system broadcast notifications.
