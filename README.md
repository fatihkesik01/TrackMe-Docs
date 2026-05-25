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

## Detailed References

- [Backend Modules](backend/modules/README.md)
- [Database ERD](database/erd.md)
- [PostgreSQL Schema Draft](database/schema.sql)
- [API OpenAPI Draft](api/openapi-draft.yaml)
- [Mobile Screens](mobile/screens.md)
- [Mobile Navigation](mobile/navigation.md)
- [Mobile State Management](mobile/state-management.md)
- [Business Rules Index](business-rules/README.md)

## Core Stack

- Mobile: React Native for Android and iOS
- Web App: React.js
- Backend: ASP.NET Core Web API
- Database: PostgreSQL
- Authentication: JWT, refresh tokens, role based authorization
- Hosting: Hostinger VPS, Docker, Nginx, HTTPS

## Application Repositories

- TrackMe Docs: `https://github.com/fatihkesik01/TrackMe-docs`
- TrackMe Mobile App: `https://github.com/fatihkesik01/TrackMe-mobile`
- TrackMe Web App: `https://github.com/fatihkesik01/TrackMe-web`
- TrackMe API: `https://github.com/fatihkesik01/TrackMe-api`

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
