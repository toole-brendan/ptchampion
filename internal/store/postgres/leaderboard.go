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
	TimeFrame    string  // Time period filter (daily, weekly, monthly, all_time)
}

// GlobalLeaderboardParams contains parameters for global leaderboard queries
type GlobalLeaderboardParams struct {
	ExerciseType string // Type of exercise (push_up, pull_up, etc.)
	Limit        int    // Maximum number of results to return
	TimeFrame    string // Time period filter (daily, weekly, monthly, all_time)
}

// GetLocalLeaderboardWithParams returns a leaderboard of users within a specified radius
// Uses PostGIS K-NN operator (<->) for spatial queries
func (r *LeaderboardRepository) GetLocalLeaderboardWithParams(ctx context.Context, params LocalLeaderboardParams) ([]LeaderboardEntry, error) {
	// Use bind variables instead of string formatting for the point
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
			AND u.is_public = true
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
			ST_Distance(u.last_location::geography, ST_MakePoint($2, $3)::geography) AS distance_meters,
			MAX(w.completed_at) AS last_updated
		FROM ranked_workouts rw
		JOIN users u ON rw.user_id = u.id
		JOIN workouts w ON rw.user_id = w.user_id AND rw.exercise_type = w.exercise_type
		WHERE u.last_location IS NOT NULL
		AND u.is_public = true
		AND ST_DWithin(u.last_location::geography, ST_MakePoint($2, $3)::geography, $4)
		GROUP BY u.id, u.username, u.display_name, u.profile_picture_url, rw.best_score, rw.rank, rw.exercise_type, u.last_location
		ORDER BY ST_Distance(u.last_location::geography, ST_MakePoint($2, $3)::geography) ASC
		LIMIT $5
	`

	rows, err := r.db.QueryContext(ctx, query,
		params.ExerciseType,
		params.Longitude, // Using ST_MakePoint(long, lat)
		params.Latitude,
		params.RadiusMeters,
		params.Limit)

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

// GetGlobalLeaderboard returns a global leaderboard for a specific exercise type with time filtering
func (r *LeaderboardRepository) GetGlobalLeaderboard(ctx context.Context, exerciseType string, startDate, endDate *time.Time, limit, offset int) ([]LeaderboardEntry, error) {
	query := `
		WITH ranked_workouts AS (
			SELECT 
				w.user_id,
				w.exercise_type,
				MAX(w.grade) AS best_score,
				ROW_NUMBER() OVER (
					ORDER BY 
						MAX(w.grade) DESC,          -- Primary: highest score
						MAX(w.completed_at) DESC,   -- Tie-breaker 1: most recent
						w.user_id ASC               -- Tie-breaker 2: consistent ordering
				) AS rank
			FROM workouts w
			JOIN users u ON w.user_id = u.id
			WHERE w.exercise_type = $1
			AND u.is_public = true
			AND ($4::timestamp IS NULL OR w.completed_at >= $4)  -- Start date
			AND ($5::timestamp IS NULL OR w.completed_at < $5)   -- End date
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
		WHERE u.is_public = true
		GROUP BY u.id, u.username, u.display_name, u.profile_picture_url, rw.best_score, rw.rank, rw.exercise_type
		ORDER BY rw.rank ASC
		LIMIT $2 OFFSET $3
	`

	// Handle optional time parameters
	var startTime, endTime interface{}
	if startDate != nil {
		startTime = *startDate
	}
	if endDate != nil {
		endTime = *endDate
	}

	rows, err := r.db.QueryContext(ctx, query, exerciseType, limit, offset, startTime, endTime)
	if err != nil {
		return nil, fmt.Errorf("error querying global leaderboard with time filter: %w", err)
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

// GetLocalLeaderboard returns a local leaderboard for a specific exercise type with time filtering
func (r *LeaderboardRepository) GetLocalLeaderboard(ctx context.Context, exerciseType string, lat, lng, radiusMeters float64, startDate, endDate *time.Time, limit, offset int) ([]LeaderboardEntry, error) {
	query := `
		WITH ranked_workouts AS (
			SELECT 
				w.user_id,
				w.exercise_type,
				MAX(w.grade) AS best_score,
				ROW_NUMBER() OVER (
					ORDER BY 
						MAX(w.grade) DESC,          -- Primary: highest score
						MAX(w.completed_at) DESC,   -- Tie-breaker 1: most recent
						w.user_id ASC               -- Tie-breaker 2: consistent ordering
				) AS rank
			FROM workouts w
			JOIN users u ON w.user_id = u.id
			WHERE w.exercise_type = $1
			AND u.is_public = true
			AND ($6::timestamp IS NULL OR w.completed_at >= $6)  -- Start date
			AND ($7::timestamp IS NULL OR w.completed_at < $7)   -- End date
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
			ST_Distance(u.last_location::geography, ST_MakePoint($2, $3)::geography) AS distance_meters,
			MAX(w.completed_at) AS last_updated
		FROM ranked_workouts rw
		JOIN users u ON rw.user_id = u.id
		JOIN workouts w ON rw.user_id = w.user_id AND rw.exercise_type = w.exercise_type
		WHERE u.last_location IS NOT NULL
		AND u.is_public = true
		AND ST_DWithin(u.last_location::geography, ST_MakePoint($2, $3)::geography, $4)
		GROUP BY u.id, u.username, u.display_name, u.profile_picture_url, rw.best_score, rw.rank, rw.exercise_type, u.last_location
		ORDER BY rw.best_score DESC, 
		         ST_Distance(u.last_location::geography, ST_MakePoint($2, $3)::geography) ASC
		LIMIT $5 OFFSET $8
	`

	// Handle optional time parameters
	var startTime, endTime interface{}
	if startDate != nil {
		startTime = *startDate
	}
	if endDate != nil {
		endTime = *endDate
	}

	rows, err := r.db.QueryContext(ctx, query,
		exerciseType,
		lng, // longitude first for ST_MakePoint
		lat,
		radiusMeters,
		limit,
		startTime,
		endTime,
		offset)

	if err != nil {
		return nil, fmt.Errorf("error querying local leaderboard with time filter: %w", err)
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
