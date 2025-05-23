package handlers

import (
	"math"
	"net/http"
	"strconv"
	"strings"
	"time"

	"ptchampion/internal/logging"
	"ptchampion/internal/store" // For store.WorkoutRecord, store.PaginatedWorkoutRecords
	"ptchampion/internal/workouts"

	"github.com/labstack/echo/v4"
)

// LogWorkoutRequest defines the API request for logging a workout.
// This is the primary request struct for creating a workout record.
type LogWorkoutRequest struct {
	ExerciseID      int32     `json:"exercise_id" validate:"required,gt=0"`
	Reps            *int32    `json:"reps,omitempty" validate:"omitempty,min=0"`
	DurationSeconds *int32    `json:"duration_seconds,omitempty" validate:"omitempty,min=0"`
	FormScore       *int32    `json:"form_score,omitempty" validate:"omitempty,min=0,max=100"`
	CompletedAt     time.Time `json:"completed_at" validate:"required"`
	// Grade removed - calculate server-side only
}

// WorkoutResponse defines the API response for a single workout record.
// This maps from store.WorkoutRecord.
type WorkoutResponse struct {
	ID              int32     `json:"id"`
	UserID          int32     `json:"user_id"`
	ExerciseID      int32     `json:"exercise_id"`
	ExerciseName    string    `json:"exercise_name"`
	ExerciseType    string    `json:"exercise_type"`
	Reps            *int32    `json:"reps,omitempty"`
	DurationSeconds *int32    `json:"duration_seconds,omitempty"`
	FormScore       *int32    `json:"form_score,omitempty"`
	Grade           int32     `json:"grade"`
	CompletedAt     time.Time `json:"completed_at"`
	CreatedAt       time.Time `json:"created_at"`
}

// PaginatedWorkoutsResponse defines the API response for a list of workout records.
// This uses the WorkoutResponse struct defined above.
type PaginatedWorkoutsResponse struct {
	Items      []WorkoutResponse `json:"items"` // Corrected field name from Workouts to Items
	TotalCount int64             `json:"totalCount"`
	Page       int               `json:"page"`
	PageSize   int               `json:"pageSize"`
	TotalPages int               `json:"totalPages"`
}

// UpdateWorkoutVisibilityRequest defines the API request for updating visibility.
type UpdateWorkoutVisibilityRequest struct {
	IsPublic bool `json:"is_public"`
}

// WorkoutHandler handles workout-related API requests.
type WorkoutHandler struct {
	service workouts.Service
	logger  logging.Logger
}

// NewWorkoutHandler creates a new WorkoutHandler instance.
func NewWorkoutHandler(service workouts.Service, logger logging.Logger) *WorkoutHandler {
	return &WorkoutHandler{
		service: service,
		logger:  logger,
	}
}

func mapStoreWorkoutRecordToResponse(record *store.WorkoutRecord) WorkoutResponse {
	return WorkoutResponse{
		ID:              record.ID,
		UserID:          record.UserID,
		ExerciseID:      record.ExerciseID,
		ExerciseName:    record.ExerciseName,
		ExerciseType:    record.ExerciseType,
		Reps:            record.Reps,
		DurationSeconds: record.DurationSeconds,
		FormScore:       record.FormScore,
		Grade:           record.Grade,
		CompletedAt:     record.CompletedAt,
		CreatedAt:       record.CreatedAt,
	}
}

// LogWorkout handles POST requests to log a new workout record.
func (h *WorkoutHandler) LogWorkout(c echo.Context) error {
	var req LogWorkoutRequest
	if err := c.Bind(&req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request body")
	}

	if err := c.Validate(req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}

	userID := c.Get("user_id").(int32)

	// Server calculates grade - no client input accepted
	serviceData := &workouts.LogWorkoutData{
		ExerciseID:      req.ExerciseID,
		Reps:            req.Reps,
		DurationSeconds: req.DurationSeconds,
		FormScore:       req.FormScore,
		CompletedAt:     req.CompletedAt,
		// Grade calculated in service layer
	}

	workout, err := h.service.LogWorkout(c.Request().Context(), userID, serviceData)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusCreated, mapStoreWorkoutRecordToResponse(workout))
}

