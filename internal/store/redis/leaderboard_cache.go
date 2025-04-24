package redis

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

const (
	// DefaultTTL is the default time-to-live for cached leaderboard data
	DefaultTTL = 5 * time.Minute
)

// LeaderboardCache implements a Redis-backed cache for leaderboard data
type LeaderboardCache struct {
	client *redis.Client
	ttl    time.Duration
}

// NewLeaderboardCache creates a new LeaderboardCache with the given Redis client
func NewLeaderboardCache(client *redis.Client) *LeaderboardCache {
	return &LeaderboardCache{
		client: client,
		ttl:    DefaultTTL,
	}
}

// WithTTL sets a custom TTL for the cache entries
func (c *LeaderboardCache) WithTTL(ttl time.Duration) *LeaderboardCache {
	c.ttl = ttl
	return c
}

// LocalLeaderboardKey generates a cache key for a local leaderboard
// lat and lon are the coordinates for the center point
// radius is the search radius in meters
// exerciseType filters by type of exercise
func LocalLeaderboardKey(lat, lon float64, radius float64, exerciseType string, limit int) string {
	return fmt.Sprintf("leaderboard:local:%f:%f:%f:%s:%d", lat, lon, radius, exerciseType, limit)
}

// GlobalLeaderboardKey generates a cache key for a global leaderboard
func GlobalLeaderboardKey(exerciseType string, limit int) string {
	return fmt.Sprintf("leaderboard:global:%s:%d", exerciseType, limit)
}

// Get retrieves data from the cache by key
func (c *LeaderboardCache) Get(ctx context.Context, key string, dest interface{}) error {
	data, err := c.client.Get(ctx, key).Bytes()
	if err != nil {
		if err == redis.Nil {
			return fmt.Errorf("cache miss for key %s", key)
		}
		return fmt.Errorf("error retrieving from cache: %w", err)
	}

	if err := json.Unmarshal(data, dest); err != nil {
		return fmt.Errorf("error unmarshaling cached data: %w", err)
	}

	return nil
}

// Set stores data in the cache with the default TTL
func (c *LeaderboardCache) Set(ctx context.Context, key string, value interface{}) error {
	data, err := json.Marshal(value)
	if err != nil {
		return fmt.Errorf("error marshaling data for cache: %w", err)
	}

	if err := c.client.Set(ctx, key, data, c.ttl).Err(); err != nil {
		return fmt.Errorf("error storing in cache: %w", err)
	}

	return nil
}

// Delete removes an item from the cache
func (c *LeaderboardCache) Delete(ctx context.Context, key string) error {
	if err := c.client.Del(ctx, key).Err(); err != nil {
		return fmt.Errorf("error deleting from cache: %w", err)
	}
	return nil
}

// FlushLeaderboards removes all leaderboard entries from the cache
func (c *LeaderboardCache) FlushLeaderboards(ctx context.Context) error {
	keys, err := c.client.Keys(ctx, "leaderboard:*").Result()
	if err != nil {
		return fmt.Errorf("error getting leaderboard keys: %w", err)
	}

	if len(keys) > 0 {
		if err := c.client.Del(ctx, keys...).Err(); err != nil {
			return fmt.Errorf("error flushing leaderboard cache: %w", err)
		}
	}

	return nil
}
