package handlers

import (
	"ptchampion/internal/config"                 // Import config
	dbStore "ptchampion/internal/store/postgres" // Use alias
)

// Handler holds shared dependencies for HTTP handlers
type Handler struct {
	Config  *config.Config // Add config field
	Queries *dbStore.Queries
	// Add other shared dependencies here later (e.g., logger, config)
}

// NewHandler creates a new Handler with dependencies
func NewHandler(cfg *config.Config, queries *dbStore.Queries) *Handler { // Accept config
	return &Handler{
		Config:  cfg, // Store config
		Queries: queries,
	}
}

// RegisterUserRequest defines the expected JSON payload for user registration
// ... rest of the file (RegisterUserRequest, UserResponse, RegisterUser, helpers) remains the same ...
