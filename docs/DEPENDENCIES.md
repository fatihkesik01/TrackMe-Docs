# TrackMe Dependencies

## Media Dependencies

Avatar Photo
-> MediaAsset
-> Object Storage
-> Image upload
-> Access control
-> Profile model

Cover Photo
-> MediaAsset
-> Object Storage
-> Image upload
-> Access control
-> Profile model

Progress Photos
-> MediaAsset
-> Athlete profile
-> Visibility model
-> Trainer-athlete relationship
-> Timeline UI
-> Before/after comparison UI

Athlete Submission Videos
-> MediaAsset
-> Video upload
-> Relationship model
-> Session/exercise linking
-> Notifications

Trainer Feedback Videos
-> MediaAsset
-> Video upload
-> Relationship model
-> Notifications
-> Feedback domain

Audio Feedback
-> MediaAsset
-> Audio upload/playback
-> Feedback domain

Exercise Videos
-> MediaAsset
-> Exercise library
-> CDN delivery
-> User-created exercise ownership
-> Trainer program permissions
-> Official/community content model

Program Videos
-> MediaAsset
-> Program Builder
-> Program exercise/day model

Published Program Images
-> MediaAsset
-> Published Programs
-> Public visibility
-> Moderation

Media Reporting
-> MediaAsset
-> User identity
-> Moderation status
-> Admin review workflow
-> Audit trail

PR Evidence Videos
-> MediaAsset
-> Personal Records
-> Verification workflow
-> Leaderboard

## Gym Dependencies

Gym
-> User identity
-> Role/permission model
-> MediaAsset for logo/cover

Gym Membership
-> Gym
-> User
-> Invitation flow

Gym Coaches
-> Gym Membership
-> Trainer profile
-> Permission model

Gym Feed
-> Gym
-> Gym Membership
-> MediaAsset
-> Moderation
-> Notifications

Leaderboard
-> Sessions
-> Personal Records
-> Gym Membership
-> PR Evidence for verification

## Public Program Dependencies

Program Fork
-> Public Programs
-> Program copy operation
-> Source program reference
-> Copied-at timestamp or source version
-> Program ownership rules

Optional Program Fork Updates
-> Program Fork
-> Source version tracking
-> Diff/merge policy
-> User confirmation UI

## AI Dependencies

AI Program Generation
-> Standard program schema
-> Exercise library quality
-> Program Builder
-> Trainer approval flow

AI Coaching Suggestions
-> Workout history
-> Analytics
-> Athlete goals
-> Trainer approval flow

## Mobile Dependencies

Mobile Workout Mode
-> Stable API contracts
-> Auth refresh
-> Program/session APIs
-> Offline draft strategy

Mobile Media Upload
-> MediaAsset
-> Signed upload URL
-> Object storage
-> Resumable upload
