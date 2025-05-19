package routes

import (
	"context"
	"net/http"

	"github.com/labstack/echo/v4"

	"ptchampion/internal/api/handlers"
	"ptchampion/internal/api/middleware"
	"ptchampion/internal/auth"
	"ptchampion/internal/config"
	"ptchampion/internal/exercises"
	"ptchampion/internal/leaderboards"
	"ptchampion/internal/logging"
	db "ptchampion/internal/store/postgres"
	"ptchampion/internal/store/redis"
	"ptchampion/internal/users"
	"ptchampion/internal/workouts"
)

// RegisterRoutes registers all routes for the application
func RegisterRoutes(e *echo.Echo, cfg *config.Config, store *db.Store, tokenService *auth.TokenService, logger logging.Logger, handler *handlers.Handler) {
	// Create refresh store
	var refreshStore redis.RefreshStore

	// For development, use memory store instead of Redis if RedisURL is not set
	if cfg.AppEnv == "development" && cfg.RedisURL == "" {
		logger.Info(context.Background(), "Routes using in-memory refresh token store for development")
		refreshStore = redis.NewMemoryRefreshStore()
	} else {
		// Use Redis for production or if RedisURL is explicitly set
		redisOptions := redis.DefaultOptions()
		redisOptions.URL = cfg.RedisURL
		redisClient, err := redis.CreateClient(redisOptions)
		if err != nil {
			logger.Fatal(context.Background(), "Failed to connect to Redis", err)
		}
		refreshStore = redis.NewRedisRefreshStore(redisClient)
	}

	// Auth middleware with token store
	authMiddleware := middleware.JWTAuthMiddleware(cfg.JWTSecret, cfg.RefreshTokenSecret, refreshStore)

	// Instantiate the consolidated AuthHandler
	// Note: The 'store' variable here is *db.Store from postgres,
	// but NewAuthHandler expects store.Store (the interface).
	// We need to ensure that *db.Store implements store.Store.
	// For now, assuming it does or can be wrapped/passed directly if compatible.
	// If *db.Store is the concrete implementation of store.Store, this should be fine.
	authHandlerInstance := handlers.NewAuthHandler(store, cfg, logger)

	// Instantiate User Service and User Handler
	// The 'store' (*db.Store) is passed as store.UserStore.
	// We need to ensure *db.Store implements store.UserStore.
	userService := users.NewUserService(store, logger)
	userHandler := handlers.NewUserHandler(userService, logger)

	// Instantiate Exercise Service and Exercise Handler
	exerciseService := exercises.NewService(store, logger)
	exerciseHandler := handlers.NewExerciseHandler(exerciseService, logger)

	// Instantiate Leaderboard Service and Leaderboard Handler
	leaderboardService := leaderboards.NewService(store, logger)
	leaderboardHandler := handlers.NewLeaderboardHandler(leaderboardService, logger)

	// Instantiate Workout Service and Workout Handler
	// store implements both store.WorkoutStore and store.ExerciseStore
	workoutService := workouts.NewService(store, store, logger)
	workoutHandler := handlers.NewWorkoutHandler(workoutService, logger)

	// Create API group
	apiGroup := e.Group("/api/v1")

	// Register public auth routes BEFORE applying middleware
	// These routes should be accessible without authentication
	apiGroup.POST("/auth/login", authHandlerInstance.Login)
	apiGroup.POST("/auth/register", authHandlerInstance.Register)
	apiGroup.POST("/auth/refresh", authHandlerInstance.RefreshToken)

	// Social authentication routes
	authGroup := apiGroup.Group("/auth")

	// Use the existing tokenService
	socialAuthService := auth.NewSocialAuthService(cfg, logger)
	socialAuthHandler := NewSocialAuthHandler(store, tokenService, socialAuthService, cfg, logger)

	// Register social auth routes
	RegisterSocialAuthRoutes(authGroup, socialAuthHandler)

	// Create a separate group for protected routes
	protectedGroup := apiGroup.Group("", authMiddleware)

	// --- Register grouped protected routes ---

	// User Routes
	userRoutes := protectedGroup.Group("/users")
	RegisterUserRoutes(userRoutes, store, logger, userHandler)

	// Workout Routes
	workoutRoutesGroup := protectedGroup.Group("/workouts")
	RegisterWorkoutRoutes(workoutRoutesGroup, store, logger, workoutHandler)

	// Leaderboard Routes
	leaderboardRoutesGroup := protectedGroup.Group("/leaderboards")
	RegisterLeaderboardRoutes(leaderboardRoutesGroup, store, logger, leaderboardHandler)

	// Exercise Routes
	exerciseRoutesGroup := protectedGroup.Group("/exercises")
	RegisterExerciseRoutes(exerciseRoutesGroup, store, logger, exerciseHandler)

	// --- Public (non-authenticated) feature flags endpoint ---
	apiGroup.GET("/features", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]interface{}{"features": map[string]interface{}{}})
	})

	// Serve static files (web frontend)
	e.Static("/", "web/dist")

	// Fallback route for SPA (handles refresh)
	e.File("/*", "web/dist/index.html")
}

