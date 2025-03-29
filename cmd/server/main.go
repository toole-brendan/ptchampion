package main

import (
	"log"
	"net/http"

	"ptchampion/internal/api"
	"ptchampion/internal/api/handlers"
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

	// Create handler with dependencies
	handler := handlers.NewHandler(cfg, queries)

	// 3. Setup Router (Pass dependencies)
	router := api.NewRouter(handler, cfg)

	// 4. Start Server
	port := cfg.Port
	log.Printf("Starting server on :%s", port)
	serverAddr := ":" + port
	if err := http.ListenAndServe(serverAddr, router); err != nil {
		log.Fatalf("ListenAndServe on %s failed: %v", serverAddr, err)
	}
}
