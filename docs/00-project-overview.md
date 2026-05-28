# Project Overview

TrackMe is a coach-athlete training management platform. It enables trainers to create and assign workout programs, monitor athlete progress, and manage coaching relationships. Athletes log sessions, track body measurements, and follow their programs.

## Core User Roles

| Role | Primary Activities |
|------|-------------------|
| **Admin** | Manage all users, manage exercise library, view system stats |
| **Trainer** | Manage athlete roster via relationships, create programs per athlete, view athlete analytics |
| **Athlete** | Follow assigned programs, log workout sessions, track body metrics |

### Dual-Role User

A single registered account can function as both Trainer and Athlete. The account's JWT role is `Athlete`, but a Trainer entity linked by email also exists. The frontend switches context via the `uiRole` toggle (Sporcu / Antrenör). The backend resolves the trainer entity via email lookup on any trainer-scoped operation.

## Architecture Summary

```
Browser / Web App (React + Vite)
        │  HTTP + JWT
        ▼
ASP.NET Core 10 Minimal API
        │  EF Core + Npgsql
        ▼
PostgreSQL 16
```

## Navigation — Current Structure

### Trainer UI

| Menu Item | View |
|-----------|------|
| Kontrol Paneli | Dashboard — trainer stats (athletes, active programs, weekly sessions) |
| Sporcular | Athlete list → Athlete Detail (tabs: Overview, Programs, Sessions, Progress) |
| Programlarım | Trainer's program library + Program Builder |
| Egzersizler | Exercise library |
| İlişkiler | Relationship requests (send / accept / reject) |
| Profil | Account settings |

### Athlete UI

| Menu Item | View |
|-----------|------|
| Kontrol Paneli | Dashboard — personal stats (streak, weekly sessions, duration) |
| Programım | Athlete's programs + Program Builder |
| Antrenmanlar | Session log + log new session |
| Vücut Ölçüleri | Body measurement history + log new measurement |
| İlişkiler | Invite trainer / manage relationships |
| Profil | Account settings |

### Admin UI

| Menu Item | View |
|-----------|------|
| Kontrol Paneli | System stats |
| Sporcular | Full athlete list |
| Antrenmanlar | Full session list |
| Egzersizler | Exercise management |
| Profil | Account settings |
| Admin | User management, exercise audit |

## Key Flows

### Program Flow

```
Trainer opens Athlete Detail → Programs tab
→ Create Program (title, dates, description)
→ Program Builder: Add Days → Add Exercises per Day
  (sets / reps / target weight / RPE / rest seconds)
→ Athlete sees program in "Programım"
→ Athlete starts a workout day → WorkoutMode overlay
```

### Session / Workout Flow

```
Athlete selects Program Day → Start Workout
→ WorkoutMode overlay opens
→ Log each set: reps + weight + RPE
→ Complete Workout → session created with duration + overall RPE
→ Session appears in history and in analytics
```

### Relationship Flow

```
Trainer searches for athlete → Send access request
  OR
Athlete searches for trainer → Send invite
→ Status: Pending
→ Recipient accepts or rejects
→ Accepted: athlete appears in trainer's Sporcularım list
```

## Feature Status

| Feature | Status |
|---------|--------|
| Auth (JWT + refresh tokens) | ✅ Live |
| Trainer-Athlete relationships | ✅ Live |
| Program builder (days + exercises) | ✅ Live |
| Workout mode (set-by-set logging) | ✅ Live |
| Session history + filtering | ✅ Live |
| Analytics (RPE trend, volume, consistency) | ✅ Live |
| Body metrics (9 measurement fields) | ✅ Live |
| Exercise library (global + private) | ✅ Live |
| In-app notifications | ✅ Live |
| Admin panel | ✅ Live |
| Dark mode + i18n (TR/EN) | ✅ Live |
| Mobile app (React Native) | 🔲 Planned |
| AI suggestions | 🔲 Planned |
