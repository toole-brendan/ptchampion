package middleware

import (
	"net/http"
	"regexp"
	"strconv"
	"time"

	"github.com/labstack/echo/v4"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// HTTP metrics variables
var (
	// httpRequestsTotal counts total HTTP requests
	httpRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "ptchampion_http_requests_total",
			Help: "Total number of HTTP requests",
		},
		[]string{"method", "path", "status"},
	)

	// httpRequestDuration tracks request latency
	httpRequestDuration = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "ptchampion_http_request_duration_seconds",
			Help:    "HTTP request duration in seconds",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"method", "path", "status"},
	)

	// httpRequestSize tracks request size
	httpRequestSize = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "ptchampion_http_request_size_bytes",
			Help:    "Size of HTTP requests in bytes",
			Buckets: prometheus.ExponentialBuckets(100, 10, 8),
		},
		[]string{"method", "path"},
	)

	// httpResponseSize tracks response size
	httpResponseSize = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "ptchampion_http_response_size_bytes",
			Help:    "Size of HTTP responses in bytes",
			Buckets: prometheus.ExponentialBuckets(100, 10, 8),
		},
		[]string{"method", "path", "status"},
	)

	// concurrentRequests tracks concurrent requests
	concurrentRequests = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "ptchampion_http_requests_in_progress",
			Help: "Current number of HTTP requests in progress",
		},
	)
)

// Business metrics variables
var (
	// ExerciseCompletions tracks completed exercises
	ExerciseCompletions = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "ptchampion_exercise_completions_total",
			Help: "Total number of completed exercises by type",
		},
		[]string{"exercise_type"},
	)

	// ExerciseFormScores tracks the distribution of form scores
	ExerciseFormScores = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "ptchampion_exercise_form_scores",
			Help:    "Distribution of exercise form scores",
			Buckets: []float64{50, 60, 70, 80, 90, 95, 100},
		},
		[]string{"exercise_type"},
	)

	// UserSessionDurations tracks how long users spend in the app
	UserSessionDurations = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "ptchampion_user_session_seconds",
			Help:    "Duration of user sessions in seconds",
			Buckets: prometheus.ExponentialBuckets(30, 2, 10), // 30s to ~8hrs
		},
		[]string{"platform"},
	)

	// APIErrorsByType tracks errors by type and endpoint
	APIErrorsByType = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "ptchampion_api_errors_total",
			Help: "Total number of API errors by type",
		},
		[]string{"error_type", "endpoint"},
	)
)

// MetricsMiddleware tracks metrics for each request
func MetricsMiddleware() echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			if c.Path() == "/metrics" {
				return next(c)
			}

			req := c.Request()
			res := c.Response()
			// Normalize path to avoid high cardinality in metrics
			path := normalizePath(c.Path())
			method := req.Method

			// Track request size
			requestSize := computeApproximateRequestSize(req)
			httpRequestSize.WithLabelValues(method, path).Observe(float64(requestSize))

			// Track concurrent requests
			concurrentRequests.Inc()
			defer concurrentRequests.Dec()

			// Track request duration
			start := time.Now()
			err := next(c)
			duration := time.Since(start).Seconds()

			// Record metrics
			status := strconv.Itoa(res.Status)
			httpRequestsTotal.WithLabelValues(method, path, status).Inc()
			httpRequestDuration.WithLabelValues(method, path, status).Observe(duration)
			httpResponseSize.WithLabelValues(method, path, status).Observe(float64(res.Size))

			// Increment error counter if there was an error
			if err != nil {
				errorType := "unknown"
				if echoErr, ok := err.(*echo.HTTPError); ok {
					errorType = http.StatusText(echoErr.Code)
				}
				APIErrorsByType.WithLabelValues(errorType, path).Inc()
			}

			return err
		}
	}
}

// RegisterMetrics sets up the metrics endpoint
func RegisterMetrics(e *echo.Echo) {
	// Expose metrics on /metrics endpoint
	e.GET("/metrics", echo.WrapHandler(promhttp.Handler()))

	// Add metrics middleware to all routes
	e.Use(MetricsMiddleware())
}

// computeApproximateRequestSize computes an approximate request size in bytes
func computeApproximateRequestSize(r *http.Request) int {
	s := 0
	if r.URL != nil {
		s += len(r.URL.String())
	}

	s += len(r.Method)
	s += len(r.Proto)

	for name, values := range r.Header {
		s += len(name)
		for _, value := range values {
			s += len(value)
		}
	}

	if r.Host != "" {
		s += len(r.Host)
	}

	// r.Form and r.MultipartForm are not included
	if r.ContentLength != -1 {
		s += int(r.ContentLength)
	}

	return s
}

// normalizePath reduces path cardinality by replacing ID segments with placeholders
func normalizePath(path string) string {
	// Check common path patterns and normalize them
	// Example: /api/v1/users/123 -> /api/v1/users/:id

	// Match numeric IDs
	numericIDRegex := regexp.MustCompile(`/\d+(/|$)`)
	path = numericIDRegex.ReplaceAllString(path, "/:id$1")

	// Match UUID-like strings
	uuidRegex := regexp.MustCompile(`/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}(/|$)`)
	path = uuidRegex.ReplaceAllString(path, "/:id$1")

	return path
}
