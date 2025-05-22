package handlers

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	db "ptchampion/internal/store/postgres"
	"ptchampion/internal/store/redis"

	"ptchampion/internal/leaderboards"
	"ptchampion/internal/logging"
	"ptchampion/internal/store" // For store.LeaderboardEntry

	"github.com/labstack/echo/v4"
	goredis "github.com/redis/go-redis/v9"
)

// Default radius in meters (approx 5 miles)
const defaultSearchRadiusMeters = 8047

const defaultLeaderboardLimit = 20
const leaderboardCacheTTL = 10 * time.Minute // 10 minute TTL for cached leaderboards (increased from 5 minutes)

// LocalLeaderboardEntry defines the structure for local leaderboard results
type LocalLeaderboardEntry struct {
	UserID       int32   `json:"userId"`
	Username     string  `json:"username"`
	FirstName    string  `json:"first_name"`
	LastName     string  `json:"last_name"`
	ExerciseID   int32   `json:"exerciseId"`
	Score        int32   `json:"score"` // Represents MAX(repetitions) or MIN(duration) etc.
	Distance     float64 `json:"distanceMeters,omitempty"`
	LastUpdated  string  `json:"lastUpdated,omitempty"`
	CachedResult bool    `json:"cachedResult,omitempty"`
}

// LeaderboardEntry defines the structure for a single entry on the leaderboard
type LeaderboardEntry struct {
	Username  string `json:"username"`
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	BestGrade int32  `json:"best_grade"`
}

// LeaderboardAPIEntry is the response model for a leaderboard entry.
type LeaderboardAPIEntry struct {
	Rank      int32   `json:"rank"`
	UserID    string  `json:"user_id,omitempty"` // omitempty if not available
	Username  string  `json:"username"`
	FirstName *string `json:"first_name,omitempty"`
	LastName  *string `json:"last_name,omitempty"`
	Score     int32   `json:"score"`
}

// LeaderboardHandler handles leaderboard-related API requests.
type LeaderboardHandler struct {
	service leaderboards.Service
	logger  logging.Logger
}

// NewLeaderboardHandler creates a new LeaderboardHandler instance.
func NewLeaderboardHandler(service leaderboards.Service, logger logging.Logger) *LeaderboardHandler {
	return &LeaderboardHandler{
		service: service,
		logger:  logger,
	}
}

// GetCacheClient returns a Redis client or nil if Redis is not configured
func (h *Handler) GetCacheClient() *goredis.Client {
	// For development, when Redis URL is not set, don't try to connect
	if os.Getenv("APP_ENV") == "development" && getEnvOrDefault("REDIS_URL", "") == "" {
		log.Printf("Development mode with no Redis URL set - skipping Redis cache for leaderboards")
		return nil
	}

	// Check if Redis is enabled via environment variables
	// We're enabling Redis by default now
	redisEnabled := true // Changed from false to true

	// Create options from environment
	redisURL := fmt.Sprintf("redis://%s:%d",
		getEnvOrDefault("REDIS_HOST", "localhost"),
		getEnvIntOrDefault("REDIS_PORT", 6379))

	if password := getEnvOrDefault("REDIS_PASSWORD", ""); password != "" {
		redisURL = fmt.Sprintf("redis://:%s@%s:%d",
			password,
			getEnvOrDefault("REDIS_HOST", "localhost"),
			getEnvIntOrDefault("REDIS_PORT", 6379))
	}

	// Use standard options with our URL
	redisOpts := redis.DefaultOptions()
	redisOpts.URL = redisURL
	redisOpts.PoolSize = getEnvIntOrDefault("REDIS_POOL_SIZE", 10)

	if redisEnabled {
		client, err := redis.CreateClient(redisOpts)
		if err != nil {
			log.Printf("Error creating Redis client: %v", err)
			return nil
		}
		return client
	}
	return nil
}

// Helper function to get environment variables with defaults
func getEnvOrDefault(key, defaultValue string) string {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	return value
}

