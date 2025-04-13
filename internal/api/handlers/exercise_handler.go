package handlers

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"ptchampion/internal/grading"
	dbStore "ptchampion/internal/store/postgres"

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

// LogExercise handles logging a completed exercise session
func (h *Handler) LogExercise(c echo.Context) error {
	// 1. Get User ID from context (echo JWT middleware will provide this)
	userID, ok := c.Get("user_id").(int32)
	if !ok {
		log.Printf("ERROR: Could not get user ID from context")
		return echo.NewHTTPError(http.StatusInternalServerError, "Authentication error")
	}

	// 2. Decode request body
	var req LogExerciseRequest
	if err := c.Bind(&req); err != nil {
		log.Printf("ERROR: Failed to decode log exercise request: %v", err)
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid request body")
	}

	// 3. Validate the request struct
	if err := c.Validate(req); err != nil {
		log.Printf("INFO: Invalid log exercise request: %v", err)
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}

	// 4. Fetch the Exercise definition by ID to get its type and name
	exercise, err := h.Queries.GetExercise(c.Request().Context(), req.ExerciseID)
	if err != nil {
		if err == sql.ErrNoRows {
			log.Printf("INFO: Attempt to log exercise with invalid ID: %d", req.ExerciseID)
			return echo.NewHTTPError(http.StatusBadRequest, fmt.Sprintf("Invalid exercise ID: %d", req.ExerciseID))
		} else {
			log.Printf("ERROR: Failed to get exercise by ID %d: %v", req.ExerciseID, err)
			return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve exercise details")
		}
	}

	// 5. Calculate Grade based on exercise type and performance value
	var performanceValue float64
	var metricMissing bool = false

	// Use constants from grading package
	switch exercise.Type {
	case grading.ExerciseTypeRun: // Run is timed
		if req.Duration != nil {
			performanceValue = float64(*req.Duration)
		} else {
			metricMissing = true
		}
	case grading.ExerciseTypePushup, grading.ExerciseTypeSitup, grading.ExerciseTypePullup: // These are reps-based
		if req.Reps != nil {
			performanceValue = float64(*req.Reps)
		} else {
			metricMissing = true
		}
	// Add case for purely distance-based exercises if they exist
	// case "some_distance_exercise_type":
	// 	if req.Distance != nil {
	// 		performanceValue = float64(*req.Distance) // Assumes distance is in relevant unit for grading
	// 	} else {
	// 		metricMissing = true
	// 	}
	default:
		// This case should ideally not be hit if exercise type exists in DB and grading
		log.Printf("Warning: Attempting to grade unknown or unhandled exercise type '%s'", exercise.Type)
		// metricMissing = true // Or handle as appropriate
		// For now, let CalculateScore handle it, which returns 0
	}

	// Validate that the required metric was provided for the exercise type
	if metricMissing {
		log.Printf("INFO: Missing required performance metric for user %d, exercise type %s", userID, exercise.Type)
		return echo.NewHTTPError(http.StatusBadRequest, fmt.Sprintf("Missing required performance metric (duration, reps, or distance) for exercise type %s", exercise.Type))
	}

	// TODO: If distance exercises are added, ensure req.Distance (expected in meters from frontend)
	// is compatible with the unit expected by calculateDistanceScore if that's different.

	calculatedGrade := grading.CalculateScore(exercise.Type, performanceValue)

	// 6. Prepare parameters for database insertion
	params := dbStore.LogUserExerciseParams{
		UserID:        userID,
		ExerciseID:    exercise.ID,
		Repetitions:   int32PtrToNullInt32(req.Reps),     // Correct type *int32
		TimeInSeconds: int32PtrToNullInt32(req.Duration), // Correct type *int32
		Distance:      int32PtrToNullInt32(req.Distance), // Add distance
		Grade:         sql.NullInt32{Int32: int32(calculatedGrade), Valid: true},
		Notes:         stringPtrToNullString(req.Notes), // Use Notes field
		// FormScore, Completed, DeviceID removed as they are not in current request struct
		// FormScore:     int32PtrToNullInt32(req.FormScore), // Add back if needed
		// Completed:     sql.NullBool{Bool: req.Completed, Valid: true}, // Add back if needed
		// Metadata:      stringPtrToNullString(req.Metadata), // Changed to Notes
		// DeviceID:      stringPtrToNullString(req.DeviceID), // Add back if needed
	}

	// 7. Save to database
	loggedExercise, err := h.Queries.LogUserExercise(c.Request().Context(), params)
	if err != nil {
		log.Printf("ERROR: Failed to log user exercise for user %d, exercise %d: %v", userID, exercise.ID, err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to save exercise log")
	}

	// 8. Prepare response
	resp := LogExerciseResponse{
		ID:            loggedExercise.ID,
		UserID:        loggedExercise.UserID,
		ExerciseID:    loggedExercise.ExerciseID,
		ExerciseName:  exercise.Name, // Include name from fetched exercise
		ExerciseType:  exercise.Type, // Include type from fetched exercise
		Reps:          nullInt32ToInt32Ptr(loggedExercise.Repetitions),
		TimeInSeconds: nullInt32ToInt32Ptr(loggedExercise.TimeInSeconds), // Use TimeInSeconds from DB
		Distance:      nullInt32ToInt32Ptr(loggedExercise.Distance),
		Notes:         nullStringToStringPtr(loggedExercise.Notes),
		Grade:         loggedExercise.Grade.Int32,            // Grade should be valid based on calculation
		CreatedAt:     getNullTime(loggedExercise.CreatedAt), // Use helper if available
	}

	// 9. Send response
	return c.JSON(http.StatusCreated, resp)
}

// GetUserExercises handles retrieving exercise history for the logged-in user with pagination
func (h *Handler) GetUserExercises(c echo.Context) error {
	// 1. Get User ID from context
	userID, ok := c.Get("user_id").(int32)
	if !ok {
		log.Printf("ERROR: Could not get user ID from context")
		return echo.NewHTTPError(http.StatusInternalServerError, "Authentication error")
	}

	// 2. Get Pagination Parameters from query string
	pageStr := c.QueryParam("page")
	pageSizeStr := c.QueryParam("pageSize")

	page, err := strconv.Atoi(pageStr)
	if err != nil || page < 1 {
		page = 1 // Default to page 1 if invalid or missing
	}

	pageSize, err := strconv.Atoi(pageSizeStr)
	if err != nil || pageSize < 1 || pageSize > 100 { // Add a max page size
		pageSize = 20 // Default page size
	}

	limit := int32(pageSize)
	offset := int32((page - 1) * pageSize)

	// 3. Fetch total count
	totalCount, err := h.Queries.GetUserExercisesCount(c.Request().Context(), userID)
	if err != nil {
		log.Printf("ERROR: Failed to get user exercises count for user %d: %v", userID, err)
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve exercise count")
	}

	var dbExercises []dbStore.GetUserExercisesRow // Assuming sqlc generated this type
	if totalCount > 0 {
		// 4. Fetch exercises for the current page from database
		params := dbStore.GetUserExercisesParams{
			UserID: userID,
			Limit:  limit,  // Use int32 for limit
			Offset: offset, // Use int32 for offset
		}
		dbExercises, err = h.Queries.GetUserExercises(c.Request().Context(), params)
		if err != nil && err != sql.ErrNoRows { // Ignore ErrNoRows here, could happen if page is beyond total
			log.Printf("ERROR: Failed to get user exercises for user %d (page %d, size %d): %v", userID, page, pageSize, err)
			return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve exercise history")
		}
	} else {
		dbExercises = []dbStore.GetUserExercisesRow{} // Empty slice if total count is 0
	}

	// 5. Map DB results to response struct
	respItems := make([]LogExerciseResponse, len(dbExercises))
	for i, dbEx := range dbExercises {
		respItems[i] = LogExerciseResponse{
			ID:            dbEx.ID,
			UserID:        dbEx.UserID,
			ExerciseID:    dbEx.ExerciseID,
			ExerciseName:  dbEx.ExerciseName,
			ExerciseType:  dbEx.ExerciseType,
			Reps:          nullInt32ToInt32Ptr(dbEx.Repetitions),
			TimeInSeconds: nullInt32ToInt32Ptr(dbEx.TimeInSeconds),
			Distance:      nullInt32ToInt32Ptr(dbEx.Distance),
			Notes:         nullStringToStringPtr(dbEx.Notes),
			Grade:         dbEx.Grade.Int32,
			CreatedAt:     getNullTime(dbEx.CreatedAt), // Ensure getNullTime handles potential null timestamp
		}
	}

	// 6. Prepare paginated response object
	paginatedResp := PaginatedExerciseHistoryResponse{
		Items:      respItems,
		TotalCount: totalCount,
		Page:       page,
		PageSize:   pageSize,
	}

	// 7. Send response
	return c.JSON(http.StatusOK, paginatedResp)
}

// handleListExercises retrieves all available exercises
func (h *Handler) handleListExercises(c echo.Context) error {
	ctx := c.Request().Context()

	// 1. Fetch exercises from database using the existing sqlc query
	dbExercises, err := h.Queries.ListExercises(ctx)
	if err != nil {
		log.Printf("ERROR [handleListExercises]: Failed to list exercises: %v", err)
		// Don't expose detailed error to client
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to retrieve exercises")
	}

	// 2. Map DB results to response struct
	respExercises := make([]ListExerciseResponse, len(dbExercises))
	for i, dbEx := range dbExercises {
		respExercises[i] = ListExerciseResponse{
			ID:          dbEx.ID,
			Name:        dbEx.Name,
			Description: nullStringToStringPtr(dbEx.Description), // Use helper for sql.NullString
			Type:        dbEx.Type,
		}
	}

	// 3. Return the list as JSON
	return c.JSON(http.StatusOK, respExercises)
}

// Helper functions are defined in helpers.go
