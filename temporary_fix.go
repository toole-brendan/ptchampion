package main

import (
	"log"
	"net/http"
	"os"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

// Health handler function to reuse across multiple endpoints
func healthHandler(c echo.Context) error {
	path := c.Request().URL.Path
	log.Printf("Health check hit at %s", path)
	return c.JSON(http.StatusOK, map[string]string{
		"status":  "healthy",
		"message": "Health check endpoint for CI/CD monitoring",
		"path":    path,
	})
}

func main() {
	e := echo.New()

	// Add basic middleware
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())

	// IMPORTANT: Register health endpoints FIRST, before any other middleware
	// that might interfere with these critical paths

	// Root health endpoint
	e.GET("/health", healthHandler)

	// API health endpoints at various paths for maximum compatibility
	e.GET("/api/health", healthHandler)
	e.GET("/api/v1/health", healthHandler)

	// Azure App Service specific health endpoint
	e.GET("/robots933456.txt", func(c echo.Context) error {
		log.Printf("Azure App Service health check hit")
		return c.String(http.StatusOK, "")
	})

	// Root path for basic info
	e.GET("/", func(c echo.Context) error {
		return c.JSON(http.StatusOK, map[string]string{
			"status":  "online",
			"service": "ptchampion-health-service",
			"message": "Health check service is running",
		})
	})

	// Get port from environment or use default
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Start server
	log.Printf("Starting health check service on port %s", port)
	if err := e.Start(":" + port); err != nil && err != http.ErrServerClosed {
		log.Fatalf("Failed to start server: %v", err)
	}
}
