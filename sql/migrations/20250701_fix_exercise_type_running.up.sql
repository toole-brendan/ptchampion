-- +migrate Up
-- Fix exercise type from 'run' to 'running' to match the leaderboard queries

UPDATE exercises 
SET type = 'running' 
WHERE id = 4 AND type = 'run';

-- Also update any existing workout records to use 'running' for consistency
UPDATE workouts 
SET exercise_type = 'running' 
WHERE exercise_id = 4 AND exercise_type = 'run';

-- Add a comment to document why this change was necessary
COMMENT ON COLUMN exercises.type IS 'Exercise type identifier. Note: Use "running" not "run" for consistency with leaderboard queries';