// Helper function to get integer environment variables with defaults
func getEnvIntOrDefault(key string, defaultValue int) int {
	value := os.Getenv(key)
	if value == "" {
		return defaultValue
	}
	intValue, err := strconv.Atoi(value)
	if err != nil {
		return defaultValue
	}
	return intValue
}

// GetLeaderboard handles requests to retrieve the leaderboard for a specific exercise type
func (h *Handler) GetLeaderboard(c echo.Context) error {
	exerciseType := c.Param("exerciseType")
	if exerciseType == "" {
		return echo.NewHTTPError(http.StatusBadRequest, "Exercise type is required")
	}

	// Get limit from query param, default if not provided or invalid
	limitStr := c.QueryParam("limit")
	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit <= 0 {
		limit = defaultLeaderboardLimit
	}

	// Get time frame from query param, default to all_time if not provided
	timeFrame := c.QueryParam("time_frame")
	if timeFrame == "" {
		timeFrame = "all_time"
	}

	// Check if we can use the Redis cache
	redisClient := h.GetCacheClient()
	if redisClient != nil {
		cache := redis.NewLeaderboardCache(redisClient).WithTTL(leaderboardCacheTTL)
		cacheKey := redis.GlobalLeaderboardKey(exerciseType, limit, timeFrame)

		// Try to get from cache
		var cachedEntries []LeaderboardEntry
		ctx := c.Request().Context()
		err := cache.Get(ctx, cacheKey, &cachedEntries)
		if err == nil && len(cachedEntries) > 0 {
			// Cache hit
			return c.JSON(http.StatusOK, cachedEntries)
		}

		// Cache miss, continue with DB query
	}

	// Prepare params for DB query
	params := db.GetLeaderboardByExerciseTypeParams{
		Type:  exerciseType,
		Limit: int32(limit),
	}

	// Fetch leaderboard data from database
	dbEntries, err := h.Queries.GetLeaderboardByExerciseType(c.Request().Context(), params)
	if err != nil {
		log.Printf("ERROR: Failed to get leaderboard for type '%s': %v", exerciseType, err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve leaderboard")
	}

	// Map DB results to response struct
	respEntries := make([]LeaderboardEntry, len(dbEntries))
	for i, dbEntry := range dbEntries {
		var bestGrade int32
		if gradeVal, ok := dbEntry.BestGrade.(int64); ok { // Assert to int64 first
			bestGrade = int32(gradeVal)
		} // else: bestGrade remains 0 if assertion fails or value is NULL

		// Split display_name (which is now generated from CONCAT in SQL) into first_name and last_name
		firstName := ""
		lastName := ""
		displayName := GetStringFromInterface(dbEntry.DisplayName)
		if displayName != "" {
			parts := strings.SplitN(displayName, " ", 2)
			firstName = parts[0]
			if len(parts) > 1 {
				lastName = parts[1]
			}
		}

		respEntries[i] = LeaderboardEntry{
			Username:  dbEntry.Username,
			FirstName: firstName,
			LastName:  lastName,
			BestGrade: bestGrade,
		}
	}

	// Cache the result if Redis is available
	if redisClient != nil && len(respEntries) > 0 {
		cache := redis.NewLeaderboardCache(redisClient).WithTTL(leaderboardCacheTTL)
		cacheKey := redis.GlobalLeaderboardKey(exerciseType, limit, timeFrame)

		ctx := c.Request().Context()
		if err := cache.Set(ctx, cacheKey, respEntries); err != nil {
			// Just log the error, don't fail the request
			log.Printf("Error caching global leaderboard: %v", err)
		}
	}

	// Send response
	return c.JSON(http.StatusOK, respEntries)
}

// HandleGetLocalLeaderboard handles GET /leaderboards/local (Exported)
func (h *Handler) HandleGetLocalLeaderboard(c echo.Context) error {
	// 1. Parse required query parameters: exercise_id, latitude, longitude
	exerciseIDStr := c.QueryParam("exercise_id")
	latStr := c.QueryParam("latitude")
	lonStr := c.QueryParam("longitude")
	radiusStr := c.QueryParam("radius_meters") // Optional
	timeFrame := c.QueryParam("time_frame")    // Time frame parameter

	if timeFrame == "" {
		timeFrame = "all_time" // Default if not provided
	}

	if exerciseIDStr == "" || latStr == "" || lonStr == "" {
		return echo.NewHTTPError(http.StatusBadRequest, "Missing required query parameters: exercise_id, latitude, longitude")
	}

	exerciseID, err := strconv.ParseInt(exerciseIDStr, 10, 32)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid exercise_id parameter")
	}

	latitude, err := strconv.ParseFloat(latStr, 64)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid latitude parameter")
	}

	longitude, err := strconv.ParseFloat(lonStr, 64)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid longitude parameter")
	}

	radiusMeters, err := strconv.ParseFloat(radiusStr, 64)
	if err != nil || radiusMeters <= 0 {
		radiusMeters = defaultSearchRadiusMeters // Use default radius
	}

	// Check if we can use the Redis cache
	redisClient := h.GetCacheClient()
	var respEntries []LocalLeaderboardEntry

	if redisClient != nil {
		cache := redis.NewLeaderboardCache(redisClient).WithTTL(leaderboardCacheTTL)
		cacheKey := redis.LocalLeaderboardKey(latitude, longitude, radiusMeters, exerciseIDStr, defaultLeaderboardLimit, timeFrame)

		// Try to get from cache
		ctx := c.Request().Context()
		err := cache.Get(ctx, cacheKey, &respEntries)
		if err == nil && len(respEntries) > 0 {
			// Cache hit
			// Mark as from cache for debugging
			for i := range respEntries {
				respEntries[i].CachedResult = true
			}
			return c.JSON(http.StatusOK, respEntries)
		}

		// Cache miss, continue with DB query
	}

	// Create enhanced K-NN query for improved performance
	// This query uses PostGIS K-NN operator (<->) for better spatial index performance
	query := `
		WITH ranked_workouts AS (
			SELECT 
				w.user_id,
				MAX(w.grade) AS best_score,
				ROW_NUMBER() OVER (ORDER BY MAX(w.grade) DESC) AS rank
			FROM workouts w
			WHERE w.exercise_id = $1
			GROUP BY w.user_id
		)
		SELECT 
			u.id AS user_id,
			u.username,
			u.first_name,
			u.last_name,
			$1::int as exercise_id,
			rw.best_score AS score,
			ST_Distance(u.last_location::geography, ST_GeographyFromText($2)::geography) AS distance_meters,
			MAX(w.completed_at) AS last_updated
		FROM ranked_workouts rw
		JOIN users u ON rw.user_id = u.id
		JOIN workouts w ON rw.user_id = w.user_id AND w.exercise_id = $1
		WHERE u.last_location IS NOT NULL
		AND ST_DWithin(u.last_location::geography, ST_GeographyFromText($2)::geography, $3)
		GROUP BY u.id, u.username, u.first_name, u.last_name, rw.best_score, u.last_location
		ORDER BY u.last_location <-> ST_GeographyFromText($2) ASC -- Using the <-> KNN operator for faster spatial ordering
		LIMIT $4
	`

	pointWKT := fmt.Sprintf("SRID=4326;POINT(%f %f)", longitude, latitude)

	// Execute query through the database connection
	// Use the DB() method to access the underlying database interface
	rows, err := h.Queries.DB().QueryContext(c.Request().Context(), query, exerciseID, pointWKT, radiusMeters, defaultLeaderboardLimit)
	if err != nil {
		log.Printf("ERROR [HandleGetLocalLeaderboard]: Failed to execute K-NN query: %v", err)
		// Fall back to the original implementation if the custom query fails
		return h.fallbackLocalLeaderboard(c, exerciseID, latitude, longitude, radiusMeters)
	}
	defer rows.Close()

	respEntries = []LocalLeaderboardEntry{}
	for rows.Next() {
		var entry struct {
			UserID      int32
			Username    string
			DisplayName sql.NullString // Keep DisplayName for scanning from SQL
			ExerciseID  int32
			Score       sql.NullInt32
			Distance    float64
			LastUpdated sql.NullTime
		}

		if err := rows.Scan(
			&entry.UserID,
			&entry.Username,
			&entry.DisplayName,
			&entry.ExerciseID,
			&entry.Score,
			&entry.Distance,
			&entry.LastUpdated,
		); err != nil {
			log.Printf("ERROR [HandleGetLocalLeaderboard]: Failed to scan row: %v", err)
			continue
		}

		// Format the data for response
		var lastUpdatedStr string
		if entry.LastUpdated.Valid {
			lastUpdatedStr = entry.LastUpdated.Time.Format(time.RFC3339)
		}

		score := int32(0)
		if entry.Score.Valid {
			score = entry.Score.Int32
		}

		// Split display_name into first_name and last_name
		firstName := ""
		lastName := ""
		displayName := GetStringFromInterface(entry.DisplayName)
		if displayName != "" {
			parts := strings.SplitN(displayName, " ", 2)
			firstName = parts[0]
			if len(parts) > 1 {
				lastName = parts[1]
			}
		}

		respEntries = append(respEntries, LocalLeaderboardEntry{
			UserID:      entry.UserID,
			Username:    entry.Username,
			FirstName:   firstName,
			LastName:    lastName,
			ExerciseID:  entry.ExerciseID,
			Score:       score,
			Distance:    entry.Distance,
			LastUpdated: lastUpdatedStr,
		})
	}

	if err := rows.Err(); err != nil {
		log.Printf("ERROR [HandleGetLocalLeaderboard]: Error iterating result rows: %v", err)
		return h.fallbackLocalLeaderboard(c, exerciseID, latitude, longitude, radiusMeters)
	}

	// Cache the result if Redis is available
	if redisClient != nil && len(respEntries) > 0 {
		cache := redis.NewLeaderboardCache(redisClient).WithTTL(leaderboardCacheTTL)
		cacheKey := redis.LocalLeaderboardKey(latitude, longitude, radiusMeters, exerciseIDStr, defaultLeaderboardLimit, timeFrame)

		// Don't store the cachedResult flag in Redis
		cacheCopy := make([]LocalLeaderboardEntry, len(respEntries))
		copy(cacheCopy, respEntries)
		for i := range cacheCopy {
			cacheCopy[i].CachedResult = false
		}

		ctx := c.Request().Context()
		if err := cache.Set(ctx, cacheKey, cacheCopy); err != nil {
			// Just log the error, don't fail the request
			log.Printf("Error caching local leaderboard: %v", err)
		}
	}

	// Return the result
	return c.JSON(http.StatusOK, respEntries)
}

