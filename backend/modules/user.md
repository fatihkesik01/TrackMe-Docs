# User Module

## Purpose

Manages base user data shared across roles.

## Responsibilities

- Manage user profile basics
- Manage account status
- Manage role assignments through admin workflows
- Provide user lookup for other modules

## Main Entities

- User
- Role
- UserRole

## Main Use Cases

- Get current user
- Update current user
- Change password
- Search users as admin
- Deactivate user as admin

## Business Rules

- Users must have at least one role.
- Users can update only their own base profile unless admin.
- Deactivated users cannot authenticate.
- Role changes must be audited.
