package middleware

import (
	"context"
	"time"

	sentry "github.com/getsentry/sentry-go"
	"github.com/labstack/echo/v4"
)

// SentryConfig holds configuration for Sentry middleware
type SentryConfig struct {
	Dsn              string
	Environment      string
	Release          string
	Debug            bool
	AttachStacktrace bool
	SampleRate       float64           // Default: 1.0 (100% of errors)
	TracesSampleRate float64           // Default: 0.2 (20% of transactions)
	ServerName       string            // Optional server/container name
	AppVersion       string            // App version for easier identification
	Tags             map[string]string // Additional tags to include by default
}

// SentryMiddleware captures errors and sends them to Sentry
func SentryMiddleware(config SentryConfig) (echo.MiddlewareFunc, error) {
	// Initialize Sentry client
	sentryOptions := sentry.ClientOptions{
		Dsn:              config.Dsn,
		Environment:      config.Environment,
		Release:          config.Release,
		Debug:            config.Debug,
		AttachStacktrace: config.AttachStacktrace,
		SampleRate:       config.SampleRate,
		TracesSampleRate: config.TracesSampleRate,
		ServerName:       config.ServerName,
	}

	// Set default values if not provided
	if sentryOptions.SampleRate == 0 {
		sentryOptions.SampleRate = 1.0 // Capture all errors by default
	}

	if sentryOptions.TracesSampleRate == 0 {
		sentryOptions.TracesSampleRate = 0.2 // Trace 20% of transactions by default
	}

	// Record app version as release if no release is specified
	if sentryOptions.Release == "" && config.AppVersion != "" {
		sentryOptions.Release = config.AppVersion
	}

	err := sentry.Init(sentryOptions)
	if err != nil {
		return nil, err
	}

	// Return Echo middleware function
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			// Create a Sentry hub for this request
			hub := sentry.CurrentHub().Clone()

			// Add request info to the hub scope
			hub.ConfigureScope(func(scope *sentry.Scope) {
				scope.SetRequest(c.Request())
				scope.SetTag("transaction_id", c.Response().Header().Get(echo.HeaderXRequestID))
			})

			// Attach the hub to the context
			ctx := sentry.SetHubOnContext(c.Request().Context(), hub)
			c.SetRequest(c.Request().WithContext(ctx))

			// Start a new Sentry transaction for this request
			transaction := sentry.StartTransaction(
				ctx,
				c.Request().Method+" "+c.Path(),
				sentry.ContinueFromRequest(c.Request()),
			)
			defer transaction.Finish()

			// Update the request context with the transaction
			// Skipping SetTransaction that may not exist in current version
			// Just continue using the context with the hub

			// Process the request
			err := next(c)

			// Capture error if present
			if err != nil {
				// Only create error events for server errors and unexpected errors
				// Skip client errors (4xx) which are expected application behavior
				skip := false

				if httpErr, ok := err.(*echo.HTTPError); ok {
					// Pass through HTTP errors but only report 500s to Sentry
					if httpErr.Code < 500 {
						skip = true
					}
				}

				if !skip {
					// Set error severity and add tags
					hub.WithScope(func(scope *sentry.Scope) {
						scope.SetLevel(sentry.LevelError)

						// Add request path for error grouping
						scope.SetTag("path", c.Path())

						// Add default tags passed in config
						for k, v := range config.Tags {
							scope.SetTag(k, v)
						}

						hub.CaptureException(err)
					})
				}

				return err
			}

			return err
		}
	}, nil
}

// GetSentryHub retrieves the Sentry hub from the context
func GetSentryHub(ctx context.Context) *sentry.Hub {
	if hub := sentry.GetHubFromContext(ctx); hub != nil {
		return hub
	}
	return sentry.CurrentHub()
}

// CaptureMessage sends a message to Sentry
func CaptureMessage(ctx context.Context, message string, level sentry.Level) {
	hub := GetSentryHub(ctx)
	hub.WithScope(func(scope *sentry.Scope) {
		scope.SetLevel(level)
		hub.CaptureMessage(message)
	})
}

// CaptureException sends an error to Sentry
func CaptureException(ctx context.Context, err error) {
	if err == nil {
		return
	}

	hub := GetSentryHub(ctx)
	hub.CaptureException(err)
}

// Flush waits for all events to be sent to Sentry
// Call this before your program terminates
func Flush(timeout time.Duration) {
	sentry.Flush(timeout)
}
