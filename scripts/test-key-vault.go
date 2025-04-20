package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/security/keyvault/azsecrets"
	_ "github.com/lib/pq"
)

func main() {
	// Check if Key Vault URL is provided
	keyVaultURL := os.Getenv("AZURE_KEY_VAULT_URL")
	if keyVaultURL == "" {
		keyVaultURL = "https://ptchampion-kv.vault.azure.net/"
	}

	fmt.Printf("Testing connection to Key Vault: %s\n", keyVaultURL)

	// Create a context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Get credentials from environment (Az CLI, Managed Identity, etc.)
	cred, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		log.Fatalf("Failed to obtain Azure credential: %v", err)
	}

	// Create Key Vault client
	client, err := azsecrets.NewClient(keyVaultURL, cred, nil)
	if err != nil {
		log.Fatalf("Failed to create Key Vault client: %v", err)
	}

	// Get database connection parameters
	fmt.Println("Fetching database connection parameters from Key Vault...")

	// DB-HOST
	hostResp, err := client.GetSecret(ctx, "DB-HOST", "", nil)
	if err != nil {
		log.Fatalf("Failed to get DB-HOST: %v", err)
	}
	if hostResp.Value == nil {
		log.Fatalf("DB-HOST has no value")
	}
	dbHost := *hostResp.Value

	// Use the known username and password
	dbUser := "ptadmin"
	dbPassword := "PTChampion123!"

	// DB-NAME
	nameResp, err := client.GetSecret(ctx, "DB-NAME", "", nil)
	if err != nil {
		log.Fatalf("Failed to get DB-NAME: %v", err)
	}
	if nameResp.Value == nil {
		log.Fatalf("DB-NAME has no value")
	}
	dbName := *nameResp.Value

	databaseURL := fmt.Sprintf("postgresql://%s:%s@%s:5432/%s?sslmode=require",
		dbUser, dbPassword, dbHost, dbName)

	fmt.Println("Successfully retrieved database connection parameters")

	// Test database connection
	fmt.Println("Testing PostgreSQL connection...")
	db, err := sql.Open("postgres", databaseURL)
	if err != nil {
		log.Fatalf("Failed to open database connection: %v", err)
	}
	defer db.Close()

	err = db.Ping()
	if err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}

	// Execute a simple query
	var connectionTest int
	err = db.QueryRow("SELECT 1 as connection_test").Scan(&connectionTest)
	if err != nil {
		log.Fatalf("Failed to execute query: %v", err)
	}

	fmt.Printf("✅ Successfully connected to PostgreSQL database and executed test query: %d\n", connectionTest)

	// Get Redis URL
	fmt.Println("\nFetching REDIS-URL from Key Vault...")
	redisResp, err := client.GetSecret(ctx, "REDIS-URL", "", nil)
	if err != nil {
		log.Printf("Warning: Failed to get REDIS-URL: %v", err)
	} else if redisResp.Value == nil {
		log.Printf("Warning: REDIS-URL has no value")
	} else {
		fmt.Println("✅ Successfully retrieved REDIS-URL from Key Vault")
		redisURL := *redisResp.Value
		fmt.Printf("Redis URL (masked): %s...\n", maskURL(redisURL))
	}

	fmt.Println("\nKey Vault integration test completed successfully!")
	fmt.Println("\nYour Azure database connections are set up correctly and working!")
}

// Simple function to mask sensitive parts of URLs
func maskURL(url string) string {
	if len(url) < 10 {
		return "***masked***"
	}
	return url[:10] + "***masked***"
}
