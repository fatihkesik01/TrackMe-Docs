# Project Overview

TrackMe is a mobile workout tracking and coach-athlete management application.

The purpose of TrackMe is not to generate AI workout programs. The primary goal is to provide a structured system where trainers and athletes can manage programs, track workouts, monitor performance, analyze RPE, and communicate efficiently.

## Main Roles

- Admin
- Trainer
- Athlete

## Main Capabilities

- Workout tracking
- Trainer-athlete management
- Workout program management
- RPE tracking
- Progress analytics
- Notifications
- Structured workout history

## Application Split

TrackMe is split into separate repositories:

- `TrackMe-mobilapp`: React Native mobile application for athletes and trainers.
- `TrackMe-app`: React.js web application, primarily for admin and trainer workflows.
- `TrackMe-api`: ASP.NET Core Web API backend.
- `TrackMe-docs`: Product and technical documentation.

## Product Direction

TrackMe should feel like a professional training management system instead of a generic gym logging application.

It should support:

- General fitness users
- Professional athletes
- Semi-professional athletes
- Trainers managing multiple athletes
- Athletes working with multiple coaches

## Success Criteria

- Athletes can log a workout quickly during training.
- Trainers can create, update, and monitor programs.
- Workout history is structured enough for analytics.
- RPE data can identify fatigue and program difficulty.
- Notifications keep trainer-athlete communication organized.
- The platform can scale without rewriting core modules.
