package db

import (
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
	if err := conn.Ping(); err != nil {
		return nil, fmt.Errorf("error connecting to the database: %w", err)
	}

	return conn, nil
}

// Store provides access to all database operations
type Store struct {
	Queries *Queries
	db      *sql.DB
}

// NewStore creates a new Store
func NewStore(dbPool *sql.DB) *Store {
	return &Store{
		Queries: New(dbPool),
		db:      dbPool,
	}
}

// ExecTx executes a function within a database transaction
func (s *Store) ExecTx(fn func(*Queries) error) error {
	tx, err := s.db.Begin()
	if err != nil {
		return err
	}

	q := New(tx)
	err = fn(q)
	if err != nil {
		if rbErr := tx.Rollback(); rbErr != nil {
			return fmt.Errorf("tx err: %v, rb err: %v", err, rbErr)
		}
		return err
	}

	return tx.Commit()
}
