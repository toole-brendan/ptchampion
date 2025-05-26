package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"

	_ "github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	// Test user credentials for App Store review
	email := "testuser@ptchampion.ai"
	password := "TestUser123!"
	username := "testuser"
	firstName := "Test"
	lastName := "User"

	// Generate bcrypt hash
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	if err != nil {
		log.Fatal("Failed to hash password:", err)
	}

	fmt.Printf("=== Test User for App Store Review ===\n")
	fmt.Printf("Email: %s\n", email)
	fmt.Printf("Password: %s\n", password)
	fmt.Printf("Username: %s\n", username)
	fmt.Printf("Bcrypt Hash: %s\n", string(hashedPassword))
	fmt.Printf("=====================================\n\n")

	// Check if we should insert into database
	if len(os.Args) > 1 && os.Args[1] == "--insert" {
		databaseURL := os.Getenv("DATABASE_URL")
		if databaseURL == "" {
			log.Fatal("DATABASE_URL environment variable is required when using --insert")
		}

		db, err := sql.Open("postgres", databaseURL)
		if err != nil {
			log.Fatal("Failed to connect to database:", err)
		}
		defer db.Close()

		// Test connection
		if err := db.Ping(); err != nil {
			log.Fatal("Failed to ping database:", err)
		}

		// Check if user already exists
		var exists bool
		err = db.QueryRow("SELECT EXISTS(SELECT 1 FROM users WHERE email = $1)", email).Scan(&exists)
		if err != nil {
			log.Fatal("Failed to check if user exists:", err)
		}

		if exists {
			fmt.Printf("Test user already exists in database\n")
			return
		}

		// Insert the test user
		var userID int32
		err = db.QueryRow(`
			INSERT INTO users (username, email, password_hash, first_name, last_name, created_at, updated_at)
			VALUES ($1, $2, $3, $4, $5, NOW(), NOW())
			RETURNING id
		`, username, email, string(hashedPassword), firstName, lastName).Scan(&userID)

		if err != nil {
			log.Fatal("Failed to insert test user:", err)
		}

		fmt.Printf("✅ Test user created successfully with ID: %d\n", userID)
		fmt.Printf("You can now use these credentials for App Store review:\n")
		fmt.Printf("Email: %s\n", email)
		fmt.Printf("Password: %s\n", password)
	} else {
		fmt.Printf("To insert this user into the database, run:\n")
		fmt.Printf("DATABASE_URL=\"your_database_url\" go run cmd/create-test-user/main.go --insert\n")
	}
}
