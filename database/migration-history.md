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
| 39 | `Phase23_SessionDayIndex` | `workout_sessions.program_day_id` üzerine index — session-gün sorgu performansı |
| 40 | `Phase24_PerSetDetails` | `workout_program_exercise_sets`'e `planned_reps`, `planned_rpe`, `planned_rest_seconds`, `notes` sütunları — set bazında tam plan desteği |
| 41 | `Phase5_TemplateExerciseSetWeights` | `program_template_exercise_sets` tablosu — template egzersizleri için set bazında planlı veri (ağırlık/tekrar/RPE/dinlenme/not); ApplyToDay ve ApplyToProgram bu verileri programa kopyalar |
| 42–45 | `Phase6_*` / `Phase7_AvatarEmoji` | Social connections, profile privacy (6 alan), coaching endpoint rename, emoji avatar |
| 46 | `Phase8_ProgramSharing` | `published_programs`, `program_likes`, `program_comments` tabloları; `workout_programs`'a `started_at`, `duration_type`, `duration_value`, `source_published_program_id` sütunları; `starts_on` nullable yapıldı |
| 47 | `Phase9_ProgramAnalyticsAndInfra` | `published_programs`'a `save_count`, `start_count` sütunları; future infra: `program_forks`, `program_collections`, `program_collection_items`, `program_favorites`, `program_followers` tabloları |
| 48 | `Phase1_ArchAlignment` | **Mimari uyum — Faz 1:** `workout_programs`'a `locked_at` + `locked_reason` sütunları (koçluk sona erince program kilitlenir); `athletes.trainer_id` sütunu kaldırıldı (multi-coach: ilişki artık yalnızca `trainer_athlete_relationships` tablosundan yönetilir); `body_metrics` 7 sütun adı düzeltildi (PascalCase → snake_case: `arms_cm`, `chest_cm`, `height_cm`, `hips_cm`, `legs_cm`, `muscle_pct`, `waist_cm`); `program_templates.template_type` integer → string olarak değiştirildi (mevcut satırlar CASE WHEN ile dönüştürüldü) |
| 49 | `Phase2_ProgramVersioning` | **Program Versioning — Faz 2:** `published_programs`'a `version_number`, `root_published_program_id`, `previous_version_id`, `changelog` sütunları; `workout_programs`'a `source_version_number`, `has_pending_update`, `pending_version_id` sütunları. Program sahibi yeni sürüm yayınlayabilir, kaydedenlere bildirim gider ve güncellemeyi accept/dismiss edebilirler. |
| 50 | `Phase3_UserFollows_ProgramMetadata` | **Sosyal Ağ ve Program Keşif — Faz 3:** `program_followers` tablosu silindi (future-infra); `user_follows` tablosu oluşturuldu (`follower_user_id`, `followed_user_id`, unique index) — tek yönlü takip sistemi; `published_programs`'a `sport_category`, `difficulty_level`, `equipment_required`, `tags` sütunları — program keşif metadata'sı. |
| 51 | `Phase5_PersonalRecords` | `personal_records` tablosu — `(athlete_id, exercise_id)` unique index; `max_weight_kg`, `estimated_one_rm_kg`, `max_volume_session_kg`, `record_session_id`, `recorded_at` alanları. CompleteSession çağrısında otomatik UPSERT yapılır. |
| 52 | `Sprint1MediaFoundation` | **Media Altyapısı — Sprint 1:** `media_assets` tablosu (storage_provider, bucket, object_key, public_url, mime_type, status, visibility, purpose, file_size_bytes, width, height vb.); `users`'a `avatar_media_asset_id` ve `cover_media_asset_id` nullable FK sütunları; 4 index (object_key unique, owner+purpose composite, users avatar/cover FK). |

---

## Faz Numaralandırma Notları

Migration isimlerindeki faz numaraları kronolojik değil tematiktir; geliştirme sırasında bazı numara atlamalar olmuştur. Gerçek sıra için yukarıdaki tablodaki satır numaralarını kullan. Yeni migration eklerken timestamp-bazlı sıralama geçerlidir — faz numarası şablonu: `Phase<N>_<Açıklama>`.
