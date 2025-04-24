package redis

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

// RefreshToken represents a refresh token stored in Redis
type RefreshToken struct {
	ID        string    `json:"id"`
	UserID    string    `json:"user_id"`
	IssuedAt  time.Time `json:"issued_at"`
	ExpiresAt time.Time `json:"expires_at"`
}

// RefreshStore defines the interface for refresh token operations
type RefreshStore interface {
	// Save stores a refresh token in Redis
	Save(ctx context.Context, token RefreshToken) error

	// Find retrieves a refresh token by ID
	Find(ctx context.Context, tokenID string) (*RefreshToken, error)

	// Revoke invalidates a refresh token
	Revoke(ctx context.Context, tokenID string) error

	// RevokeAllForUser revokes all refresh tokens for a user
	RevokeAllForUser(ctx context.Context, userID string) error
}

// RedisRefreshStore implements RefreshStore using Redis
type RedisRefreshStore struct {
	client *redis.Client
	prefix string
}

// NewRedisRefreshStore creates a new Redis-backed refresh token store
func NewRedisRefreshStore(client *redis.Client) *RedisRefreshStore {
	return &RedisRefreshStore{
		client: client,
		prefix: "refresh_token:",
	}
}

// tokenKey creates a Redis key for a token
func (s *RedisRefreshStore) tokenKey(tokenID string) string {
	return fmt.Sprintf("%s%s", s.prefix, tokenID)
}

// userTokensKey creates a Redis key for a user's token set
func (s *RedisRefreshStore) userTokensKey(userID string) string {
	return fmt.Sprintf("user_tokens:%s", userID)
}

// Save stores a refresh token in Redis
func (s *RedisRefreshStore) Save(ctx context.Context, token RefreshToken) error {
	// Marshal token to JSON
	data, err := json.Marshal(token)
	if err != nil {
		return fmt.Errorf("failed to marshal token: %w", err)
	}

	// Calculate TTL from expiry time
	ttl := time.Until(token.ExpiresAt)
	if ttl <= 0 {
		return fmt.Errorf("token already expired")
	}

	// Store token in Redis with expiration
	key := s.tokenKey(token.ID)
	if err := s.client.Set(ctx, key, data, ttl).Err(); err != nil {
		return fmt.Errorf("failed to store token: %w", err)
	}

	// Add token ID to user's set of tokens
	if err := s.client.SAdd(ctx, s.userTokensKey(token.UserID), token.ID).Err(); err != nil {
		return fmt.Errorf("failed to add token to user set: %w", err)
	}

	// Set expiry on the user's token set to match token expiry
	if err := s.client.ExpireAt(ctx, s.userTokensKey(token.UserID), token.ExpiresAt).Err(); err != nil {
		return fmt.Errorf("failed to set expiry on user token set: %w", err)
	}

	return nil
}

// Find retrieves a refresh token by ID
func (s *RedisRefreshStore) Find(ctx context.Context, tokenID string) (*RefreshToken, error) {
	key := s.tokenKey(tokenID)
	data, err := s.client.Get(ctx, key).Bytes()
	if err != nil {
		if err == redis.Nil {
			return nil, fmt.Errorf("token not found")
		}
		return nil, fmt.Errorf("failed to retrieve token: %w", err)
	}

	var token RefreshToken
	if err := json.Unmarshal(data, &token); err != nil {
		return nil, fmt.Errorf("failed to unmarshal token: %w", err)
	}

	return &token, nil
}

// Revoke invalidates a refresh token
func (s *RedisRefreshStore) Revoke(ctx context.Context, tokenID string) error {
	// First, get the token to extract user ID
	token, err := s.Find(ctx, tokenID)
	if err != nil {
		return err
	}

	// Delete the token
	key := s.tokenKey(tokenID)
	if err := s.client.Del(ctx, key).Err(); err != nil {
		return fmt.Errorf("failed to delete token: %w", err)
	}

	// Remove from user's set of tokens
	if err := s.client.SRem(ctx, s.userTokensKey(token.UserID), tokenID).Err(); err != nil {
		return fmt.Errorf("failed to remove token from user set: %w", err)
	}

	return nil
}

// RevokeAllForUser revokes all refresh tokens for a user
func (s *RedisRefreshStore) RevokeAllForUser(ctx context.Context, userID string) error {
	// Get all token IDs for the user
	userTokensKey := s.userTokensKey(userID)
	tokenIDs, err := s.client.SMembers(ctx, userTokensKey).Result()
	if err != nil {
		return fmt.Errorf("failed to get user tokens: %w", err)
	}

	if len(tokenIDs) == 0 {
		return nil
	}

	// Create a slice of token keys
	keys := make([]string, len(tokenIDs))
	for i, id := range tokenIDs {
		keys[i] = s.tokenKey(id)
	}

	// Delete all tokens in a pipeline
	pipe := s.client.Pipeline()
	pipe.Del(ctx, keys...)
	pipe.Del(ctx, userTokensKey)
	_, err = pipe.Exec(ctx)
	if err != nil {
		return fmt.Errorf("failed to revoke user tokens: %w", err)
	}

	return nil
}
