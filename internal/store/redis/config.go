package redis

import "fmt"

// Config holds Redis connection configuration
type Config struct {
	Host     string
	Port     int
	Password string
	DB       int
	PoolSize int
}

// DefaultConfig returns a Config with sensible defaults
func DefaultConfig() Config {
	return Config{
		Host:     "localhost",
		Port:     6379,
		Password: "",
		DB:       0,
		PoolSize: 10,
	}
}

// ToOptions converts a Config to an Options struct
func (c Config) ToOptions() Options {
	opts := DefaultOptions()
	opts.URL = fmt.Sprintf("redis://%s:%d/%d", c.Host, c.Port, c.DB)
	if c.Password != "" {
		opts.URL = fmt.Sprintf("redis://:%s@%s:%d/%d", c.Password, c.Host, c.Port, c.DB)
	}
	opts.PoolSize = c.PoolSize
	return opts
}
