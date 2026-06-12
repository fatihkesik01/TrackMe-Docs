# TrackMe Task Tree

## Epic: Media

### Feature: MediaAsset

- Define media ownership rules
- Define media visibility rules
- Define media lifecycle states
- Define media moderation states
- Select storage provider
- Design signed upload flow
- Design signed download flow
- Add thumbnail strategy
- Add cleanup strategy
- Add file size limits
- Add video duration limits
- Add audio duration limits
- Add reporting metadata model
- Add mobile-ready media API contract

### Feature: Profile Photos

- Add avatar photo domain rules
- Add cover photo domain rules
- Add current avatar photo reference
- Add current cover photo reference
- Add avatar upload UI
- Add cover upload UI
- Add crop/preview flow
- Add delete/replace flow
- Add fallback avatar behavior
- Add fallback cover behavior

### Feature: Progress Photos

- Define visibility: private, coach-only, public
- Add progress timeline concept
- Add before/after comparison concept
- Link photo to athlete
- Link optional body metric
- Add trainer access rules
- Add upload flow
- Add delete flow
- Add sharing settings
- Add timeline grouping by date
- Add compare selection UX
- Add trainer shared-photo view

### Feature: Media Reporting

- Define report reasons
- Link report to MediaAsset
- Link report to reporting user
- Add report status lifecycle
- Add admin review queue concept
- Add moderation decision audit trail
- Define public media moderation behavior
- Define private coaching media abuse reporting behavior

### Feature: Athlete Submission Videos

- Define submission types
- Link to trainer-athlete relationship
- Link to session/exercise/set
- Add upload flow
- Add review status
- Notify trainer
- Show in trainer inbox

### Feature: Trainer Feedback Videos

- Link feedback to athlete
- Link feedback to submission/session/program
- Add recording/upload flow
- Notify athlete
- Add viewed/read status

### Feature: Audio Feedback

- Add audio media type
- Add recording/upload UX
- Add playback component
- Link to feedback/message/session/program

### Feature: Exercise Videos

- Link video to exercise
- Add official/user-generated distinction
- Allow user video for user-created exercises
- Allow trainer video for exercises inside trainer programs
- Add thumbnail
- Add language/level metadata
- Add video display in exercise picker
- Add video display in workout mode

### Feature: Program Media

- Attach media to program
- Attach media to program day
- Attach media to program exercise
- Display media in builder
- Display media in workout mode

## Epic: Public Programs

### Feature: Copy Public Program

- Define copy ownership
- Define Program Fork semantics
- Copy program structure
- Copy days
- Copy exercises
- Copy media references or snapshots
- Allow self-use
- Allow trainer assignment
- Track source program
- Track source version or copied-at timestamp
- Track fork/copy count
- Prevent automatic mutation when source program changes
- Design optional future update-from-source flow

### Feature: Published Program Images

- Add cover image
- Add gallery images
- Add image moderation
- Show in discovery cards

## Epic: Gym

### Feature: Gym

- Create gym
- Edit gym
- Add logo/cover
- Set visibility
- Support multi-gym membership

### Feature: Membership

- Invite user
- Accept invite
- Leave gym
- Remove member
- Assign member role

### Feature: Gym Coaches

- Assign coach
- Remove coach
- Coach athlete within gym
- Define gym coach permissions

### Feature: Gym Feed

- Create post
- Attach media
- Comment
- React
- Delete/moderate post
- Filter by gym

## Epic: Leaderboard

### Feature: Gym Leaderboard

- Define metrics
- Define time periods
- Compute rankings
- Filter by exercise
- Show evidence status

### Feature: Global Leaderboard

- Define eligible records
- Require verification for public ranking
- Add abuse/moderation rules

### Feature: PR Evidence

- Attach video to PR
- Submit verification
- Approve/reject evidence
- Show verification badge

## Epic: AI

### Feature: AI Program Draft

- Standardize program schema
- Define prompt inputs
- Define constraints
- Generate draft
- Let trainer edit before save
- Track AI-generated source

### Feature: AI Suggestions

- Analyze completed sessions
- Detect missed workouts
- Detect load progression
- Suggest adjustments
- Require trainer approval

## Epic: Mobile

### Feature: Mobile App Foundation

- Auth flow
- Role/mode handling
- Workout mode
- Offline-tolerant session draft
- Push notifications

### Feature: Mobile Media

- Camera capture
- Gallery upload
- Resumable upload
- Background upload
- Compression before upload

## Epic: Monetization

### Feature: Ads

- Define allowed placements
- Exclude workout mode
- Exclude private feedback
- Add ad placement config
- Add frequency caps

### Feature: Subscription

- Define trainer plans
- Define gym plans
- Define usage limits
- Define billing events
