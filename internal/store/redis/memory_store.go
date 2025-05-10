package redis

import (
	"context"
	"errors"
	"sync"
	"time"
)

// MemoryRefreshStore implements RefreshStore using an in-memory map
// This is for development only - DO NOT use in production
type MemoryRefreshStore struct {
	tokens     map[string]RefreshToken
	userTokens map[string]map[string]struct{} // Map of userID -> set of tokenIDs
	mutex      sync.RWMutex
}

// NewMemoryRefreshStore creates a new memory-based refresh token store for development
func NewMemoryRefreshStore() *MemoryRefreshStore {
	return &MemoryRefreshStore{
		tokens:     make(map[string]RefreshToken),
		userTokens: make(map[string]map[string]struct{}),
	}
}

// Save stores a refresh token in memory
func (s *MemoryRefreshStore) Save(ctx context.Context, token RefreshToken) error {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	// Calculate TTL from expiry time
	ttl := time.Until(token.ExpiresAt)
	if ttl <= 0 {
		return errors.New("token already expired")
	}

	// Store token
	s.tokens[token.ID] = token

	// Add to user's tokens
	if _, exists := s.userTokens[token.UserID]; !exists {
		s.userTokens[token.UserID] = make(map[string]struct{})
	}
	s.userTokens[token.UserID][token.ID] = struct{}{}

	// Set up a goroutine to clean up expired tokens
	go func(tokenID string, expiresAt time.Time) {
		time.Sleep(time.Until(expiresAt))
		s.mutex.Lock()
		defer s.mutex.Unlock()
		delete(s.tokens, tokenID)
	}(token.ID, token.ExpiresAt)

	return nil
}

// Find retrieves a refresh token by ID
func (s *MemoryRefreshStore) Find(ctx context.Context, tokenID string) (*RefreshToken, error) {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	token, exists := s.tokens[tokenID]
	if !exists {
		return nil, errors.New("token not found")
	}

	if time.Now().After(token.ExpiresAt) {
		return nil, errors.New("token has expired")
	}

	return &token, nil
}

// Revoke invalidates a refresh token
func (s *MemoryRefreshStore) Revoke(ctx context.Context, tokenID string) error {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	token, exists := s.tokens[tokenID]
	if !exists {
		return errors.New("token not found")
	}

	// Remove from tokens map
	delete(s.tokens, tokenID)

	// Remove from user tokens map
	if userTokens, exists := s.userTokens[token.UserID]; exists {
		delete(userTokens, tokenID)
	}

	return nil
}

// RevokeAllForUser revokes all refresh tokens for a user
func (s *MemoryRefreshStore) RevokeAllForUser(ctx context.Context, userID string) error {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	userTokens, exists := s.userTokens[userID]
	if !exists || len(userTokens) == 0 {
		return nil
	}

	// Delete all tokens for this user
	for tokenID := range userTokens {
		delete(s.tokens, tokenID)
	}

	// Clear user's token set
	delete(s.userTokens, userID)

	return nil
}
