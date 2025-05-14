-- Combined Schema matching existing database (for sqlc generation)

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username TEXT NOT NULL UNIQUE, -- Username used for display, must be unique
    email TEXT NOT NULL UNIQUE, -- Added separate email field for login
    first_name TEXT,
    last_name TEXT,
    password_hash TEXT NOT NULL, -- Renamed to password_hash to reflect its actual content
    display_name TEXT,
    profile_picture_url TEXT,
    location TEXT,
    latitude NUMERIC,
    longitude NUMERIC,
    last_location TEXT,
    last_synced_at TIMESTAMP DEFAULT now(),
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- Create indexes for frequently queried fields
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);

CREATE TABLE exercises (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL
);

CREATE TABLE user_exercises (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id INT NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    repetitions INT NULL,           -- Number of repetitions (for rep-based exercises)
    time_in_seconds INT NULL,       -- Duration in seconds (for timed exercises like run)
    distance INT NULL,              -- Distance in meters (e.g., for run)
    form_score INT NULL,            -- Optional score (0-100) based on form analysis
    grade INT NULL,                 -- Calculated score (0-100) based on performance benchmarks
    completed BOOLEAN NULL,         -- Whether the exercise attempt was fully completed
    metadata TEXT NULL,             -- Optional JSON blob for additional data (e.g., vision analysis details)
    notes TEXT NULL,                -- User-provided notes
    device_id VARCHAR(255) NULL,    -- Optional identifier of the device used for logging
    created_at TIMESTAMPTZ NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, exercise_id, created_at) -- Prevent duplicate logs at the exact same time (adjust as needed)
);

-- Indexes for faster querying
CREATE INDEX idx_user_exercises_user_id ON user_exercises(user_id);
CREATE INDEX idx_user_exercises_exercise_id ON user_exercises(exercise_id);
CREATE INDEX idx_user_exercises_created_at ON user_exercises(created_at DESC);

CREATE TABLE workouts (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id INT NOT NULL REFERENCES exercises(id),
    exercise_type VARCHAR(50) NOT NULL,
    repetitions INT,
    duration_seconds INT,
    form_score INT NULL CHECK (form_score >= 0 AND form_score <= 100),
    grade INT NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_workouts_user_id_completed_at ON workouts(user_id, completed_at DESC);
CREATE INDEX idx_workouts_exercise_type ON workouts(exercise_type);

-- TODO: Add tables for sessions, leaderboards, etc.
-- TODO: Add indexes for performance 