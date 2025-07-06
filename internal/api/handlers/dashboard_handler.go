package handlers

import (
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
	"ptchampion/internal/logging"
	"ptchampion/internal/workouts"
)

// DashboardHandler handles dashboard-related API requests
type DashboardHandler struct {
	workoutService workouts.Service
	logger         logging.Logger
}

// NewDashboardHandler creates a new dashboard handler instance
func NewDashboardHandler(workoutService workouts.Service, logger logging.Logger) *DashboardHandler {
	return &DashboardHandler{
		workoutService: workoutService,
		logger:         logger,
	}
}

// DashboardStats represents aggregated dashboard statistics
type DashboardStats struct {
	TotalWorkouts    int              `json:"totalWorkouts"`
	TotalReps        int              `json:"totalReps"`
	AverageRunTime   *float64         `json:"averageRunTime"` // in seconds, nil if no runs
	RecentWorkouts   []WorkoutSummary `json:"recentWorkouts"`
	ExerciseCounts   map[string]int   `json:"exerciseCounts"`
	LastWorkoutDate  *time.Time       `json:"lastWorkoutDate"`
}

// WorkoutSummary represents a minimal workout for dashboard display
type WorkoutSummary struct {
	ID           int32     `json:"id"`
	ExerciseName string    `json:"exerciseName"`
	Reps         int       `json:"reps"`
	Duration     int       `json:"duration"` // in seconds
	Score        int32     `json:"score"`
	CreatedAt    time.Time `json:"createdAt"`
}

// GetDashboardStats returns aggregated dashboard statistics for the authenticated user
func (h *DashboardHandler) GetDashboardStats(c echo.Context) error {
	ctx := c.Request().Context()
	userID, err := GetUserIDFromContext(c)
	if err != nil {
		h.logger.Error(ctx, "Could not get user ID from context for GetDashboardStats", "error", err)
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": "User not found"})
	}

	// Get aggregated stats from the workout service
	stats, err := h.workoutService.GetDashboardStats(ctx, userID)
	if err != nil {
		h.logger.Error(ctx, "Failed to get dashboard stats", "error", err, "userID", userID)
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to retrieve dashboard statistics"})
	}

	// Transform the service response to the API response format
	response := DashboardStats{
		TotalWorkouts:   stats.TotalWorkouts,
		TotalReps:       stats.TotalReps,
		AverageRunTime:  stats.AverageRunTime,
		LastWorkoutDate: stats.LastWorkoutDate,
		ExerciseCounts:  stats.ExerciseCounts,
		RecentWorkouts:  make([]WorkoutSummary, len(stats.RecentWorkouts)),
	}

	// Convert recent workouts to API format
	for i, w := range stats.RecentWorkouts {
		reps := 0
		if w.Reps != nil {
			reps = int(*w.Reps)
		}
		duration := 0
		if w.DurationSeconds != nil {
			duration = int(*w.DurationSeconds)
		}
		response.RecentWorkouts[i] = WorkoutSummary{
			ID:           w.ID,
			ExerciseName: w.ExerciseName,
			Reps:         reps,
			Duration:     duration,
			Score:        w.Grade,
			CreatedAt:    w.CreatedAt,
		}
	}

	return c.JSON(http.StatusOK, response)
}