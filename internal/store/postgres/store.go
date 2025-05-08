package db

import (
	"context"
	"database/sql"
	"fmt"
	"strconv"
	"strings"
	"time"

	"ptchampion/internal/store" // Import the store package for the interface

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

// Helper to convert db.User (from SQLC) to store.User (domain model)
func toStoreUser(dbUser User) *store.User {
	// Approximate FirstName and LastName from DisplayName
	var firstName, lastName string
	if dbUser.DisplayName.Valid {
		parts := strings.SplitN(dbUser.DisplayName.String, " ", 2)
		firstName = parts[0]
		if len(parts) > 1 {
			lastName = parts[1]
		}
	}

	var avatarURL *string
	if dbUser.ProfilePictureUrl.Valid {
		avatarURL = &dbUser.ProfilePictureUrl.String
	}

	// Handle potential null times from DB
	var createdAt, updatedAt time.Time
	if dbUser.CreatedAt.Valid {
		createdAt = dbUser.CreatedAt.Time
	}
	if dbUser.UpdatedAt.Valid {
		updatedAt = dbUser.UpdatedAt.Time
	}

	return &store.User{
		ID:           strconv.Itoa(int(dbUser.ID)), // Convert int32 to string; NOTE: This is a temporary fix for ID mismatch
		Email:        dbUser.Username,              // Assuming Username in DB is Email
		PasswordHash: dbUser.PasswordHash,
		FirstName:    firstName,
		LastName:     lastName,
		AvatarURL:    avatarURL,
		CreatedAt:    createdAt,
		UpdatedAt:    updatedAt,
	}
}

// CreateUser implements store.UserStore
func (s *Store) CreateUser(ctx context.Context, user *store.User) (*store.User, error) {
	// Combine FirstName and LastName for DisplayName
	var displayName sql.NullString
	if user.FirstName != "" || user.LastName != "" {
		displayName.String = strings.TrimSpace(user.FirstName + " " + user.LastName)
		displayName.Valid = true
	}

	params := CreateUserParams{
		Username:     user.Email, // Assuming Email from store.User maps to Username in db.User
		PasswordHash: user.PasswordHash,
		DisplayName:  displayName,
	}

	dbUser, err := s.Queries.CreateUser(ctx, params)
	if err != nil {
		return nil, fmt.Errorf("failed to create user in DB: %w", err)
	}

	// The returned dbUser.ID is int32, user.ID is string (UUID)
	// This is a significant mismatch. For now, to satisfy the interface,
	// we convert the int32 ID to string for store.User.ID.
	// The original UUID from store.NewUser(..) is lost here.
	return toStoreUser(dbUser), nil
}

// GetUserByID implements store.UserStore
func (s *Store) GetUserByID(ctx context.Context, id string) (*store.User, error) {
	userIDInt, err := strconv.ParseInt(id, 10, 32)
	if err != nil {
		// If parsing fails, it's unlikely an int32 ID, could be a UUID if conventions change.
		// For now, assume IDs passed here should be int32 representable as string.
		return nil, fmt.Errorf("invalid user ID format for DB lookup: %w", err)
	}

	dbUser, err := s.Queries.GetUser(ctx, int32(userIDInt))
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, store.ErrUserNotFound // Consider defining this error in store package
		}
		return nil, fmt.Errorf("failed to get user by ID from DB: %w", err)
	}
	return toStoreUser(dbUser), nil
}

// GetUserByEmail implements store.UserStore
// It uses GetUserByUsername as the DB schema has username, not email.
func (s *Store) GetUserByEmail(ctx context.Context, email string) (*store.User, error) {
	dbUser, err := s.Queries.GetUserByUsername(ctx, email) // email maps to username
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, store.ErrUserNotFound // Consider defining this error in store package
		}
		return nil, fmt.Errorf("failed to get user by email (username) from DB: %w", err)
	}
	return toStoreUser(dbUser), nil
}

// UpdateUser implements store.UserStore (STUB - needs full implementation)
func (s *Store) UpdateUser(ctx context.Context, user *store.User) (*store.User, error) {
	// TODO: Implement this by converting store.User to db.UpdateUserParams
	// and calling s.Queries.UpdateUser. Then convert result back.
	// Handle ID string to int32 conversion.
	// Handle FirstName/LastName to DisplayName.
	// Handle AvatarURL to ProfilePictureUrl.
	// This is a placeholder to satisfy the interface.

	userIDInt, err := strconv.ParseInt(user.ID, 10, 32)
	if err != nil {
		return nil, fmt.Errorf("invalid user ID format for update: %w", err)
	}

	var displayName sql.NullString
	if user.FirstName != "" || user.LastName != "" {
		displayName.String = strings.TrimSpace(user.FirstName + " " + user.LastName)
		displayName.Valid = true
	}

	var profilePicURL sql.NullString
	if user.AvatarURL != nil {
		profilePicURL.String = *user.AvatarURL
		profilePicURL.Valid = true
	}

	// Assuming user.Email maps to db.UpdateUserParams.Username
	// and user.PasswordHash may or may not be updated here (usually separate flow)
	// For now, let's assume username (email) is part of UpdateUserParams if it's changeable
	// and PasswordHash is also part of it if it can be updated here.
	// The existing db.UpdateUserParams includes Username and PasswordHash.

	updateParams := UpdateUserParams{
		ID:                int32(userIDInt),
		Username:          user.Email,        // Assuming email is username and can be updated
		PasswordHash:      user.PasswordHash, // Assuming password can be updated
		DisplayName:       displayName,
		ProfilePictureUrl: profilePicURL,
		// Location, Latitude, Longitude, LastSyncedAt are not in store.User directly.
		// They would need to be passed differently or handled by a more specific update method.
	}

	dbUser, err := s.Queries.UpdateUser(ctx, updateParams)
	if err != nil {
		return nil, fmt.Errorf("failed to update user in DB: %w", err)
	}
	return toStoreUser(dbUser), nil
}

// DeleteUser implements store.UserStore (STUB - needs underlying DB query)
func (s *Store) DeleteUser(ctx context.Context, id string) error {
	// TODO: Implement this. Requires a s.Queries.DeleteUser method,
	// which means a DELETE SQL query needs to be added to user.sql and sqlc regenerated.
	return fmt.Errorf("DeleteUser not implemented in postgres store")
}

// Ensure *Store implements store.Store (and thus store.UserStore)
var _ store.UserStore = (*Store)(nil)

// If store.Store embeds other interfaces like ExerciseStore, add them to the check:
// var _ store.Store = (*Store)(nil)
// For now, focusing on UserStore to fix the immediate linter error.
// If the linter error was specifically about store.Store, and CreateUser was the only missing one from UserStore,
// then fixing UserStore will fix store.Store if other embedded interfaces are already implemented or empty.
// The error message specifically said missing "CreateUser", part of UserStore.
// To be safe, let's ensure Store implements the full store.Store.
// This will fail if ExerciseStore or LeaderboardStore methods are not (even if stubbed) on *db.Store
var _ store.Store = (*Store)(nil)
