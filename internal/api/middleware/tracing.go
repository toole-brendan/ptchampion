package middleware

import (
	"github.com/labstack/echo/v4"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/trace"
)

// TracerName is the name used for the tracer
const TracerName = "ptchampion/api"

// Tracing middleware adds OpenTelemetry distributed tracing
func Tracing() echo.MiddlewareFunc {
	// Create a tracer from the global provider
	tracer := otel.GetTracerProvider().Tracer(TracerName)
	propagator := otel.GetTextMapPropagator()

	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			req := c.Request()
			ctx := req.Context()

			// Extract any existing trace information from the request headers
			ctx = propagator.Extract(ctx, propagation.HeaderCarrier(req.Header))

			// Start a new span for this request
			spanName := c.Path()
			if spanName == "" {
				spanName = req.URL.Path
			}

			// Create options with attributes describing the request
			opts := []trace.SpanStartOption{
				trace.WithAttributes(
					attribute.String("http.method", req.Method),
					attribute.String("http.url", req.URL.String()),
					attribute.String("http.host", req.Host),
					attribute.String("http.user_agent", req.UserAgent()),
					attribute.String("http.client_ip", c.RealIP()),
				),
				trace.WithSpanKind(trace.SpanKindServer),
			}

			ctx, span := tracer.Start(ctx, "HTTP "+req.Method+" "+spanName, opts...)
			defer span.End()

			// Update the request with the context containing tracing data
			c.SetRequest(req.WithContext(ctx))

			// Process the request
			err := next(c)

			// Update span with information about the response
			if err != nil {
				span.SetStatus(codes.Error, err.Error())
				span.RecordError(err)
			} else {
				span.SetStatus(codes.Ok, "")
			}

			// Set attributes about the response
			span.SetAttributes(
				attribute.Int("http.status_code", c.Response().Status),
				attribute.Int64("http.response_content_length", c.Response().Size),
			)

			return err
		}
	}
}
