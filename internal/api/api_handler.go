package api

import (
	"ptchampion/internal/api/handlers" // Import the handlers package
	// Keep for TokenService if other parts use it, but NewApiHandler won't create auth.Service
	"ptchampion/internal/config"
	"ptchampion/internal/leaderboards"
	"ptchampion/internal/logging"
	db "ptchampion/internal/store/postgres" // Renamed to db to avoid conflict
	"ptchampion/internal/store/redis"
	"ptchampion/internal/users"
	"ptchampion/internal/workouts"

	"github.com/labstack/echo/v4"
)

// ApiHandler now holds specific handlers
// It no longer embeds handlers.Handler directly
type ApiHandler struct {
	cfg         *config.Config
	logger      logging.Logger
	authHandler *handlers.AuthHandler
	userHandler *handlers.UserHandler
	// exerciseHandler    *handlers.ExerciseHandler // REMOVED - exercise handler deleted
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
	// Create Redis client and leaderboard cache
	var leaderboardCache *redis.LeaderboardCache

	// Only create cache if Redis URL is configured
	if cfg.RedisURL != "" {
		redisOptions := redis.DefaultOptions()
		redisOptions.URL = cfg.RedisURL
		redisClient, err := redis.CreateClient(redisOptions)
		if err != nil {
			logger.Error(nil, "Failed to connect to Redis for leaderboard cache, proceeding without cache", "error", err)
			leaderboardCache = nil
		} else {
			leaderboardCache = redis.NewLeaderboardCache(redisClient)
		}
	} else {
		logger.Info(nil, "Redis URL not configured, leaderboard cache disabled")
		leaderboardCache = nil
	}

	// Instantiate Services (mainStore implements all store interfaces)
	// No separate authService to create here, as NewAuthHandler takes store.Store
	// and creates its own internal tokenService.
	userService := users.NewUserService(mainStore, leaderboardCache, logger)
	// exerciseService := exercises.NewService(mainStore, logger) // REMOVED - no exercise handler
	leaderboardService := leaderboards.NewService(mainStore, logger)
	workoutService := workouts.NewService(mainStore, mainStore, logger) // WorkoutStore and ExerciseStore

	// Create location service
	locationService := users.NewLocationService(mainStore.Queries, leaderboardCache, logger)

	// Instantiate Handlers
	// NewAuthHandler takes store.Store (which mainStore is), config, and logger.
	// It will create its own TokenService internally.
	authHandler := handlers.NewAuthHandler(mainStore, cfg, logger)
	userHandler := handlers.NewUserHandler(userService, locationService, logger)
	// exerciseHandler := handlers.NewExerciseHandler(exerciseService, logger) // REMOVED
	leaderboardHandler := handlers.NewLeaderboardHandler(leaderboardService, logger)
	workoutHandler := handlers.NewWorkoutHandler(workoutService, logger)
	genericHandler := handlers.NewHandler(cfg, mainStore.Queries, logger) // For legacy/generic handlers

	return &ApiHandler{
		cfg:         cfg,
		logger:      logger,
		authHandler: authHandler,
		userHandler: userHandler,
		// exerciseHandler:    exerciseHandler, // REMOVED
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
	// Exercise handler removed - functionality moved to workouts
	return ctx.JSON(501, map[string]string{"error": "Exercise endpoints moved to /workouts"})
}

func (h *ApiHandler) PostExercises(ctx echo.Context) error {
	// Exercise handler removed - functionality moved to workouts
	return ctx.JSON(501, map[string]string{"error": "Exercise endpoints moved to /workouts"})
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

func (h *ApiHandler) PatchUsersMeLocation(ctx echo.Context) error {
	// Call the new location update handler method
	return h.userHandler.UpdateLocation(ctx)
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
	// Delegate to the user handler's UpdateLocation method
	return h.userHandler.UpdateLocation(ctx)
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
