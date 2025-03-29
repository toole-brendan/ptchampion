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
  form_score, 
  time_in_seconds, 
  distance,
  grade,
  notes,
  completed, 
  metadata, 
  device_id
)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
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
    ue.created_at DESC;

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
    u.profile_picture_url,
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
    u.id, u.username, u.display_name, u.profile_picture_url
ORDER BY 
    max_grade DESC, last_attempt_date ASC
LIMIT 100;

-- TODO: Add queries for getting specific exercise types, date ranges, etc. 