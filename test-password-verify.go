package main

import (
	"fmt"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	password := "TestUser123!"
	storedHash := "$2a$14$T6noL1xxibNzQgDAZuygmOH6Oygem/SMiFtjaLvp0d1yX.6hi3pXK"
	
	fmt.Printf("Testing password verification:\n")
	fmt.Printf("Password: %s\n", password)
	fmt.Printf("Stored Hash: %s\n", storedHash)
	
	// Test verification
	err := bcrypt.CompareHashAndPassword([]byte(storedHash), []byte(password))
	if err == nil {
		fmt.Printf("✅ Password verification PASSED!\n")
	} else {
		fmt.Printf("❌ Password verification FAILED: %v\n", err)
	}
	
	// Generate a new hash for comparison
	newHash, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	if err != nil {
		fmt.Printf("Error generating new hash: %v\n", err)
		return
	}
	fmt.Printf("\nNew hash generated: %s\n", string(newHash))
	
	// Test with the new hash
	err = bcrypt.CompareHashAndPassword(newHash, []byte(password))
	if err == nil {
		fmt.Printf("✅ New hash verification PASSED!\n")
	} else {
		fmt.Printf("❌ New hash verification FAILED: %v\n", err)
	}
}