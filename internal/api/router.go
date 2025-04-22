package api

import (
	"context"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	// Use the new api_handler which embeds the core handlers
	// handlers "ptchampion/internal/api/handlers"

	"ptchampion/internal/api/middleware"
	"ptchampion/internal/config"
	"ptchampion/internal/logging"
	"ptchampion/internal/telemetry"

	"github.com/go-chi/chi/v5"
	"github.com/go-playground/validator/v10"
	"github.com/labstack/echo/v4"
	echoMiddleware "github.com/labstack/echo/v4/middleware" // Import echo middleware
	"go.uber.org/zap"
)

// FileServer conveniently sets up a http.FileServer handler to serve
// static files from a http.FileSystem.
func FileServer(r chi.Router, path string, root http.FileSystem) {
	if strings.Contains(path, "{") || strings.Contains(path, "*") {
		panic("FileServer does not permit URL parameters.")
	}

	if path != "/" && path[len(path)-1] != '/' {
		r.Get(path, http.RedirectHandler(path+"/", http.StatusMovedPermanently).ServeHTTP)
		path += "/"
	}
	path += "*"

	r.Get(path, func(w http.ResponseWriter, r *http.Request) {
		rctx := chi.RouteContext(r.Context())
		pathPrefix := strings.TrimSuffix(rctx.RoutePattern(), "/*")
		fs := http.StripPrefix(pathPrefix, http.FileServer(root))
		fs.ServeHTTP(w, r)
	})
}

// CustomValidator holds the validator instance
type CustomValidator struct {
	validator *validator.Validate
}

// Validate performs validation on the struct
func (cv *CustomValidator) Validate(i interface{}) error {
	return cv.validator.Struct(i)
}

