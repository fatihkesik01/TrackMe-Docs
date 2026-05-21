# Trainer Module

## Purpose

Provides trainer-specific workflows for managing athletes, programs, notes, and performance review.

## Responsibilities

- List trainer athletes
- Review athlete workout history
- Review athlete analytics
- Create trainer notes
- Manage trainer-owned programs

## Main Use Cases

- Get my athletes
- Get athlete summary
- Get athlete workout history
- Add trainer note
- Get trainer dashboard

## Business Rules

- Trainer can access only accepted athletes.
- Trainer cannot view athlete data through pending relationships.
- Trainer notes must belong to an accepted relationship context.
- Trainer can manage only own programs unless admin.
