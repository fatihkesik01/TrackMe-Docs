-- ============================================================
-- TrackMe — Reset All Data
-- Deletes every row from every table in dependency order.
-- UUID PKs have no sequences; RESTART IDENTITY is a no-op but
-- included for completeness.
-- ⚠️  DO NOT run on production unless you intend a full wipe.
-- ============================================================

TRUNCATE TABLE
  -- Session logs (deepest children first)
  workout_set_logs,
  workout_session_exercises,
  workout_sessions,

  -- Program structure
  workout_program_exercises,
  workout_program_days,
  workout_programs,

  -- Body metrics
  body_metrics,

  -- Relationships & notifications
  trainer_athlete_relationships,
  notifications,

  -- Auth tokens
  password_reset_tokens,
  refresh_tokens,

  -- Dead tables (kept in schema, no active endpoints)
  class_participants,
  training_classes,
  template_purchases,
  program_template_exercises,
  program_template_days,
  program_templates,
  user_integrations,

  -- Core entities
  exercises,
  athletes,
  trainers,
  users

RESTART IDENTITY CASCADE;
