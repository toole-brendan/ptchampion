package config

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
	"github.com/joho/godotenv"
	"github.com/kelseyhightower/envconfig"
)

// Config holds application configuration settings
type Config struct {
	DatabaseURL  string `envconfig:"DATABASE_URL"`
	DBSecretARN  string `envconfig:"DB_SECRET_ARN"`
	JWTSecret    string `envconfig:"JWT_SECRET"`
	JWTSecretARN string `envconfig:"JWT_SECRET_ARN"`
	Port         string `envconfig:"PORT" default:"8080"`
	ClientOrigin string `envconfig:"CLIENT_ORIGIN" default:"http://localhost:5173"` // Default client origin for CORS
	Region       string `envconfig:"AWS_REGION" default:"us-west-2"`                // Default AWS region

	// Feature Flag Configuration
	FlagsmithAPIKey          string `envconfig:"FLAGSMITH_API_KEY"`
	FlagsmithBaseURL         string `envconfig:"FLAGSMITH_BASE_URL" default:"https://api.flagsmith.com/api/v1"`
	FlagsmithCacheTTL        int    `envconfig:"FLAGSMITH_CACHE_TTL" default:"300"` // Default to 5 minutes
	FlagsmithEnvironmentName string `envconfig:"FLAGSMITH_ENVIRONMENT" default:"development"`

	// Add other config fields like SESSION_SECRET later
	// SessionSecret string `envconfig:"SESSION_SECRET" required:"true"`
}

// Load loads configuration from environment variables, .env file, or AWS Secrets Manager
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

	// Check if we need to fetch secrets from AWS Secrets Manager
	err = fetchSecretsIfNeeded(&cfg)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch secrets: %w", err)
	}

	// Validate required configuration values
	if cfg.DatabaseURL == "" {
		return nil, fmt.Errorf("DATABASE_URL is required (directly or via AWS Secrets Manager)")
	}
	if cfg.JWTSecret == "" {
		return nil, fmt.Errorf("JWT_SECRET is required (directly or via AWS Secrets Manager)")
	}

	// Log the port for debugging
	log.Printf("Server configured to run on port: %s", cfg.Port)
	log.Printf("Client origin set to: %s", cfg.ClientOrigin)

	return &cfg, nil
}

// fetchSecretsIfNeeded checks if AWS Secret ARNs are provided and fetches the secrets
func fetchSecretsIfNeeded(cfg *Config) error {
	// Skip if no ARNs are provided
	if cfg.DBSecretARN == "" && cfg.JWTSecretARN == "" {
		log.Println("No AWS Secret ARNs provided, using environment variables")
		return nil
	}

	log.Println("AWS Secret ARNs detected, fetching secrets from AWS Secrets Manager")

	// Configure AWS SDK
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	awsCfg, err := config.LoadDefaultConfig(ctx, config.WithRegion(cfg.Region))
	if err != nil {
		return fmt.Errorf("failed to load AWS config: %w", err)
	}

	// Create Secrets Manager client
	svc := secretsmanager.NewFromConfig(awsCfg)

	// Fetch database URL if ARN is provided
	if cfg.DBSecretARN != "" && cfg.DatabaseURL == "" {
		log.Printf("Fetching database URL from Secret ARN: %s", cfg.DBSecretARN)
		secret, err := getSecret(ctx, svc, cfg.DBSecretARN)
		if err != nil {
			return err
		}

		// Check if the secret is a JSON object with a DATABASE_URL field
		var secretObj map[string]string
		if err := json.Unmarshal([]byte(secret), &secretObj); err == nil {
			if dbURL, ok := secretObj["DATABASE_URL"]; ok {
				cfg.DatabaseURL = dbURL
			} else {
				// If not a JSON object or no DATABASE_URL field, use the secret value directly
				cfg.DatabaseURL = secret
			}
		} else {
			// If not a JSON object, use the secret value directly
			cfg.DatabaseURL = secret
		}
	}

	// Fetch JWT secret if ARN is provided
	if cfg.JWTSecretARN != "" && cfg.JWTSecret == "" {
		log.Printf("Fetching JWT secret from Secret ARN: %s", cfg.JWTSecretARN)
		secret, err := getSecret(ctx, svc, cfg.JWTSecretARN)
		if err != nil {
			return err
		}

		// Check if the secret is a JSON object with a JWT_SECRET field
		var secretObj map[string]string
		if err := json.Unmarshal([]byte(secret), &secretObj); err == nil {
			if jwtSecret, ok := secretObj["JWT_SECRET"]; ok {
				cfg.JWTSecret = jwtSecret
			} else {
				// If not a JSON object or no JWT_SECRET field, use the secret value directly
				cfg.JWTSecret = secret
			}
		} else {
			// If not a JSON object, use the secret value directly
			cfg.JWTSecret = secret
		}
	}

	return nil
}

// getSecret fetches a secret from AWS Secrets Manager
func getSecret(ctx context.Context, svc *secretsmanager.Client, secretARN string) (string, error) {
	input := &secretsmanager.GetSecretValueInput{
		SecretId: aws.String(secretARN),
	}

	result, err := svc.GetSecretValue(ctx, input)
	if err != nil {
		return "", fmt.Errorf("failed to get secret value: %w", err)
	}

	// Return the secret value or secret string
	if result.SecretString != nil {
		return *result.SecretString, nil
	}

	return "", fmt.Errorf("no secret value found")
}
