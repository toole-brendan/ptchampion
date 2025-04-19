package telemetry

import (
	"context"
	"fmt"
	"time"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.12.0"
)

// Config holds configuration for telemetry setup
type Config struct {
	ServiceName        string
	ServiceVersion     string
	Environment        string
	OTLPEndpoint       string
	OTLPInsecure       bool
	TracingSampleRatio float64
}

// SetupOTelSDK initializes the OpenTelemetry SDK with OTLP exporter
func SetupOTelSDK(ctx context.Context, cfg Config) (shutdown func(context.Context) error, err error) {
	// If no endpoint is provided, return a no-op shutdown function
	if cfg.OTLPEndpoint == "" {
		return func(context.Context) error { return nil }, nil
	}

	// Create OTLP HTTP exporter
	opts := []otlptracehttp.Option{
		otlptracehttp.WithEndpoint(cfg.OTLPEndpoint),
		otlptracehttp.WithTimeout(30 * time.Second),
	}

	if cfg.OTLPInsecure {
		opts = append(opts, otlptracehttp.WithInsecure())
	}

	traceExporter, err := otlptrace.New(
		ctx,
		otlptracehttp.NewClient(opts...),
	)
	if err != nil {
		return nil, fmt.Errorf("creating OTLP trace exporter: %w", err)
	}

	// Configure trace resource
	res, err := resource.New(ctx,
		resource.WithAttributes(
			semconv.ServiceNameKey.String(cfg.ServiceName),
			semconv.ServiceVersionKey.String(cfg.ServiceVersion),
			semconv.DeploymentEnvironmentKey.String(cfg.Environment),
		),
	)
	if err != nil {
		return nil, fmt.Errorf("creating trace resource: %w", err)
	}

	// Configure trace provider
	sampleRatio := cfg.TracingSampleRatio
	if sampleRatio <= 0 {
		sampleRatio = 0.1 // Default to 10% sampling
	}

	tracerProvider := sdktrace.NewTracerProvider(
		sdktrace.WithSampler(sdktrace.TraceIDRatioBased(sampleRatio)),
		sdktrace.WithBatcher(traceExporter),
		sdktrace.WithResource(res),
	)
	otel.SetTracerProvider(tracerProvider)

	// Set global propagator
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
		propagation.TraceContext{},
		propagation.Baggage{},
	))

	// Return a shutdown function that flushes and closes the tracer provider
	return func(ctx context.Context) error {
		// Flush and shutdown the tracer provider
		if err := tracerProvider.Shutdown(ctx); err != nil {
			return fmt.Errorf("shutting down tracer provider: %w", err)
		}
		return nil
	}, nil
}
