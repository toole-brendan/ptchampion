package main

import (
	"context"
	"encoding/json"
	"errors"
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
	ctxBg := context.Background() // Background context for startup/shutdown logs
	logger.Info(ctxBg, "Starting PT Champion server")

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		logger.Fatal(ctxBg, "Failed to load configuration", err)
	}

	// Validate configuration - will exit if any required config is missing
	cfg.Validate()

	// Initialize database connection
	dbConn, err := db.NewDB(cfg.DatabaseURL)
	if err != nil {
		logger.Fatal(ctxBg, "Failed to connect to database", err)
	}
	defer dbConn.Close()

	// Initialize Redis connection
	redisOptions := redis.DefaultOptions()
	redisOptions.URL = cfg.RedisURL
	redisClient, err := redis.CreateClient(redisOptions)
	if err != nil {
		logger.Fatal(ctxBg, "Failed to connect to Redis", err)
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

	// --- Custom HTTP Error Handler ---
	e.HTTPErrorHandler = customHTTPErrorHandler(logger) // Set the custom error handler

	// Add middleware (Ensure RequestID runs *before* context logger middleware)
	e.Use(middleware.Recover())   // Echo's recover middleware
	e.Use(middleware.RequestID()) // Generate/propagate X-Request-ID header
	// Middleware to put Request ID into context
	e.Use(func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			reqID := c.Response().Header().Get(echo.HeaderXRequestID)
			// Use the defined constant key from logging package
			ctx := context.WithValue(c.Request().Context(), logging.ContextKeyRequestID, reqID)
			c.SetRequest(c.Request().WithContext(ctx))
			return next(c)
		}
	})
	// NOTE: Removed middleware.Logger() as our custom logger provides more context
	// e.Use(middleware.Logger())
	e.Use(middleware.CORS())
	// Consider adding Sentry middleware here if not implicitly handled by logger
	// sentryMiddleware, err := middleware.SentryMiddleware(...)
	// if err == nil { e.Use(sentryMiddleware) } else { logger.Warn(ctxBg, "Failed to init Sentry Middleware", "error", err) }

	// Create handler for routes
	coreHandler := handlers.NewHandler(cfg, store.Queries, logger)

	// Register routes
	routes.RegisterRoutes(e, cfg, store, tokenService, logger, coreHandler)

	// Start server in a goroutine
	go func() {
		if err := e.Start(":" + cfg.Port); err != nil && err != http.ErrServerClosed {
			logger.Fatal(ctxBg, "Failed to start server", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	// Graceful shutdown with a timeout
	ctxShutdown, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := e.Shutdown(ctxShutdown); err != nil {
		// Use the shutdown context? Or background? Background safer if shutdown context times out.
		logger.Fatal(ctxBg, "Failed to shutdown server gracefully", err)
	} else {
		logger.Info(ctxBg, "Server shutdown gracefully")
	}
}

// customHTTPErrorHandler handles errors and formats them into the standard APIErrorResponse
func customHTTPErrorHandler(logger logging.Logger) echo.HTTPErrorHandler {
	return func(err error, c echo.Context) {
		if c.Response().Committed {
			return // Already committed
		}

		var he *echo.HTTPError
		var apiResp handlers.APIErrorResponse
		statusCode := http.StatusInternalServerError // Default to 500

		if errors.As(err, &he) {
			// It's an echo.HTTPError, use its status code
			statusCode = he.Code
			// Try to decode the message if it's JSON, otherwise use it directly
			if jsonErr := json.Unmarshal([]byte(he.Message.(string)), &apiResp); jsonErr == nil {
				// Successfully parsed a structured error message from echo.HTTPError
			} else {
				// Use the raw message from echo.HTTPError, map code to known API codes if possible
				apiResp = handlers.APIErrorResponse{
					Error: handlers.ErrorDetail{
						Code:    mapHTTPStatusToCode(statusCode),
						Message: he.Message.(string),
					},
				}
			}
		} else {
			// It's some other error, log it and return a generic 500
			ctx := c.Request().Context()
			logger.Error(ctx, "Unhandled internal error", "error", err)
			apiResp = handlers.APIErrorResponse{
				Error: handlers.ErrorDetail{
					Code:    handlers.ErrCodeInternalServer,
					Message: "An unexpected internal error occurred.",
				},
			}
		}

		// Send response
		if err := c.JSON(statusCode, apiResp); err != nil {
			// Log error during error response sending
			logger.Error(c.Request().Context(), "Error sending JSON error response", "error", err)
		}
	}
}

// mapHTTPStatusToCode provides a basic mapping from HTTP status to our error codes
// This can be expanded as needed.
func mapHTTPStatusToCode(status int) string {
	switch status {
	case http.StatusBadRequest: // 400
		return handlers.ErrCodeBadRequest
	case http.StatusUnauthorized: // 401
		return handlers.ErrCodeUnauthorized
	case http.StatusForbidden: // 403
		return handlers.ErrCodeForbidden
	case http.StatusNotFound: // 404
		return handlers.ErrCodeNotFound
	case http.StatusConflict: // 409
		return handlers.ErrCodeConflict
	default:
		return handlers.ErrCodeInternalServer // Default to internal server error
	}
}
