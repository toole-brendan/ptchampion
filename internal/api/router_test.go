package api

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"ptchampion/internal/config"
	"ptchampion/internal/logging"
)

// TestHealthEndpoint verifies that /health returns 200 OK
func TestHealthEndpoint(t *testing.T) {
	cfg := &config.Config{}
	logger := logging.NewDefaultLogger()

	// We don't hit any handler that needs DB, so pass nils safely.
	router := NewRouter(nil, cfg, logger)

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rec.Code)
	}
}

// TestPingEndpoint checks custom /ping heartbeat.
func TestPingEndpoint(t *testing.T) {
	cfg := &config.Config{}
	logger := logging.NewDefaultLogger()

	router := NewRouter(nil, cfg, logger)

	req := httptest.NewRequest(http.MethodGet, "/ping", nil)
	rec := httptest.NewRecorder()

	router.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", rec.Code)
	}

	if rec.Body.String() != "pong" {
		t.Fatalf("expected body pong, got %s", rec.Body.String())
	}
}
