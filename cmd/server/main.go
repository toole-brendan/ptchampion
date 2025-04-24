package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"

	"ptchampion/internal/api/handlers"
	"ptchampion/internal/api/routes"
	"ptchampion/internal/auth"
	"ptchampion/internal/config"
	"ptchampion/internal/logging"
	db "ptchampion/internal/store/postgres"
	"ptchampion/internal/store/redis"
)

func main() {
	// Initialize logger
	logger := logging.NewDefaultLogger()
	logger.Info("Starting PT Champion server")

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		logger.Fatal("Failed to load configuration", err)
	}

	// Validate configuration - will exit if any required config is missing
	cfg.Validate()

	// Initialize database connection
	dbConn, err := db.NewDB(cfg.DatabaseURL)
	if err != nil {
		logger.Fatal("Failed to connect to database", err)
	}
	defer dbConn.Close()

	// Initialize Redis connection
	redisOptions := redis.DefaultOptions()
	redisOptions.URL = cfg.RedisURL
	redisClient, err := redis.CreateClient(redisOptions)
	if err != nil {
		logger.Fatal("Failed to connect to Redis", err)
	}
	defer redisClient.Close()

	// Create the refresh token store
	refreshStore := redis.NewRedisRefreshStore(redisClient)

	// Initialize database store with timeout
	store := db.NewStore(dbConn, cfg.DBTimeout)

	// Initialize token service with Redis store
	tokenService := auth.NewTokenService(cfg.JWTSecret, cfg.RefreshTokenSecret, refreshStore)

	// Create Echo instance
	e := echo.New()

	// Add middleware
	e.Use(middleware.Recover())
	e.Use(middleware.Logger())
	e.Use(middleware.CORS())

	// Create handler for routes
	coreHandler := handlers.NewHandler(cfg, store.Queries)

	// Register routes
	routes.RegisterRoutes(e, cfg, store, tokenService, logger, coreHandler)

	// Start server in a goroutine
	go func() {
		if err := e.Start(":" + cfg.Port); err != nil && err != http.ErrServerClosed {
			logger.Fatal("Failed to start server", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	// Graceful shutdown with a timeout
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := e.Shutdown(ctx); err != nil {
		logger.Fatal("Failed to shutdown server gracefully", err)
	} else {
		logger.Info("Server shutdown gracefully")
	}
}
