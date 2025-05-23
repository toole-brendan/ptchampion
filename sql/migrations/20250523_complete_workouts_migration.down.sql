-- Reverse migration: Restore user_exercises table and migrate data back
-- WARNING: This will recreate the user_exercises table and may result in data loss
-- Only run this if you need to revert the workouts table migration

-- Step 1: Recreate user_exercises table with original schema
CREATE TABLE IF NOT EXISTS user_exercises (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    exercise_id INT NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    repetitions INT NULL,
    time_in_seconds INT NULL,
    distance INT NULL,
    form_score INT NULL,
    grade INT NULL,
    completed BOOLEAN NULL,
    metadata TEXT NULL,
    notes TEXT NULL,
    device_id VARCHAR(255) NULL,
    sync_status VARCHAR(20) DEFAULT 'synced',
    created_at TIMESTAMPTZ NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NULL DEFAULT CURRENT_TIMESTAMP
);

-- Step 2: Recreate indexes
CREATE INDEX IF NOT EXISTS idx_user_exercises_user_id ON user_exercises(user_id);
CREATE INDEX IF NOT EXISTS idx_user_exercises_exercise_id ON user_exercises(exercise_id);
CREATE INDEX IF NOT EXISTS idx_user_exercises_created_at ON user_exercises(created_at DESC);

-- Step 3: Migrate data back from workouts to user_exercises
DO $$
DECLARE
    migrated_count INTEGER;
    total_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_count FROM workouts;
    RAISE NOTICE 'Migrating % records from workouts back to user_exercises', total_count;
    
    INSERT INTO user_exercises (
        user_id,
        exercise_id,
        repetitions,
        time_in_seconds,
        distance,
        form_score,
        grade,
        completed,
        metadata,
        notes,
        device_id,
        sync_status,
        created_at,
        updated_at
    )
    SELECT 
        w.user_id,
        w.exercise_id,
        w.repetitions,
        w.duration_seconds,
        w.distance_meters::INT,
        w.form_score,
        w.grade,
        true, -- Assume completed if in workouts
        w.metadata::TEXT,
        w.notes,
        w.device_id,
        COALESCE(w.sync_status, 'synced'),
        w.created_at,
        w.created_at
    FROM workouts w
    ON CONFLICT DO NOTHING;
    
    GET DIAGNOSTICS migrated_count = ROW_COUNT;
    RAISE NOTICE 'Migrated % records back to user_exercises', migrated_count;
    
END $$;

-- Step 4: Remove added columns from workouts table
ALTER TABLE workouts 
DROP COLUMN IF EXISTS device_id,
DROP COLUMN IF EXISTS metadata,
DROP COLUMN IF EXISTS notes,
DROP COLUMN IF EXISTS is_public,
DROP COLUMN IF EXISTS distance_meters,
DROP COLUMN IF EXISTS sync_status;

-- Step 5: Drop indexes we created
DROP INDEX IF EXISTS idx_workouts_user_id_exercise_type;
DROP INDEX IF EXISTS idx_workouts_device_id;
DROP INDEX IF EXISTS idx_workouts_sync_status;

RAISE NOTICE 'Down migration completed. user_exercises table restored.'; 