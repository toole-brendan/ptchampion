-- name: GetLeaderboardByExerciseType :many
SELECT 
    u.username,
    u.display_name,
    e.type as exercise_type,
    MAX(ue.grade) as best_grade -- Get the best grade for this exercise type per user
FROM user_exercises ue
JOIN users u ON ue.user_id = u.id
JOIN exercises e ON ue.exercise_id = e.id
WHERE e.type = $1
AND ue.grade IS NOT NULL
GROUP BY u.id, e.type -- Group by user to find their best score for this exercise
ORDER BY best_grade DESC
LIMIT $2; -- Limit the number of results (e.g., top 10, 20) 

-- name: GetLocalLeaderboard :many
SELECT
    u.id AS user_id,
    u.username,
    u.display_name,
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
GROUP BY u.id, u.username, u.display_name, w.exercise_id
ORDER BY score DESC
LIMIT 50; -- Apply a reasonable limit 