// NewRouter creates and configures the main application router.
func NewRouter(apiHandler *ApiHandler, cfg *config.Config, logger logging.Logger) http.Handler { // Accept *ApiHandler
	// Use Echo router instead of Chi
	e := echo.New()

	// Setup Validator
	e.Validator = &CustomValidator{validator: validator.New()}

	// Initialize OpenTelemetry (no‑op if endpoint not provided)
	ctx := context.Background()
	shutdown, err := telemetry.SetupOTelSDK(ctx, telemetry.Config{
		ServiceName:    "ptchampion",
		Environment:    cfg.AppEnv,
		ServiceVersion: cfg.AppVersion,
		OTLPEndpoint:   cfg.OTLPEndpoint,
		OTLPInsecure:   cfg.OTLPInsecure,
	})
	if err != nil {
		log.Printf("Failed to initialize OpenTelemetry: %v", err)
	} else {
		// Register tracer shutdown on server close
		e.Server.RegisterOnShutdown(func() {
			if err := shutdown(ctx); err != nil {
				log.Printf("Error shutting down tracer provider: %v", err)
			}
		})
	}

	// Initialize Feature Flag Middleware if API key is provided
	var featureFlagMiddleware *middleware.FeatureFlagMiddleware
	if cfg.FlagsmithAPIKey != "" {
		ffConfig := middleware.FeatureFlagConfig{
			APIKey:             cfg.FlagsmithAPIKey,
			BaseURL:            cfg.FlagsmithBaseURL,
			CacheTTL:           cfg.FlagsmithCacheTTL,
			DefaultEnvironment: cfg.FlagsmithEnvironmentName,
		}

		var featureFlagErr error
		featureFlagMiddleware, featureFlagErr = middleware.NewFeatureFlagMiddleware(ffConfig)
		if featureFlagErr != nil {
			log.Printf("Warning: Failed to initialize feature flag middleware: %v", featureFlagErr)
		} else {
			log.Printf("Feature flag middleware initialized with environment: %s", cfg.FlagsmithEnvironmentName)
			// Add the feature flag middleware
			e.Use(featureFlagMiddleware.Middleware())
		}
	} else {
		log.Println("Feature flag middleware not initialized (FLAGSMITH_API_KEY not provided)")
	}

	// Middleware for Echo
	e.Use(echoMiddleware.Logger())
	e.Use(echoMiddleware.Recover())
	e.Use(echoMiddleware.RequestID())
	// Add OpenTelemetry middleware
	e.Use(middleware.OTELMiddleware())
	// Add Security Headers middleware
	e.Use(middleware.SecurityHeaders())
	// Replace the basic CORS middleware with our secure configuration
	e.Use(echoMiddleware.CORSWithConfig(middleware.CORSConfig()))
	e.Use(func(next echo.HandlerFunc) echo.HandlerFunc { // Heartbeat equivalent
		return func(c echo.Context) error {
			if c.Request().URL.Path == "/ping" {
				return c.String(http.StatusOK, "pong")
			}
			return next(c)
		}
	})

	// Initialize Sentry for error monitoring (if DSN is provided)
	if cfg.SentryDSN != "" {
		sentryConfig := middleware.SentryConfig{
			Dsn:              cfg.SentryDSN,
			Environment:      cfg.AppEnv,
			Release:          cfg.AppVersion,
			Debug:            cfg.AppEnv == "development",
			AttachStacktrace: true,
			TracesSampleRate: 0.2,
			ServerName:       cfg.ServerName,
			AppVersion:       cfg.AppVersion,
			Tags: map[string]string{
				"service": "backend-api",
			},
		}

		sentryMiddleware, err := middleware.SentryMiddleware(sentryConfig)
		if err != nil {
			logger.Warn("Failed to initialize Sentry middleware", zap.Error(err))
		} else {
			logger.Info("Sentry error reporting initialized")
			e.Use(sentryMiddleware)
		}
	} else {
		logger.Info("Sentry DSN not provided; error reporting disabled")
	}

	// Health Check endpoints
	e.GET("/health", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{"status": "healthy"})
	})

	// Add /healthz endpoint specifically for synthetic health checks
	e.GET("/healthz", func(c echo.Context) error {
		// This endpoint performs a more thorough check including:
		// 1. System status
		// 2. Database connection
		// 3. External services (if applicable)

		// TODO: Add additional checks for database and external services

		return c.JSON(http.StatusOK, map[string]interface{}{
			"status":      "healthy",
			"version":     os.Getenv("APP_VERSION"),
			"environment": os.Getenv("APP_ENV"),
			"timestamp":   time.Now().UTC().Format(time.RFC3339),
			"components": map[string]string{
				"api": "healthy",
				// Add more component statuses here as needed
			},
		})
	})

	// Add root path handler to avoid AlwaysOn 404s
	e.GET("/", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]interface{}{
			"status":  "online",
			"service": "ptchampion-api",
			"version": cfg.AppVersion,
			"env":     cfg.AppEnv,
			"message": "API is running. Use /api/v1 endpoints to access services.",
		})
	})

	// Add Azure liveness probe endpoint
	e.GET("/robots933456.txt", func(c echo.Context) error {
		return c.String(http.StatusOK, "")
	})

	// Register API endpoints
	apiGroup := e.Group("/api/v1")
	RegisterHandlers(apiGroup, apiHandler)

	// Add feature flags endpoint if middleware is available
	if featureFlagMiddleware != nil {
		apiGroup.GET("/features", featureFlagMiddleware.FeaturesHandler())
	} else {
		// Use a fallback feature flags handler when middleware isn't available
		apiGroup.GET("/features", apiHandler.FeaturesHandler)
	}

	// --- Static File Serving for React App (Echo version) ---
	staticFilesDir := "/app/static"
	if _, err := os.Stat(staticFilesDir); os.IsNotExist(err) {
		// Fallback to local development path if /app/static doesn't exist
		staticFilesDir = "./web/dist"
		if _, err := os.Stat(staticFilesDir); os.IsNotExist(err) {
			// Suppressing warning to keep logs cleaner - static files are optional for this API service
			// log.Printf("Warning: Neither /app/static nor ./web/dist exist. Static file serving may not work correctly.")
		}
	}

	// Serve static files from root and /assets
	e.Static("/", filepath.Join(staticFilesDir, "index.html"))
	e.Static("/assets", filepath.Join(staticFilesDir, "assets"))

	// SPA Handler: For any other GET request not matching API or static files, serve index.html
	e.GET("*", func(c echo.Context) error {
		if !strings.HasPrefix(c.Request().URL.Path, "/api/") &&
			!strings.HasPrefix(c.Request().URL.Path, "/assets/") {
			return c.File(filepath.Join(staticFilesDir, "index.html"))
		}
		// Let Echo handle 404 for API routes or missing assets
		return echo.ErrNotFound
	})

	// Register Prometheus metrics and expose /metrics endpoint
	middleware.RegisterMetrics(e)

	// Set up middleware that should be applied to all routes
	e.Use(middleware.RequestLogging(middleware.RequestLoggingConfig{
		Logger: logger,
		SkipPaths: []string{
			"/health",
			"/metrics",
		},
	}))

	// All routes are registered through OpenAPI‑generated RegisterHandlers above.

	return e // Return the Echo instance
}
