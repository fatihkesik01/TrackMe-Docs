# Direct Messaging

## Overview

TrackMe's messaging system enables direct text communication between users who have an established relationship. Messages support optional structured references to programs or exercises, allowing coaching conversations to be anchored to specific training content.

## Access Rules

To send or receive direct messages, the two users must have **either**:
1. An accepted coaching relationship (`trainer_athlete_relationships.status = 'Accepted'`), OR
2. An accepted social connection (`user_connections.status = 'Accepted'`)

Pending, rejected, or ended relationships do NOT grant messaging access. Attempting to send without either → 403.

---

## Data Model

### `direct_messages` Table

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid PK | |
| `sender_user_id` | uuid FK | → `users` |
| `recipient_user_id` | uuid FK | → `users` |
| `body` | string | message text |
| `is_read` | bool | recipient-specific |
| `read_at` | timestamptz? | |
| `created_at` | timestamptz | |
| `reference_type` | string? | `"program"` / `"exercise"` |
| `reference_id` | uuid? | program or exercise ID |
| `reference_title` | string? | snapshot of program/exercise name |
| `reference_day_id` | uuid? | for exercise refs: the program day |

Messages are stored between account users (`user_id`), not trainer/athlete profile rows. The backend resolves trainer and athlete profile entities by matching the caller's account email when applying relationship checks.

---

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/messages` | List conversations (one row per contact) |
| `GET` | `/api/messages/contacts` | List messageable contacts |
| `GET` | `/api/messages/unread-count` | Count of unread messages |
| `GET` | `/api/messages/{userId}` | Load thread with a specific user |
| `POST` | `/api/messages` | Send a message |
| `PATCH` | `/api/messages/{userId}/read` | Mark thread as read |
| `GET` | `/api/messages/{userId}/references` | List program/exercise refs available in this thread |

---

## Message References

A message may include one structured reference to training content:

```json
{
  "body": "Can you add more volume here?",
  "recipientUserId": "...",
  "referenceType": "exercise",
  "referenceId": "...",
  "referenceDayId": "..."
}
```

Reference constraints:
- The referenced program must belong to the accepted trainer-athlete coaching relationship between sender and recipient.
- Inactive (locked) programs cannot be referenced.
- References are resolved and validated server-side; `reference_title` is stored as a snapshot.

---

## Real-Time Delivery

When a message is sent:

1. A `direct_messages` row is created.
2. A `NewMessage` `app_notification` row is created for the recipient.
3. Both are committed atomically.
4. `message.created` is sent via SignalR to `Clients.User(recipientUserId)` with the full `DirectMessageDto`.
5. `notification.created` is sent via SignalR to the same user.

On the recipient's client:
- If the message thread is open: the new message is appended to the thread view.
- The conversation list row is updated with the new last message.
- If the thread is active and visible, the thread is marked read immediately.
- The unread message badge count is incremented.

---

## Read State

`is_read` and `read_at` are recipient-side fields. The sender never marks a message as read.

`PATCH /api/messages/{userId}/read` marks all messages from that user as read. Automatically called when:
- The user opens a thread in `MessagesView`
- A `message.created` event arrives while that thread is the active view

---

## Frontend

### MessagesView (`MessagesView.jsx`)

Two-panel layout (collapsed to single-panel on narrow screens):

**Left panel — conversation list:**
- Each row: contact avatar, name, last message preview, unread badge, timestamp
- Sorted by most recent message first
- "Contacts" tab shows all messageable contacts (including those with no thread yet)

**Right panel — thread:**
- Chronological message list
- Each message: avatar, sender name, body, time
- Reference pills for program/exercise references (clickable — navigates to the referenced content)
- Message input at bottom with optional reference picker
- "Send" sends immediately; Enter key also sends

**Reference picker:**
- Dropdown shows available programs + exercises from the active coaching relationship
- Only one reference per message

### Unread Badge

Displayed on the Messages nav item. Updated in real-time via `message.created` SignalR events. Cleared when the thread is opened.

### Coach Message References in ProgramBuilderView

The Program Builder shows a "Mesaj Gönder" shortcut that pre-populates the message compose dialog with a reference to the currently-viewed program day or exercise. This lets trainers send feedback directly anchored to a specific training day without switching to the Messages view.
