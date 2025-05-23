-- Complete Migration from user_exercises to workouts table
-- This migration ensures data integrity and includes proper verification

-- Step 1: Add missing columns to workouts table
ALTER TABLE workouts 
ADD COLUMN IF NOT EXISTS device_id VARCHAR(255),
ADD COLUMN IF NOT EXISTS metadata JSONB,
ADD COLUMN IF NOT EXISTS notes TEXT,
ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS distance_meters DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS sync_status VARCHAR(20) DEFAULT 'synced';

-- Step 2: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_workouts_user_id_exercise_type ON workouts(user_id, exercise_type);
CREATE INDEX IF NOT EXISTS idx_workouts_device_id ON workouts(device_id);
CREATE INDEX IF NOT EXISTS idx_workouts_sync_status ON workouts(sync_status);

-- Step 3: Migrate data with proper verification
DO $$
DECLARE
    migrated_count INTEGER;
    total_count INTEGER;
    verification_count INTEGER;
BEGIN
    -- Get total count from source table
    SELECT COUNT(*) INTO total_count FROM user_exercises;
    RAISE NOTICE 'Starting migration of % records from user_exercises to workouts', total_count;
    
    -- Perform migration with ON CONFLICT handling
    INSERT INTO workouts (
        user_id, 
        exercise_id, 
        exercise_type, 
        repetitions,
        duration_seconds, 
        distance_meters,
        form_score, 
        grade, 
        is_public,
        completed_at, 
        created_at, 
        device_id, 
        metadata, 
        notes,
        sync_status
    )
    SELECT 
        ue.user_id,
        ue.exercise_id,
        e.type,
        ue.repetitions,
        ue.time_in_seconds,
        ue.distance,
        ue.form_score,
        COALESCE(ue.grade, 0),
        false, -- Default to private
        COALESCE(ue.created_at, NOW()),
        ue.created_at,
        ue.device_id,
        CASE 
            WHEN ue.metadata IS NOT NULL AND ue.metadata != '' 
            THEN ue.metadata::jsonb 
            ELSE '{}'::jsonb 
        END,
        ue.notes,
        COALESCE(ue.sync_status, 'synced')
    FROM user_exercises ue
    JOIN exercises e ON ue.exercise_id = e.id
    ON CONFLICT (user_id, exercise_id, created_at) DO NOTHING;
    
    GET DIAGNOSTICS migrated_count = ROW_COUNT;
    
    -- Verify migration
    SELECT COUNT(*) INTO verification_count FROM workouts 
    WHERE created_at >= (SELECT MIN(created_at) FROM user_exercises);
    
    RAISE NOTICE 'Migration completed: % new records inserted', migrated_count;
    RAISE NOTICE 'Total records in workouts table: %', verification_count;
    
    -- Additional verification: check for data consistency
    IF EXISTS (
        SELECT 1 FROM user_exercises ue
        JOIN exercises e ON ue.exercise_id = e.id
        WHERE NOT EXISTS (
            SELECT 1 FROM workouts w 
            WHERE w.user_id = ue.user_id 
            AND w.exercise_id = ue.exercise_id 
            AND w.created_at = ue.created_at
        )
    ) THEN
        RAISE EXCEPTION 'Migration verification failed: some records were not migrated properly';
    END IF;
    
    RAISE NOTICE 'Migration verification successful - all data migrated correctly';
    
END $$;

-- Step 4: Update any foreign key references (if they exist)
-- Note: Add any additional FK updates here if needed

-- Step 5: Grant permissions (adjust as needed for your setup)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON workouts TO your_app_user;

RAISE NOTICE 'Migration completed successfully. Review the data before running the down migration to drop user_exercises table.'; 