package main

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	_ "github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	// Fresh test user credentials
	email := "clicktest@ptchampion.ai"
	password := "clicktest123"
	username := "clicktest"
	firstName := "Click"
	lastName := "Test"

	// Generate bcrypt hash with cost 14 (same as backend)
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	if err != nil {
		log.Fatal("Failed to hash password:", err)
	}

	fmt.Printf("Creating fresh test user:\n")
	fmt.Printf("Email: %s\n", email)
	fmt.Printf("Password: %s\n", password)
	fmt.Printf("Hash: %s\n", string(hashedPassword))

	// Connect to database
	connStr := fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=require",
		"ptadmin",
		"Dunlainge1",
		"ptchampion-db.postgres.database.azure.com",
		"5432",
		"ptchampion")

	db, err := sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal("Failed to connect:", err)
	}
	defer db.Close()

	// Delete if exists
	_, err = db.Exec("DELETE FROM users WHERE email = $1", email)
	if err != nil {
		log.Printf("Warning deleting user: %v", err)
	}

	// Insert new user
	var userID int
	err = db.QueryRow(`
		INSERT INTO users (username, email, password_hash, first_name, last_name, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id
	`, username, email, string(hashedPassword), firstName, lastName, time.Now(), time.Now()).Scan(&userID)

	if err != nil {
		log.Fatal("Failed to insert user:", err)
	}

	fmt.Printf("\n✅ User created with ID: %d\n", userID)
	fmt.Printf("\nTest with:\n")
	fmt.Printf("curl -X POST https://ptchampion-api-westus.azurewebsites.net/api/v1/auth/login \\\n")
	fmt.Printf("  -H \"Content-Type: application/json\" \\\n")
	fmt.Printf("  -d '{\"email\":\"%s\",\"password\":\"%s\"}'\n", email, password)
}