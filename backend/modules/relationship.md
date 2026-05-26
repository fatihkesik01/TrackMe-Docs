# Relationship Module

## Purpose

Manages many-to-many trainer-athlete relationships.

## Responsibilities

- Create connection requests
- Accept or reject requests
- Remove relationships
- Validate relationship-based access

## Main Entity

- TrainerAthleteRelationship

## States

Current MVP:

- Pending
- Accepted
- Rejected

Target lifecycle:

- Cancelled
- Removed

## Main Use Cases

- Request connection
- Accept connection
- Reject connection
- Remove relationship
- List relationships

## Business Rules

- Pending relationships do not grant data access.
- Accepted relationships grant trainer access to athlete training data.
- Duplicate active requests are not allowed.
- Removed relationships preserve historical programs and workout data.
- Day 2 uses a unique trainer-athlete pair, so a rejected pair cannot be recreated until the lifecycle is expanded.
- Day 3 verifies accepted relationships as the gate for trainer-created programs and sessions.
- Trainers request athlete access through search/autocomplete instead of seeing the full athlete directory.
- A relationship request may target an existing athlete id or an active trainer/athlete user email. If the target user is a trainer without an athlete profile, the API creates the athlete profile for that user.
- A trainer who is the athlete side of a relationship can accept or reject the request through matching email ownership.
