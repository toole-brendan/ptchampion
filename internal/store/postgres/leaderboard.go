package db

import (
	"context"
	"fmt"
	"time"
)

// LeaderboardRepository provides methods to access and manipulate leaderboard data
type LeaderboardRepository struct {
	db DBTX
}

// NewLeaderboardRepository creates a new LeaderboardRepository instance
func NewLeaderboardRepository(db DBTX) *LeaderboardRepository {
	return &LeaderboardRepository{db: db}
}

// LeaderboardEntry represents an entry in the leaderboard
type LeaderboardEntry struct {
	UserID         int       `json:"user_id"`
	Username       string    `json:"username"`
	DisplayName    string    `json:"display_name"`
	ProfilePicture string    `json:"profile_picture_url"`
	Score          int       `json:"score"`
	Rank           int       `json:"rank"`
	ExerciseType   string    `json:"exercise_type"`
	Distance       float64   `json:"distance_meters,omitempty"` // Distance in meters, only for local leaderboards
	LastUpdated    time.Time `json:"last_updated"`
}

// LocalLeaderboardParams contains parameters for local leaderboard queries
type LocalLeaderboardParams struct {
	Latitude     float64 // Center point latitude
	Longitude    float64 // Center point longitude
	RadiusMeters float64 // Search radius in meters
	ExerciseType string  // Type of exercise (push_up, pull_up, etc.)
	Limit        int     // Maximum number of results to return
}

// GlobalLeaderboardParams contains parameters for global leaderboard queries
type GlobalLeaderboardParams struct {
	ExerciseType string // Type of exercise (push_up, pull_up, etc.)
	Limit        int    // Maximum number of results to return
}

// GetLocalLeaderboard returns a leaderboard of users within a specified radius
// Uses PostGIS K-NN operator (<->) for spatial queries
func (r *LeaderboardRepository) GetLocalLeaderboard(ctx context.Context, params LocalLeaderboardParams) ([]LeaderboardEntry, error) {
	// Convert lat/long to a PostGIS Point
	pointText := fmt.Sprintf("SRID=4326;POINT(%f %f)", params.Longitude, params.Latitude)

	// Query using K-NN spatial operator for better performance on large datasets
	query := `
		WITH ranked_workouts AS (
			SELECT 
				w.user_id,
				w.exercise_type,
				MAX(w.grade) AS best_score,
				ROW_NUMBER() OVER (ORDER BY MAX(w.grade) DESC) AS rank
			FROM workouts w
			JOIN users u ON w.user_id = u.id
			WHERE w.exercise_type = $1
			GROUP BY w.user_id, w.exercise_type
		)
		SELECT 
			u.id AS user_id,
			u.username,
			u.display_name,
			u.profile_picture_url,
			rw.best_score AS score,
			rw.rank,
			rw.exercise_type,
			ST_Distance(u.last_location::geography, ST_GeographyFromText($2)::geography) AS distance_meters,
			MAX(w.completed_at) AS last_updated
		FROM ranked_workouts rw
		JOIN users u ON rw.user_id = u.id
		JOIN workouts w ON rw.user_id = w.user_id AND rw.exercise_type = w.exercise_type
		WHERE u.last_location IS NOT NULL
		AND ST_DWithin(u.last_location::geography, ST_GeographyFromText($2)::geography, $3)
		GROUP BY u.id, u.username, u.display_name, u.profile_picture_url, rw.best_score, rw.rank, rw.exercise_type, u.last_location
		ORDER BY ST_Distance(u.last_location::geography, ST_GeographyFromText($2)::geography) ASC
		LIMIT $4
	`

	rows, err := r.db.QueryContext(ctx, query, params.ExerciseType, pointText, params.RadiusMeters, params.Limit)
	if err != nil {
		return nil, fmt.Errorf("error querying local leaderboard: %w", err)
	}
	defer rows.Close()

	var entries []LeaderboardEntry
	for rows.Next() {
		var entry LeaderboardEntry
		if err := rows.Scan(
			&entry.UserID,
			&entry.Username,
			&entry.DisplayName,
			&entry.ProfilePicture,
			&entry.Score,
			&entry.Rank,
			&entry.ExerciseType,
			&entry.Distance,
			&entry.LastUpdated,
		); err != nil {
			return nil, fmt.Errorf("error scanning leaderboard entry: %w", err)
		}
		entries = append(entries, entry)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating leaderboard entries: %w", err)
	}

	return entries, nil
}

// GetGlobalLeaderboard returns a global leaderboard for a specific exercise type
func (r *LeaderboardRepository) GetGlobalLeaderboard(ctx context.Context, params GlobalLeaderboardParams) ([]LeaderboardEntry, error) {
	query := `
		WITH ranked_workouts AS (
			SELECT 
				w.user_id,
				w.exercise_type,
				MAX(w.grade) AS best_score,
				ROW_NUMBER() OVER (ORDER BY MAX(w.grade) DESC) AS rank
			FROM workouts w
			WHERE w.exercise_type = $1
			GROUP BY w.user_id, w.exercise_type
		)
		SELECT 
			u.id AS user_id,
			u.username,
			u.display_name,
			u.profile_picture_url,
			rw.best_score AS score,
			rw.rank,
			rw.exercise_type,
			MAX(w.completed_at) AS last_updated
		FROM ranked_workouts rw
		JOIN users u ON rw.user_id = u.id
		JOIN workouts w ON rw.user_id = w.user_id AND rw.exercise_type = w.exercise_type
		GROUP BY u.id, u.username, u.display_name, u.profile_picture_url, rw.best_score, rw.rank, rw.exercise_type
		ORDER BY rw.rank ASC
		LIMIT $2
	`

	rows, err := r.db.QueryContext(ctx, query, params.ExerciseType, params.Limit)
	if err != nil {
		return nil, fmt.Errorf("error querying global leaderboard: %w", err)
	}
	defer rows.Close()

	var entries []LeaderboardEntry
	for rows.Next() {
		var entry LeaderboardEntry
		if err := rows.Scan(
			&entry.UserID,
			&entry.Username,
			&entry.DisplayName,
			&entry.ProfilePicture,
			&entry.Score,
			&entry.Rank,
			&entry.ExerciseType,
			&entry.LastUpdated,
		); err != nil {
			return nil, fmt.Errorf("error scanning leaderboard entry: %w", err)
		}
		entries = append(entries, entry)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating leaderboard entries: %w", err)
	}

	return entries, nil
}
