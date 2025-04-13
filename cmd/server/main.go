package main

import (
	"log"
	"net/http"

	"ptchampion/internal/api"
	// "ptchampion/internal/api/handlers" // No longer needed directly here
	"ptchampion/internal/config"
	dbStore "ptchampion/internal/store/postgres"
)

func main() {
	// 1. Load Configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Error loading configuration: %v", err)
	}

	// 2. Connect to Database
	dbPool, err := dbStore.NewDB(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Error connecting to database: %v", err)
	}
	defer dbPool.Close() // Ensure connection is closed eventually
	log.Println("Successfully connected to the database.")

	// Dependency Injection: Create DB Querier
	queries := dbStore.New(dbPool)

	// Create the API Handler (which embeds the core handler)
	apiHandler := api.NewApiHandler(cfg, queries)

	// 3. Setup Router (Pass the API Handler)
	router := api.NewRouter(apiHandler, cfg)

	// 4. Start Server
	port := cfg.Port
	log.Printf("Starting server on :%s", port)
	serverAddr := ":" + port
	if err := http.ListenAndServe(serverAddr, router); err != nil {
		log.Fatalf("ListenAndServe on %s failed: %v", serverAddr, err)
	}
}
