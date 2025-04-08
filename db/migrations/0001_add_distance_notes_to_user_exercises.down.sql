-- Drop index on distance
DROP INDEX IF EXISTS idx_user_exercises_distance;

-- Remove distance column
ALTER TABLE user_exercises DROP COLUMN IF EXISTS distance;

-- Remove notes column
ALTER TABLE user_exercises DROP COLUMN IF EXISTS notes;
