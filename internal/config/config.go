package config

import (
	"fmt"
	"log"
	"os"

	"github.com/joho/godotenv"
	"github.com/kelseyhightower/envconfig"
)

// Config holds application configuration settings
type Config struct {
	DatabaseURL  string `envconfig:"DATABASE_URL" required:"true"`
	Port         string `envconfig:"PORT" default:"8080"`
	JWTSecret    string `envconfig:"JWT_SECRET" required:"true"`
	ClientOrigin string `envconfig:"CLIENT_ORIGIN" default:"http://localhost:5173"` // Default client origin for CORS
	// Add other config fields like SESSION_SECRET later
	// SessionSecret string `envconfig:"SESSION_SECRET" required:"true"`
}

// Load loads configuration from environment variables or .env file
func Load() (*Config, error) {
	// First try to load from .env.dev for development
	if err := godotenv.Load(".env.dev"); err == nil {
		log.Println("Loaded configuration from .env.dev")
	} else {
		// If .env.dev doesn't exist, try .env
		if err := godotenv.Load(); err != nil && !os.IsNotExist(err) {
			log.Printf("Warning: Could not load .env file: %v", err)
		} else if err == nil {
			log.Println("Loaded configuration from .env")
		}
	}

	var cfg Config
	err := envconfig.Process("", &cfg)
	if err != nil {
		return nil, fmt.Errorf("failed to process configuration: %w", err)
	}

	// Log the port for debugging
	log.Printf("Server configured to run on port: %s", cfg.Port)
	log.Printf("Client origin set to: %s", cfg.ClientOrigin)

	return &cfg, nil
}
