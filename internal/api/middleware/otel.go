package middleware

import (
	"context"
	"fmt"
	"os"
	"strings"

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

// tracerName uniquely identifies spans coming from this middleware
const tracerName = "github.com/ptchampion/internal/api/middleware"

// InitTracer initialises OpenTelemetry and returns a shutdown fn.
func InitTracer(ctx context.Context) (func(context.Context) error, error) {
	// Resolve endpoint (defaults to local collector)
	endpoint := os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
	if endpoint == "" {
		endpoint = "http://localhost:4318"
	}

	// Resolve service name (defaults to something sensible for dev)
	serviceName := os.Getenv("OTEL_SERVICE_NAME")
	if serviceName == "" {
		serviceName = "ptchampion-service"
	}

	// Create OTLP HTTP exporter (insecure for local dev)
	client := otlptracehttp.NewClient(
		otlptracehttp.WithEndpoint(strings.TrimPrefix(endpoint, "http://")),
		otlptracehttp.WithInsecure(),
	)
	exporter, err := otlptrace.New(ctx, client)
	if err != nil {
		return nil, fmt.Errorf("creating OTLP trace exporter: %w", err)
	}

	// Describe this service for back‑ends (Jaeger, Honeycomb, etc.)
	res, err := resource.New(ctx,
		resource.WithAttributes(
			semconv.ServiceNameKey.String(serviceName),
			attribute.String("library.language", "go"),
		),
		resource.WithFromEnv(),
		resource.WithHost(),
		resource.WithTelemetrySDK(),
	)
	if err != nil {
		return nil, fmt.Errorf("creating OTEL resource: %w", err)
	}

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(res),
	)

	otel.SetTracerProvider(tp)
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
		propagation.TraceContext{},
		propagation.Baggage{},
	))

	return tp.Shutdown, nil
}

// OTELMiddleware instruments Echo requests with OpenTelemetry tracing.
// It gracefully handles cases where OTEL isn't configured by checking for nil spans.
func OTELMiddleware() echo.MiddlewareFunc {
	// Get a tracer from the global provider
	tracer := otel.GetTracerProvider().Tracer(tracerName)
	propagator := otel.GetTextMapPropagator()

	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			req := c.Request()
			ctx := req.Context()

			// Extract any trace information from request headers
			ctx = propagator.Extract(ctx, propagation.HeaderCarrier(req.Header))

			// Get span name from path
			spanName := c.Path()
			if spanName == "" {
				spanName = req.URL.Path
			}

			// Set HTTP attributes for the span
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

			// Start a new span
			ctx, span := tracer.Start(ctx, "HTTP "+req.Method+" "+spanName, opts...)

			// FIX: First check if span is nil to avoid any nil pointer dereference
			if span == nil {
				return next(c)
			}

			// FIX: Then check if span is recording or has a valid context
			if !span.IsRecording() || !span.SpanContext().IsValid() {
				return next(c)
			}
			defer span.End()

			// Update request with the context containing tracing data
			c.SetRequest(req.WithContext(ctx))

			// Process the request
			err := next(c)

			// Update span with response information
			if err != nil {
				span.SetStatus(codes.Error, err.Error())
				span.RecordError(err)
			} else {
				span.SetStatus(codes.Ok, "")
			}

			// Record response attributes
			if c.Response() != nil {
				span.SetAttributes(
					attribute.Int("http.status_code", c.Response().Status),
					attribute.Int64("http.response_content_length", c.Response().Size),
				)
			}

			return err
		}
	}
}
