# Notifications

## Overview

Notifications inform users about events that require attention: coaching requests, program assignments, workout completions, new messages, and social events. All notifications are persisted to the database and optionally delivered in real-time via SignalR.

## Channels

| Channel | Status |
|---------|--------|
| In-app (PostgreSQL persistence) | ✅ Live |
| Real-time web (SignalR `/hubs/notifications`) | ✅ Live |
| Mobile push (FCM/APNs) | 🔲 Planned (when mobile app ships) |

SignalR delivery failure does NOT roll back the database transaction. Clients recover missed real-time events from `GET /api/notifications` on reconnect or boot.

---

## Notification Types

| Enum value | Int | Trigger |
|-----------|-----|---------|
| `RelationshipRequest` | 1 | Coaching request sent |
| `RelationshipAccepted` | 2 | Coaching request accepted |
| `RelationshipRejected` | 3 | Coaching request rejected |
| `RelationshipEnded` | 4 | Coaching relationship ended |
| `ProgramAssigned` | 5 | Trainer created a program for athlete |
| `WorkoutCompleted` | 6 | Athlete completed a workout (trainer notified) |
| `NewMessage` | 7 | New direct message received |
| `ConnectionRequest` | 8 | Social connection request sent |
| `ConnectionAccepted` | 9 | Social connection request accepted |
| `ConnectionRejected` | 10 | Social connection request rejected |
| `ConnectionEnded` | 11 | Social connection ended |
| `NewFollower` | 12 | Someone followed the user |
| `ProgramUpdateAvailable` | 13 | Publisher released a new program version |

---

## `app_notifications` Table

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid PK | |
| `user_id` | uuid FK | recipient user |
| `sender_user_id` | uuid? FK | who triggered the event |
| `sender_name` | string? | snapshot of sender name |
| `sender_role` | string? | snapshot of sender role |
| `type` | int | `NotificationType` enum value |
| `title` | string | localizable text (may be localized on storage for older rows) |
| `body` | string | detail text |
| `is_read` | bool | default false |
| `read_at` | timestamptz? | |
| `created_at` | timestamptz | |

---

## Delivery Flow

### Creating a notification (server-side)

```
1. EndpointHelpers.QueueNotificationAsync → creates AppNotification row
2. db.SaveChangesAsync() — commits atomically with the triggering event
3. EndpointHelpers.PushNotificationAsync → sends via SignalR
   (failure here is logged and swallowed — does not roll back)
```

### Real-time client events

| SignalR event | Payload | Effect on client |
|--------------|---------|-----------------|
| `notification.created` | `NotificationDto` | Prepend to notification state, show toast |
| `message.created` | `DirectMessageDto` | Append to active thread, update conversation list |

Relationship / program / workout notifications also trigger a **data refresh** so open screens reflect the new state (new relationship, new program, session just completed) without a browser refresh.

`NewMessage` notifications update the unread message badge. When the user opens the notification, they are routed to the Messages page.

---

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/notifications` | List caller's notifications (paginated) |
| `PATCH` | `/api/notifications/{id}/read` | Mark one notification as read |
| `PATCH` | `/api/notifications/read-all` | Mark all as read |
| `DELETE` | `/api/notifications/{id}` | Delete one notification |

---

## Retention & Visibility Rules

- **Unread notifications** are never hidden by age anywhere in the UI.
- **Read-notification retention** (`users.read_notification_retention_days`): controls the topbar dropdown only. Read notifications older than this value are hidden from the dropdown — they are NOT deleted from the database.
- **Notifications page** (`NotificationsView.jsx`): shows the full loaded history, ignoring the topbar retention filter.
- Physical deletion is not user-triggered. Old notifications remain in the database until a future archival policy is implemented.

---

## Frontend

### Topbar Bell Icon

- Badge shows unread count.
- Dropdown shows recent notifications (respects read retention setting).
- Clicking a notification marks it as read + navigates to relevant view.
- "Tümünü Okundu İşaretle" button for bulk mark-read.

### NotificationsView (`NotificationsView.jsx`)

Full-page notification center accessible from the sidebar nav.

**Filter chips row** (`filter-chips-row` CSS pattern):
- Tümü (All)
- Sosyal (social: connections, follows)
- Koçluk (coaching: relationships, programs, workouts)
- Mesajlar (messages: NewMessage)
- Programlar (programs: ProgramAssigned, ProgramUpdateAvailable)

**Unread items**: `.data-list-item.notification-unread` class — light blue background with left accent border.

**Search**: searches across localized title/body, notification type string, and original stored text. Older English-language notification rows render in the active UI language via `notificationText.js` which maps type + body patterns to localized strings.

**Each notification row shows:**
- Sender avatar (UserAvatar component)
- Title + body text
- Time ago label
- Unread dot
- Read / Delete actions

---

## Background Jobs (Planned)

- **Workout reminder dispatcher** — remind athlete when a program day is scheduled for today but no session started
- **Missed workout detector** — detect days with no session after the planned date
- **Push retry processor** — retry failed FCM/APNs pushes (when mobile active)
- **Notification archival** — soft-archive very old read notifications
