package routes

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"ptchampion/internal/api/handlers"
	"ptchampion/internal/api/middleware"
	"ptchampion/internal/auth"
	"ptchampion/internal/config"
	"ptchampion/internal/logging"
	db "ptchampion/internal/store/postgres"
	"ptchampion/internal/store/redis"
)

// RegisterRoutes registers all routes for the application
func RegisterRoutes(e *echo.Echo, cfg *config.Config, store *db.Store, tokenService *auth.TokenService, logger logging.Logger, handler *handlers.Handler) {
	// Create refresh store
	redisOptions := redis.DefaultOptions()
	redisOptions.URL = cfg.RedisURL
	redisClient, err := redis.CreateClient(redisOptions)
	if err != nil {
		logger.Fatal("Failed to connect to Redis", err)
	}
	refreshStore := redis.NewRedisRefreshStore(redisClient)

	// Auth middleware with Redis refresh store
	authMiddleware := middleware.JWTAuthMiddleware(cfg.JWTSecret, cfg.RefreshTokenSecret, refreshStore)

	// Create API group
	apiGroup := e.Group("/api/v1")

	// Register public auth routes BEFORE applying middleware
	// These routes should be accessible without authentication
	apiGroup.POST("/auth/login", handler.PostAuthLogin)
	apiGroup.POST("/auth/register", handler.PostAuthRegister)
	apiGroup.POST("/auth/refresh", handler.PostAuthRefresh)

	// Create a separate group for protected routes
	protectedGroup := apiGroup.Group("", authMiddleware)

	// Register user routes (protected)
	RegisterUserRoutes(protectedGroup, store, logger)

	// Register workout routes (protected)
	RegisterWorkoutRoutes(protectedGroup, store, logger)

	// Register leaderboard routes (protected)
	RegisterLeaderboardRoutes(protectedGroup, store, handler, logger)

	// Register exercise routes (protected)
	RegisterExerciseRoutes(protectedGroup, store, handler, logger)

	// --- Public (non-authenticated) feature flags endpoint ---
	apiGroup.GET("/features", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]interface{}{"features": map[string]interface{}{}})
	})

	// Serve static files (web frontend)
	e.Static("/", "web/dist")

	// Fallback route for SPA (handles refresh)
	e.File("/*", "web/dist/index.html")
}

// RegisterUserRoutes registers user-related routes
func RegisterUserRoutes(g *echo.Group, store *db.Store, logger logging.Logger) {
	// TODO: Implement user routes
	g.GET("/users/me", func(c echo.Context) error {
		// Simple placeholder implementation
		return c.JSON(http.StatusOK, map[string]interface{}{
			"id":          1,
			"username":    "user1",
			"displayName": "User One",
		})
	})
}

// RegisterWorkoutRoutes registers workout-related routes
func RegisterWorkoutRoutes(g *echo.Group, store *db.Store, logger logging.Logger) {
	// TODO: Implement workout routes
	g.GET("/workouts", func(c echo.Context) error {
		// Simple placeholder implementation
		return c.JSON(http.StatusOK, map[string]interface{}{
			"workouts":   []interface{}{},
			"page":       1,
			"pageSize":   15,
			"totalCount": 0,
			"totalPages": 0,
		})
	})
}

// RegisterLeaderboardRoutes registers leaderboard-related routes
func RegisterLeaderboardRoutes(g *echo.Group, store *db.Store, handler *handlers.Handler, logger logging.Logger) {
	// Register overall leaderboard endpoint
	g.GET("/leaderboard/overall", func(c echo.Context) error {
		// Simple implementation that returns an empty leaderboard
		leaderboard := []map[string]interface{}{}
		return c.JSON(http.StatusOK, leaderboard)
	})

	// Register exercise-specific leaderboard endpoint
	g.GET("/leaderboard/:exerciseType", func(c echo.Context) error {
		// Simple implementation that returns an empty leaderboard
		leaderboard := []map[string]interface{}{}
		return c.JSON(http.StatusOK, leaderboard)
	})

	// Register location-based leaderboard endpoint
	g.GET("/leaderboards/local", func(c echo.Context) error {
		// Simple implementation that returns an empty leaderboard
		leaderboard := []map[string]interface{}{}
		return c.JSON(http.StatusOK, leaderboard)
	})
}

// RegisterExerciseRoutes registers exercise-related routes
func RegisterExerciseRoutes(g *echo.Group, store *db.Store, handler *handlers.Handler, logger logging.Logger) {
	// Register route to get exercise history
	g.GET("/exercises", func(c echo.Context) error {
		// Simple implementation that returns an empty exercise list
		return c.JSON(http.StatusOK, map[string]interface{}{
			"items":       []interface{}{},
			"page":        1,
			"page_size":   15,
			"total_count": 0,
		})
	})

	// Register route to log a new exercise
	g.POST("/exercises", func(c echo.Context) error {
		// Simple implementation that returns a success message
		return c.JSON(http.StatusOK, map[string]interface{}{
			"success": true,
			"message": "Exercise logged successfully",
		})
	})
}
