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

-- name: LogUserExercise :one
INSERT INTO user_exercises (
  user_id, 
  exercise_id, 
  repetitions, 
  time_in_seconds, 
  distance,
  grade, -- Calculated grade based on performance
  notes,
  completed, 
  metadata, -- Keep metadata for potential future use (e.g., raw analysis details)
  device_id,
  form_score -- Add form_score from client
)
VALUES (
    $1, -- user_id
    $2, -- exercise_id
    $3, -- repetitions (sqlc.narg)
    $4, -- time_in_seconds (sqlc.narg)
    $5, -- distance (sqlc.narg)
    $6, -- grade (calculated)
    $7, -- notes (sqlc.narg)
    $8, -- completed (sqlc.narg)
    $9, -- metadata (sqlc.narg - placeholder for now)
    $10, -- device_id (sqlc.narg)
    $11 -- form_score (sqlc.narg)
)
RETURNING *;

-- name: GetUserExercises :many
SELECT
    ue.id,
    ue.user_id,
    ue.exercise_id,
    ue.repetitions,
    ue.time_in_seconds,
    ue.distance,
    ue.grade,
    ue.notes,
    ue.created_at,
    e.name AS exercise_name,
    e.type AS exercise_type
FROM
    user_exercises ue
JOIN
    exercises e ON ue.exercise_id = e.id
WHERE
    ue.user_id = $1
ORDER BY
    ue.created_at DESC
LIMIT $2
OFFSET $3;

-- name: GetUserExercisesCount :one
SELECT count(*) FROM user_exercises
WHERE user_id = $1;

-- name: GetUserExercisesByType :many
SELECT ue.*, e.name as exercise_name, e.type as exercise_type
FROM user_exercises ue
JOIN exercises e ON e.id = ue.exercise_id
WHERE ue.user_id = $1 AND e.type = $2
ORDER BY ue.created_at DESC;

-- name: GetLeaderboard :many
SELECT 
    u.id AS user_id,
    u.username,
    u.display_name,
    MAX(ue.grade) AS max_grade,
    MAX(ue.created_at) AS last_attempt_date
FROM 
    user_exercises ue
JOIN 
    users u ON ue.user_id = u.id
JOIN
    exercises e ON ue.exercise_id = e.id
WHERE 
    e.type = $1
    AND ue.grade IS NOT NULL
GROUP BY 
    u.id, u.username, u.display_name
ORDER BY 
    max_grade DESC, last_attempt_date ASC
LIMIT 100;

-- TODO: Add queries for getting specific exercise types, date ranges, etc. 