package store

import (
	"time"
)

// User represents a user in the system
type User struct {
	ID           string `json:"id"`
	Username     string `json:"username"`
	Email        string `json:"email"`
	PasswordHash string `json:"-"` // Don't include password in JSON
	FirstName    string `json:"first_name"`
	LastName     string `json:"last_name"`
	// Added for social authentication
	Provider          string `json:"provider"`
	ProviderId        string `json:"provider_id"`
	ProfilePictureURL string `json:"profile_picture_url"`
	EmailVerified     bool   `json:"email_verified"`
	// Added for USMC PFT scoring
	Gender      string    `json:"gender"`        // 'male' or 'female'
	DateOfBirth time.Time `json:"date_of_birth"` // For age calculation
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// UserStore interface is defined in store.go

// NewUser creates a new user with generated ID and timestamps
func NewUser(email, passwordHash, firstName, lastName, username string) *User {
	now := time.Now()
	return &User{
		ID:           generateID(),
		Email:        email,
		PasswordHash: passwordHash,
		FirstName:    firstName,
		LastName:     lastName,
		Username:     username,
		CreatedAt:    now,
		UpdatedAt:    now,
	}
}

// generateID generates a unique ID for a user
// This is a placeholder - in a real implementation, you would use UUID or another ID generation method
func generateID() string {
	return "u_" + time.Now().Format("20060102150405")
}
