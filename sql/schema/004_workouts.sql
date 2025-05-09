-- Create workouts table if it doesn't exist
CREATE TABLE IF NOT EXISTS workouts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id INTEGER NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    exercise_type VARCHAR(50) NOT NULL, -- Denormalized for query performance
    repetitions INTEGER,
    duration_seconds INTEGER,
    form_score INTEGER,
    grade INTEGER NOT NULL, -- Normalized score (0-100)
    is_public BOOLEAN NOT NULL DEFAULT false, -- Flag for leaderboard eligibility
    completed_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT check_has_metric CHECK (
        repetitions IS NOT NULL OR
        duration_seconds IS NOT NULL
    )
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_workouts_user_id ON workouts(user_id);
CREATE INDEX IF NOT EXISTS idx_workouts_exercise_id ON workouts(exercise_id);
CREATE INDEX IF NOT EXISTS idx_workouts_completed_at ON workouts(completed_at);
CREATE INDEX IF NOT EXISTS idx_workouts_is_public ON workouts(is_public) WHERE is_public = true; 