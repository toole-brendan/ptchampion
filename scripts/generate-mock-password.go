package main

import (
	"fmt"
	"log"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	password := "mockpassword"
	
	// Generate bcrypt hash with cost factor 14
	hash, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	if err != nil {
		log.Fatal("Error generating hash:", err)
	}
	
	fmt.Println("Password:", password)
	fmt.Println("Bcrypt Hash:", string(hash))
	fmt.Println("\nSQL Statement:")
	fmt.Printf(`
INSERT INTO users (
    username,
    email,
    first_name,
    last_name,
    password_hash,
    display_name,
    email_verified,
    created_at,
    updated_at
) VALUES (
    'mockuser',
    'mock@example.com',
    'Mock',
    'User',
    '%s',
    'Mock User',
    true,
    NOW(),
    NOW()
);
`, string(hash))
}