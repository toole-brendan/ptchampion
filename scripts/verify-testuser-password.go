package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

func main() {
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

	// Test users
	testCases := []struct {
		email    string
		password string
	}{
		{"testuser@ptchampion.ai", "TestUser123!"},
		{"mock@example.com", "mockpassword"},
		{"clicktest@ptchampion.ai", "clicktest123"},
	}

	for _, tc := range testCases {
		var hash string
		var username string
		
		err := db.QueryRow("SELECT username, password_hash FROM users WHERE email = $1", tc.email).Scan(&username, &hash)
		if err != nil {
			fmt.Printf("❌ %s: User not found\n", tc.email)
			continue
		}

		err = bcrypt.CompareHashAndPassword([]byte(hash), []byte(tc.password))
		if err != nil {
			fmt.Printf("❌ %s: Password does NOT match (error: %v)\n", tc.email, err)
			fmt.Printf("   Hash: %s\n", hash[:30]+"...")
		} else {
			fmt.Printf("✅ %s: Password matches! (username: %s)\n", tc.email, username)
		}
	}
}