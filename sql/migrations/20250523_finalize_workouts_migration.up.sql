-- Final cleanup migration: Drop user_exercises table after successful migration
-- WARNING: This is destructive and should only be run after thorough verification
-- Ensure all applications are updated to use the workouts table

-- Step 1: Final verification before cleanup
DO $$
DECLARE
    user_exercises_count INTEGER;
    workouts_count INTEGER;
    unmatched_count INTEGER;
BEGIN
    -- Get counts
    SELECT COUNT(*) INTO user_exercises_count FROM user_exercises;
    SELECT COUNT(*) INTO workouts_count FROM workouts;
    
    RAISE NOTICE 'Final verification before cleanup:';
    RAISE NOTICE 'user_exercises table has % records', user_exercises_count;
    RAISE NOTICE 'workouts table has % records', workouts_count;
    
    -- Check for any user_exercises that don't have corresponding workouts
    SELECT COUNT(*) INTO unmatched_count
    FROM user_exercises ue
    JOIN exercises e ON ue.exercise_id = e.id
    WHERE NOT EXISTS (
        SELECT 1 FROM workouts w 
        WHERE w.user_id = ue.user_id 
        AND w.exercise_id = ue.exercise_id 
        AND w.created_at = ue.created_at
    );
    
    IF unmatched_count > 0 THEN
        RAISE EXCEPTION 'Cannot proceed with cleanup: % user_exercises records have no corresponding workouts', unmatched_count;
    END IF;
    
    IF workouts_count < user_exercises_count THEN
        RAISE EXCEPTION 'Cannot proceed with cleanup: workouts table has fewer records (%) than user_exercises (%)', workouts_count, user_exercises_count;
    END IF;
    
    RAISE NOTICE 'Verification passed: All user_exercises data has been migrated to workouts table';
    
END $$;

-- Step 2: Update any views or stored procedures that might reference user_exercises
-- (Add any specific updates needed for your application here)

-- Step 3: Drop indexes on user_exercises table
DROP INDEX IF EXISTS idx_user_exercises_user_id;
DROP INDEX IF EXISTS idx_user_exercises_exercise_id;
DROP INDEX IF EXISTS idx_user_exercises_created_at;

-- Step 4: Drop foreign key constraints if they exist
-- (PostgreSQL will handle this automatically when we drop the table)

-- Step 5: Create a backup of user_exercises data in a JSON format (optional)
-- This creates a backup table that can be removed later if desired
CREATE TABLE IF NOT EXISTS user_exercises_backup AS
SELECT 
    row_to_json(ue.*) as backup_data,
    NOW() as backup_created_at
FROM user_exercises ue;

-- Step 6: Drop the user_exercises table
DROP TABLE user_exercises;

-- Step 7: Log the completion
DO $$
BEGIN
    RAISE NOTICE 'Migration finalized successfully:';
    RAISE NOTICE '- user_exercises table has been dropped';
    RAISE NOTICE '- Backup created in user_exercises_backup table';
    RAISE NOTICE '- All data is now in the workouts table';
    RAISE NOTICE 'Migration completed at %', NOW();
END $$; 