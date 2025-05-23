-- Reverse finalization: Restore user_exercises table from backup
-- WARNING: This will restore the old schema structure
-- Only use this if you need to rollback the entire workouts migration

-- Step 1: Check if backup exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'user_exercises_backup') THEN
        RAISE EXCEPTION 'Cannot restore: user_exercises_backup table does not exist';
    END IF;
    
    RAISE NOTICE 'Found user_exercises_backup table, proceeding with restoration';
END $$;

-- Step 2: Recreate user_exercises table from backup
CREATE TABLE user_exercises AS
SELECT 
    (backup_data->>'id')::INTEGER as id,
    (backup_data->>'user_id')::INTEGER as user_id,
    (backup_data->>'exercise_id')::INTEGER as exercise_id,
    CASE 
        WHEN backup_data->>'repetitions' IS NOT NULL 
        THEN (backup_data->>'repetitions')::INTEGER 
        ELSE NULL 
    END as repetitions,
    CASE 
        WHEN backup_data->>'time_in_seconds' IS NOT NULL 
        THEN (backup_data->>'time_in_seconds')::INTEGER 
        ELSE NULL 
    END as time_in_seconds,
    CASE 
        WHEN backup_data->>'distance' IS NOT NULL 
        THEN (backup_data->>'distance')::INTEGER 
        ELSE NULL 
    END as distance,
    CASE 
        WHEN backup_data->>'form_score' IS NOT NULL 
        THEN (backup_data->>'form_score')::INTEGER 
        ELSE NULL 
    END as form_score,
    CASE 
        WHEN backup_data->>'grade' IS NOT NULL 
        THEN (backup_data->>'grade')::INTEGER 
        ELSE NULL 
    END as grade,
    CASE 
        WHEN backup_data->>'completed' IS NOT NULL 
        THEN (backup_data->>'completed')::BOOLEAN 
        ELSE NULL 
    END as completed,
    backup_data->>'metadata' as metadata,
    backup_data->>'notes' as notes,
    backup_data->>'device_id' as device_id,
    COALESCE(backup_data->>'sync_status', 'synced') as sync_status,
    (backup_data->>'created_at')::TIMESTAMPTZ as created_at,
    (backup_data->>'updated_at')::TIMESTAMPTZ as updated_at
FROM user_exercises_backup;

-- Step 3: Add constraints and primary key
ALTER TABLE user_exercises ADD PRIMARY KEY (id);

-- Step 4: Add foreign key constraints
ALTER TABLE user_exercises 
ADD CONSTRAINT fk_user_exercises_user_id 
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE user_exercises 
ADD CONSTRAINT fk_user_exercises_exercise_id 
FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE;

-- Step 5: Recreate indexes
CREATE INDEX idx_user_exercises_user_id ON user_exercises(user_id);
CREATE INDEX idx_user_exercises_exercise_id ON user_exercises(exercise_id);
CREATE INDEX idx_user_exercises_created_at ON user_exercises(created_at DESC);

-- Step 6: Recreate sequence for id column
CREATE SEQUENCE IF NOT EXISTS user_exercises_id_seq;
ALTER TABLE user_exercises ALTER COLUMN id SET DEFAULT nextval('user_exercises_id_seq');
SELECT setval('user_exercises_id_seq', COALESCE((SELECT MAX(id) FROM user_exercises), 1));

-- Step 7: Drop the backup table
DROP TABLE user_exercises_backup;

-- Step 8: Verification and logging
DO $$
DECLARE
    restored_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO restored_count FROM user_exercises;
    
    RAISE NOTICE 'user_exercises table restored successfully';
    RAISE NOTICE 'Restored % records from backup', restored_count;
    RAISE NOTICE 'Rollback completed at %', NOW();
    RAISE NOTICE 'WARNING: You may need to update your application to use user_exercises instead of workouts';
END $$; 