# Auth Module

## Purpose

Handles registration, login, refresh tokens, logout, current user identity, password hashing, and authentication-related security.

## Responsibilities

- Register users
- Authenticate credentials
- Issue JWT access tokens
- Issue and rotate refresh tokens
- Revoke refresh tokens
- Return current user identity
- Enforce password security

## Main Entities

- User
- Role
- UserRole
- RefreshToken

## Main Use Cases

- Register user
- Login user
- Refresh token
- Logout user
- Get current user
- Change password

## Business Rules

- Email must be unique.
- Password must be hashed.
- Refresh tokens must be stored hashed.
- Revoked refresh tokens cannot be reused.
- Access tokens should be short-lived.

## Events

- UserRegistered
- UserLoggedIn
- RefreshTokenRevoked
