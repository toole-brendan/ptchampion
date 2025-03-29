package handlers

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	customMiddleware "ptchampion/internal/api/middleware"
	"ptchampion/internal/api/utils"
	"ptchampion/internal/grading"
	dbStore "ptchampion/internal/store/postgres"
	// REMOVE: "github.com/go-playground/validator/v10"
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

// ExerciseHistoryResponse defines the structure for returning user exercise history
// ... existing struct ...

// LogExercise handles logging a completed exercise session
func (h *Handler) LogExercise(w http.ResponseWriter, r *http.Request) {
	// 1. Get User ID from context
	userID, ok := r.Context().Value(customMiddleware.UserIDContextKey).(int32)
	if !ok {
		log.Printf("ERROR: Could not get user ID from context")
		http.Error(w, "Authentication error", http.StatusInternalServerError)
		return
	}

	// 2. Decode request body
	var req LogExerciseRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("ERROR: Failed to decode log exercise request: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// 3. Validate the request struct using the shared validator
	if err := utils.Validate.Struct(req); err != nil {
		log.Printf("INFO: Invalid log exercise request: %v", err)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		if encodeErr := json.NewEncoder(w).Encode(utils.ValidationErrorResponse(err)); encodeErr != nil {
			log.Printf("ERROR: Failed to encode validation error response: %v", encodeErr)
		}
		return
	}

	// 4. Fetch the Exercise definition by ID to get its type and name
	exercise, err := h.Queries.GetExercise(r.Context(), req.ExerciseID) // Use GetExercise by ID
	if err != nil {
		if err == sql.ErrNoRows {
			log.Printf("INFO: Attempt to log exercise with invalid ID: %d", req.ExerciseID)
			http.Error(w, fmt.Sprintf("Invalid exercise ID: %d", req.ExerciseID), http.StatusBadRequest)
		} else {
			log.Printf("ERROR: Failed to get exercise by ID %d: %v", req.ExerciseID, err)
			http.Error(w, "Failed to retrieve exercise details", http.StatusInternalServerError)
		}
		return
	}

	// 5. Calculate Grade based on exercise type and performance value
	var performanceValue float64
	if exercise.Type == "timed" && req.Duration != nil { // Check fetched exercise type
		performanceValue = float64(*req.Duration)
	} else if (exercise.Type == "reps" || exercise.Type == "distance") && req.Reps != nil { // Assuming distance also uses reps field for simplicity?
		// If distance is treated differently, add specific logic
		// For now, using Reps for both reps and distance based exercises
		performanceValue = float64(*req.Reps)
	} else if exercise.Type == "distance" && req.Distance != nil {
		// If distance has its own field and distinct grading
		performanceValue = float64(*req.Distance) // Example: Using Distance field for grading if applicable
	}
	// Add logic validation: e.g., ensure Reps is provided for 'reps' type, Duration for 'timed'
	// This check could be more robust.

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
	loggedExercise, err := h.Queries.LogUserExercise(r.Context(), params)
	if err != nil {
		log.Printf("ERROR: Failed to log user exercise for user %d, exercise %d: %v", userID, exercise.ID, err)
		http.Error(w, "Failed to save exercise log", http.StatusInternalServerError)
		return
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
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		log.Printf("ERROR: Failed to encode log exercise response: %v", err)
	}
}

// GetUserExercises handles retrieving exercise history for the logged-in user
func (h *Handler) GetUserExercises(w http.ResponseWriter, r *http.Request) {
	// 1. Get User ID from context
	userID, ok := r.Context().Value(customMiddleware.UserIDContextKey).(int32)
	if !ok {
		log.Printf("ERROR: Could not get user ID from context")
		http.Error(w, "Authentication error", http.StatusInternalServerError)
		return
	}

	// 2. Fetch exercises from database
	dbExercises, err := h.Queries.GetUserExercises(r.Context(), userID)
	if err != nil {
		if err == sql.ErrNoRows {
			// No exercises found is not an error, return empty list
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusOK)
			json.NewEncoder(w).Encode([]LogExerciseResponse{}) // Return empty array
			return
		}
		log.Printf("ERROR: Failed to get user exercises for user %d: %v", userID, err)
		http.Error(w, "Failed to retrieve exercise history", http.StatusInternalServerError)
		return
	}

	// 3. Map DB results to response struct
	respExercises := make([]LogExerciseResponse, len(dbExercises))
	for i, dbEx := range dbExercises {
		respExercises[i] = LogExerciseResponse{
			ID:            dbEx.ID,
			UserID:        dbEx.UserID,
			ExerciseID:    dbEx.ExerciseID,
			ExerciseName:  dbEx.ExerciseName, // Directly use the string fields
			ExerciseType:  dbEx.ExerciseType,
			Reps:          nullInt32ToInt32Ptr(dbEx.Repetitions),
			TimeInSeconds: nullInt32ToInt32Ptr(dbEx.TimeInSeconds),
			Distance:      nullInt32ToInt32Ptr(dbEx.Distance),
			Notes:         nullStringToStringPtr(dbEx.Notes),
			Grade:         dbEx.Grade.Int32,
			CreatedAt:     getNullTime(dbEx.CreatedAt),
		}
	}

	// 4. Send response
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(respExercises); err != nil {
		log.Printf("ERROR: Failed to encode user exercises response: %v", err)
	}
}

// --- Grading Logic --- (Should probably move to a separate service/package later)
// ... existing logic (assuming it's in grading package now) ...

// --- Nullable Type Helpers ---
// These should be in helpers.go and imported if needed
// ... removed ...
