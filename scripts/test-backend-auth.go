package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
)

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type LoginResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresAt    string `json:"expires_at"`
	User         interface{} `json:"user"`
}

func main() {
	// Test credentials
	loginReq := LoginRequest{
		Email:    "mock@example.com",
		Password: "mockpassword",
	}

	// Convert to JSON
	jsonData, err := json.Marshal(loginReq)
	if err != nil {
		log.Fatal("Error marshaling request:", err)
	}

	fmt.Printf("Request JSON: %s\n", string(jsonData))

	// Create request
	req, err := http.NewRequest("POST", "https://ptchampion-api-westus.azurewebsites.net/api/v1/auth/login", bytes.NewBuffer(jsonData))
	if err != nil {
		log.Fatal("Error creating request:", err)
	}

	req.Header.Set("Content-Type", "application/json")

	// Send request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Fatal("Error sending request:", err)
	}
	defer resp.Body.Close()

	// Read response
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Fatal("Error reading response:", err)
	}

	fmt.Printf("\nResponse Status: %d\n", resp.StatusCode)
	fmt.Printf("Response Headers: %v\n", resp.Header)
	fmt.Printf("Response Body: %s\n", string(body))

	// If successful, parse the response
	if resp.StatusCode == 200 {
		var loginResp LoginResponse
		if err := json.Unmarshal(body, &loginResp); err != nil {
			log.Printf("Error parsing success response: %v", err)
		} else {
			fmt.Printf("\nLogin successful!\n")
			fmt.Printf("Access Token: %s...\n", loginResp.AccessToken[:20])
			fmt.Printf("User: %+v\n", loginResp.User)
		}
	}
}