// ListUserWorkouts handles GET requests to list a user's workout records.
func (h *WorkoutHandler) ListUserWorkouts(c echo.Context) error {
	ctx := c.Request().Context()
	userID, err := GetUserIDFromContext(c)
	if err != nil {
		h.logger.Error(ctx, "Could not get user ID from context for ListUserWorkouts", "error", err)
		return NewAPIError(http.StatusUnauthorized, ErrCodeUnauthorized, "Authentication error: User ID not found")
	}

	pageStr := c.QueryParam("page")
	pageSizeStr := c.QueryParam("pageSize")
	page, _ := strconv.Atoi(pageStr)
	pageSize, _ := strconv.Atoi(pageSizeStr)

	paginatedResults, err := h.service.ListUserWorkouts(ctx, userID, page, pageSize)
	if err != nil {
		h.logger.Error(ctx, "Service failed to list user workouts", "userID", userID, "error", err)
		return NewAPIError(http.StatusInternalServerError, ErrCodeInternalServer, "Failed to retrieve workout records")
	}

	apiItems := make([]WorkoutResponse, len(paginatedResults.Records))
	for i, record := range paginatedResults.Records {
		apiItems[i] = mapStoreWorkoutRecordToResponse(record)
	}

	actualPage := page
	if actualPage == 0 {
		actualPage = 1
	}
	actualPageSize := pageSize
	if actualPageSize == 0 {
		actualPageSize = 20
	}

	return c.JSON(http.StatusOK, PaginatedWorkoutsResponse{
		Items:      apiItems, // Corrected from Workouts to Items
		TotalCount: paginatedResults.TotalCount,
		Page:       actualPage,
		PageSize:   actualPageSize,
		TotalPages: int(math.Ceil(float64(paginatedResults.TotalCount) / float64(actualPageSize))),
	})
}

// UpdateWorkoutVisibility handles PATCH requests to update a workout record's visibility.
func (h *WorkoutHandler) UpdateWorkoutVisibility(c echo.Context) error {
	ctx := c.Request().Context()
	userID, err := GetUserIDFromContext(c)
	if err != nil {
		h.logger.Error(ctx, "Could not get user ID from context for UpdateWorkoutVisibility", "error", err)
		return NewAPIError(http.StatusUnauthorized, ErrCodeUnauthorized, "Authentication error: User ID not found")
	}

	workoutIDStr := c.Param("workout_id")
	workoutID, err := strconv.Atoi(workoutIDStr)
	if err != nil {
		h.logger.Warn(ctx, "Invalid workout ID format", "workoutID", workoutIDStr, "error", err)
		return NewAPIError(http.StatusBadRequest, ErrCodeBadRequest, "Invalid workout ID format")
	}

	var req UpdateWorkoutVisibilityRequest
	if err := c.Bind(&req); err != nil {
		h.logger.Error(ctx, "Failed to decode UpdateWorkoutVisibility request", "error", err)
		return NewAPIError(http.StatusBadRequest, ErrCodeBadRequest, "Invalid request body")
	}

	// No validation needed for a single boolean? Add if more complex later.

	err = h.service.UpdateWorkoutVisibility(ctx, userID, int32(workoutID), req.IsPublic)
	if err != nil {
		if err == store.ErrWorkoutRecordNotFound {
			return NewAPIError(http.StatusNotFound, ErrCodeNotFound, "Workout record not found")
		} else if strings.Contains(err.Error(), "user does not have permission") {
			return NewAPIError(http.StatusForbidden, ErrCodeForbidden, "You do not have permission to modify this workout")
		}
		h.logger.Error(ctx, "Service failed to update workout visibility", "userID", userID, "workoutID", workoutID, "error", err)
		return NewAPIError(http.StatusInternalServerError, ErrCodeInternalServer, "Failed to update workout visibility")
	}

	return c.NoContent(http.StatusOK)
}
