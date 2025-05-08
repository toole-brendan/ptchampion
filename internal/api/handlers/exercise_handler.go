package handlers

import (
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"time"

	// dbStore "ptchampion/internal/store/postgres" // No longer directly needed by handler
	"ptchampion/internal/exercises" // Import the new exercises service package
	"ptchampion/internal/logging"
	"ptchampion/internal/store" // For store models like store.UserExerciseRecord

	// REMOVE: "github.com/go-playground/validator/v10"

	"github.com/labstack/echo/v4"
)

// REMOVE: Define a global validator instance for this package
// var exerciseValidate = validator.New()

// LogExerciseRequest defines the payload for logging an exercise
type LogExerciseRequest struct {
	ExerciseID int32   `json:"exercise_id" validate:"required,gt=0"`          // Must be positive
	Reps       *int32  `json:"reps,omitempty" validate:"omitempty,min=0"`     // Optional, non-negative
	Duration   *int32  `json:"duration,omitempty" validate:"omitempty,min=0"` // Optional, in seconds, non-negative
	Distance   *int32  `json:"distance,omitempty" validate:"omitempty,min=0"` // Optional, in meters?, non-negative
	Notes      *string `json:"notes,omitempty"`                               // Optional
	// Add FormScore, Completed, DeviceID back if needed by frontend/requirements
}

// ExerciseLogResponse defines the structure for returning a logged exercise
type LogExerciseResponse struct {
	ID            int32   `json:"id"`
	UserID        int32   `json:"user_id"`
	ExerciseID    int32   `json:"exercise_id"`
	ExerciseName  string  `json:"exercise_name"` // Added field
	ExerciseType  string  `json:"exercise_type"` // Added field
	Reps          *int32  `json:"reps,omitempty"`
	TimeInSeconds *int32  `json:"time_in_seconds,omitempty"` // Renamed from duration for consistency?
	Distance      *int32  `json:"distance,omitempty"`
	Notes         *string `json:"notes,omitempty"`
	Grade         int32   `json:"grade"` // Assuming grade is always calculated
	// FormScore     *int32    `json:"form_score,omitempty"` // Add back if needed
	// Completed     bool      `json:"completed"` // Add back if needed
	// DeviceID      *string   `json:"device_id,omitempty"` // Add back if needed
	CreatedAt time.Time `json:"created_at"`
}

// PaginatedExerciseHistoryResponse defines the structure for paginated user exercise history
type PaginatedExerciseHistoryResponse struct {
	Items      []LogExerciseResponse `json:"items"`
	TotalCount int64                 `json:"total_count"`
	Page       int                   `json:"page"`
	PageSize   int                   `json:"page_size"`
}

// ExerciseHistoryResponse defines the structure for returning user exercise history
// ... existing struct ...

// Simple Exercise response mirroring the DB model for now
// Keep naming consistent with Kotlin ExerciseResponse (lowercase snake_case for JSON)
type ListExerciseResponse struct {
	ID          int32   `json:"id"`
	Name        string  `json:"name"`
	Description *string `json:"description,omitempty"` // Use pointer for nullable string
	Type        string  `json:"type"`
}

// --- New Exercise Handler ---

// ExerciseHandler handles exercise-related API requests.
type ExerciseHandler struct {
	service exercises.Service // Depends on the new exercise service
	logger  logging.Logger
}

// NewExerciseHandler creates a new ExerciseHandler instance.
func NewExerciseHandler(service exercises.Service, logger logging.Logger) *ExerciseHandler {
	return &ExerciseHandler{
		service: service,
		logger:  logger,
	}
}

// mapStoreUserExerciseRecordToLogExerciseResponse converts store.UserExerciseRecord to LogExerciseResponse
func mapStoreUserExerciseRecordToLogExerciseResponse(record *store.UserExerciseRecord) LogExerciseResponse {
	return LogExerciseResponse{
		ID:            record.ID,
		UserID:        record.UserID,
		ExerciseID:    record.ExerciseID,
		ExerciseName:  record.ExerciseName,
		ExerciseType:  record.ExerciseType,
		Reps:          record.Reps,
		TimeInSeconds: record.TimeInSeconds,
		Distance:      record.Distance,
		Notes:         record.Notes,
		Grade:         record.Grade,
		CreatedAt:     record.CreatedAt,
	}
}

// mapStoreExerciseToLifeExerciseResponse converts store.Exercise to ListExerciseResponse
func mapStoreExerciseToListExerciseResponse(exercise *store.Exercise) ListExerciseResponse {
	return ListExerciseResponse{
		ID:          exercise.ID,
		Name:        exercise.Name,
		Description: exercise.Description,
		Type:        exercise.Type,
	}
}

