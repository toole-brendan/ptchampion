package main

import (
	"fmt"
	"log"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	password := "mockpassword"
	hash := "$2a$14$h1dGU.cq/y.08bzYcRFqX.sEglgaXojiXNyXJj3SZg3MXNXXArUiy"
	
	// Verify the password matches the hash
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	if err != nil {
		log.Fatal("Password does not match hash:", err)
	}
	
	fmt.Println("✓ Password verification successful!")
	fmt.Println("Password:", password)
	fmt.Println("Hash:", hash)
	fmt.Println("The password 'mockpassword' correctly matches the stored hash.")
}