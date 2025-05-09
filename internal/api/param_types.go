package api

// Parameter types for OpenAPI endpoints

// GetExercisesParams defines parameters for GetExercises.
type GetExercisesParams struct {
	// Page number for pagination
	Page *int `form:"page,omitempty" json:"page,omitempty"`

	// Number of items per page
	PageSize *int `form:"pageSize,omitempty" json:"pageSize,omitempty"`
}

// GetLeaderboardExerciseTypeParams defines parameters for GetLeaderboardExerciseType.
type GetLeaderboardExerciseTypeParams struct {
	// Maximum number of leaderboard entries to return
	Limit *int `form:"limit,omitempty" json:"limit,omitempty"`
}

// GetLeaderboardExerciseTypeParamsExerciseType defines parameters for GetLeaderboardExerciseType.
type GetLeaderboardExerciseTypeParamsExerciseType string

// GetLocalLeaderboardParams defines parameters for GetLocalLeaderboard.
type GetLocalLeaderboardParams struct {
	// ID of the exercise to filter leaderboard by
	ExerciseId int `form:"exercise_id" json:"exercise_id"`

	// User's current latitude
	Latitude float64 `form:"latitude" json:"latitude"`

	// User's current longitude
	Longitude float64 `form:"longitude" json:"longitude"`

	// Search radius in meters
	RadiusMeters *float64 `form:"radius_meters,omitempty" json:"radius_meters,omitempty"`
}

// GetWorkoutsParams defines parameters for GetWorkouts.
type GetWorkoutsParams struct {
	// Page number for pagination
	Page *int `form:"page,omitempty" json:"page,omitempty"`

	// Number of items per page
	PageSize *int `form:"pageSize,omitempty" json:"pageSize,omitempty"`
}

// Constants for BearerAuth
const (
	BearerAuthScopes = "BearerAuth.Scopes"
)
