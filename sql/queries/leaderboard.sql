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