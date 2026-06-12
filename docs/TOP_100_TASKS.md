# Top 100 TrackMe Tasks

Legend: ✅ Done · 🔄 In Progress · ⬜ Pending

## Media Foundation (Tasks 1–9)
1. ✅ Define canonical MediaAsset model.
2. ✅ Choose production object storage provider. (Cloudflare R2)
3. ✅ Define media visibility model. (Private / CoachOnly / Public)
4. ✅ Define media ownership model. (OwnerUserId FK on MediaAsset)
5. ✅ Design signed upload flow. (direct multipart POST → R2)
6. ✅ Design signed download flow. (/api/media/{id}/content proxy + PublicUrl redirect)
7. ✅ Define media lifecycle states. (PendingUpload / Uploaded / Ready / Failed / Deleted)
8. ✅ Add avatar photo product flow. (POST/DELETE /api/media/profile/avatar + UserAvatar component)
9. ✅ Add cover photo product flow. (POST/DELETE /api/media/profile/cover + ProfileView UI)

## Progress Photos (Tasks 10–14)
10. ⬜ Add progress photo product flow. (Backend: MediaPurpose.ProgressPhoto + POST /api/media/progress-photos)
11. ⬜ Add progress photo visibility settings. (Private default, coach-visible toggle)
12. ⬜ Add progress photo timeline. (ProfileView date-grouped photo grid)
13. ⬜ Add before/after progress comparison. (Side-by-side viewer modal)
14. ⬜ Add trainer access rules for shared progress photos. (respect CoachOnly visibility)

## Media Moderation & Limits (Tasks 15–26)
15. ⬜ Define media reporting flow.
16. ⬜ Define admin media moderation workflow.
17. ⬜ Add athlete submission video model.
18. ⬜ Add trainer feedback video model.
19. ⬜ Add audio feedback model.
20. ⬜ Add media notification rules.
21. ⬜ Add media upload limits. (per-user quota enforcement)
22. ⬜ Add media moderation states. (Reported → review)
23. ⬜ Add thumbnail generation plan.
24. ⬜ Add video compression/transcoding plan.
25. ⬜ Define PR verification workflow.
26. ⬜ Add media cleanup policy. (orphan asset GC job)

## Program Media (Tasks 27–32)
27. ⬜ Add program media attachment model. (exercise demo videos)
28. ⬜ Add exercise video model.
29. ⬜ Define user-generated exercise video rules.
30. ⬜ Define trainer exercise video attachment rules.
31. ✅ Add published program image model. (CoverMediaAssetId on PublishedProgram + upload endpoint)
32. ⬜ Add PR evidence video model.

## Program Fork & Copy (Tasks 33–40)
33. ✅ Define public program copy rules. (SavePublishedProgram flow, SourcePublishedProgramId tracking)
34. ✅ Define Program Fork semantics. (ProgramFork entity with fork history)
35. ✅ Track copied program source. (SourcePublishedProgramId on WorkoutProgram)
36. ✅ Allow copied program self-use. (Save → start flow)
37. ✅ Allow copied program trainer assignment. (saved program visible in trainer view)
38. ⬜ Define copied media behavior. (copy cover photo or link?)
39. ✅ Prevent automatic mutation of existing program forks. (snapshots are immutable JSON)
40. ✅ Define optional future fork update flow. (ProgramUpdateAvailable notification + version tracking)

## Mobile Readiness (Tasks 41–50)
41. ⬜ Improve Program Builder mobile readiness.
42. ⬜ Improve Workout Mode mobile readiness.
43. ⬜ Define mobile auth/session strategy. (biometric / secure token storage)
44. ⬜ Define mobile offline session draft behavior.
45. ⬜ Define push notification categories. (FCM / APNs token storage)
46. ⬜ Define trainer media inbox.
47. ⬜ Define athlete progress timeline.
48. ⬜ Define feedback read/view status.
49. ⬜ Define media privacy audit rules.
50. ⬜ Define public media moderation rules.

