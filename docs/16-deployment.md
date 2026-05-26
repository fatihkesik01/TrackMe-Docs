# Deployment

TrackMe is hosted on a Hostinger VPS with Docker Compose.

The current MVP runs directly on the VPS IP and explicit ports. A domain, HTTPS, and optional reverse proxy can be added later without changing the application split.

## Current Setup

- Docker
- Docker Compose
- PostgreSQL
- ASP.NET Core 10 Web API container
- React web container

## Current URLs

- Web: `http://187.77.92.30:8080`
- API: `http://187.77.92.30:5050`
- Health check: `http://187.77.92.30:5050/health`
- Scalar API reference: `http://187.77.92.30:5050/scalar/v1`
- OpenAPI JSON: `http://187.77.92.30:5050/openapi/v1.json`
- PostgreSQL tunnel target: `localhost:15432` through SSH to the VPS

## Runtime Components

```text
Browser -> TrackMe Web container :8080
       -> TrackMe API container :5050 -> PostgreSQL container
```

## Environment Variables

- ASPNETCORE_ENVIRONMENT
- ConnectionStrings__Postgres
- POSTGRES_DB
- POSTGRES_USER
- POSTGRES_PASSWORD
- TRACKME_CONNECTION
- TRACKME_WEB_ORIGIN
- TRACKME_API_PORT
- TRACKME_POSTGRES_BIND
- TRACKME_POSTGRES_PORT
- JWT__ISSUER
- JWT__AUDIENCE
- JWT__SECRET
- JWT__ACCESS_TOKEN_MINUTES
- JWT__REFRESH_TOKEN_DAYS
- FCM__CREDENTIALS_PATH

## Deployment Rules

- HTTPS is required once a real domain is attached.
- Secrets must not be committed.
- Database backups must be scheduled.
- Logs must be retained.
- EF Core migrations should run in a controlled deployment step.
- Production CORS settings must be restrictive.

## Auto Deploy

`TrackMe-Api` and `TrackMe-Web` deploy from GitHub Actions on pushes to `main`.

The workflows SSH into the VPS as the `deploy` user, update the repository under `/opt/trackme`, rebuild Docker images, and restart containers.

API deploy also runs EF Core migrations before rebuilding the API container.

Required GitHub Actions secrets:

- `VPS_HOST`: `187.77.92.30`
- `VPS_USER`: `deploy`
- `VPS_PORT`: `22` or omitted
- `VPS_SSH_KEY`: private key that can SSH into the VPS as `deploy`

## VPS Layout

```text
/opt/trackme/TrackMe-Api
/opt/trackme/TrackMe-Web
```

Current containers:

- `trackme-web`
- `trackme-api`
- `trackme-postgres`

The previous Sera containers may still exist on the same VPS and should not be touched unless intentionally decommissioned.

## Docker Compose Shape

```yaml
services:
  postgres:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-trackme}
      POSTGRES_USER: ${POSTGRES_USER:-trackme}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-trackme_dev_password}
    ports:
      - "${TRACKME_POSTGRES_BIND:-127.0.0.1}:${TRACKME_POSTGRES_PORT:-15432}:5432"
    volumes:
      - trackme-postgres-data:/var/lib/postgresql/data

  api:
    build:
      context: .
      dockerfile: Dockerfile
    restart: unless-stopped
    environment:
      ASPNETCORE_ENVIRONMENT: Production
      ConnectionStrings__Postgres: ${TRACKME_CONNECTION}
      Cors__AllowedOrigins__0: ${TRACKME_WEB_ORIGIN}
    ports:
      - "${TRACKME_API_PORT:-5050}:8080"
    depends_on:
      postgres:
        condition: service_healthy

volumes:
  trackme-postgres-data:
```

## DBeaver Access

PostgreSQL is not exposed publicly. Use DBeaver with SSH tunnel:

Database tab:

- Host: `localhost`
- Port: `15432`
- Database: `trackme`
- Username: `trackme`

SSH tab:

- Host/IP: `187.77.92.30`
- Port: `22`
- User Name: `deploy`
- Authentication: password or key
