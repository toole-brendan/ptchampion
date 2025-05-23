-- name: CreateWorkout :one
INSERT INTO workouts (
    user_id,
    exercise_id,
    exercise_type, -- Consider removing if always joining
    repetitions,
    duration_seconds,
    form_score,
    grade,
    completed_at,
    is_public
    -- created_at is handled by DEFAULT NOW()
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9
)
RETURNING *;

-- name: GetUserWorkouts :many
SELECT 
    w.id, 
    w.user_id, 
    w.exercise_id,
    e.name as exercise_name,  -- Join with exercises table to get the name
    w.repetitions,
    w.duration_seconds,
    w.form_score,
    w.grade,
    w.is_public,
    w.created_at,
    w.completed_at
FROM workouts w
JOIN exercises e ON w.exercise_id = e.id
WHERE w.user_id = $1
ORDER BY w.completed_at DESC
LIMIT $2 OFFSET $3;

-- name: GetUserWorkoutsCount :one
SELECT COUNT(*) FROM workouts WHERE user_id = $1;

-- name: UpdateWorkoutVisibility :exec
UPDATE workouts
SET is_public = $1
WHERE id = $2 AND user_id = $3;

-- name: GetWorkoutRecordByID :one
SELECT * FROM workouts WHERE id = $1 LIMIT 1; 