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
	// Test credentials
	testEmail := "testuser@ptchampion.ai"
	testPassword := "TestUser123!"
	
	// Database connection
	dbURL := fmt.Sprintf("postgresql://%s:%s@%s:%s/%s?sslmode=require",
		os.Getenv("DB_USER"),
		os.Getenv("DB_PASSWORD"),
		os.Getenv("DB_HOST"),
		os.Getenv("DB_PORT"),
		os.Getenv("DB_NAME"),
	)
	
	if os.Getenv("DB_USER") == "" {
		// Use hardcoded values for local testing
		dbURL = "postgresql://ptadmin:Dunlainge1@ptchampion-db.postgres.database.azure.com:5432/ptchampion?sslmode=require"
	}
	
	fmt.Printf("Connecting to database...\n")
	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}
	defer db.Close()
	
	// Test connection
	if err := db.Ping(); err != nil {
		log.Fatal("Failed to ping database:", err)
	}
	fmt.Printf("✅ Connected to database\n\n")
	
	// Query user
	var id int
	var email, username, passwordHash string
	var firstName, lastName sql.NullString
	
	query := `SELECT id, email, username, password_hash, first_name, last_name FROM users WHERE email = $1 LIMIT 1`
	err = db.QueryRow(query, testEmail).Scan(&id, &email, &username, &passwordHash, &firstName, &lastName)
	
	if err != nil {
		if err == sql.ErrNoRows {
			fmt.Printf("❌ User not found with email: %s\n", testEmail)
		} else {
			log.Fatal("Query error:", err)
		}
		return
	}
	
	fmt.Printf("✅ User found:\n")
	fmt.Printf("   ID: %d\n", id)
	fmt.Printf("   Email: %s\n", email)
	fmt.Printf("   Username: %s\n", username)
	fmt.Printf("   First Name: %s\n", firstName.String)
	fmt.Printf("   Last Name: %s\n", lastName.String)
	fmt.Printf("   Password Hash: %s...\n\n", passwordHash[:20])
	
	// Test password verification
	fmt.Printf("Testing password verification:\n")
	fmt.Printf("   Input Password: %s\n", testPassword)
	
	err = bcrypt.CompareHashAndPassword([]byte(passwordHash), []byte(testPassword))
	if err == nil {
		fmt.Printf("✅ Password verification PASSED!\n")
	} else {
		fmt.Printf("❌ Password verification FAILED: %v\n", err)
		
		// Try generating a new hash for comparison
		newHash, _ := bcrypt.GenerateFromPassword([]byte(testPassword), 14)
		fmt.Printf("\n   New hash would be: %s\n", string(newHash))
	}
	
	// Also check if there might be whitespace issues
	fmt.Printf("\n🔍 Checking for whitespace issues:\n")
	fmt.Printf("   Email length: %d\n", len(email))
	fmt.Printf("   Expected length: %d\n", len(testEmail))
	fmt.Printf("   Hash length: %d\n", len(passwordHash))
}