CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE roles (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name varchar(50) NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE users (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    email varchar(255) NOT NULL UNIQUE,
    password_hash text NOT NULL,
    full_name varchar(150) NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz NULL
);

CREATE TABLE user_roles (
    user_id uuid NOT NULL REFERENCES users(id),
    role_id uuid NOT NULL REFERENCES roles(id),
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE refresh_tokens (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL REFERENCES users(id),
    token_hash text NOT NULL,
    expires_at timestamptz NOT NULL,
    revoked_at timestamptz NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE athlete_profiles (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL UNIQUE REFERENCES users(id),
    age int NULL,
    gender varchar(50) NULL,
    height_cm numeric(6,2) NULL,
    weight_kg numeric(6,2) NULL,
    training_level varchar(50) NULL,
    primary_goal varchar(80) NULL,
    sport_type varchar(80) NULL,
    training_experience text NULL,
    injury_notes text NULL,
    workout_availability text NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE trainer_athlete_relations (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    trainer_id uuid NOT NULL REFERENCES users(id),
    athlete_id uuid NOT NULL REFERENCES users(id),
    status varchar(30) NOT NULL,
    requested_by_user_id uuid NOT NULL REFERENCES users(id),
    accepted_at timestamptz NULL,
    removed_at timestamptz NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_trainer_athlete UNIQUE (trainer_id, athlete_id)
);

CREATE TABLE exercises (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    name varchar(150) NOT NULL,
    slug varchar(180) NOT NULL UNIQUE,
    category varchar(60) NOT NULL,
    movement_pattern varchar(80) NULL,
    primary_muscle_group varchar(80) NULL,
    secondary_muscle_groups text NULL,
    equipment varchar(80) NULL,
    measurement_type varchar(40) NOT NULL,
    instructions text NULL,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz NULL
);

CREATE UNIQUE INDEX ux_exercises_name_lower ON exercises (lower(name));

CREATE TABLE workout_programs (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    trainer_id uuid NOT NULL REFERENCES users(id),
    name varchar(160) NOT NULL,
    description text NULL,
    goal varchar(80) NULL,
    training_level varchar(50) NULL,
    status varchar(30) NOT NULL DEFAULT 'Draft',
    start_date date NULL,
    end_date date NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    deleted_at timestamptz NULL
);

CREATE TABLE workout_program_weeks (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    program_id uuid NOT NULL REFERENCES workout_programs(id),
    week_number int NOT NULL,
    notes text NULL,
    UNIQUE (program_id, week_number)
);

CREATE TABLE workout_program_days (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    week_id uuid NOT NULL REFERENCES workout_program_weeks(id),
    day_number int NOT NULL,
    title varchar(120) NOT NULL,
    notes text NULL,
    UNIQUE (week_id, day_number)
);

CREATE TABLE workout_program_exercises (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    day_id uuid NOT NULL REFERENCES workout_program_days(id),
    exercise_id uuid NOT NULL REFERENCES exercises(id),
    exercise_order int NOT NULL,
    target_sets int NULL,
    target_reps_min int NULL,
    target_reps_max int NULL,
    target_rpe numeric(3,1) NULL CHECK (target_rpe BETWEEN 1 AND 10),
    rest_seconds int NULL CHECK (rest_seconds >= 0),
    notes text NULL,
    UNIQUE (day_id, exercise_order)
);

CREATE TABLE workout_program_exercise_sets (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    program_exercise_id uuid NOT NULL REFERENCES workout_program_exercises(id),
    set_number int NOT NULL,
    target_reps_min int NULL,
    target_reps_max int NULL,
    target_weight numeric(8,2) NULL,
    target_rpe numeric(3,1) NULL CHECK (target_rpe BETWEEN 1 AND 10),
    rest_seconds int NULL CHECK (rest_seconds >= 0),
    notes text NULL,
    UNIQUE (program_exercise_id, set_number)
);

CREATE TABLE workout_program_assignments (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    program_id uuid NOT NULL REFERENCES workout_programs(id),
    athlete_id uuid NOT NULL REFERENCES users(id),
    assigned_by_trainer_id uuid NOT NULL REFERENCES users(id),
    assigned_at timestamptz NOT NULL DEFAULT now(),
    removed_at timestamptz NULL,
    UNIQUE (program_id, athlete_id)
);

CREATE TABLE workout_sessions (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    athlete_id uuid NOT NULL REFERENCES users(id),
    program_id uuid NULL REFERENCES workout_programs(id),
    program_day_id uuid NULL REFERENCES workout_program_days(id),
    started_at timestamptz NOT NULL,
    ended_at timestamptz NULL,
    status varchar(30) NOT NULL,
    workout_rpe numeric(3,1) NULL CHECK (workout_rpe BETWEEN 1 AND 10),
    notes text NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE workout_session_exercises (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id uuid NOT NULL REFERENCES workout_sessions(id),
    exercise_id uuid NOT NULL REFERENCES exercises(id),
    exercise_name_snapshot varchar(150) NOT NULL,
    exercise_order int NOT NULL,
    notes text NULL,
    UNIQUE (session_id, exercise_order)
);

CREATE TABLE workout_set_logs (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_exercise_id uuid NOT NULL REFERENCES workout_session_exercises(id),
    set_number int NOT NULL,
    weight numeric(8,2) NULL CHECK (weight >= 0),
    reps int NULL CHECK (reps >= 0),
    duration_seconds int NULL CHECK (duration_seconds >= 0),
    distance_meters numeric(10,2) NULL CHECK (distance_meters >= 0),
    machine_level numeric(8,2) NULL,
    rpe numeric(3,1) NULL CHECK (rpe BETWEEN 1 AND 10),
    notes text NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (session_exercise_id, set_number)
);

CREATE TABLE workout_notes (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id uuid NOT NULL REFERENCES workout_sessions(id),
    user_id uuid NOT NULL REFERENCES users(id),
    note text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE rest_logs (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    set_log_id uuid NULL REFERENCES workout_set_logs(id),
    session_id uuid NOT NULL REFERENCES workout_sessions(id),
    duration_seconds int NOT NULL CHECK (duration_seconds >= 0),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE notifications (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL REFERENCES users(id),
    type varchar(80) NOT NULL,
    title varchar(160) NOT NULL,
    message text NOT NULL,
    related_entity_type varchar(80) NULL,
    related_entity_id uuid NULL,
    is_read boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    read_at timestamptz NULL
);

CREATE TABLE trainer_notes (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    trainer_id uuid NOT NULL REFERENCES users(id),
    athlete_id uuid NOT NULL REFERENCES users(id),
    note text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE progress_records (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    athlete_id uuid NOT NULL REFERENCES users(id),
    record_type varchar(80) NOT NULL,
    value numeric(10,2) NOT NULL,
    unit varchar(30) NOT NULL,
    recorded_at timestamptz NOT NULL,
    notes text NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX ix_relations_trainer ON trainer_athlete_relations(trainer_id);
CREATE INDEX ix_relations_athlete ON trainer_athlete_relations(athlete_id);
CREATE INDEX ix_sessions_athlete_started ON workout_sessions(athlete_id, started_at);
CREATE INDEX ix_set_logs_session_exercise ON workout_set_logs(session_exercise_id);
CREATE INDEX ix_notifications_user_read_created ON notifications(user_id, is_read, created_at);
CREATE INDEX ix_progress_athlete_recorded ON progress_records(athlete_id, recorded_at);
