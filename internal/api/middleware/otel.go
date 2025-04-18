package middleware

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/labstack/echo/v4"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.21.0"
	"go.opentelemetry.io/otel/trace"
)

var tracer trace.Tracer

const (
	tracerName = "github.com/ptchampion/internal/api/middleware"
)

// InitTracer initializes an OTLP exporter, and configures the corresponding trace provider
func InitTracer(ctx context.Context) (func(context.Context) error, error) {
	// OTEL_EXPORTER_OTLP_ENDPOINT env var should be set, or we'll use a default
	endpoint := os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
	if endpoint == "" {
		endpoint = "http://localhost:4318" // Default to local Jaeger
	}

	// OTEL_SERVICE_NAME env var should be set, or we'll use a default
	serviceName := os.Getenv("OTEL_SERVICE_NAME")
	if serviceName == "" {
		serviceName = "ptchampion-service"
	}

	// Configure the client to use insecure (http) connections
	client := otlptracehttp.NewClient(
		otlptracehttp.WithEndpoint(strings.TrimPrefix(endpoint, "http://")),
		otlptracehttp.WithInsecure(),
	)

	// Create a new OTLP exporter
	exporter, err := otlptrace.New(ctx, client)
	if err != nil {
		return nil, fmt.Errorf("creating OTLP trace exporter: %w", err)
	}

	// Identify this application with resource attributes
	res, err := resource.New(ctx,
		resource.WithAttributes(
			// Service name used to identify this application in the Jaeger UI
			semconv.ServiceNameKey.String(serviceName),
			// Additional custom attributes
			attribute.String("library.language", "go"),
		),
		// Pull standard environment attributes
		resource.WithFromEnv(),
		resource.WithHost(),
		resource.WithTelemetrySDK(),
	)
	if err != nil {
		return nil, fmt.Errorf("creating resource: %w", err)
	}

	// Create a trace provider with the exporter
	// The BatchSpanProcessor ensures spans are batched before export
	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(res),
	)
	otel.SetTracerProvider(tp)

	// Set the global propagator to tracecontext (for distributed tracing)
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
		propagation.TraceContext{},
		propagation.Baggage{},
	))

	// Initialize the global tracer
	tracer = tp.Tracer(tracerName)

	// Return a function to shutdown the TracerProvider when the application exits
	return tp.Shutdown, nil
}

// OTELMiddleware returns middleware that traces Echo requests
func OTELMiddleware() echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			req := c.Request()
			ctx := req.Context()

			// Extract trace information from request, if present
			ctx = otel.GetTextMapPropagator().Extract(ctx, propagation.HeaderCarrier(req.Header))

			// Start a new span for this request
			spanName := fmt.Sprintf("%s %s", req.Method, c.Path())
			ctx, span := tracer.Start(
				ctx,
				spanName,
				trace.WithSpanKind(trace.SpanKindServer),
			)
			defer span.End()

			// Set span attributes from the request
			span.SetAttributes(
				semconv.HTTPMethodKey.String(req.Method),
				semconv.HTTPRouteKey.String(c.Path()),
				semconv.HTTPURLKey.String(req.URL.String()),
				attribute.String("http.user_agent", req.UserAgent()),
				attribute.Int64("http.request.content_length", req.ContentLength),
				attribute.String("http.remote_addr", req.RemoteAddr),
			)

			// Record request ID if available (if using request ID middleware)
			if requestID := c.Response().Header().Get(echo.HeaderXRequestID); requestID != "" {
				span.SetAttributes(attribute.String("http.request_id", requestID))
			}

			// Record user ID if available
			if userID, ok := c.Get("user_id").(string); ok && userID != "" {
				span.SetAttributes(attribute.String("enduser.id", userID))
			}

			// Put the span back into the request context and update the request
			c.SetRequest(req.WithContext(ctx))

			// Start time for calculating request duration
			start := time.Now()

			// Call the next handler
			err := next(c)

			// Record response information in the span
			status := c.Response().Status
			span.SetAttributes(
				semconv.HTTPStatusCodeKey.Int(status),
				attribute.Int64("http.response_time_ms", time.Since(start).Milliseconds()),
			)

			// If there was an error, record it
			if err != nil {
				span.RecordError(err)
				span.SetAttributes(attribute.String("error.message", err.Error()))

				// Set span status based on HTTP response
				if status >= http.StatusInternalServerError {
					span.SetStatus(codes.Error, err.Error())
				}
			}

			// Set span status based on HTTP response
			if status >= http.StatusBadRequest {
				span.SetStatus(codes.Error, fmt.Sprintf("HTTP %d", status))
			} else {
				span.SetStatus(codes.Ok, "")
			}

			return err
		}
	}
}
