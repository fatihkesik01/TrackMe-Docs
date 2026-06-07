# Migration History

Tüm EF Core migration'larının ne eklediğini açıklayan referans belgesi.

> **Kural:** Migration dosyaları hiçbir zaman elle yazılmaz.
> Detaylar için bkz. [migration-strategy.md](migration-strategy.md)

---

## Migration Listesi

| # | Dosya Adı | Ne Ekliyor / Değiştiriyor |
|---|-----------|--------------------------|
| 1 | `InitialCreate` | Temel tablolar: `users`, `trainers`, `athletes`, `workout_programs`, `workout_program_days`, `workout_program_exercises`, `workout_sessions`, `workout_session_exercises`, `workout_set_logs`, `exercises` |
| 2 | `AddIdentityFoundation` | JWT auth altyapısı: `refresh_tokens`, `password_reset_tokens` tabloları |
| 3 | `AllowSelfGuidedPrograms` | `workout_programs.trainer_id` nullable yapıldı — trainersız program oluşturma |
| 4 | `AddTrainerAthleteRelationships` | `trainer_athlete_relationships` tablosu (Pending/Accepted/Rejected/Ended statüsleri) |
| 5 | `AddExerciseLibrary` | `exercises` tablosu genişletildi: `category`, `primary_muscles`, `equipment`, `instructions`, `is_active` |
| 6 | `AddSessionExerciseTracking` | `workout_session_exercises` ve `workout_set_logs` tabloları — set bazında loglama |
| 7 | `AddProgramStructure` | `workout_program_days` ve `workout_program_exercises` tabloları |
| 8 | `Phase2_ProfileBioAndNotifications` | `users` tablosuna `bio`, `goal` alanları; `notifications` tablosu eklendi |
| 9 | `Phase3TemplatesAnalyticsAuth` | `program_templates`, `program_template_days`, `program_template_exercises` tabloları |
| 10 | `Phase3AnalyticsIndexes` | Analytics sorgularını hızlandıran index'ler: `workout_sessions(athlete_id, created_at)` |
| 11 | `Phase2_RelationshipInitiator` | `trainer_athlete_relationships.initiated_by_athlete` boolean alanı |
| 12 | `Phase6_BodyMetricsClassesMarketplace` | `body_metrics` tablosu; `training_classes`, `class_participants`, `template_purchases` (sonradan silindi, bkz. #38) |
| 13 | `Phase7_ExerciseOwnership` | `exercises.owner_id` (nullable), `exercises.is_global` — özel egzersiz desteği |
| 14 | `Phase8_WorkoutMode` | Workout mode için session exercise yapısı yeniden tasarlandı |
| 15 | `Phase8b_RepsAsString` | `reps` alanı int → string olarak değiştirildi ("8", "8-10", "AMRAP" formatları) |
| 16 | `Phase9_TargetWeightAndPlannedFields` | `workout_session_exercises`'e `planned_*` alanlar — anlık plan snapshot'ı |
| 17 | `Phase12_TrainerNoteOnSessionExercise` | `workout_session_exercises.trainer_note` alanı |
| 18 | `Phase15_BodyMetricsExtendedFields` | `body_metrics`'e vücut ölçüm alanları: `muscle_pct`, `height_cm`, `waist_cm`, `chest_cm`, `arms_cm`, `legs_cm`, `hips_cm` |
| 19 | `Phase16_ExerciseDifficulty` | `exercises.difficulty` alanı (Beginner/Intermediate/Advanced) |
| 20 | `Phase17_UserPreferredUiRole` | `users.preferred_ui_role` — Trainer hesabının Athlete arayüzü tercih edebilmesi |
| 21 | `Phase18_AllowMultipleDaysPerDate` | `workout_program_days` unique index kaldırıldı — aynı tarihe birden fazla antrenman günü |
| 22 | `Phase19_AthleteFeaturedExercise` | `athlete_featured_exercises` tablosu — sporcu profil vitrin listesi |
| 23 | `Phase20_AthleteFeaturedSession` | `athlete_featured_exercises.session_id` alanı — vitrin egzersizine session bağlama |
| 24 | `Phase21_SessionDayLinkAndReschedule` | `workout_sessions.program_day_id` bağlantısı; `workout_program_days.rescheduled_date` |
| 25 | `Phase3_SessionProgramCascadeDelete` | `workout_sessions → workout_programs` cascade delete davranışı düzeltildi |
| 26 | `EndRelationshipDeactivatePrograms` | İlişki bitince trainer programları deaktif yapan FK davranışı |
| 27 | `Phase3_FeaturedExercisesList` | `athlete_featured_exercises` tablosu yeniden düzenlendi (unlimited entries) |
| 28 | `ProfileNotificationSettings` | `users.read_notification_retention_days` tercihi |
| 29 | `NotificationSenderMetadata` | `notifications.sender_name`, `notifications.sender_role` alanları |
| 30 | `ProfileSportsList` | `users.sports_json` — birden fazla spor desteği (JSON array) |
| 31 | `ProfileSportExperience` | `sports_json` yapısı zenginleştirildi — spor başına deneyim yılı |
| 32 | `ProfileTrainingYearsDecimal` | `users.training_years` int → decimal(4,1) (0.5 gibi değerler) |
| 33 | `UserUnitPreferences` | `users.weight_unit`, `users.height_unit`, `users.dumbbell_increment_kg`, `users.barbell_plate_per_side_kg` |
| 34 | `DirectMessages` | `direct_messages` tablosu — trainer-athlete mesajlaşma |
| 35 | `DirectMessageReferences` | `direct_messages`'a referans alanları: `reference_type`, `reference_id`, `reference_label`, `reference_detail`, `reference_program_id`, `reference_exercise_id` |
| 36 | `Phase3_RepeatPattern_SetWeights_EquipmentIncrements` | `workout_programs.repeat_pattern_weeks`; `workout_program_exercise_sets` tablosu (set bazında planlı ağırlık); `workout_program_days.pattern_week_number` |
| 37 | `Phase4_TemplateTypes_WarmupSets` | `program_templates.template_type` (DayTemplate/ProgramTemplate/PatternTemplate); `warm_up_sets` alanı exercise tablolarına eklendi |
| 38 | `Phase22_RemoveDeadFeatures` | `training_classes`, `class_participants`, `template_purchases` tabloları silindi; `program_templates`'ten `price_cents`, `is_marketplace` kaldırıldı |

---

## Faz Numaralandırma Notları

Migration isimlerindeki faz numaraları kronolojik değil tematiktir; geliştirme sırasında bazı numara atlamalar olmuştur. Gerçek sıra için yukarıdaki tablodaki satır numaralarını kullan. Yeni migration eklerken timestamp-bazlı sıralama geçerlidir — faz numarası şablonu: `Phase<N>_<Açıklama>`.
