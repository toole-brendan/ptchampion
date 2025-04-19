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
	DBSecretARN           string `envconfig:"DB_SECRET_ARN"`
	JWTSecret             string `envconfig:"JWT_SECRET"`
	JWTSecretARN          string `envconfig:"JWT_SECRET_ARN"`
	RefreshTokenSecret    string `envconfig:"REFRESH_TOKEN_SECRET"`
	RefreshTokenSecretARN string `envconfig:"REFRESH_TOKEN_SECRET_ARN"`
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

	// Add other config fields like SESSION_SECRET later
	// SessionSecret string `envconfig:"SESSION_SECRET" required:"true"`
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

	return &cfg, nil
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

	// Secret names are hard‑coded; adjust as needed
	if err := resolve("DATABASE_URL", &cfg.DatabaseURL); err != nil {
		return err
	}
	if err := resolve("JWT_SECRET", &cfg.JWTSecret); err != nil {
		return err
	}
	if err := resolve("REFRESH_TOKEN_SECRET", &cfg.RefreshTokenSecret); err != nil {
		// Not fatal – fallback to JWT_SECRET later
		log.Printf("Warning: REFRESH_TOKEN_SECRET not found: %v", err)
	}

	return nil
}