// fallbackLocalLeaderboard uses the original query method from GetLocalLeaderboard if the enhanced K-NN query fails
func (h *Handler) fallbackLocalLeaderboard(c echo.Context, exerciseID int64, latitude, longitude, radiusMeters float64) error {
	// 2. Prepare parameters for DB query using the original implementation
	// Note: Param names match the generated struct from GetLocalLeaderboard query
	params := db.GetLocalLeaderboardParams{
		ExerciseID:    int32(exerciseID),
		StMakepoint_2: latitude,     // $2 = latitude
		StMakepoint:   longitude,    // $3 = longitude
		StDwithin:     radiusMeters, // $4 = radius
	}

	// 3. Fetch leaderboard data from database
	dbResults, err := h.Queries.GetLocalLeaderboard(c.Request().Context(), params)
	if err != nil {
		// Handle sql.ErrNoRows specifically? Maybe just return empty list.
		if err == sql.ErrNoRows {
			return c.JSON(http.StatusOK, []LocalLeaderboardEntry{}) // Return empty list
		}
		log.Printf("ERROR [handleGetLocalLeaderboard]: Failed to get local leaderboard: %v", err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve local leaderboard")
	}

	// 4. Map DB results to response struct
	respEntries := make([]LocalLeaderboardEntry, len(dbResults))
	for i, dbEntry := range dbResults {
		var score int32
		if scoreVal, ok := dbEntry.Score.(int64); ok { // Assert to int64 first (MAX often returns int64)
			score = int32(scoreVal)
		} else if scoreVal32, ok := dbEntry.Score.(int32); ok { // Fallback check for int32
			score = scoreVal32
		}
		// Handle potential nil score if MAX returns NULL (e.g., no workouts found)
		// score will remain 0 if dbEntry.Score is nil or not an int type

		// Split display_name into first_name and last_name
		firstName := ""
		lastName := ""
		displayName := GetStringFromInterface(dbEntry.DisplayName)
		if displayName != "" {
			parts := strings.SplitN(displayName, " ", 2)
			firstName = parts[0]
			if len(parts) > 1 {
				lastName = parts[1]
			}
		}

		respEntries[i] = LocalLeaderboardEntry{
			UserID:     dbEntry.UserID,
			Username:   dbEntry.Username,
			FirstName:  firstName,
			LastName:   lastName,
			ExerciseID: dbEntry.ExerciseID,
			Score:      score, // Use the correctly asserted score
		}
	}

	// 5. Send response
	return c.JSON(http.StatusOK, respEntries)
}

func mapStoreLeaderboardEntryToAPIEntry(storeEntry *store.LeaderboardEntry) LeaderboardAPIEntry {
	return LeaderboardAPIEntry{
		Rank:      storeEntry.Rank,
		UserID:    storeEntry.UserID,
		Username:  storeEntry.Username,
		FirstName: storeEntry.FirstName,
		LastName:  storeEntry.LastName,
		Score:     storeEntry.Score,
	}
}

// GetGlobalExerciseLeaderboard handles GET /leaderboards/global/exercise/:exerciseType
func (h *LeaderboardHandler) GetGlobalExerciseLeaderboard(c echo.Context) error {
	ctx := c.Request().Context()
	exerciseType := c.Param("exerciseType")
	if exerciseType == "" {
		h.logger.Warn(ctx, "GetGlobalExerciseLeaderboard: missing exerciseType param")
		return NewAPIError(http.StatusBadRequest, ErrCodeBadRequest, "Exercise type parameter is required")
	}

	limitStr := c.QueryParam("limit")
	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit <= 0 {
		limit = defaultLeaderboardLimit
	}

	// Read the time_frame query parameter
	timeFrame := c.QueryParam("time_frame")
	if timeFrame == "" {
		timeFrame = "all_time" // Default to all_time if not provided
	}

	h.logger.Debug(ctx, "GetGlobalExerciseLeaderboard called", "type", exerciseType, "limit", limit, "timeFrame", timeFrame)

	storeEntries, err := h.service.GetGlobalExerciseLeaderboard(ctx, exerciseType, limit, timeFrame) // Pass timeFrame
	if err != nil {
		h.logger.Error(ctx, "Error from GetGlobalExerciseLeaderboard service", "type", exerciseType, "timeFrame", timeFrame, "error", err)
		if err.Error() == "GetGlobalExerciseLeaderboard not implemented in store yet" || strings.Contains(err.Error(), "not implemented in store yet") {
			return NewAPIError(http.StatusNotImplemented, ErrCodeNotImplemented, "Global exercise leaderboard is not fully implemented yet.")
		}
		return NewAPIError(http.StatusInternalServerError, ErrCodeInternalServer, "Failed to retrieve global exercise leaderboard")
	}

	apiEntries := make([]LeaderboardAPIEntry, len(storeEntries))
	for i, entry := range storeEntries {
		apiEntries[i] = mapStoreLeaderboardEntryToAPIEntry(entry)
	}
	return c.JSON(http.StatusOK, apiEntries)
}

// GetGlobalAggregateLeaderboard handles GET /leaderboards/global/aggregate
func (h *LeaderboardHandler) GetGlobalAggregateLeaderboard(c echo.Context) error {
	ctx := c.Request().Context()
	limitStr := c.QueryParam("limit")
	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit <= 0 {
		limit = defaultLeaderboardLimit
	}

	// Read the time_frame query parameter
	timeFrame := c.QueryParam("time_frame")
	if timeFrame == "" {
		timeFrame = "all_time" // Default to all_time if not provided
	}

	// Log which endpoint is being accessed (overall or aggregate)
	path := c.Path()
	if strings.Contains(path, "/overall") {
		h.logger.Debug(ctx, "GetGlobalOverallLeaderboard called", "limit", limit, "timeFrame", timeFrame)
	} else {
		h.logger.Debug(ctx, "GetGlobalAggregateLeaderboard called", "limit", limit, "timeFrame", timeFrame)
	}

	storeEntries, err := h.service.GetGlobalAggregateLeaderboard(ctx, limit, timeFrame) // Pass timeFrame
	if err != nil {
		h.logger.Error(ctx, "Error from GetGlobalAggregateLeaderboard service", "timeFrame", timeFrame, "error", err)
		return NewAPIError(http.StatusInternalServerError, ErrCodeInternalServer, "Failed to retrieve global aggregate leaderboard")
	}

	apiEntries := make([]LeaderboardAPIEntry, len(storeEntries))
	for i, entry := range storeEntries {
		apiEntries[i] = mapStoreLeaderboardEntryToAPIEntry(entry)
	}
	return c.JSON(http.StatusOK, apiEntries)
}

// GetLocalExerciseLeaderboard handles GET /leaderboards/local/exercise/:exerciseType
func (h *LeaderboardHandler) GetLocalExerciseLeaderboard(c echo.Context) error {
	ctx := c.Request().Context()
	exerciseType := c.Param("exerciseType")
	if exerciseType == "" {
		h.logger.Warn(ctx, "GetLocalExerciseLeaderboard: missing exerciseType param")
		return NewAPIError(http.StatusBadRequest, ErrCodeBadRequest, "Exercise type parameter is required")
	}

	latStr := c.QueryParam("latitude")
	lonStr := c.QueryParam("longitude")
	radiusMetersStr := c.QueryParam("radius_meters")
	limitStr := c.QueryParam("limit")
	// Read the time_frame query parameter
	timeFrame := c.QueryParam("time_frame")
	if timeFrame == "" {
		timeFrame = "all_time" // Default to all_time if not provided
	}

	if latStr == "" || lonStr == "" {
		return NewAPIError(http.StatusBadRequest, ErrCodeBadRequest, "Missing required query parameters: latitude, longitude")
	}

	latitude, err := strconv.ParseFloat(latStr, 64)
	if err != nil {
		return NewAPIError(http.StatusBadRequest, ErrCodeBadRequest, "Invalid latitude parameter")
	}
	longitude, err := strconv.ParseFloat(lonStr, 64)
	if err != nil {
		return NewAPIError(http.StatusBadRequest, ErrCodeBadRequest, "Invalid longitude parameter")
	}

	radiusMeters, err := strconv.Atoi(radiusMetersStr)
	if err != nil || radiusMeters <= 0 {
		radiusMeters = defaultSearchRadiusMeters
	}
	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit <= 0 {
		limit = defaultLeaderboardLimit
	}
	h.logger.Debug(ctx, "GetLocalExerciseLeaderboard called", "type", exerciseType, "lat", latitude, "lon", longitude, "radiusM", radiusMeters, "limit", limit, "timeFrame", timeFrame)

	storeEntries, err := h.service.GetLocalExerciseLeaderboard(ctx, exerciseType, latitude, longitude, radiusMeters, limit, timeFrame) // Pass timeFrame
	if err != nil {
		h.logger.Error(ctx, "Error from GetLocalExerciseLeaderboard service", "type", exerciseType, "timeFrame", timeFrame, "error", err)
		if err.Error() == "GetLocalExerciseLeaderboard not implemented in store yet" || strings.Contains(err.Error(), "not implemented in store yet") {
			return NewAPIError(http.StatusNotImplemented, ErrCodeNotImplemented, "Local exercise leaderboard is not fully implemented yet.")
		}
		return NewAPIError(http.StatusInternalServerError, ErrCodeInternalServer, "Failed to retrieve local exercise leaderboard")
	}

	apiEntries := make([]LeaderboardAPIEntry, len(storeEntries))
	for i, entry := range storeEntries {
		apiEntries[i] = mapStoreLeaderboardEntryToAPIEntry(entry)
	}
	return c.JSON(http.StatusOK, apiEntries)
}

// GetLocalAggregateLeaderboard handles GET /leaderboards/local/aggregate
func (h *LeaderboardHandler) GetLocalAggregateLeaderboard(c echo.Context) error {
	ctx := c.Request().Context()
	latStr := c.QueryParam("latitude")
	lonStr := c.QueryParam("longitude")
	radiusMetersStr := c.QueryParam("radius_meters")
	limitStr := c.QueryParam("limit")
	// Read the time_frame query parameter
	timeFrame := c.QueryParam("time_frame")
	if timeFrame == "" {
		timeFrame = "all_time" // Default to all_time if not provided
	}

	if latStr == "" || lonStr == "" {
		return NewAPIError(http.StatusBadRequest, ErrCodeBadRequest, "Missing required query parameters: latitude, longitude")
	}

	latitude, err := strconv.ParseFloat(latStr, 64)
	if err != nil {
		return NewAPIError(http.StatusBadRequest, ErrCodeBadRequest, "Invalid latitude parameter")
	}
	longitude, err := strconv.ParseFloat(lonStr, 64)
	if err != nil {
		return NewAPIError(http.StatusBadRequest, ErrCodeBadRequest, "Invalid longitude parameter")
	}

	radiusMeters, err := strconv.Atoi(radiusMetersStr)
	if err != nil || radiusMeters <= 0 {
		radiusMeters = defaultSearchRadiusMeters
	}
	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit <= 0 {
		limit = defaultLeaderboardLimit
	}

	// Log which endpoint is being accessed (overall or aggregate)
	path := c.Path()
	if strings.Contains(path, "/overall") {
		h.logger.Debug(ctx, "GetLocalOverallLeaderboard called", "lat", latitude, "lon", longitude, "radiusM", radiusMeters, "limit", limit, "timeFrame", timeFrame)
	} else {
		h.logger.Debug(ctx, "GetLocalAggregateLeaderboard called", "lat", latitude, "lon", longitude, "radiusM", radiusMeters, "limit", limit, "timeFrame", timeFrame)
	}

	storeEntries, err := h.service.GetLocalAggregateLeaderboard(ctx, latitude, longitude, radiusMeters, limit, timeFrame) // Pass timeFrame
	if err != nil {
		h.logger.Error(ctx, "Error from GetLocalAggregateLeaderboard service", "timeFrame", timeFrame, "error", err)
		return NewAPIError(http.StatusInternalServerError, ErrCodeInternalServer, "Failed to retrieve local aggregate leaderboard")
	}

	apiEntries := make([]LeaderboardAPIEntry, len(storeEntries))
	for i, entry := range storeEntries {
		apiEntries[i] = mapStoreLeaderboardEntryToAPIEntry(entry)
	}
	return c.JSON(http.StatusOK, apiEntries)
}
