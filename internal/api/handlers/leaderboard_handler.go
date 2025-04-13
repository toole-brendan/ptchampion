package handlers

import (
	"database/sql"
	"log"
	"net/http"
	"strconv"

	db "ptchampion/internal/store/postgres"

	"github.com/labstack/echo/v4"
)

// Default radius in meters (approx 5 miles)
const defaultSearchRadiusMeters = 8047

const defaultLeaderboardLimit = 20

// LocalLeaderboardEntry defines the structure for local leaderboard results
type LocalLeaderboardEntry struct {
	UserID      int32  `json:"userId"`
	Username    string `json:"username"`
	DisplayName string `json:"displayName"`
	ExerciseID  int32  `json:"exerciseId"`
	Score       int32  `json:"score"` // Represents MAX(repetitions) or MIN(duration) etc.
}

// LeaderboardEntry defines the structure for a single entry on the leaderboard
type LeaderboardEntry struct {
	Username    string `json:"username"`
	DisplayName string `json:"display_name"`
	BestGrade   int32  `json:"best_grade"`
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

		respEntries[i] = LeaderboardEntry{
			Username:    dbEntry.Username,
			DisplayName: getNullString(dbEntry.DisplayName),
			BestGrade:   bestGrade,
		}
	}

	// Send response
	return c.JSON(http.StatusOK, respEntries)
}

// handleGetLocalLeaderboard handles GET /leaderboards/local
func (h *Handler) handleGetLocalLeaderboard(c echo.Context) error {
	// 1. Parse required query parameters: exercise_id, latitude, longitude
	exerciseIDStr := c.QueryParam("exercise_id")
	latStr := c.QueryParam("latitude")
	lonStr := c.QueryParam("longitude")
	radiusStr := c.QueryParam("radius_meters") // Optional

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

	// 2. Prepare parameters for DB query
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

		respEntries[i] = LocalLeaderboardEntry{
			UserID:      dbEntry.UserID,
			Username:    dbEntry.Username,
			DisplayName: getNullString(dbEntry.DisplayName), // Handle potential null display name
			ExerciseID:  dbEntry.ExerciseID,
			Score:       score, // Use the correctly asserted score
		}
	}

	// 5. Send response
	return c.JSON(http.StatusOK, respEntries)
}
