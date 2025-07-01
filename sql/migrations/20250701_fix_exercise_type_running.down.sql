-- +migrate Down
-- Revert exercise type back to 'run' if needed

UPDATE exercises 
SET type = 'run' 
WHERE id = 4 AND type = 'running';

-- Also revert workout records
UPDATE workouts 
SET exercise_type = 'run' 
WHERE exercise_id = 4 AND exercise_type = 'running';

-- Remove the comment
COMMENT ON COLUMN exercises.type IS NULL;