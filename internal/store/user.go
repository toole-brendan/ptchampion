package store

import (
	"time"

	"github.com/google/uuid"
)

// User represents a user in the system
type User struct {
	ID           string    `json:"id"`
	Email        string    `json:"email"`
	PasswordHash string    `json:"-"` // Never expose password hash
	FirstName    string    `json:"first_name"`
	LastName     string    `json:"last_name"`
	AvatarURL    *string   `json:"avatar_url,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// NewUser creates a new user with generated ID and timestamps
func NewUser(email, passwordHash, firstName, lastName string) *User {
	now := time.Now()
	return &User{
		ID:           uuid.New().String(),
		Email:        email,
		PasswordHash: passwordHash,
		FirstName:    firstName,
		LastName:     lastName,
		CreatedAt:    now,
		UpdatedAt:    now,
	}
}
