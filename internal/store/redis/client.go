package redis

import (
	"context"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

// Options contains configuration for the Redis client
type Options struct {
	URL               string
	PoolSize          int
	MinIdleConns      int
	MaxRetries        int
	ConnectTimeout    time.Duration
	ReadTimeout       time.Duration
	WriteTimeout      time.Duration
	PoolTimeout       time.Duration
	IdleTimeout       time.Duration
	IdleCheckFreq     time.Duration
	MaxConnAge        time.Duration
	HealthCheckPeriod time.Duration
}

// DefaultOptions returns sensible default options for Redis
func DefaultOptions() Options {
	return Options{
		PoolSize:          10,
		MinIdleConns:      2,
		MaxRetries:        3,
		ConnectTimeout:    5 * time.Second,
		ReadTimeout:       3 * time.Second,
		WriteTimeout:      3 * time.Second,
		PoolTimeout:       4 * time.Second,
		IdleTimeout:       5 * time.Minute,
		IdleCheckFreq:     1 * time.Minute,
		MaxConnAge:        30 * time.Minute,
		HealthCheckPeriod: 10 * time.Second,
	}
}

// CreateClient creates a new Redis client using the provided options
func CreateClient(opts Options) (*redis.Client, error) {
	if opts.URL == "" {
		return nil, fmt.Errorf("Redis URL is required")
	}

	options, err := redis.ParseURL(opts.URL)
	if err != nil {
		return nil, fmt.Errorf("failed to parse Redis URL: %w", err)
	}

	// Set additional options
	options.PoolSize = opts.PoolSize
	options.MinIdleConns = opts.MinIdleConns
	options.MaxRetries = opts.MaxRetries
	options.DialTimeout = opts.ConnectTimeout
	options.ReadTimeout = opts.ReadTimeout
	options.WriteTimeout = opts.WriteTimeout
	options.PoolTimeout = opts.PoolTimeout
	options.ConnMaxIdleTime = opts.IdleTimeout
	options.ConnMaxLifetime = opts.MaxConnAge
	options.MinIdleConns = opts.MinIdleConns

	client := redis.NewClient(options)

	// Test connection
	ctx, cancel := context.WithTimeout(context.Background(), opts.ConnectTimeout)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("failed to connect to Redis: %w", err)
	}

	return client, nil
}