## Gym Feature (Tasks 51–62)
51. ⬜ Define Gym entity.
52. ⬜ Define multi-gym membership rules.
53. ⬜ Define gym owner role.
54. ⬜ Define gym coach role.
55. ⬜ Define gym member role.
56. ⬜ Define gym invitation flow.
57. ⬜ Define gym permission matrix.
58. ⬜ Define gym logo/cover media.
59. ⬜ Define gym feed post model.
60. ⬜ Define gym feed media support.
61. ⬜ Define gym feed moderation.
62. ⬜ Define gym feed notification rules.

## Leaderboards & PRs (Tasks 63–70)
63. ⬜ Define gym leaderboard metrics.
64. ⬜ Define global leaderboard metrics.
65. ⬜ Define leaderboard eligibility.
66. ⬜ Define leaderboard period rules.
67. ⬜ Define leaderboard computation strategy.
68. ⬜ Define PR evidence requirement.
69. ⬜ Define verified PR badge.
70. ⬜ Define abuse/reporting flow.

## AI Integration (Tasks 71–79)
71. ⬜ Standardize program schema for AI.
72. ⬜ Standardize exercise metadata.
73. ⬜ Define AI program draft inputs.
74. ⬜ Define AI program draft constraints.
75. ⬜ Define AI trainer approval flow.
76. ⬜ Define AI audit/source metadata.
77. ⬜ Define AI coaching suggestion inputs.
78. ⬜ Define AI safety boundaries.
79. ⬜ Define AI non-goals.

## Monetization (Tasks 80–88)
80. ⬜ Define subscription vs ads strategy.
81. ⬜ Define allowed ad placements.
82. ⬜ Exclude ads from workout mode.
83. ⬜ Exclude ads from private feedback.
84. ⬜ Define trainer plan packaging.
85. ⬜ Define gym plan packaging.
86. ⬜ Define storage quota policy.
87. ⬜ Define media quota policy.
88. ⬜ Define export/download policy.

## Discovery & Analytics (Tasks 89–100)
89. ⬜ Define public profile strategy.
90. ⬜ Define trainer portfolio strategy.
91. ⬜ Define rebranding criteria.
92. ⬜ Define product analytics events.
93. ⬜ Track program creation funnel.
94. ⬜ Track workout completion funnel.
95. ⬜ Track media feedback funnel.
96. ⬜ Track public program copy funnel.
97. ⬜ Track trainer-athlete relationship funnel.
98. ⬜ Track retention cohorts.
99. ⬜ Define staging media environment.
100. ⬜ Define production rollout checklist.

---

## Next Actionable Tasks (selected from above)

| # | Task | Effort |
|---|------|--------|
| 10 | Progress photo upload backend + ProfileView timeline | M |
| 11 | Progress photo visibility toggle (Private / CoachOnly) | S |
| 12 | Before/after comparison modal | M |
| 41 | Program Builder mobile-friendly layout | M |
| 51 | Gym entity + basic membership API | L |
| 45 | Push notification token storage (FCM/APNs) | M |
| 92 | Product analytics events (Mixpanel / PostHog) | M |
| 71 | AI program draft — OpenAI integration | L |

## Completed Summary (Phase 1–7)

- ✅ Tasks 1–9: Full media foundation (R2 storage, avatar, cover photo, proxy endpoint)
- ✅ Task 31: Published program cover photo (CoverMediaAssetId, upload/delete endpoints)
- ✅ Tasks 33–37, 39–40: Program fork/copy/versioning system
- ✅ Social graph: follow/unfollow, connections, relationships
- ✅ Published programs: publish, like, comment, save, version, visibility
- ✅ Notifications: all types with filter chips, date groups, sender avatars (Phase 7 frontend)
- ✅ Avatar everywhere: UserAvatar component in all relevant views
