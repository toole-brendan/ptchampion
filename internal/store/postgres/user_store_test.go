//go:build integration
// +build integration

// Package db_test contains integration tests for the postgres implementation
package db_test

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"os"
	"testing"
	"time"

	"github.com/ory/dockertest/v3"
	"github.com/ory/dockertest/v3/docker"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	sqlcdb "ptchampion/internal/store/postgres"
)

var (
	testDB  *sql.DB
	queries *sqlcdb.Queries
)

func TestMain(m *testing.M) {
	// Uses a sensible default on windows (tcp/http) and linux/osx (socket)
	pool, err := dockertest.NewPool("")
	if err != nil {
		log.Fatalf("Could not connect to docker: %s", err)
	}

	// Pull postgres image
	resource, err := pool.RunWithOptions(&dockertest.RunOptions{
		Repository: "postgres",
		Tag:        "14",
		Env: []string{
			"POSTGRES_PASSWORD=postgres",
			"POSTGRES_USER=postgres",
			"POSTGRES_DB=ptchampion_test",
		},
	}, func(config *docker.HostConfig) {
		// Set AutoRemove to true so that stopped container goes away by itself
		config.AutoRemove = true
		config.RestartPolicy = docker.RestartPolicy{
			Name: "no",
		}
	})
	if err != nil {
		log.Fatalf("Could not start resource: %s", err)
	}

	// Exponential backoff-retry for the database to be ready
	if err := pool.Retry(func() error {
		var err error
		testDB, err = sql.Open("postgres", fmt.Sprintf("postgres://postgres:postgres@localhost:%s/ptchampion_test?sslmode=disable", resource.GetPort("5432/tcp")))
		if err != nil {
			return err
		}
		return testDB.Ping()
	}); err != nil {
		log.Fatalf("Could not connect to docker: %s", err)
	}

	// Setup schema
	if err := setupTestDB(testDB); err != nil {
		log.Fatalf("Could not set up test database: %s", err)
	}

	// Initialize sqlc queries
	queries = sqlcdb.New(testDB)

	// Run tests
	code := m.Run()

	// Clean up
	if err := pool.Purge(resource); err != nil {
		log.Fatalf("Could not purge resource: %s", err)
	}

	os.Exit(code)
}

func setupTestDB(db *sql.DB) error {
	// Create users table
	_, err := db.Exec(`
		CREATE TABLE IF NOT EXISTS users (
			id SERIAL PRIMARY KEY,
			username VARCHAR(50) UNIQUE NOT NULL,
			password_hash VARCHAR(100) NOT NULL,
			email VARCHAR(255) NOT NULL,
			first_name VARCHAR(255),
			last_name VARCHAR(255),
			profile_picture_url VARCHAR(255),
			location VARCHAR(100),
			latitude VARCHAR(50),
			longitude VARCHAR(50),
			last_location VARCHAR(255),
			last_synced_at TIMESTAMP WITH TIME ZONE,
			created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
			updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
		);
	`)
	return err
}

func cleanupTestDB(t *testing.T) {
	_, err := testDB.Exec("TRUNCATE TABLE users RESTART IDENTITY CASCADE;")
	require.NoError(t, err)
}

func TestCreateUser(t *testing.T) {
	defer cleanupTestDB(t)

	ctx := context.Background()
	params := sqlcdb.CreateUserParams{
		Username:     "testuser",
		Email:        "test@example.com",
		PasswordHash: "hashedpassword",
		FirstName:    sql.NullString{String: "Test", Valid: true},
		LastName:     sql.NullString{String: "User", Valid: true},
	}

	createdUser, err := queries.CreateUser(ctx, params)

	// Assertions
	assert.NoError(t, err)
	assert.NotNil(t, createdUser)
	assert.Equal(t, int64(1), createdUser.ID)
	assert.Equal(t, "testuser", createdUser.Username)
	assert.Equal(t, "Test", createdUser.FirstName.String)
	assert.Equal(t, "User", createdUser.LastName.String)
	if createdUser.CreatedAt.Valid {
		assert.WithinDuration(t, time.Now(), createdUser.CreatedAt.Time, 2*time.Second)
	} else {
		t.Errorf("createdUser.CreatedAt should be valid time")
	}
}

func TestGetUserByUsername(t *testing.T) {
	defer cleanupTestDB(t)

	ctx := context.Background()
	params := sqlcdb.CreateUserParams{
		Username:     "findme",
		Email:        "find@example.com",
		PasswordHash: "hashedpassword",
		FirstName:    sql.NullString{String: "Find", Valid: true},
		LastName:     sql.NullString{String: "Me", Valid: true},
	}
	_, err := queries.CreateUser(ctx, params)
	require.NoError(t, err)

	user, err := queries.GetUserByUsername(ctx, "findme")

	// Assertions
	assert.NoError(t, err)
	assert.NotNil(t, user)
	assert.Equal(t, "findme", user.Username)
	assert.Equal(t, "Find", user.FirstName.String)
	assert.Equal(t, "Me", user.LastName.String)
}

func TestGetUserByID(t *testing.T) {
	defer cleanupTestDB(t)

	ctx := context.Background()
	insertParams := sqlcdb.CreateUserParams{
		Username:     "testuser",
		Email:        "test@example.com",
		PasswordHash: "hashedpassword",
		FirstName:    sql.NullString{String: "Test", Valid: true},
		LastName:     sql.NullString{String: "User", Valid: true},
	}
	createdUser, err := queries.CreateUser(ctx, insertParams)
	require.NoError(t, err)

	user, err := queries.GetUser(ctx, createdUser.ID)

	// Assertions
	assert.NoError(t, err)
	assert.NotNil(t, user)
	assert.Equal(t, createdUser.ID, user.ID)
	assert.Equal(t, "testuser", user.Username)
}

func TestUpdateUser(t *testing.T) {
	defer cleanupTestDB(t)

	ctx := context.Background()
	insertParams := sqlcdb.CreateUserParams{
		Username:     "updateme",
		Email:        "update@example.com",
		PasswordHash: "hashedpassword",
		FirstName:    sql.NullString{String: "Update", Valid: true},
		LastName:     sql.NullString{String: "Me", Valid: true},
	}
	createdUser, err := queries.CreateUser(ctx, insertParams)
	require.NoError(t, err)

	updateParams := sqlcdb.UpdateUserParams{
		ID:        createdUser.ID,
		Username:  createdUser.Username,
		Email:     createdUser.Email,
		FirstName: sql.NullString{String: "Updated", Valid: true},
		LastName:  sql.NullString{String: "Name", Valid: true},
		Location:  sql.NullString{Valid: false},
		Latitude:  sql.NullString{Valid: false},
		Longitude: sql.NullString{Valid: false},
	}

	updatedUser, err := queries.UpdateUser(ctx, updateParams)

	// Assertions
	assert.NoError(t, err)
	assert.NotNil(t, updatedUser)
	assert.Equal(t, createdUser.ID, updatedUser.ID)
	assert.Equal(t, "updateme", updatedUser.Username) // Username shouldn't change
	assert.Equal(t, "Updated", updatedUser.FirstName.String)
	assert.Equal(t, "Name", updatedUser.LastName.String)
}
