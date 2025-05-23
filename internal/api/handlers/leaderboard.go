package handlers

import (
	"context"
	"database/sql"
	"errors"
	"net/http"
	"strconv"
	"time"

	db "ptchampion/internal/store/postgres"
	redis_cache "ptchampion/internal/store/redis"

	"github.com/labstack/echo/v4"
	"github.com/redis/go-redis/v9"
)

// LeaderboardService provides leaderboard-related functionality
type LeaderboardService struct {
	repo  *db.LeaderboardRepository
	cache *redis_cache.LeaderboardCache
}

// NewLeaderboardService creates a new leaderboard service
func NewLeaderboardService(dbConn *sql.DB, redisClient *redis.Client) *LeaderboardService {
	return &LeaderboardService{
		repo:  db.NewLeaderboardRepository(dbConn),
		cache: redis_cache.NewLeaderboardCache(redisClient),
	}
}

// LocalLeaderboardResponse is the response model for local leaderboard API
type LocalLeaderboardResponse struct {
	Entries  []db.LeaderboardEntry `json:"entries"`
	Metadata struct {
		Center struct {
			Latitude  float64 `json:"latitude"`
			Longitude float64 `json:"longitude"`
		} `json:"center"`
		RadiusMeters float64 `json:"radius_meters"`
		ExerciseType string  `json:"exercise_type"`
		Count        int     `json:"count"`
	} `json:"metadata"`
}

// GlobalLeaderboardResponse is the response model for global leaderboard API
type GlobalLeaderboardResponse struct {
	Entries  []db.LeaderboardEntry `json:"entries"`
	Metadata struct {
		ExerciseType string `json:"exercise_type"`
		Count        int    `json:"count"`
	} `json:"metadata"`
}

// GetLocalLeaderboard returns a leaderboard of users within a specified radius
func (s *LeaderboardService) GetLocalLeaderboard(ctx context.Context, exerciseType string, lat, lng, radius float64, startDate, endDate *time.Time, limit, offset int) (*LocalLeaderboardResponse, error) {
	// Cache miss or error - query database using new method signature
	entries, err := s.repo.GetLocalLeaderboard(ctx, exerciseType, lat, lng, radius, startDate, endDate, limit, offset)
	if err != nil {
		return nil, err
	}

	// Build response
	response := LocalLeaderboardResponse{
		Entries: entries,
		Metadata: struct {
			Center struct {
				Latitude  float64 `json:"latitude"`
				Longitude float64 `json:"longitude"`
			} `json:"center"`
			RadiusMeters float64 `json:"radius_meters"`
			ExerciseType string  `json:"exercise_type"`
			Count        int     `json:"count"`
		}{
			Center: struct {
				Latitude  float64 `json:"latitude"`
				Longitude float64 `json:"longitude"`
			}{
				Latitude:  lat,
				Longitude: lng,
			},
			RadiusMeters: radius,
			ExerciseType: exerciseType,
			Count:        len(entries),
		},
	}

	return &response, nil
}

// GetGlobalLeaderboard returns a global leaderboard for a specific exercise type
func (s *LeaderboardService) GetGlobalLeaderboard(ctx context.Context, exerciseType string, startDate, endDate *time.Time, limit, offset int) (*GlobalLeaderboardResponse, error) {
	// Cache miss or error - query database using new method signature
	entries, err := s.repo.GetGlobalLeaderboard(ctx, exerciseType, startDate, endDate, limit, offset)
	if err != nil {
		return nil, err
	}

	// Build response
	response := GlobalLeaderboardResponse{
		Entries: entries,
		Metadata: struct {
			ExerciseType string `json:"exercise_type"`
			Count        int    `json:"count"`
		}{
			ExerciseType: exerciseType,
			Count:        len(entries),
		},
	}

	return &response, nil
}

// HandleGetLocalLeaderboard is an HTTP handler for local leaderboard requests
func (s *LeaderboardService) HandleGetLocalLeaderboard(c echo.Context) error {
	// Parse query parameters
	lat, err := strconv.ParseFloat(c.QueryParam("lat"), 64)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid latitude")
	}

	lon, err := strconv.ParseFloat(c.QueryParam("lon"), 64)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid longitude")
	}

	radius, err := strconv.ParseFloat(c.QueryParam("radius"), 64)
	if err != nil || radius <= 0 {
		radius = 5000 // Default: 5km
	}

	exerciseType := c.QueryParam("exercise_type")
	if exerciseType == "" {
		return echo.NewHTTPError(http.StatusBadRequest, "Exercise type is required")
	}

	limitStr := c.QueryParam("limit")
	limit := 50 // Default
	if limitStr != "" {
		parsedLimit, err := strconv.Atoi(limitStr)
		if err == nil && parsedLimit > 0 {
			limit = parsedLimit
		}
	}

	// Query data from service
	params := db.LocalLeaderboardParams{
		Latitude:     lat,
		Longitude:    lon,
		RadiusMeters: radius,
		ExerciseType: exerciseType,
		Limit:        limit,
	}

	response, err := s.GetLocalLeaderboard(c.Request().Context(), params.ExerciseType, params.Latitude, params.Longitude, params.RadiusMeters, nil, nil, params.Limit, 0)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return c.JSON(http.StatusOK, map[string]interface{}{
				"entries":  []interface{}{},
				"metadata": params,
			})
		}
		return echo.NewHTTPError(http.StatusInternalServerError, "Error fetching leaderboard")
	}

	return c.JSON(http.StatusOK, response)
}

// HandleGetGlobalLeaderboard is an HTTP handler for global leaderboard requests
func (s *LeaderboardService) HandleGetGlobalLeaderboard(c echo.Context) error {
	exerciseType := c.QueryParam("exercise_type")
	if exerciseType == "" {
		return echo.NewHTTPError(http.StatusBadRequest, "Exercise type is required")
	}

	limitStr := c.QueryParam("limit")
	limit := 50 // Default
	if limitStr != "" {
		parsedLimit, err := strconv.Atoi(limitStr)
		if err == nil && parsedLimit > 0 {
			limit = parsedLimit
		}
	}

	// Query data from service
	params := db.GlobalLeaderboardParams{
		ExerciseType: exerciseType,
		Limit:        limit,
	}

	response, err := s.GetGlobalLeaderboard(c.Request().Context(), params.ExerciseType, nil, nil, params.Limit, 0)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return c.JSON(http.StatusOK, map[string]interface{}{
				"entries":  []interface{}{},
				"metadata": params,
			})
		}
		return echo.NewHTTPError(http.StatusInternalServerError, "Error fetching leaderboard")
	}

	return c.JSON(http.StatusOK, response)
}
