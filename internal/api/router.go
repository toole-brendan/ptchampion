package api

import (
	"context"
	"database/sql"
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
	db "ptchampion/internal/store/postgres"
	"ptchampion/internal/telemetry"

	"github.com/go-chi/chi/v5"
	"github.com/go-playground/validator/v10"
	"github.com/labstack/echo/v4"
	echoMiddleware "github.com/labstack/echo/v4/middleware" // Import echo middleware
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

// NewCustomValidatorInstance creates a new CustomValidator instance that implements echo.Validator.
func NewCustomValidatorInstance() echo.Validator {
	return &CustomValidator{validator: validator.New()}
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
	
	// Add compression middleware for better performance
	e.Use(echoMiddleware.GzipWithConfig(echoMiddleware.GzipConfig{
		Level: 5, // Balanced compression level
		Skipper: func(c echo.Context) bool {
			// Skip compression for small responses
			return c.Response().Size < 1024 // Skip if less than 1KB
		},
	}))
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
		// Define the SentryConfig for the middleware
		middlewareSentryConfig := middleware.SentryConfig{
			Dsn:              cfg.SentryDSN,
			Environment:      cfg.AppEnv,
			Release:          cfg.AppVersion,
			Debug:            cfg.AppEnv == "development",
			AttachStacktrace: true,           // Defaulting to true, adjust if needed
			SampleRate:       1.0,            // Defaulting, adjust if needed (e.g., cfg.SentrySampleRate)
			TracesSampleRate: 0.2,            // Defaulting, adjust if needed (e.g., cfg.SentryTracesSampleRate)
			ServerName:       cfg.ServerName, // Assuming ServerName is in cfg
			AppVersion:       cfg.AppVersion,
			Tags: map[string]string{ // Optional: Add default tags
				"service": "ptchampion-api",
			},
		}

		// Pass the middleware.SentryConfig to the middleware
		sentryEchoMiddleware, err := middleware.SentryMiddleware(middlewareSentryConfig)
		if err != nil {
			logger.Warn(context.Background(), "Failed to initialize Sentry middleware", "error", err)
		} else {
			logger.Info(context.Background(), "Sentry error reporting initialized via middleware")
			e.Use(sentryEchoMiddleware) // Use the middleware returned by SentryMiddleware
		}
	} else {
		logger.Info(context.Background(), "Sentry DSN not provided; error reporting disabled")
	}

	// Health Check endpoints
	e.GET("/health", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{"status": "healthy"})
	})

	// This variable will hold the DB connection if initialized by the router
	var dbConnForHealthCheck *sql.DB

	// Create API handler if one wasn't provided
	if apiHandler == nil {
		// Try to connect to database
		dbConn, dbErr := db.NewDB(cfg.DatabaseURL)
		if dbErr != nil {
			log.Printf("Warning: Failed to connect to database for API handler: %v", dbErr)
		} else {
			dbConnForHealthCheck = dbConn // Capture for health check
			// Initialize store with simple timeout
			store := db.NewStore(dbConn, cfg.DBTimeout)
			store.SetLogger(logger) // Make sure logger is set on store if methods use it

			// Create a new handler with the store and logger
			apiHandler = NewApiHandler(cfg, store, logger) // Pass full store and logger
		}
	}

	// Add /healthz endpoint specifically for synthetic health checks
	e.GET("/healthz", func(c echo.Context) error {
		components := map[string]string{
			"api": "healthy",
		}
		overallStatus := "healthy"

		// Database health check
		if dbConnForHealthCheck != nil {
			ctx, cancel := context.WithTimeout(c.Request().Context(), 2*time.Second) // Short timeout for ping
			defer cancel()
			if err := dbConnForHealthCheck.PingContext(ctx); err == nil {
				components["database"] = "healthy"
			} else {
				components["database"] = "unhealthy"
				overallStatus = "degraded"
				logger.Error(context.Background(), "Health check: Database ping failed", "error", err)
			}
		} else {
			components["database"] = "unknown"
			// overallStatus could remain "healthy" if DB is optional or "degraded" if critical
		}

		// TODO: Add checks for other external services if applicable (e.g., Redis, Flagsmith)
		// if featureFlagMiddleware != nil && featureFlagMiddleware.IsHealthy() { ... }

		return c.JSON(http.StatusOK, map[string]interface{}{
			"status":      overallStatus,
			"version":     cfg.AppVersion, // Use cfg for version
			"environment": cfg.AppEnv,     // Use cfg for environment
			"timestamp":   time.Now().UTC().Format(time.RFC3339),
			"components":  components,
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

	// Register OpenAPI handlers and set up API groups
	if apiHandler != nil {
		log.Printf("Registering API routes and handlers")

		// Create the base API group
		apiGroup := e.Group("/api/v1")

		// 1️⃣ Public health check - MUST come before auth-protected routes
		apiGroup.GET("/health", func(c echo.Context) error {
			return c.JSON(http.StatusOK, map[string]string{
				"status":  "healthy",
				"message": "Health check endpoint for CI/CD monitoring",
			})
		})

		// 2️⃣ Register OpenAPI handlers for auth routes that don't need protection
		// This is handled in the generated code

		// 3️⃣ Everything else requires JWT
		// The OpenAPI handlers will apply auth middleware to protected routes

		// OAuth routes for Google and Apple authentication
		e.GET("/auth/google", handleGoogleOAuth)
		e.POST("/auth/google", handleGoogleOAuth)
		e.GET("/auth/apple", handleAppleOAuth)
		e.POST("/auth/apple", handleAppleOAuth)

		RegisterHandlersWithBaseURL(e, apiHandler, "/api/v1")
	} else {
		log.Printf("Warning: apiHandler is nil, OpenAPI endpoints not registered")
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

// handleGoogleOAuth handles OAuth authentication flow for Google accounts.
// Supports both web (GET) and mobile (POST) flows.
func handleGoogleOAuth(c echo.Context) error {
	// Placeholder for Google OAuth implementation
	return c.JSON(http.StatusNotImplemented, map[string]string{
		"message": "Google OAuth implementation pending",
	})
}

// handleAppleOAuth handles OAuth authentication flow for Apple accounts.
// Supports both web (GET) and mobile (POST) flows.
func handleAppleOAuth(c echo.Context) error {
	// Placeholder for Apple OAuth implementation
	return c.JSON(http.StatusNotImplemented, map[string]string{
		"message": "Apple OAuth implementation pending",
	})
}
