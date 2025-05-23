-- name: GetLeaderboardByExerciseType :many
SELECT 
    u.username,
    CONCAT(u.first_name, ' ', u.last_name) as display_name,
    e.type as exercise_type,
    MAX(w.grade) as best_grade -- Get the best grade for this exercise type per user
FROM workouts w
JOIN users u ON w.user_id = u.id
JOIN exercises e ON w.exercise_id = e.id
WHERE e.type = $1
AND w.grade IS NOT NULL
AND u.is_public = true
GROUP BY u.id, e.type -- Group by user to find their best score for this exercise
ORDER BY best_grade DESC
LIMIT $2; -- Limit the number of results (e.g., top 10, 20) 

-- name: GetLocalLeaderboard :many
SELECT
    u.id AS user_id,
    u.username,
    CONCAT(u.first_name, ' ', u.last_name) as display_name,
    w.exercise_id,
    -- Aggregate score based on exercise type (e.g., MAX reps or MIN duration)
    -- This example assumes higher repetitions are better.
    -- Adjust aggregation (e.g., MIN(duration_seconds)) and ordering for other types.
    MAX(w.repetitions) AS score
FROM workouts w
JOIN users u ON w.user_id = u.id
WHERE
    -- Filter by specific exercise
    w.exercise_id = $1
    -- Ensure user has a location set
    AND u.last_location IS NOT NULL
    -- Filter users within the specified radius using ST_DWithin
    -- $2 = latitude, $3 = longitude, $4 = radius_meters
    AND ST_DWithin(
        u.last_location,
        -- IMPORTANT: ST_MakePoint expects (longitude, latitude)
        ST_SetSRID(ST_MakePoint($3, $2), 4326)::geography, -- Swapped $2 and $3
        $4
    )
    AND w.is_public = true
    AND u.is_public = true
GROUP BY u.id, u.username, u.first_name, u.last_name, w.exercise_id
ORDER BY score DESC
LIMIT 50; -- Apply a reasonable limit 

-- name: GetGlobalExerciseLeaderboard :many
SELECT 
    u.id as user_id,
    u.username,
    CONCAT(u.first_name, ' ', u.last_name) as display_name,
    MAX(w.grade) as score
FROM workouts w
JOIN users u ON w.user_id = u.id
JOIN exercises e ON w.exercise_id = e.id
WHERE e.type = @type
  AND w.is_public = true
  AND (sqlc.narg('start_date')::timestamptz IS NULL OR w.completed_at >= sqlc.narg('start_date')::timestamptz)
  AND (sqlc.narg('end_date')::timestamptz IS NULL OR w.completed_at < sqlc.narg('end_date')::timestamptz)
GROUP BY u.id, u.username, u.first_name, u.last_name
ORDER BY score DESC
LIMIT sqlc.arg('limit');

-- name: GetGlobalAggregateLeaderboard :many
WITH user_best_scores AS (
    SELECT 
        u.id as user_id,
        e.type as exercise_type,
        MAX(w.grade) as best_score
    FROM workouts w
    JOIN users u ON w.user_id = u.id
    JOIN exercises e ON w.exercise_id = e.id
    WHERE w.is_public = true
      AND e.type IN ('pushup','situp','pullup','running')              -- NEW: limit to 4 core types
      AND (sqlc.narg('start_date')::timestamptz IS NULL OR w.completed_at >= sqlc.narg('start_date')::timestamptz)
      AND (sqlc.narg('end_date')::timestamptz IS NULL OR w.completed_at < sqlc.narg('end_date')::timestamptz)
    GROUP BY u.id, e.type
)
SELECT 
    u.id as user_id,
    u.username,
    CONCAT(u.first_name, ' ', u.last_name) as display_name,
    SUM(ubs.best_score) as score
FROM users u
JOIN user_best_scores ubs ON u.id = ubs.user_id
GROUP BY u.id, u.username, u.first_name, u.last_name
HAVING COUNT(DISTINCT ubs.exercise_type) = 4                     -- NEW: require all 4 types
ORDER BY score DESC
LIMIT sqlc.arg('limit');

-- name: GetLocalExerciseLeaderboard :many
SELECT 
    u.id as user_id,
    u.username,
    CONCAT(u.first_name, ' ', u.last_name) as display_name,
    MAX(w.grade) as score,
    ST_Distance(u.last_location::geography, ST_MakePoint(@longitude, @latitude)::geography) as distance_meters
FROM workouts w
JOIN users u ON w.user_id = u.id
JOIN exercises e ON w.exercise_id = e.id
WHERE 
    e.type = @type 
    AND w.is_public = true
    AND ST_DWithin(
        u.last_location::geography,
        ST_MakePoint(@longitude, @latitude)::geography, -- longitude, then latitude for ST_MakePoint
        @radius_meters 
    )
    AND (sqlc.narg('start_date')::timestamptz IS NULL OR w.completed_at >= sqlc.narg('start_date')::timestamptz)
    AND (sqlc.narg('end_date')::timestamptz IS NULL OR w.completed_at < sqlc.narg('end_date')::timestamptz)
GROUP BY u.id, u.username, u.first_name, u.last_name, u.last_location
ORDER BY score DESC
LIMIT sqlc.arg('limit');

-- name: GetLocalAggregateLeaderboard :many
WITH user_best_scores AS (
    SELECT 
        u.id as user_id,
        e.type as exercise_type,
        MAX(w.grade) as best_score
    FROM workouts w
    JOIN users u ON w.user_id = u.id
    JOIN exercises e ON w.exercise_id = e.id
    WHERE 
        w.is_public = true
        AND e.type IN ('pushup','situp','pullup','running')              -- NEW: limit to 4 core types
        AND ST_DWithin(
            u.last_location::geography,
            ST_MakePoint(@longitude, @latitude)::geography, -- longitude, then latitude for ST_MakePoint
            @radius_meters
        )
        AND (sqlc.narg('start_date')::timestamptz IS NULL OR w.completed_at >= sqlc.narg('start_date')::timestamptz)
        AND (sqlc.narg('end_date')::timestamptz IS NULL OR w.completed_at < sqlc.narg('end_date')::timestamptz)
    GROUP BY u.id, e.type
)
SELECT 
    u.id as user_id,
    u.username,
    CONCAT(u.first_name, ' ', u.last_name) as display_name,
    SUM(ubs.best_score) as score,
    ST_Distance(u.last_location::geography, ST_MakePoint(@longitude, @latitude)::geography) as distance_meters
FROM users u
JOIN user_best_scores ubs ON u.id = ubs.user_id
GROUP BY u.id, u.username, u.first_name, u.last_name, u.last_location
HAVING COUNT(DISTINCT ubs.exercise_type) = 4                     -- NEW: require all 4 types
ORDER BY score DESC
LIMIT sqlc.arg('limit'); 