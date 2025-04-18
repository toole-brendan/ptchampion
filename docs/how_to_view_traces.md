# How to View Traces in PT Champion

This guide explains how to use Jaeger to view distributed traces in the PT Champion application.

## What is Tracing?

Distributed tracing is a method used to profile and monitor applications, especially those built using a microservices architecture. It helps pinpoint where failures occur and what causes poor performance.

PT Champion uses OpenTelemetry for instrumentation and Jaeger as the tracing backend.

## Setup

The tracing system is automatically set up when you run the application using Docker Compose:

```bash
make dev
```

This starts all required services, including:
- The main PTChampion backend service (with built-in tracing)
- A PostgreSQL database
- Jaeger (for collecting and visualizing traces)

## Accessing the Jaeger UI

1. Start the application using `make dev`
2. Open your browser and navigate to: [http://localhost:16686](http://localhost:16686)
3. You should see the Jaeger UI dashboard

## Viewing Traces

### Basic Search

1. In the Jaeger UI, select "ptchampion-backend" from the "Service" dropdown
2. Click the "Find Traces" button
3. You'll see a list of traces, ordered by most recent first
4. Click on any trace to view its details

### Advanced Filtering

You can filter traces by:

- **Time Range**: Use the time picker to narrow down traces to a specific time period
- **Tags**: Filter by HTTP method, status code, or user ID
- **Operation**: Filter by specific operations like "GET /api/users"
- **Duration**: Find slow requests by filtering for minimum duration

### Understanding the Trace View

When viewing a trace:

- Each trace represents a single request through the system
- Traces are broken down into "spans" representing operations inside that request
- The waterfall view shows timing and parent-child relationships
- Click on any span to view its details, including:
  - Tags: Key-value attributes (HTTP method, status code, etc.)
  - Process: The service that generated the span
  - Logs: Events that occurred during the span

### Common Use Cases

#### Identifying Slow API Endpoints

1. Filter for traces with long durations (e.g., > 500ms)
2. Sort by duration to find the slowest requests
3. Analyze which spans within those traces take the most time

#### Troubleshooting Errors

1. Filter for traces with error tags
2. Examine the spans to identify where the error occurred
3. Check the logs and tags within the error span for details

#### Understanding Request Flow

1. Select any trace
2. Follow the spans from top to bottom to understand how the request was processed
3. Note the timing information to see which steps took longest

## Adding Custom Traces

For developers who want to add custom traces to specific code sections:

```go
// Assuming ctx contains an active span
ctx, span := tracer.Start(ctx, "my-operation-name")
defer span.End()

// Add custom attributes
span.SetAttributes(attribute.String("key", "value"))

// Record errors
if err != nil {
    span.RecordError(err)
}
```

## References

- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Jaeger Documentation](https://www.jaegertracing.io/docs/) 