-- Rollback migration: Remove added columns from workouts table
-- Note: This will lose data in these columns!

-- Remove the added columns (this will delete any data in these columns)
ALTER TABLE workouts 
DROP COLUMN IF EXISTS device_id,
DROP COLUMN IF EXISTS metadata,
DROP COLUMN IF EXISTS notes;

-- Note: We cannot automatically restore the user_exercises table
-- as the original data structure may have been lost.
-- Manual restoration would be required from a backup if needed. 