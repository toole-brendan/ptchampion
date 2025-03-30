package api

import (
	"encoding/json"
	"net/http"
	"os"
	"path/filepath"
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

// FileServer conveniently sets up a http.FileServer handler to serve
// static files from a http.FileSystem.
func FileServer(r chi.Router, path string, root http.FileSystem) {
	if strings.Contains(path, "{") || strings.Contains(path, "*") {
		panic("FileServer does not permit URL parameters.")
	}

	if path != "/" && path[len(path)-1] != '/' {
		r.Get(path, http.RedirectHandler(path+"/", http.StatusMovedPermanently).ServeHTTP)
		path += "/"
	}
	path += "*"

	r.Get(path, func(w http.ResponseWriter, r *http.Request) {
		rctx := chi.RouteContext(r.Context())
		pathPrefix := strings.TrimSuffix(rctx.RoutePattern(), "/*")
		fs := http.StripPrefix(pathPrefix, http.FileServer(root))
		fs.ServeHTTP(w, r)
	})
}

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
			// Allow configured production origins and localhost for dev
			return origin == "https://ptchampion.ai" ||
				origin == "https://www.ptchampion.ai" ||
				strings.HasPrefix(origin, "http://localhost:") ||
				origin == cfg.ClientOrigin // Keep env var check just in case
		},
		AllowedMethods:   []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type", "X-CSRF-Token"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: true,
		MaxAge:           300, // Maximum value not ignored by any major browsers
	}))

	// Health Check endpoint
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Access-Control-Allow-Origin", "*") // Allow any origin for health checks
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]string{"status": "healthy"})
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

	// --- Static File Serving for React App ---
	staticFilesDir := "/app/static"
	staticFS := http.Dir(staticFilesDir)

	// Serve static files (like /assets/...)
	FileServer(r, "/", staticFS)

	// Serve index.html for non-API GET requests (SPA Handler)
	r.NotFound(func(w http.ResponseWriter, r *http.Request) {
		// If it's not an API call and not a direct file request handled by FileServer
		// (or if the file doesn't exist), serve the main index.html file.
		if !strings.HasPrefix(r.URL.Path, "/api/") {
			// Check if the actual file exists before serving index.html
			// This prevents serving index.html for potentially missing static assets
			filePath := filepath.Join(staticFilesDir, r.URL.Path)
			_, err := os.Stat(filePath)
			if os.IsNotExist(err) {
				http.ServeFile(w, r, filepath.Join(staticFilesDir, "index.html"))
				return
			}
		}
		// For actual API 404s or other errors
		http.Error(w, http.StatusText(http.StatusNotFound), http.StatusNotFound)
	})

	return r
}
