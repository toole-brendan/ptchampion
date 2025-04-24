package db

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	_ "github.com/lib/pq"
)

// NewDB creates a new database connection pool
func NewDB(databaseURL string) (*sql.DB, error) {
	// Connect to the database
	conn, err := sql.Open("postgres", databaseURL)
	if err != nil {
		return nil, fmt.Errorf("error opening database connection: %w", err)
	}

	// Set connection pool parameters
	conn.SetMaxOpenConns(25)
	conn.SetMaxIdleConns(25)
	conn.SetConnMaxLifetime(5 * time.Minute)

	// Verify connection works
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := conn.PingContext(ctx); err != nil {
		return nil, fmt.Errorf("error connecting to the database: %w", err)
	}

	return conn, nil
}

// Store provides access to all database operations
type Store struct {
	Queries    *Queries
	db         *sql.DB
	DefaultTTL time.Duration
}

// NewStore creates a new Store with default timeout
func NewStore(dbPool *sql.DB, defaultTTL time.Duration) *Store {
	if defaultTTL <= 0 {
		defaultTTL = 3 * time.Second // Default to 3 seconds if not specified
	}

	return &Store{
		Queries:    New(dbPool),
		db:         dbPool,
		DefaultTTL: defaultTTL,
	}
}

// WithContext returns a context with timeout based on the store's default TTL
func (s *Store) WithContext() (context.Context, context.CancelFunc) {
	return context.WithTimeout(context.Background(), s.DefaultTTL)
}

// ExecTx executes a function within a database transaction with context timeout
func (s *Store) ExecTx(ctx context.Context, fn func(*Queries) error) error {
	// Create a timeout ctx if one wasn't provided
	if ctx == nil {
		var cancel context.CancelFunc
		ctx, cancel = s.WithContext()
		defer cancel()
	}

	tx, err := s.db.BeginTx(ctx, nil)
	if err != nil {
		return fmt.Errorf("error beginning transaction: %w", err)
	}

	q := New(tx)
	err = fn(q)
	if err != nil {
		if rbErr := tx.Rollback(); rbErr != nil {
			return fmt.Errorf("tx err: %v, rb err: %v", err, rbErr)
		}
		return err
	}

	if err := tx.Commit(); err != nil {
		return fmt.Errorf("error committing transaction: %w", err)
	}

	return nil
}

// DB returns the underlying database interface to allow for custom queries
func (q *Queries) DB() DBTX {
	return q.db
}

// ExecuteWithTimeout runs a database function with the store's default timeout
func (s *Store) ExecuteWithTimeout(fn func(context.Context, *Queries) error) error {
	ctx, cancel := s.WithContext()
	defer cancel()

	return fn(ctx, s.Queries)
}