// LogExercise handles logging a completed exercise session
// Now a method on *ExerciseHandler
func (h *ExerciseHandler) LogExercise(c echo.Context) error {
	ctx := c.Request().Context()
	userID, err := GetUserIDFromContext(c)
	if err != nil {
		h.logger.Error(ctx, "Could not get user ID from context", "error", err)
		return NewAPIError(http.StatusUnauthorized, ErrCodeUnauthorized, "Authentication error: User ID not found")
	}

	var req LogExerciseRequest
	if err := c.Bind(&req); err != nil {
		h.logger.Error(ctx, "Failed to decode log exercise request", "error", err)
		return NewAPIError(http.StatusBadRequest, ErrCodeBadRequest, "Invalid request body")
	}

	if err := c.Validate(req); err != nil {
		h.logger.Warn(ctx, "Invalid log exercise request", "error", err)
		return NewAPIError(http.StatusBadRequest, ErrCodeValidation, err.Error())
	}

	// Map handler request to service request data
	serviceReqData := &exercises.LogExerciseRequestData{
		ExerciseID: req.ExerciseID,
		Reps:       req.Reps,
		Duration:   req.Duration,
		Distance:   req.Distance,
		Notes:      req.Notes,
	}

	// Call the service
	loggedRecord, err := h.service.LogExercise(ctx, userID, serviceReqData)
	if err != nil {
		// Handle specific errors from service, e.g., exercise not found, validation from service
		if errors.Is(err, store.ErrExerciseNotFound) || (err != nil && err.Error() == fmt.Sprintf("invalid exercise ID: %d: %s", req.ExerciseID, store.ErrExerciseNotFound.Error())) {
			return NewAPIError(http.StatusBadRequest, ErrCodeBadRequest, fmt.Sprintf("Invalid exercise ID: %d", req.ExerciseID))
		} else if err != nil && err.Error() == fmt.Sprintf("missing required performance metric (duration, reps, or distance) for exercise type %s", "unknown") { // Placeholder for actual type
			// This error matching is brittle; service should return typed errors or codes
			return NewAPIError(http.StatusBadRequest, ErrCodeBadRequest, err.Error())
		}
		// Generic internal error for other service failures
		// Logger already called in service
		return NewAPIError(http.StatusInternalServerError, ErrCodeInternalServer, "Failed to log exercise")
	}

	resp := mapStoreUserExerciseRecordToLogExerciseResponse(loggedRecord)
	return c.JSON(http.StatusCreated, resp)
}

// GetUserExercises handles retrieving exercise history for the logged-in user with pagination
// Now a method on *ExerciseHandler
func (h *ExerciseHandler) GetUserExercises(c echo.Context) error {
	ctx := c.Request().Context()
	userID, err := GetUserIDFromContext(c)
	if err != nil {
		h.logger.Error(ctx, "Could not get user ID from context", "error", err)
		return NewAPIError(http.StatusUnauthorized, ErrCodeUnauthorized, "Authentication error: User ID not found")
	}

	pageStr := c.QueryParam("page")
	pageSizeStr := c.QueryParam("pageSize")
	page, _ := strconv.Atoi(pageStr)
	pageSize, _ := strconv.Atoi(pageSizeStr)

	// Validation of page/pageSize is now handled by the service, or defaults applied

	paginatedRecords, err := h.service.GetUserExerciseHistory(ctx, userID, page, pageSize)
	if err != nil {
		// Logger already called in service
		return NewAPIError(http.StatusInternalServerError, ErrCodeDatabase, "Failed to retrieve exercise history")
	}

	respItems := make([]LogExerciseResponse, len(paginatedRecords.Records))
	for i, record := range paginatedRecords.Records {
		respItems[i] = mapStoreUserExerciseRecordToLogExerciseResponse(record)
	}

	resp := PaginatedExerciseHistoryResponse{
		Items:      respItems,
		TotalCount: paginatedRecords.TotalCount,
		Page:       page,     // Reflect back the potentially adjusted page
		PageSize:   pageSize, // Reflect back the potentially adjusted pageSize
	}
	// Adjust page/pageSize if service modified them (e.g. due to defaults/caps)
	if paginatedRecords.TotalCount > 0 && len(paginatedRecords.Records) > 0 {
		// This is a simplified way; ideally service would return the applied page/pageSize
		// For now, we assume the input page/pageSize was used if valid, or defaults from service kicked in.
		// Let's use the input page/pageSize for now, or let service return this info.
		// The service currently re-calculates page/pageSize, so we use what might have been used.
		if page < 1 {
			page = 1
		}
		if pageSize < 1 || pageSize > 100 {
			pageSize = 20
		}
		resp.Page = page
		resp.PageSize = pageSize
	}

	return c.JSON(http.StatusOK, resp)
}

// HandleListExercises handles retrieving all available exercises
// Now a method on *ExerciseHandler
func (h *ExerciseHandler) HandleListExercises(c echo.Context) error {
	ctx := c.Request().Context()
	availableExercises, err := h.service.ListAvailableExercises(ctx)
	if err != nil {
		// Logger already called in service
		return NewAPIError(http.StatusInternalServerError, ErrCodeDatabase, "Failed to retrieve available exercises")
	}

	respItems := make([]ListExerciseResponse, len(availableExercises))
	for i, exercise := range availableExercises {
		respItems[i] = mapStoreExerciseToListExerciseResponse(exercise)
	}

	return c.JSON(http.StatusOK, respItems)
}

// Helper functions are defined in helpers.go
