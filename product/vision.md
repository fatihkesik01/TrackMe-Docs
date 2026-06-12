# TrackMe — Product Vision

## What TrackMe Is

TrackMe is a professional coaching and training management platform. It digitizes the trainer-athlete coaching relationship: structured programs, real-time workout logging, performance analytics, and a rich feedback loop — images, videos, audio, and messages — all in one place.

TrackMe is not a casual gym logging app. The primary focus is on the coaching workflow: a trainer writes a program, an athlete executes it, the system captures the data, and both parties see meaningful results.

## Target Users

### Athlete
- Follows assigned or self-guided programs
- Logs workouts set by set via Workout Mode
- Records RPE, body metrics, progress photos
- Views analytics: volume trends, RPE trends, streak, PRs
- Sends form videos and progress photos to their trainer
- Receives video, audio, and text feedback

### Trainer
- Creates structured programs for athletes
- Uses templates to speed up repeated patterns
- Monitors athlete compliance, RPE, and progress
- Sends video, audio, and image feedback
- Views athlete analytics and performance history
- Copies public programs to assign to their athletes

### Gym / Club _(planned)_
- Multi-gym memberships
- Gym-specific coaches, feed, and leaderboard

### Admin
- Manages users, roles, exercise library
- Reviews reported content and makes moderation decisions
- Views platform-wide audit logs

## Core Design Principles

**Professional first.** TrackMe should feel like a tool a serious trainer would pay for. Not a social network with workout features bolted on.

**Fast logging.** An athlete starting a workout should reach the logging screen in under two taps. Logging a set should be one interaction.

**Coaching relationship is the access gate.** An accepted coaching relationship unlocks program access, session data, analytics, body metrics, and the media feedback loop. A social connection provides messaging and privacy-filtered profile viewing only. The two are independent.

**Single media model.** Every image, video, and audio file — regardless of context — flows through the `MediaAsset` entity. Avatars, cover photos, progress photos, submission videos, feedback videos, exercise demos: all use the same ownership, visibility, lifecycle, and storage model.

**Data integrity over convenience.** Workout history is permanent. Programs can be locked, not deleted. Exercise library uses soft deletes. Copied programs are independent forks — original edits never silently propagate downstream.

## Non-Goals

- TrackMe does not start as an AI workout generator
- Social media features do not take priority over coaching workflows
- Unstructured notes are not the primary data model
- Inconsistent exercise naming that damages analytics quality is not acceptable
- Ads in Workout Mode or in the private coaching feedback flow

## Product Personality

| Quality | Meaning |
|---------|---------|
| Professional | A tool trainers pay for, not a hobby app |
| Fast | Minimal friction from "open app" to "log set" |
| Clean | No clutter; every screen has a clear purpose |
| Reliable | Data never disappears; migrations never break sessions |
| Modern | Dark mode, i18n, real-time notifications |

## Key Architectural Decisions

These decisions are locked. New features must respect them.

| Decision | Rationale |
|----------|-----------|
| Coaching relationship ≠ social connection | Prevents accidental data leakage. Coaches get program/session/analytics access; social friends get profile/messages only. |
| MediaAsset for all binary content | Avoids N separate upload/delete/storage patterns. One model, one storage provider interface. |
| Copied programs are independent forks | Original updates should not silently break an athlete's current training cycle. |
| Program snapshot on publish | Public programs expose exercise names and structure, never target weights or personal performance data. |
| EF Core snake_case convention | All DB columns use explicit `HasColumnName()` mapping. Migrations are always CLI-generated, never hand-written. |
| Dual-role via email lookup | A single account can be both Trainer and Athlete. The backend resolves trainer identity by email, not JWT role. |
| Auto-migrate on startup | `MigrateAsync()` runs at API startup with retries. No manual `dotnet ef database update` in production. |

## Vision Timeline

### Current (Live)
- Full coaching workflow: programs, sessions, analytics, relationships
- Social connections, follow/discovery, public programs
- Media: avatar, cover photo, program cover photo
- Notifications (in-app + SignalR real-time)
- Direct messaging with program references
- Body metrics, personal records, consistency tracking

### 6-Month Horizon
- Progress photos: upload, timeline, before/after comparison, trainer visibility controls
- Exercise demo videos attached to exercises and program days
- Athlete submission videos for form review
- Trainer feedback videos and audio notes
- Media reporting and admin moderation

### 12-Month Horizon
- React Native mobile app (MVP)
- Full video/audio coaching workflow on mobile
- Camera capture, resumable uploads, offline session draft
- PR evidence videos
- Basic AI-assisted program draft generation

### 24-Month Horizon
- Multi-gym system: members, coaches, gym feed, gym leaderboard
- Global leaderboard with verified PRs
- Advanced AI coaching suggestions
- Subscription model (trainer plans, gym plans)
- Optional ad placements (feed/discovery only — never coaching or workout flows)
