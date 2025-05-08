package handlers

import (
	"ptchampion/internal/config"
	"ptchampion/internal/logging"
	dbStore "ptchampion/internal/store/postgres"
)

// Handler holds shared dependencies for HTTP handlers
type Handler struct {
	Config  *config.Config
	Queries *dbStore.Queries
	Logger  logging.Logger
	// Add other shared dependencies here later (e.g., logger, config)
}

// NewHandler creates a new Handler with dependencies
func NewHandler(cfg *config.Config, queries *dbStore.Queries, logger logging.Logger) *Handler {
	return &Handler{
		Config:  cfg,
		Queries: queries,
		Logger:  logger,
	}
}
