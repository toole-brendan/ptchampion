-- name: GetExercise :one
SELECT * FROM exercises
WHERE id = $1 LIMIT 1;

-- name: ListExercises :many
SELECT * FROM exercises
ORDER BY name;

-- name: GetExercisesByType :many
SELECT * FROM exercises
WHERE type = $1
ORDER BY name;

-- name: LogWorkout :one
INSERT INTO workouts (
  user_id, 
  exercise_id, 
  exercise_type,
  repetitions, 
  duration_seconds, 
  grade, -- Calculated grade based on performance
  form_score, -- Add form_score from client
  completed_at,
  is_public
)
VALUES (
    $1, -- user_id
    $2, -- exercise_id
    $3, -- exercise_type
    $4, -- repetitions (sqlc.narg)
    $5, -- duration_seconds (sqlc.narg)
    $6, -- grade (calculated)
    $7, -- form_score (sqlc.narg)
    $8, -- completed_at
    $9  -- is_public
)
RETURNING *;

-- name: GetUserWorkoutsHistory :many
SELECT
    w.id,
    w.user_id,
    w.exercise_id,
    w.repetitions,
    w.duration_seconds,
    w.grade,
    w.form_score,
    w.created_at,
    w.completed_at,
    e.name AS exercise_name,
    e.type AS exercise_type
FROM
    workouts w
JOIN
    exercises e ON w.exercise_id = e.id
WHERE
    w.user_id = $1
ORDER BY
    w.created_at DESC
LIMIT $2
OFFSET $3;

-- name: GetUserWorkoutsByType :many
SELECT w.*, e.name as exercise_name, e.type as exercise_type
FROM workouts w
JOIN exercises e ON e.id = w.exercise_id
WHERE w.user_id = $1 AND e.type = $2
ORDER BY w.created_at DESC;

-- name: GetLeaderboard :many
SELECT 
    u.id AS user_id,
    u.username,
    CONCAT(u.first_name, ' ', u.last_name) as display_name,
    MAX(w.grade) AS max_grade,
    MAX(w.created_at) AS last_attempt_date
FROM 
    workouts w
JOIN 
    users u ON w.user_id = u.id
JOIN
    exercises e ON w.exercise_id = e.id
WHERE 
    e.type = $1
    AND w.grade IS NOT NULL
    AND w.is_public = true
GROUP BY 
    u.id, u.username, u.first_name, u.last_name
ORDER BY 
    max_grade DESC, last_attempt_date ASC
LIMIT 100;

-- TODO: Add queries for getting specific exercise types, date ranges, etc. 