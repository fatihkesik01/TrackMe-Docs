# Deployment

TrackMe is planned for Hostinger VPS hosting.

## Recommended Setup

- Docker
- Docker Compose
- Nginx reverse proxy
- HTTPS certificate
- PostgreSQL
- ASP.NET Core Web API container

## Runtime Components

```text
Nginx -> TrackMe API -> PostgreSQL
                 |
                 -> Firebase Cloud Messaging
```

## Environment Variables

- ASPNETCORE_ENVIRONMENT
- CONNECTION_STRINGS__POSTGRES
- JWT__ISSUER
- JWT__AUDIENCE
- JWT__SECRET
- JWT__ACCESS_TOKEN_MINUTES
- JWT__REFRESH_TOKEN_DAYS
- FCM__CREDENTIALS_PATH

## Deployment Rules

- HTTPS is required.
- Secrets must not be committed.
- Database backups must be scheduled.
- Logs must be retained.
- Migrations should run in a controlled deployment step.
- Production CORS settings must be restrictive.

## Docker Compose Draft

```yaml
services:
  api:
    image: trackme-api:latest
    restart: always
    environment:
      ASPNETCORE_ENVIRONMENT: Production
    depends_on:
      - postgres

  postgres:
    image: postgres:16
    restart: always
    environment:
      POSTGRES_DB: trackme
      POSTGRES_USER: trackme
      POSTGRES_PASSWORD: change_me
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```
