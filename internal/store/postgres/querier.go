// Code generated by sqlc. DO NOT EDIT.
// versions:
//   sqlc v1.28.0

package db

import (
	"context"
)

type Querier interface {
	CheckUsernameExists(ctx context.Context, username string) (bool, error)
	CreateUser(ctx context.Context, arg CreateUserParams) (User, error)
	CreateWorkout(ctx context.Context, arg CreateWorkoutParams) (Workout, error)
	GetExercise(ctx context.Context, id int32) (Exercise, error)
	GetExercisesByType(ctx context.Context, type_ string) ([]Exercise, error)
	GetGlobalAggregateLeaderboard(ctx context.Context, arg GetGlobalAggregateLeaderboardParams) ([]GetGlobalAggregateLeaderboardRow, error)
	// Apply a reasonable limit
	GetGlobalExerciseLeaderboard(ctx context.Context, arg GetGlobalExerciseLeaderboardParams) ([]GetGlobalExerciseLeaderboardRow, error)
	GetLeaderboard(ctx context.Context, type_ string) ([]GetLeaderboardRow, error)
	GetLeaderboardByExerciseType(ctx context.Context, arg GetLeaderboardByExerciseTypeParams) ([]GetLeaderboardByExerciseTypeRow, error)
	GetLocalAggregateLeaderboard(ctx context.Context, arg GetLocalAggregateLeaderboardParams) ([]GetLocalAggregateLeaderboardRow, error)
	GetLocalExerciseLeaderboard(ctx context.Context, arg GetLocalExerciseLeaderboardParams) ([]GetLocalExerciseLeaderboardRow, error)
	// Limit the number of results (e.g., top 10, 20)
	GetLocalLeaderboard(ctx context.Context, arg GetLocalLeaderboardParams) ([]GetLocalLeaderboardRow, error)
	GetUser(ctx context.Context, id int32) (User, error)
	GetUserByEmail(ctx context.Context, email string) (User, error)
	GetUserByUsername(ctx context.Context, username string) (User, error)
	GetUserWorkouts(ctx context.Context, arg GetUserWorkoutsParams) ([]GetUserWorkoutsRow, error)
	GetUserWorkoutsByType(ctx context.Context, arg GetUserWorkoutsByTypeParams) ([]GetUserWorkoutsByTypeRow, error)
	GetUserWorkoutsCount(ctx context.Context, userID int32) (int64, error)
	GetUserWorkoutsHistory(ctx context.Context, arg GetUserWorkoutsHistoryParams) ([]GetUserWorkoutsHistoryRow, error)
	GetWorkoutRecordByID(ctx context.Context, id int32) (Workout, error)
	ListExercises(ctx context.Context) ([]Exercise, error)
	LogWorkout(ctx context.Context, arg LogWorkoutParams) (Workout, error)
	UpdateUser(ctx context.Context, arg UpdateUserParams) (User, error)
	UpdateUserLocation(ctx context.Context, arg UpdateUserLocationParams) error
	UpdateWorkoutVisibility(ctx context.Context, arg UpdateWorkoutVisibilityParams) error
}

var _ Querier = (*Queries)(nil)
