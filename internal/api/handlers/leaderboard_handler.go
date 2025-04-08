package handlers

import (
	"log"
	"net/http"
	"strconv"

	db "ptchampion/internal/store/postgres"

	"github.com/labstack/echo/v4"
)

const defaultLeaderboardLimit = 20

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
