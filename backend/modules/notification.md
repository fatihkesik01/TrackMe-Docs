# Notification Module

## Purpose

Manages in-app notifications and realtime Web delivery.

## Responsibilities

- Create notifications
- Mark notifications as read
- Deliver active Web notifications through SignalR
- Store notification history
- Keep REST endpoints as the source of truth for reconnect recovery

## Main Entity

- Notification

## Notification Types

- `RelationshipRequest`
- `RelationshipAccepted`
- `RelationshipRejected`
- `RelationshipEnded`
- `ProgramAssigned`
- `WorkoutCompleted`

## Business Rules

- Notification belongs to one user.
- Users can read only own notifications.
- SignalR delivery failure must not roll back main transactions.
- Important notifications must be stored in-app.
- User retention only hides old read notifications from the Web topbar dropdown.
- Unread notifications are never hidden by age.
- The Notifications page shows the full loaded notification history.

## Realtime Delivery

- Hub: `/hubs/notifications`
- Auth: JWT bearer token
- Client event: `notification.created`
- Server target: `Clients.User(userId)`
- Web clients refresh app data after relationship/program/workout notifications so currently-open screens reflect changed access, active/passive programs, and session state.

Firebase/mobile push is a future enhancement and is not active in the current deployment.
