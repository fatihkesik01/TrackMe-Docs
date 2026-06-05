# Message Module

## Purpose

Enables direct trainer-athlete messaging for users with an accepted coaching relationship.

## Responsibilities

- List messageable contacts from accepted trainer-athlete relationships
- List existing conversations
- Load a direct message thread
- Send direct messages
- List messageable program/exercise references for a thread
- Mark a thread as read
- Create realtime `NewMessage` notifications for recipients
- Deliver the created direct message to active Web clients through SignalR

## Main Entity

- DirectMessage

## API Surface

- `GET /api/messages`
- `GET /api/messages/contacts`
- `GET /api/messages/unread-count`
- `GET /api/messages/{userId}/references`
- `GET /api/messages/{userId}`
- `POST /api/messages`
- `PATCH /api/messages/{userId}/read`

## Business Rules

- Users can message only contacts with an accepted trainer-athlete relationship.
- Message access resolves trainer and athlete profile entities by matching the caller's account email.
- Pending, rejected, or ended relationships do not allow messaging.
- Direct messages are stored between account users, not trainer/athlete profile rows.
- Sending a message creates a `NewMessage` notification for the recipient.
- Sending a message also emits `message.created` to the recipient's SignalR user connection with the direct message DTO.
- Message read status is recipient-specific.
- Messages may include one structured reference to a program or a program-day exercise.
- Message references are only returned/accepted when the program belongs to the accepted trainer-athlete relationship; inactive programs cannot be referenced.
