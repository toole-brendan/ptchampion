package handlers

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"

	db "ptchampion/internal/store/postgres"

	"github.com/go-chi/chi/v5"
)

const defaultLeaderboardLimit = 20

// LeaderboardEntry defines the structure for a single entry on the leaderboard
type LeaderboardEntry struct {
	Username    string `json:"username"`
	DisplayName string `json:"display_name"`
	BestGrade   int32  `json:"best_grade"`
}

// GetLeaderboard handles requests to retrieve the leaderboard for a specific exercise type
func (h *Handler) GetLeaderboard(w http.ResponseWriter, r *http.Request) {
	exerciseType := chi.URLParam(r, "exerciseType")
	if exerciseType == "" {
		http.Error(w, "Exercise type is required", http.StatusBadRequest)
		return
	}

	// Get limit from query param, default if not provided or invalid
	limitStr := r.URL.Query().Get("limit")
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
	dbEntries, err := h.Queries.GetLeaderboardByExerciseType(r.Context(), params)
	if err != nil {
		log.Printf("ERROR: Failed to get leaderboard for type '%s': %v", exerciseType, err)
		http.Error(w, "Failed to retrieve leaderboard", http.StatusInternalServerError)
		return
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
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(respEntries); err != nil {
		log.Printf("ERROR: Failed to encode leaderboard response: %v", err)
	}
}
