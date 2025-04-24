package middleware

import (
	"time"

	"ptchampion/internal/logging"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
)

// RequestLoggingConfig holds configuration for the RequestLogging middleware
type RequestLoggingConfig struct {
	Logger        logging.Logger
	SkipPaths     []string
	DisableBody   bool
	DisableHeader bool
}

// RequestLogging creates a middleware that logs detailed request information
func RequestLogging(config RequestLoggingConfig) echo.MiddlewareFunc {
	skipMap := make(map[string]bool, len(config.SkipPaths))
	for _, path := range config.SkipPaths {
		skipMap[path] = true
	}

	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			// Skip logging for certain paths
			if skipMap[c.Path()] {
				return next(c)
			}

			start := time.Now()
			req := c.Request()
			res := c.Response()

			// Generate a unique request ID if not already present
			requestID := req.Header.Get("X-Request-ID")
			if requestID == "" {
				requestID = uuid.New().String()
				c.Response().Header().Set("X-Request-ID", requestID)
			}

			// Store request ID in context
			c.Set("requestID", requestID)

			// Process the request
			err := next(c)

			// Log after the request is complete
			latency := time.Since(start)

			// Build log message with relevant request data
			logMessage := "Request completed"
			if err != nil {
				logMessage = "Request error"
			}

			// Store request data to log
			reqData := map[string]interface{}{
				"request_id": requestID,
				"remote_ip":  c.RealIP(),
				"method":     req.Method,
				"uri":        req.RequestURI,
				"status":     res.Status,
				"latency_ms": latency.Milliseconds(),
				"host":       req.Host,
				"route":      c.Path(),
				"user_agent": req.UserAgent(),
			}

			// Conditionally log request headers
			if !config.DisableHeader {
				headers := make(map[string]string)
				for k, v := range req.Header {
					// Skip sensitive headers
					if k == "Authorization" || k == "Cookie" {
						continue
					}
					if len(v) > 0 {
						headers[k] = v[0]
					}
				}
				reqData["headers"] = headers
			}

			// Log at appropriate level based on status code
			if err != nil {
				config.Logger.Error(logMessage, err, reqData)
			} else if res.Status >= 500 {
				config.Logger.Error(logMessage, nil, reqData)
			} else if res.Status >= 400 {
				config.Logger.Warn(logMessage, reqData)
			} else {
				config.Logger.Info(logMessage, reqData)
			}

			return err
		}
	}
}
