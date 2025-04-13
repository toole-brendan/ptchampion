package handlers

import (
	"database/sql"
	"log"
	"math"
	"net/http"
	"strconv"
	"time"

	dbStore "ptchampion/internal/store/postgres"

	"github.com/labstack/echo/v4"
)

// SaveWorkoutRequest defines the structure for the workout logging request body
type SaveWorkoutRequest struct {
	ExerciseID      int32     `json:"exercise_id" validate:"required,gt=0"`
	Repetitions     *int32    `json:"repetitions" validate:"omitempty,gte=0"`      // Pointer for optional field
	DurationSeconds *int32    `json:"duration_seconds" validate:"omitempty,gte=0"` // Pointer for optional field
	CompletedAt     time.Time `json:"completed_at" validate:"required"`
	// Add other fields if needed, like notes, form_score, etc.
	// Ensure validation tags match requirements (e.g., required, omitempty, min/max values)
}

// PaginatedWorkoutsResponse defines the structure for paginated workout history
type PaginatedWorkoutsResponse struct {
	Workouts   []WorkoutResponse `json:"workouts"`
	TotalCount int64             `json:"totalCount"`
	Page       int               `json:"page"`
	PageSize   int               `json:"pageSize"`
	TotalPages int               `json:"totalPages"`
}

// WorkoutResponse defines the structure for a single workout in the history list
// Mapping from dbStore.GetUserWorkoutsRow
type WorkoutResponse struct {
	ID              int32         `json:"id"`
	UserID          int32         `json:"userId"` // Match JSON style guide if needed
	ExerciseID      int32         `json:"exerciseId"`
	ExerciseName    string        `json:"exerciseName"`
	Repetitions     sql.NullInt32 `json:"repetitions"`     // Use sql.NullInt32 for potential nulls
	DurationSeconds sql.NullInt32 `json:"durationSeconds"` // Use sql.NullInt32 for potential nulls
	FormScore       sql.NullInt32 `json:"formScore"`       // Use sql.NullInt32 for potential nulls
	Grade           int32         `json:"grade"`
	CreatedAt       time.Time     `json:"createdAt"`
	CompletedAt     time.Time     `json:"completedAt"`
}

// handleSaveWorkout handles the POST /api/v1/workouts request
func (h *Handler) handleSaveWorkout(c echo.Context) error {
	// 1. Get user ID from context (set by auth middleware)
	userID, err := GetUserIDFromContext(c)
	if err != nil {
		log.Printf("ERROR [handleSaveWorkout]: Could not get user ID from context: %v", err)
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	// 2. Bind and validate request body
	var req SaveWorkoutRequest
	if err := c.Bind(&req); err != nil {
		log.Printf("ERROR [handleSaveWorkout]: Failed to bind request: %v", err)
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request body")
	}
	if err := c.Validate(&req); err != nil {
		log.Printf("INFO [handleSaveWorkout]: Invalid request data: %v", err)
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}

	// 3. Fetch Exercise details (needed for grading and exercise_type)
	exercise, err := h.Queries.GetExercise(c.Request().Context(), req.ExerciseID)
	if err != nil {
		if err == sql.ErrNoRows {
			log.Printf("INFO [handleSaveWorkout]: Exercise with ID %d not found", req.ExerciseID)
			return echo.NewHTTPError(http.StatusNotFound, "Exercise not found")
		}
		log.Printf("ERROR [handleSaveWorkout]: Failed to get exercise %d: %v", req.ExerciseID, err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve exercise details")
	}

	// 4. Calculate Grade (Placeholder - Implement proper logic using grading package)
	// grade := grading.CalculateScore(exercise.Type, req.Repetitions, req.DurationSeconds)
	var grade int32 = 85 // Placeholder value

	// 5. Prepare parameters for DB query
	params := dbStore.CreateWorkoutParams{
		UserID:          userID,
		ExerciseID:      req.ExerciseID,
		ExerciseType:    exercise.Type,
		Repetitions:     int32PtrToNullInt32(req.Repetitions),
		DurationSeconds: int32PtrToNullInt32(req.DurationSeconds),
		Grade:           grade,
		CompletedAt:     req.CompletedAt,
	}

	// 6. Call the database query
	createdWorkout, err := h.Queries.CreateWorkout(c.Request().Context(), params)
	if err != nil {
		log.Printf("ERROR [handleSaveWorkout]: Failed to create workout for user %d: %v", userID, err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to save workout")
	}

	// 7. Return the created workout data
	// Consider creating a response struct if you want to customize the output
	return c.JSON(http.StatusCreated, createdWorkout)
}

// handleGetWorkouts handles the GET /api/v1/workouts request
func (h *Handler) handleGetWorkouts(c echo.Context) error {
	// 1. Get user ID from context
	userID, err := GetUserIDFromContext(c)
	if err != nil {
		log.Printf("ERROR [handleGetWorkouts]: Could not get user ID from context: %v", err)
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized")
	}

	// 2. Parse pagination parameters
	pageStr := c.QueryParam("page")
	pageSizeStr := c.QueryParam("pageSize")

	page, err := strconv.Atoi(pageStr)
	if err != nil || page < 1 {
		page = 1 // Default to page 1
	}

	pageSize, err := strconv.Atoi(pageSizeStr)
	if err != nil || pageSize < 1 || pageSize > 100 { // Add a max page size
		pageSize = 20 // Default page size
	}

	// 3. Calculate offset
	offset := (page - 1) * pageSize

	// 4. Get total workout count for the user
	totalCount, err := h.Queries.GetUserWorkoutsCount(c.Request().Context(), userID)
	if err != nil {
		log.Printf("ERROR [handleGetWorkouts]: Failed to get workout count for user %d: %v", userID, err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve workout count")
	}

	if totalCount == 0 {
		// Return empty response if no workouts exist
		resp := PaginatedWorkoutsResponse{
			Workouts:   []WorkoutResponse{},
			TotalCount: 0,
			Page:       page,
			PageSize:   pageSize,
			TotalPages: 0,
		}
		return c.JSON(http.StatusOK, resp)
	}

	// 5. Get paginated workouts from DB
	workouts, err := h.Queries.GetUserWorkouts(c.Request().Context(), dbStore.GetUserWorkoutsParams{
		UserID: userID,
		Limit:  int32(pageSize),
		Offset: int32(offset),
	})
	if err != nil {
		log.Printf("ERROR [handleGetWorkouts]: Failed to get workouts for user %d: %v", userID, err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve workouts")
	}

	// 6. Map DB results to response structure
	workoutResponses := make([]WorkoutResponse, len(workouts))
	for i, w := range workouts {
		workoutResponses[i] = WorkoutResponse{
			ID:              w.ID,
			UserID:          w.UserID,
			ExerciseID:      w.ExerciseID,
			ExerciseName:    w.ExerciseName,
			Repetitions:     w.Repetitions,
			DurationSeconds: w.DurationSeconds,
			FormScore:       w.FormScore, // Include the new form_score
			Grade:           w.Grade,
			CreatedAt:       w.CreatedAt,
			CompletedAt:     w.CompletedAt,
		}
	}

	// 7. Calculate total pages
	totalPages := int(math.Ceil(float64(totalCount) / float64(pageSize)))

	// 8. Construct the final response
	resp := PaginatedWorkoutsResponse{
		Workouts:   workoutResponses,
		TotalCount: totalCount,
		Page:       page,
		PageSize:   pageSize,
		TotalPages: totalPages,
	}

	return c.JSON(http.StatusOK, resp)
}

// --- REMOVED Helper functions (Already defined elsewhere or will be moved) ---
