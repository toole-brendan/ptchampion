-- Ensure workouts table has all necessary fields
ALTER TABLE workouts 
ADD COLUMN IF NOT EXISTS device_id VARCHAR(255),
ADD COLUMN IF NOT EXISTS metadata JSONB,
ADD COLUMN IF NOT EXISTS notes TEXT;

-- Migrate data from user_exercises to workouts
INSERT INTO workouts (
    user_id, exercise_id, exercise_type, repetitions,
    duration_seconds, form_score, grade, is_public,
    completed_at, created_at, device_id, metadata, notes
)
SELECT 
    ue.user_id,
    ue.exercise_id,
    e.type as exercise_type,
    ue.repetitions,
    ue.time_in_seconds as duration_seconds,
    ue.form_score,
    COALESCE(ue.grade, 0) as grade,
    false as is_public,
    COALESCE(ue.created_at, NOW()) as completed_at,
    ue.created_at,
    ue.device_id,
    ue.metadata::jsonb,
    ue.notes
FROM user_exercises ue
JOIN exercises e ON ue.exercise_id = e.id
WHERE NOT EXISTS (
    SELECT 1 FROM workouts w 
    WHERE w.user_id = ue.user_id 
    AND w.exercise_id = ue.exercise_id 
    AND w.created_at = ue.created_at
);

-- After verification, drop the old table
-- DROP TABLE user_exercises; 