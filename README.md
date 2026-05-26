# TrackMe Docs

TrackMe is a mobile workout tracking and coach-athlete management platform.

This repository contains the product, architecture, database, API, module, mobile, and business rule documentation required to design and build TrackMe as a scalable system.

## Documentation Map

- [Project Overview](docs/00-project-overview.md)
- [Product Vision](docs/01-product-vision.md)
- [System Architecture](docs/02-system-architecture.md)
- [Backend Architecture](docs/03-backend-architecture.md)
- [Mobile Architecture](docs/04-mobile-architecture.md)
- [Web App Architecture](docs/04-web-architecture.md)
- [Database Design](docs/05-database-design.md)
- [API Analysis](docs/06-api-analysis.md)
- [Business Rules](docs/07-business-rules.md)
- [Module Overview](docs/08-modules-overview.md)
- [Authentication and Authorization](docs/09-auth-authorization.md)
- [Admin System](docs/10-admin-system.md)
- [Trainer-Athlete Relationship](docs/11-trainer-athlete-relationship.md)
- [Workout Program Analysis](docs/12-workout-program-analysis.md)
- [Workout Tracking Analysis](docs/13-workout-tracking-analysis.md)
- [RPE and Analytics](docs/14-rpe-analytics.md)
- [Notification System](docs/15-notification-system.md)
- [Deployment](docs/16-deployment.md)
- [Security and Validation](docs/17-security-validation.md)
- [Future Roadmap](docs/18-future-roadmap.md)
- [Development Day 1](docs/19-development-day-1.md)

## Detailed References

- [Backend Modules](backend/modules/README.md)
- [Database ERD](database/erd.md)
- [EF Core Migration Strategy](database/migration-strategy.md)
- [API OpenAPI Draft](api/openapi-draft.yaml)
- [Mobile Screens](mobile/screens.md)
- [Mobile Navigation](mobile/navigation.md)
- [Mobile State Management](mobile/state-management.md)
- [Business Rules Index](business-rules/README.md)

## Core Stack

- Mobile: React Native for Android and iOS
- Web App: React.js
- Backend: ASP.NET Core 10 Web API
- Database: PostgreSQL
- Persistence: Entity Framework Core migrations
- Authentication: JWT, refresh tokens, role based authorization
- Hosting: Hostinger VPS and Docker Compose
- API reference: Scalar over the generated OpenAPI document

## Current VPS Runtime

The current MVP deployment runs directly on the VPS IP without a domain or Nginx reverse proxy.

- Web: `http://187.77.92.30:8080`
- API: `http://187.77.92.30:5050`
- Health: `http://187.77.92.30:5050/health`
- Scalar API reference: `http://187.77.92.30:5050/scalar/v1`
- OpenAPI JSON: `http://187.77.92.30:5050/openapi/v1.json`
- PostgreSQL: internal Docker network plus `127.0.0.1:15432` on the VPS for SSH tunnel access only

Nginx and HTTPS are deferred until a domain is attached.

## Application Repositories

- TrackMe Docs: `https://github.com/fatihkesik01/TrackMe-Docs`
- TrackMe Mobile App: `https://github.com/fatihkesik01/TrackMe-Mobile`
- TrackMe Web App: `https://github.com/fatihkesik01/TrackMe-Web`
- TrackMe API: `https://github.com/fatihkesik01/TrackMe-Api`

## Core Roles

- Admin
- Trainer
- Athlete

## Core Principles

- Simple first
- Mobile-first workflow
- Fast workout logging
- Modular backend boundaries
- Relational consistency
- Audit-friendly tracking
- Trainer-focused coaching flows
- Reliable analytics data
