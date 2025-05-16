package store

import (
	"context"
	"time"

	"github.com/google/uuid"
)

// User represents a user in the system
type User struct {
	ID        int    `json:"id"`
	Username  string `json:"username"`
	Email     string `json:"email"`
	Password  string `json:"-"` // Don't include password in JSON
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	// Added for social authentication
	Provider          string    `json:"provider"`
	ProviderId        string    `json:"provider_id"`
	ProfilePictureURL string    `json:"profile_picture_url"`
	EmailVerified     bool      `json:"email_verified"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

// UserStore defines the interface for user storage operations
type UserStore interface {
	CreateUser(ctx context.Context, user *User) (*User, error)
	GetUserByID(ctx context.Context, id int) (*User, error)
	GetUserByEmail(ctx context.Context, email string) (*User, error)
	GetUserByUsername(ctx context.Context, username string) (*User, error)
	GetUserByProviderID(ctx context.Context, provider string, providerID string) (*User, error)
	UpdateUser(ctx context.Context, user *User) (*User, error)
	DeleteUser(ctx context.Context, id int) error
	// Add other user-related methods as needed
}

// NewUser creates a new user with generated ID and timestamps
func NewUser(email, passwordHash, firstName, lastName, username string) *User {
	now := time.Now()
	return &User{
		ID:           uuid.New().String(),
		Email:        email,
		PasswordHash: passwordHash,
		FirstName:    firstName,
		LastName:     lastName,
		Username:     username,
		CreatedAt:    now,
		UpdatedAt:    now,
	}
}
