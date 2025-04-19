package middleware

import (
	"time"

	"ptchampion/internal/logging"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"go.uber.org/zap"
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

			// Add request ID to context for logging
			ctx := logging.AddRequestID(req.Context(), requestID)
			c.SetRequest(req.WithContext(ctx))

			// Process the request
			err := next(c)

			// Log after the request is complete
			latency := time.Since(start)
			fields := []zap.Field{
				zap.String("request_id", requestID),
				zap.String("remote_ip", c.RealIP()),
				zap.String("method", req.Method),
				zap.String("uri", req.RequestURI),
				zap.Int("status", res.Status),
				zap.String("user_agent", req.UserAgent()),
				zap.String("referer", req.Referer()),
				zap.Duration("latency", latency),
				zap.String("host", req.Host),
				zap.String("route", c.Path()),
			}

			// Conditionally log request headers
			if !config.DisableHeader {
				headerMap := make(map[string]string)
				for k, v := range req.Header {
					// Skip sensitive headers
					if k == "Authorization" || k == "Cookie" {
						continue
					}
					if len(v) > 0 {
						headerMap[k] = v[0]
					}
				}
				fields = append(fields, zap.Any("headers", headerMap))
			}

			// Log at appropriate level based on status code
			msg := "Request completed"
			if err != nil {
				msg = "Request error"
				fields = append(fields, zap.Error(err))
				config.Logger.Error(msg, fields...)
			} else if res.Status >= 500 {
				config.Logger.Error(msg, fields...)
			} else if res.Status >= 400 {
				config.Logger.Warn(msg, fields...)
			} else {
				config.Logger.Info(msg, fields...)
			}

			return err
		}
	}
}
