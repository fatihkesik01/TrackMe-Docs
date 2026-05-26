# Development Day 2

Day 2 goal is to make trainer-athlete relationships explicit instead of treating every athlete as globally available.

The focus is relationship requests, accepted coaching access, and preparing ownership checks for future security hardening.

## Current Baseline

- Users can register and login with JWT.
- Trainer and athlete profiles are created from role-based registration.
- Trainers can create athletes and programs.
- Athletes can create self-guided programs.
- Sessions can optionally link to programs.
- API and Web deploy through GitHub Actions.

## Day 2 Scope

- Add trainer-athlete relationship records.
- Support pending, accepted, and rejected relationship states.
- Let trainers request access to athletes.
- Let athletes accept or reject requests.
- Use accepted relationships as the basis for trainer athlete lists.
- Keep current MVP flows usable while ownership rules are introduced.

## API Tasks

- [ ] Add `TrainerAthleteRelationship` entity.
- [ ] Add `RelationshipStatus` enum: `Pending`, `Accepted`, `Rejected`.
- [ ] Add EF Core configuration for relationship table.
- [ ] Add unique index for `trainer_id + athlete_id`.
- [ ] Create EF Core migration.
- [ ] Add `POST /api/relationships/requests`.
- [ ] Add `GET /api/relationships/requests`.
- [ ] Add `POST /api/relationships/{id}/accept`.
- [ ] Add `POST /api/relationships/{id}/reject`.
- [ ] Add `GET /api/trainers/me/athletes`.
- [ ] Return relationship status in relevant DTOs.
- [ ] Prevent duplicate active relationship requests.
- [ ] Require trainer role for creating relationship requests.
- [ ] Require athlete ownership for accepting or rejecting requests.
- [ ] Keep admin bypass rules documented but not fully implemented unless needed.

## Web Tasks

- [ ] Add relationship request UI for trainers.
- [ ] Show pending requests for athlete users.
- [ ] Add accept and reject actions.
- [ ] Show accepted trainer-athlete relationship state.
- [ ] Update athlete roster to distinguish accepted, pending, and unassigned athletes.
- [ ] Use accepted athletes in trainer program/session workflows where possible.
- [ ] Keep self-guided athlete program flow available.

## Database Tasks

- [ ] Verify migration creates `trainer_athlete_relationships`.
- [ ] Confirm unique pair index works.
- [ ] Confirm status values are stored clearly.
- [ ] Confirm existing users/trainers/athletes/programs/sessions survive migration.
- [ ] Verify accepted relationship rows in DBeaver.

## Docs Tasks

- [ ] Update database design with relationship table.
- [ ] Update API analysis with relationship endpoints.
- [ ] Update trainer module docs.
- [ ] Update athlete module docs.
- [ ] Update access rules with accepted relationship ownership.
- [ ] Record any MVP shortcuts clearly.

## Acceptance Criteria

Day 2 is complete when:

- A trainer can send a relationship request to an athlete.
- An athlete can see pending relationship requests.
- An athlete can accept or reject a request.
- Accepted relationships appear in trainer athlete list.
- Duplicate relationship requests are blocked.
- GitHub Actions deploy succeeds after relationship changes.
- DBeaver confirms relationship rows and statuses.
- Docs reflect the implemented relationship behavior.

## Out Of Scope For Day 2

- Chat or messaging.
- Notifications or push delivery.
- Full admin relationship management.
- Advanced invitation links.
- Email-based invite flow.
- Fine-grained analytics permissions.
- Mobile implementation.

## Implementation Notes

- A trainer can also be an athlete of another trainer.
- An athlete can have multiple accepted trainers.
- A trainer can only manage athlete data after the relationship is accepted.
- Pending requests do not grant data access.
- Self-guided athlete programs remain allowed without a trainer relationship.

## Suggested Work Order

1. Add relationship entity and migration.
2. Implement request, list, accept, and reject endpoints.
3. Implement `GET /api/trainers/me/athletes`.
4. Verify API behavior with Scalar.
5. Add web UI for trainer request and athlete response.
6. Verify deploy and DBeaver data.
7. Update docs based on final endpoint names and DTOs.
