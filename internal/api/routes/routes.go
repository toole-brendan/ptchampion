package routes

import (
	"net/http"

	"github.com/labstack/echo/v4"

	"ptchampion/internal/api/middleware"
	"ptchampion/internal/auth"
	"ptchampion/internal/config"
	"ptchampion/internal/logging"
	db "ptchampion/internal/store/postgres"
	"ptchampion/internal/store/redis"
)

// RegisterRoutes registers all routes for the application
func RegisterRoutes(e *echo.Echo, cfg *config.Config, store *db.Store, tokenService *auth.TokenService, logger logging.Logger) {
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

	// Register auth routes
	RegisterAuthRoutes(e, cfg, tokenService, logger)

	// Protected routes (authentication required)
	apiGroup := e.Group("/api/v1")
	apiGroup.Use(authMiddleware)

	// Register user routes
	RegisterUserRoutes(apiGroup, store, logger)

	// Register workout routes
	RegisterWorkoutRoutes(apiGroup, store, logger)

	// Register leaderboard routes
	RegisterLeaderboardRoutes(apiGroup, store, logger)

	// Register exercise routes
	RegisterExerciseRoutes(apiGroup, store, logger)

	// --- Public (non-authenticated) feature flags endpoint ---
	e.GET("/api/v1/features", func(c echo.Context) error {
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
}

// RegisterWorkoutRoutes registers workout-related routes
func RegisterWorkoutRoutes(g *echo.Group, store *db.Store, logger logging.Logger) {
	// TODO: Implement workout routes
}

// RegisterLeaderboardRoutes registers leaderboard-related routes
func RegisterLeaderboardRoutes(g *echo.Group, store *db.Store, logger logging.Logger) {
	// TODO: Implement leaderboard routes
}

// RegisterExerciseRoutes registers exercise-related routes
func RegisterExerciseRoutes(g *echo.Group, store *db.Store, logger logging.Logger) {
	// TODO: Implement exercise routes
}
