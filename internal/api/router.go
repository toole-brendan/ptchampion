package api

import (
	"encoding/json"
	"net/http"
	"strings"

	"ptchampion/internal/api/handlers"
	customMiddleware "ptchampion/internal/api/middleware"
	"ptchampion/internal/config"

	"github.com/go-chi/chi/v5"
	chiMiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	// No longer need jwtauth here if using custom middleware wrapper
	// "github.com/go-chi/jwtauth/v5"
)

// NewRouter creates and configures the main application router.
func NewRouter(h *handlers.Handler, cfg *config.Config) http.Handler {
	r := chi.NewRouter()

	// Middleware
	r.Use(chiMiddleware.Logger)
	r.Use(chiMiddleware.Recoverer)
	r.Use(chiMiddleware.RequestID)
	r.Use(chiMiddleware.RealIP)
	r.Use(chiMiddleware.Heartbeat("/ping"))

	// Add CORS middleware
	r.Use(cors.Handler(cors.Options{
		// For development, allow any localhost origin with any port
		AllowOriginFunc: func(r *http.Request, origin string) bool {
			// Allow all localhost origins (any port)
			return strings.HasPrefix(origin, "http://localhost:") ||
				strings.HasPrefix(origin, "https://localhost:") ||
				origin == "http://localhost" ||
				origin == cfg.ClientOrigin // Also allow configured origin if specified
		},
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: true,
		MaxAge:           300, // Maximum value not ignored by any major browsers
	}))

	// Health Check endpoint
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// Register health check endpoint for port discovery
	r.HandleFunc("/api/v1/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Access-Control-Allow-Origin", "*") // Allow any origin for health checks
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]string{"status": "healthy"})
	})

	// API versioning (optional, but good practice)
	r.Route("/api/v1", func(r chi.Router) {
		// Public routes (auth-related routes in auth_handler.go)
		r.Post("/users/register", h.RegisterUser)
		r.Post("/users/login", h.LoginUser)
		r.Get("/leaderboard/{exerciseType}", h.GetLeaderboard)

		// Protected routes (require JWT)
		r.Group(func(r chi.Router) {
			// Use JWT Authenticator middleware
			r.Use(customMiddleware.AuthMiddleware(cfg.JWTSecret))

			// User Profile
			r.Patch("/users/me", h.UpdateCurrentUser)

			// Exercise routes
			r.Post("/exercises", h.LogExercise)
			r.Get("/exercises", h.GetUserExercises)

			// TODO: Add Leaderboard routes if any require auth?
		})
	})

	return r
}
