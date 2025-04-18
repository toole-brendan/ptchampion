-- Migration: Consolidate schema definitions from schema.sql
-- This migration adds any missing tables/columns from the schema.sql file
-- that weren't already covered in earlier migrations.

-- NOTE: Many of these may already exist from previous migrations.
-- The migration will handle these cases gracefully (IF NOT EXISTS).

-- Add any missing columns to users table
ALTER TABLE IF EXISTS users
ADD COLUMN IF NOT EXISTS username TEXT,
ADD COLUMN IF NOT EXISTS password TEXT,
ADD COLUMN IF NOT EXISTS display_name TEXT,
ADD COLUMN IF NOT EXISTS profile_picture_url TEXT,
ADD COLUMN IF NOT EXISTS location TEXT,
ADD COLUMN IF NOT EXISTS last_location TEXT,
ADD COLUMN IF NOT EXISTS last_synced_at TIMESTAMP DEFAULT now(),
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT now(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT now();

-- Check and create exercises table if not exists
CREATE TABLE IF NOT EXISTS exercises (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL
);

-- Check and create user_exercises table if not exists
CREATE TABLE IF NOT EXISTS user_exercises (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    exercise_id INT NOT NULL,
    repetitions INT NULL,
    time_in_seconds INT NULL,
    distance INT NULL,
    form_score INT NULL,
    grade INT NULL,
    completed BOOLEAN NULL,
    metadata TEXT NULL,
    notes TEXT NULL,
    device_id VARCHAR(255) NULL,
    created_at TIMESTAMPTZ NULL DEFAULT CURRENT_TIMESTAMP
);

-- Add foreign key constraints if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'user_exercises_user_id_fkey'
    ) THEN
        ALTER TABLE user_exercises
        ADD CONSTRAINT user_exercises_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'user_exercises_exercise_id_fkey'
    ) THEN
        ALTER TABLE user_exercises
        ADD CONSTRAINT user_exercises_exercise_id_fkey
        FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE;
    END IF;
END
$$;

-- Add unique constraint if it doesn't exist
ALTER TABLE user_exercises DROP CONSTRAINT IF EXISTS user_exercises_user_id_exercise_id_created_at_key;
ALTER TABLE user_exercises ADD CONSTRAINT user_exercises_user_id_exercise_id_created_at_key 
UNIQUE(user_id, exercise_id, created_at);

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_user_exercises_user_id ON user_exercises(user_id);
CREATE INDEX IF NOT EXISTS idx_user_exercises_exercise_id ON user_exercises(exercise_id);
CREATE INDEX IF NOT EXISTS idx_user_exercises_created_at ON user_exercises(created_at DESC);

-- Check and create workouts table if not exists
CREATE TABLE IF NOT EXISTS workouts (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    exercise_id INT NOT NULL,
    exercise_type VARCHAR(50) NOT NULL,
    repetitions INT,
    duration_seconds INT,
    form_score INT NULL CHECK (form_score >= 0 AND form_score <= 100),
    grade INT NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add foreign key constraints for workouts if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'workouts_user_id_fkey'
    ) THEN
        ALTER TABLE workouts
        ADD CONSTRAINT workouts_user_id_fkey
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'workouts_exercise_id_fkey'
    ) THEN
        ALTER TABLE workouts
        ADD CONSTRAINT workouts_exercise_id_fkey
        FOREIGN KEY (exercise_id) REFERENCES exercises(id);
    END IF;
END
$$;

-- Create indexes for workouts if they don't exist
CREATE INDEX IF NOT EXISTS idx_workouts_user_id_completed_at ON workouts(user_id, completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_workouts_exercise_type ON workouts(exercise_type); 