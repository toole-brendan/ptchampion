# Health Check Fix Recommendations

## Overview of the Issue

The health check endpoint at `/api/v1/health` is not being correctly served, causing Front Door health probes and GitHub Actions deployment checks to fail.

## Short-Term Fix

We've created a dedicated health check service that:
- Exposes multiple health endpoints at various paths
- Includes detailed logging for debugging 
- Handles all critical health check paths

## Long-Term Fixes for Main Application

### 1. Update Route Registration Order

In `internal/api/router.go`, move the health endpoint registration to be earlier in the middleware chain:

```go
// Create Echo instance
e := echo.New()

// Basic middleware for recovery
e.Use(middleware.Recover())

// CRITICAL: Register health endpoints FIRST - before any complex middleware
e.GET("/health", func(c echo.Context) error {
    return c.JSON(http.StatusOK, map[string]string{"status": "healthy"})
})

e.GET("/api/health", func(c echo.Context) error {
    return c.JSON(http.StatusOK, map[string]string{"status": "healthy"})
})

e.GET("/api/v1/health", func(c echo.Context) error {
    return c.JSON(http.StatusOK, map[string]string{
        "status":  "healthy",
        "message": "Health check endpoint for CI/CD monitoring",
    })
})

// Now add all other middleware and routes
// ...
```

### 2. Add Explicit Debug Logging

Add detailed logging to the health endpoints:

```go
e.GET("/api/v1/health", func(c echo.Context) error {
    log.Printf("Health check hit at /api/v1/health via %s", c.Request().Method)
    return c.JSON(http.StatusOK, map[string]string{
        "status":  "healthy",
        "message": "Health check endpoint for CI/CD monitoring",
        "timestamp": time.Now().UTC().Format(time.RFC3339),
    })
})
```

### 3. Review Middleware Interference

Check for middleware that might be interfering with health requests:

- If your app uses JWT authentication, ensure the health endpoints are exempted
- Look for any middleware that might be redirecting or rewriting URLs
- Check for middleware that handles routing in a special way (e.g., SPA fallbacks)

### 4. Consolidate Health Check Logic

Create a dedicated health check handler to reuse across endpoints:

```go
func healthHandler(c echo.Context) error {
    log.Printf("Health check hit at %s", c.Request().URL.Path)
    return c.JSON(http.StatusOK, map[string]string{
        "status":  "healthy",
        "message": "Health check endpoint for CI/CD monitoring",
        "path":    c.Request().URL.Path,
    })
}

// Then reuse it:
e.GET("/health", healthHandler)
e.GET("/api/health", healthHandler)
e.GET("/api/v1/health", healthHandler)
```

### 5. Ensure Configuration Alignment

Make sure these configurations are aligned:

1. **Front Door Health Probe**: `/api/v1/health`
2. **App Service Health Check Path**: `/api/v1/health`
3. **GitHub Actions Workflow**: Checks `/api/v1/health`

### 6. Monitoring and Alerting

Add monitoring for the health endpoints:

- Set up an alert if the health endpoint starts returning non-200 responses
- Add specific metrics for health check response times and success rates
- Ensure health check logs are easily searchable for troubleshooting

## Implementation Plan

1. **Immediate**: Deploy the dedicated health service as a stopgap solution
2. **Short-term**: Implement fixes 1-3 on the main application in development
3. **Medium-term**: Implement consolidation and monitoring (fixes 4-6)
4. **Long-term**: Establish health check standards for future services 