# Agent Instructions

## Documentation Discipline

Keep this repository as the current documentation source of truth for TrackMe.

When updating docs:

- Keep only documentation that reflects the current API, Web app, database schema, business rules, and deployment model.
- Remove or rewrite stale roadmap, phase, plan, UX note, and draft files when they conflict with current docs.
- Prefer one source of truth over duplicate summaries.
- Do not add new planning documents unless the user explicitly asks for a plan or roadmap.
- Do not touch TrackMe-Mobile or mobile documentation unless the task explicitly targets mobile.

When a code task in `../TrackMe-Web` or `../TrackMe-Api` changes documented behavior, update the relevant docs here as part of the same task.

## Migration Documentation Discipline

When `../TrackMe-Api` changes the database schema:

- Keep `database/migration-strategy.md`, `docs/03-backend-architecture.md`, `docs/06-database-design.md`, and `database/erd.md` aligned with the actual EF model and migration files.
- Document the migration name and table/relationship changes.
- Do not describe hand-written migration workflows. TrackMe migrations must be generated with `dotnet ef migrations add` from the API project.
