package routes

import (
	"log"
	"net/http"
	"time"

	"github.com/labstack/echo/v4"
)

// RegisterHealthRoutes registers all health check endpoints
// Call this EARLY in your route registration process, before other complex middleware
func RegisterHealthRoutes(e *echo.Echo) {
	// Define a reusable handler function
	healthHandler := func(c echo.Context) error {
		log.Printf("Health check hit at %s via %s", c.Request().URL.Path, c.Request().Method)
		return c.JSON(http.StatusOK, map[string]interface{}{
			"status":    "healthy",
			"message":   "Health check endpoint for CI/CD monitoring",
			"path":      c.Request().URL.Path,
			"timestamp": time.Now().UTC().Format(time.RFC3339),
		})
	}

	// Register multiple health check endpoints at different paths for maximum compatibility

	// Root health endpoint (for direct app checks)
	e.GET("/health", healthHandler)

	// API health endpoints (for Front Door and GitHub Actions)
	e.GET("/api/health", healthHandler)
	e.GET("/api/v1/health", healthHandler)

	// Azure App Service specific health endpoint
	e.GET("/robots933456.txt", func(c echo.Context) error {
		log.Printf("Azure App Service health check hit at /robots933456.txt")
		return c.String(http.StatusOK, "")
	})

	log.Println("Health check routes registered successfully")
}
