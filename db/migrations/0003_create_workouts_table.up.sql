-- +migrate Up
CREATE TABLE workouts (
    id SERIAL PRIMARY KEY, -- Use SERIAL or UUID based on preference
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id INT NOT NULL REFERENCES exercises(id),
    exercise_type VARCHAR(50) NOT NULL, -- Redundant if joining, useful otherwise
    repetitions INT,
    duration_seconds INT,
    -- distance INT,
    -- form_score INT,
    grade INT NOT NULL, -- Store the calculated grade
    completed_at TIMESTAMPTZ NOT NULL,
    -- notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_workouts_user_id_completed_at ON workouts(user_id, completed_at DESC);
CREATE INDEX idx_workouts_exercise_type ON workouts(exercise_type); -- If querying by type 