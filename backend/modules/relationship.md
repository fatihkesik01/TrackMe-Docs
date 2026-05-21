# Relationship Module

## Purpose

Manages many-to-many trainer-athlete relationships.

## Responsibilities

- Create connection requests
- Accept or reject requests
- Remove relationships
- Validate relationship-based access

## Main Entity

- TrainerAthleteRelation

## States

- Pending
- Accepted
- Rejected
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
