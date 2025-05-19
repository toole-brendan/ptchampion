package config

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/security/keyvault/azsecrets"
	"github.com/joho/godotenv"
	"github.com/kelseyhightower/envconfig"
)

// Config holds application configuration settings
type Config struct {
	DatabaseURL           string `envconfig:"DATABASE_URL"`
	DBHost                string `envconfig:"DB_HOST"`
	DBUser                string `envconfig:"DB_USER"`
	DBPassword            string `envconfig:"DB_PASSWORD"`
	DBName                string `envconfig:"DB_NAME"`
	DBPort                string `envconfig:"DB_PORT" default:"5432"`
	DBSecretARN           string `envconfig:"DB_SECRET_ARN"`
	JWTSecret             string `envconfig:"JWT_SECRET"`
	JWTSecretARN          string `envconfig:"JWT_SECRET_ARN"`
	RefreshTokenSecret    string `envconfig:"REFRESH_TOKEN_SECRET"`
	RefreshTokenSecretARN string `envconfig:"REFRESH_TOKEN_SECRET_ARN"`
	RedisURL              string `envconfig:"REDIS_URL"`
	Port                  string `envconfig:"PORT" default:"8080"`
	ClientOrigin          string `envconfig:"CLIENT_ORIGIN" default:"http://localhost:5173"` // Default client origin for CORS
	Region                string `envconfig:"AWS_REGION" default:"us-west-2"`                // Deprecated; will be removed

	// Azure specific settings
	AzureKeyVaultURL string `envconfig:"AZURE_KEY_VAULT_URL"` // e.g. https://ptchampion-kv.vault.azure.net/

	// Sentry Error Monitoring
	SentryDSN  string `envconfig:"SENTRY_DSN"`
	ServerName string `envconfig:"SERVER_NAME" default:"default-server"`

	// Feature Flag Configuration
	FlagsmithAPIKey          string `envconfig:"FLAGSMITH_API_KEY"`
	FlagsmithBaseURL         string `envconfig:"FLAGSMITH_BASE_URL" default:"https://api.flagsmith.com/api/v1"`
	FlagsmithCacheTTL        int    `envconfig:"FLAGSMITH_CACHE_TTL" default:"300"` // Default to 5 minutes
	FlagsmithEnvironmentName string `envconfig:"FLAGSMITH_ENVIRONMENT" default:"development"`

	// Application metadata / telemetry
	AppEnv       string `envconfig:"APP_ENV" default:"development"`
	AppVersion   string `envconfig:"APP_VERSION" default:"dev"`
	OTLPEndpoint string `envconfig:"OTLP_ENDPOINT"`
	OTLPInsecure bool   `envconfig:"OTLP_INSECURE" default:"false"`

	// Database operation timeout (default 3 seconds)
	DBTimeout time.Duration `envconfig:"DB_TIMEOUT" default:"3s"`

	// OAuth Configuration
	GoogleOAuth GoogleOAuthConfig
	AppleOAuth  AppleOAuthConfig

	// Add other config fields like SESSION_SECRET later
	// SessionSecret string `envconfig:"SESSION_SECRET" required:"true"`
}

// GoogleOAuthConfig holds Google OAuth credentials and settings
type GoogleOAuthConfig struct {
	WebClientID     string
	WebClientSecret string
	IOSClientID     string
	RedirectURL     string
}

// AppleOAuthConfig holds Apple Sign In credentials and settings
type AppleOAuthConfig struct {
	ServiceID      string
	AppBundleID    string
	TeamID         string
	KeyID          string
	PrivateKeyPath string
	RedirectURL    string
}

// Load loads configuration from environment variables, .env file, or Azure Key Vault
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

	// Check if we need to fetch secrets from Azure Key Vault
	err = fetchSecretsIfNeeded(&cfg)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch secrets: %w", err)
	}

	// Validate required configuration values
	if cfg.DatabaseURL == "" {
		return nil, fmt.Errorf("DATABASE_URL is required (directly or via Azure Key Vault)")
	}
	if cfg.JWTSecret == "" {
		return nil, fmt.Errorf("JWT_SECRET is required (directly or via Azure Key Vault)")
	}
	if cfg.RefreshTokenSecret == "" {
		log.Println("REFRESH_TOKEN_SECRET not set, using JWT_SECRET as fallback")
		cfg.RefreshTokenSecret = cfg.JWTSecret
	}

	// Log the port for debugging
	log.Printf("Server configured to run on port: %s", cfg.Port)
	log.Printf("Client origin set to: %s", cfg.ClientOrigin)

	// Load OAuth Configuration
	cfg.GoogleOAuth = GoogleOAuthConfig{
		WebClientID:     getEnv("GOOGLE_WEB_CLIENT_ID", ""),
		WebClientSecret: getEnv("GOOGLE_WEB_CLIENT_SECRET", ""),
		IOSClientID:     getEnv("GOOGLE_IOS_CLIENT_ID", ""),
		RedirectURL:     fmt.Sprintf("%s/auth/google", getEnv("API_BASE_URL", "http://localhost:8080")),
	}

	cfg.AppleOAuth = AppleOAuthConfig{
		ServiceID:      getEnv("APPLE_SERVICE_ID", ""),
		AppBundleID:    getEnv("APPLE_APP_BUNDLE_ID", ""),
		TeamID:         getEnv("APPLE_TEAM_ID", ""),
		KeyID:          getEnv("APPLE_KEY_ID", ""),
		PrivateKeyPath: getEnv("APPLE_PRIVATE_KEY_PATH", ""),
		RedirectURL:    fmt.Sprintf("%s/auth/apple", getEnv("API_BASE_URL", "http://localhost:8080")),
	}

	return &cfg, nil
}