// RegisterUserRoutes registers user-related routes under the given group (e.g., /api/v1/users)
func RegisterUserRoutes(g *echo.Group, store *db.Store, logger logging.Logger, userHandler *handlers.UserHandler) {
	// Use handler methods
	g.GET("/me", userHandler.GetCurrentUser)
	g.PUT("/me", userHandler.UpdateCurrentUser)
}

// RegisterWorkoutRoutes registers workout-related routes under the given group (e.g., /api/v1/workouts)
func RegisterWorkoutRoutes(g *echo.Group, store *db.Store, logger logging.Logger, workoutHandler *handlers.WorkoutHandler) {
	g.GET("", workoutHandler.ListUserWorkouts)
	g.POST("", workoutHandler.LogWorkout)
	g.PATCH("/:workout_id/visibility", workoutHandler.UpdateWorkoutVisibility)
}

// RegisterLeaderboardRoutes registers leaderboard-related routes under the given group (e.g., /api/v1/leaderboards)
func RegisterLeaderboardRoutes(g *echo.Group, store *db.Store, logger logging.Logger, leaderboardHandler *handlers.LeaderboardHandler) {
	// Global leaderboards
	g.GET("/global/exercise/:exerciseType", leaderboardHandler.GetGlobalExerciseLeaderboard)
	g.GET("/global/aggregate", leaderboardHandler.GetGlobalAggregateLeaderboard)

	// Local leaderboards
	g.GET("/local/exercise/:exerciseType", leaderboardHandler.GetLocalExerciseLeaderboard)
	g.GET("/local/aggregate", leaderboardHandler.GetLocalAggregateLeaderboard)

	// Support for legacy routes if needed - these can be removed in the future
	g.GET("/overall", leaderboardHandler.GetGlobalAggregateLeaderboard)      // Map to aggregate
	g.GET("/:exerciseType", leaderboardHandler.GetGlobalExerciseLeaderboard) // Map to exercise type
	g.GET("/local", leaderboardHandler.GetLocalExerciseLeaderboard)          // Map to local exercise type (requires exercise type param)
}

// RegisterExerciseRoutes registers exercise-related routes under the given group (e.g., /api/v1/exercises)
func RegisterExerciseRoutes(g *echo.Group, store *db.Store, logger logging.Logger, exerciseHandler *handlers.ExerciseHandler) {
	// User's logged exercises
	g.GET("", exerciseHandler.GetUserExercises)
	g.POST("", exerciseHandler.LogExercise)

	// Available exercise definitions (e.g., types of exercises like Pushup, Run)
	g.GET("/definitions", exerciseHandler.HandleListExercises)
}
