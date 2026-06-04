# Notification Rules

- Notifications belong to one recipient user.
- Users can read only their own notifications.
- Important events should create in-app notifications.
- Push notification failure should be logged.
- Push notification failure should not fail the primary business transaction.
- Read state is per recipient.
- Read-notification retention is a Web topbar display rule, not database deletion.
- Unread notifications must stay visible in the topbar regardless of age.
- The full Notifications page must not apply the topbar retention filter.
- Completing a trainer-owned workout as an athlete should notify that trainer.
