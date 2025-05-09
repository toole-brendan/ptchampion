-- Combined schema for sqlc to process - not used for migrations
-- This file is ONLY for sqlc code generation

-- Create postgis extension if it doesn't exist
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username TEXT NOT NULL,
    password_hash TEXT NOT NULL, -- Note: using password_hash instead of password
    display_name TEXT,
    location TEXT,
    latitude NUMERIC,
    longitude NUMERIC,
    last_location GEOGRAPHY, -- Use proper GEOGRAPHY type
    tokens_invalidated_at TIMESTAMP WITH TIME ZONE,
    last_synced_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create exercises table
CREATE TABLE IF NOT EXISTS exercises (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL
);

-- Create user_exercises table
CREATE TABLE IF NOT EXISTS user_exercises (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id INT NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    repetitions INT NULL,
    time_in_seconds INT NULL,
    distance INT NULL,
    form_score INT NULL,
    grade INT NULL,
    completed BOOLEAN NULL,
    metadata TEXT NULL,
    notes TEXT NULL,
    device_id VARCHAR(255) NULL,
    created_at TIMESTAMPTZ NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, exercise_id, created_at)
);

-- Create workouts table
CREATE TABLE IF NOT EXISTS workouts (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id INT NOT NULL REFERENCES exercises(id),
    exercise_type VARCHAR(50) NOT NULL,
    repetitions INT,
    duration_seconds INT,
    form_score INT NULL CHECK (form_score >= 0 AND form_score <= 100),
    grade INT NOT NULL,
    is_public BOOLEAN NOT NULL DEFAULT false,
    completed_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_exercises_user_id ON user_exercises(user_id);
CREATE INDEX IF NOT EXISTS idx_user_exercises_exercise_id ON user_exercises(exercise_id);
CREATE INDEX IF NOT EXISTS idx_user_exercises_created_at ON user_exercises(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_workouts_user_id ON workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_workouts_exercise_id ON workouts(exercise_id);
CREATE INDEX IF NOT EXISTS idx_workouts_completed_at ON workouts(completed_at);
CREATE INDEX IF NOT EXISTS idx_workouts_is_public ON workouts(is_public) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_workouts_user_id_completed_at ON workouts(user_id, completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_workouts_exercise_type ON workouts(exercise_type);

CREATE INDEX IF NOT EXISTS idx_users_last_location ON users USING GIST (last_location); 