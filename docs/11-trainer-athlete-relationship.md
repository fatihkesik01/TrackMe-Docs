# Trainer-Athlete Relationship

The trainer-athlete relationship system is one of the core systems of TrackMe.

## Relationship Type

Trainer to athlete is many-to-many.

This allows:

- One trainer to manage many athletes.
- One athlete to work with multiple trainers.
- Specialized coaching setups such as fitness coach, conditioning coach, and rehab specialist.

## Relationship States

- Pending
- Accepted
- Rejected
- Cancelled
- Removed

## Relationship Rules

- Pending requests do not grant access to athlete data.
- Accepted relationships grant trainer access to relevant athlete data.
- Trainers can create programs for accepted athletes.
- Athletes can review active trainers.
- Either side can remove the relationship.
- Removed relationships should preserve historical records.

## Access Implications

When accepted, the trainer can:

- View athlete profile
- View workout history
- View progress analytics
- Assign workout programs
- Add trainer notes
- Receive workout completion notifications

The athlete can:

- View trainer profile
- Receive assigned programs
- Receive trainer notes
- Receive program update notifications
