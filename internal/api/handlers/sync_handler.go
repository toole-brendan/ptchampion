package handlers

import (
	"log"
	"net/http"
	"time"

	dbStore "ptchampion/internal/store/postgres"

	"github.com/labstack/echo/v4"
)

// SyncPayload defines the structure for synchronization requests
type SyncPayload struct {
	LastSyncedAt *time.Time     `json:"last_synced_at,omitempty"`
	Exercises    []SyncExercise `json:"exercises,omitempty"`
}

// SyncExercise defines an exercise record for synchronization
type SyncExercise struct {
	ID            int32      `json:"id,omitempty"` // Local ID, not used by server
	ExerciseID    int32      `json:"exercise_id" validate:"required,gt=0"`
	Reps          *int32     `json:"reps,omitempty"`
	TimeInSeconds *int32     `json:"time_in_seconds,omitempty"`
	Distance      *int32     `json:"distance,omitempty"`
	Notes         *string    `json:"notes,omitempty"`
	CreatedAt     *time.Time `json:"created_at,omitempty"`
}

// LogExerciseResponse defines the response structure for logged exercises
type LogExerciseResponse struct {
	ID            int32      `json:"id"`
	UserID        int32      `json:"user_id"`
	ExerciseID    int32      `json:"exercise_id"`
	ExerciseName  string     `json:"exercise_name"`
	ExerciseType  string     `json:"exercise_type"`
	Reps          *int32     `json:"reps,omitempty"`
	TimeInSeconds *int32     `json:"time_in_seconds,omitempty"`
	Distance      *int32     `json:"distance,omitempty"`
	Notes         *string    `json:"notes,omitempty"`
	Grade         int32      `json:"grade"`
	CreatedAt     *time.Time `json:"created_at,omitempty"`
}

// SyncResponse defines the response for synchronization requests
type SyncResponse struct {
	SyncedAt time.Time             `json:"synced_at"`
	Workouts []LogExerciseResponse `json:"workouts,omitempty"`
}

// PostSync handles synchronization of exercise data between client and server
func (h *Handler) PostSync(c echo.Context) error {
	// 1. Get user ID from context
	userID, ok := c.Get("user_id").(int32)
	if !ok {
		log.Printf("ERROR: Could not get user ID from context")
		return echo.NewHTTPError(http.StatusInternalServerError, "Authentication error")
	}

	// 2. Parse request body
	var req SyncPayload
	if err := c.Bind(&req); err != nil {
		log.Printf("ERROR: Failed to decode sync request: %v", err)
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request body")
	}

	// 3. Validate request
	if err := c.Validate(req); err != nil {
		log.Printf("INFO: Invalid sync request: %v", err)
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}

	// 4. Begin transaction
	// This section may need adjustment based on how your dbStore handles transactions
	// For now, we'll use direct queries without transactions

	// 5. Process incoming exercises (if any)
	responseExercises := []LogExerciseResponse{}

	if len(req.Exercises) > 0 {
		for _, syncEx := range req.Exercises {
			// Fetch exercise details to get name and type
			exercise, err := h.Queries.GetExercise(c.Request().Context(), syncEx.ExerciseID)
			if err != nil {
				log.Printf("ERROR: Failed to get exercise %d details during sync: %v", syncEx.ExerciseID, err)
				continue // Skip this exercise but continue processing others
			}

			// Calculate grade if possible
			var grade int32 = 0 // Default to 0 if we can't calculate
			if syncEx.Reps != nil || syncEx.TimeInSeconds != nil {
				// Logic to calculate grade based on exercise type and performance
				// This is simplified - should use the grading package
				grade = 70 // Placeholder
			}

			// Prepare DB params for LogWorkout
			params := dbStore.LogWorkoutParams{
				UserID:          userID,
				ExerciseID:      syncEx.ExerciseID,
				ExerciseType:    exercise.Type,
				Repetitions:     int32PtrToNullInt32(syncEx.Reps),
				DurationSeconds: int32PtrToNullInt32(syncEx.TimeInSeconds),
				Grade:           grade,
				FormScore:       int32PtrToNullInt32(nil), // Default form score
				CompletedAt:     time.Now(),
				IsPublic:        true, // Default to public
			}

			// Save to database using LogWorkout
			loggedEx, err := h.Queries.LogWorkout(c.Request().Context(), params)
			if err != nil {
				log.Printf("ERROR: Failed to log synced exercise %d for user %d: %v",
					syncEx.ExerciseID, userID, err)
				continue // Skip this exercise but continue processing others
			}

			// Add to response
			respEx := LogExerciseResponse{
				ID:            loggedEx.ID,
				UserID:        loggedEx.UserID,
				ExerciseID:    loggedEx.ExerciseID,
				ExerciseName:  exercise.Name,
				ExerciseType:  exercise.Type,
				Reps:          nullInt32ToInt32Ptr(loggedEx.Repetitions),
				TimeInSeconds: nullInt32ToInt32Ptr(loggedEx.DurationSeconds),
				Distance:      nil, // No longer supported in workouts table
				Notes:         nil, // No longer supported in workouts table
				Grade:         loggedEx.Grade,
				CreatedAt:     &loggedEx.CreatedAt,
			}
			responseExercises = append(responseExercises, respEx)
		}
	}

	// 6. Get exercises from server since last sync (if lastSyncedAt provided)
	if req.LastSyncedAt != nil {
		// Logic to fetch exercises created since lastSyncedAt
		// This is a placeholder and would need actual implementation
	}

	// 7. Update user's last synced timestamp
	now := time.Now()
	// This would typically update the last_synced_at field for the user
	// For now, we're commenting this out since we need to see the actual DB schema
	/*
		_, err := h.Queries.UpdateUserLastSynced(c.Request().Context(), dbStore.UpdateUserLastSyncedParams{
			ID:          userID,
			LastSyncedAt: now,
		})
		if err != nil {
			log.Printf("ERROR: Failed to update last synced time for user %d: %v", userID, err)
			return echo.NewHTTPError(http.StatusInternalServerError, "Failed to complete sync")
		}
	*/

	// 9. Return response
	resp := SyncResponse{
		SyncedAt: now,
		Workouts: responseExercises,
	}

	return c.JSON(http.StatusOK, resp)
}