// Validate performs strict validation of configuration values
// Returns a list of missing required configuration values
// This should be called early in application startup and will exit the program if any required value is missing
func (c *Config) Validate() {
	var missingSecrets []string

	// Check for required secrets and add to missing list if not present
	if c.DatabaseURL == "" {
		missingSecrets = append(missingSecrets, "DATABASE_URL")
	}

	if c.JWTSecret == "" {
		missingSecrets = append(missingSecrets, "JWT_SECRET")
	}

	if c.RedisURL == "" {
		missingSecrets = append(missingSecrets, "REDIS_URL")
	}

	// Add more required secrets as necessary

	// If any required secrets are missing, log fatal error and exit
	if len(missingSecrets) > 0 {
		log.Fatalf("Fatal error: Missing required configuration values: %v", missingSecrets)
	}
}

// fetchSecretsIfNeeded fetches secrets from Azure Key Vault if AZURE_KEY_VAULT_URL is set.
func fetchSecretsIfNeeded(cfg *Config) error {
	if cfg.AzureKeyVaultURL == "" {
		// Fall back to env vars – nothing to do
		log.Println("AZURE_KEY_VAULT_URL not set; using environment variables for secrets")
		return nil
	}

	log.Printf("Fetching secrets from Azure Key Vault: %s", cfg.AzureKeyVaultURL)

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Use default Azure credentials (Managed Identity, Azure CLI, etc.)
	cred, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		return fmt.Errorf("failed to obtain Azure credential: %w", err)
	}

	client, err := azsecrets.NewClient(cfg.AzureKeyVaultURL, cred, nil)
	if err != nil {
		return fmt.Errorf("failed to create Key Vault client: %w", err)
	}

	// Helper to resolve a secret & assign to pointer if env‑var placeholder is empty
	resolve := func(secretName string, target *string) error {
		if *target != "" {
			return nil // already provided via env
		}

		resp, err := client.GetSecret(ctx, secretName, "", nil)
		if err != nil {
			return fmt.Errorf("failed to get secret %s: %w", secretName, err)
		}
		if resp.Value == nil {
			return fmt.Errorf("secret %s has no value", secretName)
		}
		*target = *resp.Value
		return nil
	}

	// Try to fetch individual database parameters
	if cfg.DatabaseURL == "" {
		// Try to fetch individual parts
		if err := resolve("DB-HOST", &cfg.DBHost); err == nil {
			if err := resolve("DB-NAME", &cfg.DBName); err == nil {
				// Use fixed values for user and password as fallback
				// since we're having issues storing those in Key Vault
				if cfg.DBUser == "" {
					cfg.DBUser = "ptadmin"
				}
				if cfg.DBPassword == "" {
					cfg.DBPassword = "PTChampion123!"
				}

				// Construct the database URL from parts
				cfg.DatabaseURL = fmt.Sprintf("postgresql://%s:%s@%s:%s/%s?sslmode=require",
					cfg.DBUser, cfg.DBPassword, cfg.DBHost, cfg.DBPort, cfg.DBName)
				log.Printf("Constructed database URL from individual parameters")
			}
		}
	}

	// JWT Secret
	if err := resolve("JWT-SECRET", &cfg.JWTSecret); err != nil {
		return err
	}

	// Refresh Token Secret (optional)
	if err := resolve("REFRESH-TOKEN-SECRET", &cfg.RefreshTokenSecret); err != nil {
		// Not fatal – fallback to JWT_SECRET later
		log.Printf("Warning: REFRESH-TOKEN-SECRET not found: %v", err)
	}

	// Redis URL (optional)
	if err := resolve("REDIS-URL", &cfg.RedisURL); err != nil {
		// Not fatal for now
		log.Printf("Warning: REDIS-URL not found: %v", err)
	}

	return nil
}

// getEnv retrieves an environment variable with a fallback default value
func getEnv(key, fallback string) string {
	value, exists := os.LookupEnv(key)
	if !exists {
		return fallback
	}
	return value
}
