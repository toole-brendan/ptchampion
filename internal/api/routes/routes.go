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
	"ptchampion/internal/logging"
	db "ptchampion/internal/store/postgres"
	"ptchampion/internal/store/redis"
	"ptchampion/internal/users"
)

// RegisterRoutes registers all routes for the application
func RegisterRoutes(e *echo.Echo, cfg *config.Config, store *db.Store, tokenService *auth.TokenService, logger logging.Logger, handler *handlers.Handler) {
	// Create refresh store
	redisOptions := redis.DefaultOptions()
	redisOptions.URL = cfg.RedisURL
	redisClient, err := redis.CreateClient(redisOptions)
	if err != nil {
		logger.Fatal(context.Background(), "Failed to connect to Redis", err)
	}
	refreshStore := redis.NewRedisRefreshStore(redisClient)

	// Auth middleware with Redis refresh store
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

	// Create API group
	apiGroup := e.Group("/api/v1")

	// Register public auth routes BEFORE applying middleware
	// These routes should be accessible without authentication
	apiGroup.POST("/auth/login", authHandlerInstance.Login)
	apiGroup.POST("/auth/register", authHandlerInstance.Register)
	apiGroup.POST("/auth/refresh", authHandlerInstance.RefreshToken)

	// Create a separate group for protected routes
	protectedGroup := apiGroup.Group("", authMiddleware)

	// --- Register grouped protected routes ---

	// User Routes
	userRoutes := protectedGroup.Group("/users")
	RegisterUserRoutes(userRoutes, store, logger, userHandler)

	// Workout Routes
	workoutRoutes := protectedGroup.Group("/workouts")
	RegisterWorkoutRoutes(workoutRoutes, store, logger, handler)

	// Leaderboard Routes
	leaderboardRoutes := protectedGroup.Group("/leaderboards")
	RegisterLeaderboardRoutes(leaderboardRoutes, store, handler, logger)

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
func RegisterWorkoutRoutes(g *echo.Group, store *db.Store, logger logging.Logger, handler *handlers.Handler) {
	// TODO: Implement actual workout routes using handler methods
	g.GET("", func(c echo.Context) error {
		// Simple placeholder implementation
		// Replace with actual handler call, e.g., handler.GetWorkouts
		return c.JSON(http.StatusOK, map[string]interface{}{
			"workouts":   []interface{}{},
			"page":       1,
			"pageSize":   15,
			"totalCount": 0,
			"totalPages": 0,
		})
	})
}

// RegisterLeaderboardRoutes registers leaderboard-related routes under the given group (e.g., /api/v1/leaderboards)
func RegisterLeaderboardRoutes(g *echo.Group, store *db.Store, handler *handlers.Handler, logger logging.Logger) {
	g.GET("/overall", func(c echo.Context) error {
		// Replace with actual handler call, e.g., handler.GetOverallLeaderboard
		leaderboard := []map[string]interface{}{}
		return c.JSON(http.StatusOK, leaderboard)
	})

	g.GET("/:exerciseType", func(c echo.Context) error {
		// Replace with actual handler call, e.g., handler.GetExerciseLeaderboard
		leaderboard := []map[string]interface{}{}
		return c.JSON(http.StatusOK, leaderboard)
	})

	g.GET("/local", func(c echo.Context) error {
		// Replace with actual handler call, e.g., handler.GetLocalLeaderboard
		leaderboard := []map[string]interface{}{}
		return c.JSON(http.StatusOK, leaderboard)
	})
}

// RegisterExerciseRoutes registers exercise-related routes under the given group (e.g., /api/v1/exercises)
func RegisterExerciseRoutes(g *echo.Group, store *db.Store, logger logging.Logger, exerciseHandler *handlers.ExerciseHandler) {
	// User's logged exercises
	g.GET("", exerciseHandler.GetUserExercises)
	g.POST("", exerciseHandler.LogExercise)

	// Available exercise definitions (e.g., types of exercises like Pushup, Run)
	g.GET("/definitions", exerciseHandler.HandleListExercises)
}
