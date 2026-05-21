# Web App Architecture

The web app should be built with React.js.

Repository: `TrackMe-app`

The web app should focus on workflows that benefit from larger screens, tables, filters, reports, and management views.

## Primary Users

- Admin
- Trainer

Athletes may use the web app later, but the first product priority for athletes is the mobile app.

## Web Responsibilities

- Admin user management
- Trainer and athlete management
- Exercise library management
- Reports and logs
- Program builder workflows
- Athlete progress review
- Notification management

## Suggested Project Structure

```text
TrackMe-app/
  src/
    app/
    features/
      auth/
      dashboard/
      admin/
      trainers/
      athletes/
      exercises/
      programs/
      analytics/
      notifications/
    components/
    services/
      api/
      auth/
    routes/
    store/
    types/
  public/
```

## Web UI Principles

- Prioritize dense but readable management screens.
- Use tables, filters, search, tabs, and detail panels.
- Keep admin actions auditable and explicit.
- Avoid marketing-style landing pages inside the app.
- Keep business logic in the API, not in the web client.

## API Integration

The web app consumes the same `TrackMe-api` endpoints as the mobile app.

Authorization rules remain server-side:

- Admin can access platform management.
- Trainer can access accepted athletes and own programs.
- Athlete web access, if added later, must stay limited to own data.
