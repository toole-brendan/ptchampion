package api

import (
	"log"
	"net/http"

	"ptchampion/internal/api/handlers" // Import the handlers package
	// Keep for TokenService if other parts use it, but NewApiHandler won't create auth.Service
	"ptchampion/internal/config"
	"ptchampion/internal/exercises"
	"ptchampion/internal/leaderboards"
	"ptchampion/internal/logging"
	db "ptchampion/internal/store/postgres" // Renamed to db to avoid conflict
	"ptchampion/internal/users"
	"ptchampion/internal/workouts"

	"github.com/labstack/echo/v4"
)

// ApiHandler now holds specific handlers
// It no longer embeds handlers.Handler directly
type ApiHandler struct {
	cfg                *config.Config
	logger             logging.Logger
	authHandler        *handlers.AuthHandler
	userHandler        *handlers.UserHandler
	exerciseHandler    *handlers.ExerciseHandler
	leaderboardHandler *handlers.LeaderboardHandler
	workoutHandler     *handlers.WorkoutHandler
	// syncHandler    *handlers.SyncHandler // Assuming you might have this
	genericHandler *handlers.Handler // For PostSync and FeaturesHandler, if they remain on generic handler
}

// Ensure ApiHandler implements ServerInterface (compile-time check)
var _ ServerInterface = (*ApiHandler)(nil)

// NewApiHandler creates a new ApiHandler
// It now initializes all specific handlers
func NewApiHandler(cfg *config.Config, mainStore *db.Store, logger logging.Logger) *ApiHandler {
	// Create refresh store - this is used by NewAuthHandler internally now via NewTokenService
	// So, we don't need to create refreshStore or tokenService explicitly here if AuthHandler handles it.
	// However, NewAuthHandler takes store.Store, not a TokenService directly.
	// It seems NewAuthHandler itself creates the TokenService.

	// Instantiate Services (mainStore implements all store interfaces)
	// No separate authService to create here, as NewAuthHandler takes store.Store
	// and creates its own internal tokenService.
	userService := users.NewUserService(mainStore, logger)
	exerciseService := exercises.NewService(mainStore, logger)
	leaderboardService := leaderboards.NewService(mainStore, logger)
	workoutService := workouts.NewService(mainStore, mainStore, logger) // WorkoutStore and ExerciseStore

	// Instantiate Handlers
	// NewAuthHandler takes store.Store (which mainStore is), config, and logger.
	// It will create its own TokenService internally.
	authHandler := handlers.NewAuthHandler(mainStore, cfg, logger)
	userHandler := handlers.NewUserHandler(userService, logger)
	exerciseHandler := handlers.NewExerciseHandler(exerciseService, logger)
	leaderboardHandler := handlers.NewLeaderboardHandler(leaderboardService, logger)
	workoutHandler := handlers.NewWorkoutHandler(workoutService, logger)
	genericHandler := handlers.NewHandler(cfg, mainStore.Queries, logger) // For legacy/generic handlers

	return &ApiHandler{
		cfg:                cfg,
		logger:             logger,
		authHandler:        authHandler,
		userHandler:        userHandler,
		exerciseHandler:    exerciseHandler,
		leaderboardHandler: leaderboardHandler,
		workoutHandler:     workoutHandler,
		genericHandler:     genericHandler,
	}
}

// --- Implement ServerInterface methods by calling embedded handler methods ---

func (h *ApiHandler) PostAuthLogin(ctx echo.Context) error {
	// Call the embedded handler method directly
	return h.authHandler.Login(ctx)
}

func (h *ApiHandler) PostAuthRegister(ctx echo.Context) error {
	// Call the embedded handler method directly
	return h.authHandler.Register(ctx)
}

func (h *ApiHandler) GetExercises(ctx echo.Context, params GetExercisesParams) error {
	// Call the exported handler that lists all exercises
	// Pass only the context as the underlying handler doesn't need params
	return h.exerciseHandler.HandleListExercises(ctx)
}

func (h *ApiHandler) PostExercises(ctx echo.Context) error {
	// Call the updated handler method directly
	return h.exerciseHandler.LogExercise(ctx)
}

func (h *ApiHandler) GetLeaderboardExerciseType(ctx echo.Context, exerciseType GetLeaderboardExerciseTypeParamsExerciseType, params GetLeaderboardExerciseTypeParams) error {
	// Set exerciseType as a path parameter for GetLeaderboard to use
	ctx.SetParamNames("exerciseType")
	ctx.SetParamValues(string(exerciseType))

	// Call the updated handler method
	return h.leaderboardHandler.GetGlobalExerciseLeaderboard(ctx)
}

func (h *ApiHandler) PostSync(ctx echo.Context) error {
	// Call the updated handler method directly
	return h.genericHandler.PostSync(ctx)
}

func (h *ApiHandler) PatchUsersMe(ctx echo.Context) error {
	// Call the updated handler method directly
	return h.userHandler.UpdateCurrentUser(ctx)
}

// GetLocalLeaderboard implements the ServerInterface
func (h *ApiHandler) GetLocalLeaderboard(ctx echo.Context, params GetLocalLeaderboardParams) error {
	// Call the correct handler method for local leaderboard
	return h.genericHandler.HandleGetLocalLeaderboard(ctx)
}

// GetWorkouts implements the ServerInterface
func (h *ApiHandler) GetWorkouts(ctx echo.Context, params GetWorkoutsParams) error {
	// Call the handler for user workouts
	return h.workoutHandler.ListUserWorkouts(ctx)
}

// Add missing HandleUpdateUserLocation implementation
func (h *ApiHandler) HandleUpdateUserLocation(ctx echo.Context) error {
	// Assuming there's a handler function UpdateUserLocation in handlers/profile_handler.go or similar
	// return h.Handler.UpdateUserLocation(ctx) // Example call
	// Placeholder implementation:
	log.Println("HandleUpdateUserLocation called, but handler not implemented/connected yet.")
	return ctx.JSON(http.StatusNotImplemented, handlers.APIErrorResponse{
		Error: handlers.ErrorDetail{
			Code:    handlers.ErrCodeNotImplemented,
			Message: "Update location not implemented",
		},
	})
}

// FeaturesHandler implements a fallback feature flags endpoint
func (h *ApiHandler) FeaturesHandler(ctx echo.Context) error {
	return h.genericHandler.FeaturesHandler(ctx)
}

// GetUsersMe handler for retrieving the current authenticated user
func (h *ApiHandler) GetUsersMe(ctx echo.Context) error {
	// Call the new handler method directly
	return h.userHandler.GetCurrentUser(ctx)
}
