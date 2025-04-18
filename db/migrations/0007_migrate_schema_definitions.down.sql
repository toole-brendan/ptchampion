-- Down migration to revert schema changes
-- Note: This is a simplistic down migration mainly for completeness.
-- In a real-world scenario, you might not want to drop all these objects.

-- Drop indexes
DROP INDEX IF EXISTS idx_workouts_exercise_type;
DROP INDEX IF EXISTS idx_workouts_user_id_completed_at;
DROP INDEX IF EXISTS idx_user_exercises_created_at;
DROP INDEX IF EXISTS idx_user_exercises_exercise_id;
DROP INDEX IF EXISTS idx_user_exercises_user_id;

-- Drop constraints (in correct order to avoid dependency issues)
ALTER TABLE IF EXISTS workouts
DROP CONSTRAINT IF EXISTS workouts_exercise_id_fkey,
DROP CONSTRAINT IF EXISTS workouts_user_id_fkey;

ALTER TABLE IF EXISTS user_exercises
DROP CONSTRAINT IF EXISTS user_exercises_exercise_id_fkey,
DROP CONSTRAINT IF EXISTS user_exercises_user_id_fkey,
DROP CONSTRAINT IF EXISTS user_exercises_user_id_exercise_id_created_at_key;

-- Note: We're not dropping the tables or removing columns from existing tables
-- as that would be destructive and might not be intended even in a rollback situation.
-- In a real migration, you would specify exactly what needs to be undone without data loss. 