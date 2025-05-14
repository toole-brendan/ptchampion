package db

import (
	"context"
	"database/sql"
	"fmt"
	"strconv"
	"strings"
	"time"

	"ptchampion/internal/logging" // Import the logging package for the logger
	"ptchampion/internal/store"   // Import the store package for the interface

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

// Store provides access to all store interfaces backed by a postgres database
type Store struct {
	*Queries
	db         *sql.DB
	DefaultTTL time.Duration
	logger     logging.Logger // Changed from *Logger to logging.Logger
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

// SetLogger sets the logger for the store.
func (s *Store) SetLogger(logger logging.Logger) {
	s.logger = logger
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

	// Handle potential null times from DB
	var createdAt, updatedAt time.Time
	if dbUser.CreatedAt.Valid {
		createdAt = dbUser.CreatedAt.Time
	}
	if dbUser.UpdatedAt.Valid {
		updatedAt = dbUser.UpdatedAt.Time
	}

	// IMPORTANT: This function will need to be updated after SQLC regeneration
	// to use the actual Email field once it exists in the database schema
	return &store.User{
		ID:           strconv.Itoa(int(dbUser.ID)), // Convert int32 to string; NOTE: This is a temporary fix for ID mismatch
		Email:        dbUser.Email,                 // Use the actual Email field
		Username:     dbUser.Username,
		PasswordHash: dbUser.PasswordHash,
		FirstName:    firstName,
		LastName:     lastName,
		CreatedAt:    createdAt,
		UpdatedAt:    updatedAt,
	}
}

// CreateUser implements store.UserStore
func (s *Store) CreateUser(ctx context.Context, user *store.User) (*store.User, error) {
	// Set display_name to username (Option A)
	displayName := sql.NullString{
		String: user.Username,
		Valid:  true,
	}

	// IMPORTANT: This will need to be updated after SQLC regeneration to include email
	// when CreateUserParams is regenerated with the Email field
	params := CreateUserParams{
		Username:     user.Username, // Use the actual Username from the input
		Email:        user.Email,    // Populate the Email field correctly
		PasswordHash: user.PasswordHash,
		DisplayName:  displayName,
	}

	dbUser, err := s.Queries.CreateUser(ctx, params)
	if err != nil {
		return nil, fmt.Errorf("failed to create user in DB: %w", err)
	}

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
func (s *Store) GetUserByEmail(ctx context.Context, email string) (*store.User, error) {
	dbUser, err := s.Queries.GetUserByEmail(ctx, email) // Use the direct GetUserByEmail from sqlc
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, store.ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to get user by email from DB: %w", err)
	}
	return toStoreUser(dbUser), nil
}

// UpdateUser implements store.UserStore
func (s *Store) UpdateUser(ctx context.Context, user *store.User) (*store.User, error) {
	userIDInt, err := strconv.ParseInt(user.ID, 10, 32)
	if err != nil {
		return nil, fmt.Errorf("invalid user ID format for update: %w", err)
	}

	// Fetch the current user record to get existing values for Username and PasswordHash
	// if they are not being updated, as UpdateUserParams requires them.
	currentUserRecord, err := s.Queries.GetUser(ctx, int32(userIDInt))
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, store.ErrUserNotFound
		}
		return nil, fmt.Errorf("failed to fetch current user for update: %w", err)
	}

	params := UpdateUserParams{
		ID: int32(userIDInt),
		// Username and PasswordHash are not nullable in UpdateUserParams.
		// Use existing value if not provided in the input user object.
		Username: currentUserRecord.Username,
		// PasswordHash: currentUserRecord.PasswordHash, // Commented out as not in UpdateUserParams
		// Location, Latitude, Longitude, LastSyncedAt will be handled by COALESCE in SQL
		// as they will be sql.NullString/Time with Valid=false if not set here.
		// This is appropriate as store.User does not carry this information.
	}

	if user.Email != "" {
		params.Username = user.Email
	}

	// if user.PasswordHash != "" { // Commented out as not in UpdateUserParams
	// 	params.PasswordHash = user.PasswordHash
	// }

	// Set display_name to username (Option A)
	if user.Username != "" {
		params.DisplayName = sql.NullString{
			String: user.Username,
			Valid:  true,
		}
	}

	updatedDbUser, err := s.Queries.UpdateUser(ctx, params)
	if err != nil {
		// TODO: Handle potential DB errors, e.g., unique constraint violations if username is changed
		return nil, fmt.Errorf("failed to update user in DB: %w", err)
	}

	return toStoreUser(updatedDbUser), nil
}

// DeleteUser implements store.UserStore
func (s *Store) DeleteUser(ctx context.Context, id string) error {
	userIDInt, err := strconv.ParseInt(id, 10, 32)
	if err != nil {
		return fmt.Errorf("invalid user ID format for delete: %w", err)
	}

	// TODO: Add a DeleteUser query to internal/store/postgres/queries/user.sql (e.g., -- name: DeleteUser :exec
	// DELETE FROM users WHERE id = $1;)
	// TODO: Regenerate sqlc code to make s.Queries.DeleteUser available.
	// Once s.Queries.DeleteUser is available, uncomment and adapt the following:
	/*
		err = s.Queries.DeleteUser(ctx, int32(userIDInt))
		if err != nil {
			// sql.ErrNoRows might not be returned by an Exec method for delete.
			// Check if the user existed before delete if specific error for not found is needed.
			// Or, the service layer can check existence first if required.
			return fmt.Errorf("failed to delete user from DB (ID: %d): %w", userIDInt, err)
		}
		return nil
	*/

	return fmt.Errorf("DeleteUser SQL query and s.Queries.DeleteUser method not yet implemented (ID: %d)", userIDInt)
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

// Ping checks the database connectivity.
func (s *Store) Ping(ctx context.Context) error {
	ctxTimeout, cancel := context.WithTimeout(ctx, s.DefaultTTL) // Use store's default TTL or a specific one for pings
	defer cancel()
	return s.db.PingContext(ctxTimeout)
}

// --- ExerciseStore Implementation ---

// Helper to convert *int32 to sql.NullInt32
func int32PtrToNullInt32(ptr *int32) sql.NullInt32 {
	if ptr == nil {
		return sql.NullInt32{}
	}
	return sql.NullInt32{Int32: *ptr, Valid: true}
}

// Helper to convert sql.NullInt32 to *int32
func nullInt32ToInt32Ptr(ni sql.NullInt32) *int32 {
	if !ni.Valid {
		return nil
	}
	return &ni.Int32
}

// Helper to convert *string to sql.NullString
func stringPtrToNullString(ptr *string) sql.NullString {
	if ptr == nil {
		return sql.NullString{}
	}
	return sql.NullString{String: *ptr, Valid: true}
}

// Helper to convert sql.NullString to *string
func nullStringToStringPtr(ns sql.NullString) *string {
	if !ns.Valid {
		return nil
	}
	return &ns.String
}

// Helper to convert sql.NullTime to time.Time, returning zero value if null
func nullTimeToTime(nt sql.NullTime) time.Time {
	if nt.Valid {
		return nt.Time
	}
	return time.Time{} // Return zero value for time if SQL time is NULL
}

// toStoreExercise converts db.Exercise to store.Exercise
func toStoreExercise(dbEx Exercise) *store.Exercise {
	return &store.Exercise{
		ID:          dbEx.ID,
		Name:        dbEx.Name,
		Description: nullStringToStringPtr(dbEx.Description),
		Type:        dbEx.Type,
	}
}

// toStoreUserExerciseRecord converts db.UserExercise or db.GetUserExercisesRow to store.UserExerciseRecord
func toStoreUserExerciseRecord(dbRecord interface{}) *store.UserExerciseRecord {
	switch v := dbRecord.(type) {
	case UserExercise: // From LogUserExercise query result
		return &store.UserExerciseRecord{
			ID:         v.ID,
			UserID:     v.UserID,
			ExerciseID: v.ExerciseID,
			// ExerciseName and ExerciseType are not in db.UserExercise model directly
			// These are usually populated by the service layer after fetching definition or if joined in query
			Reps:          nullInt32ToInt32Ptr(v.Repetitions),
			TimeInSeconds: nullInt32ToInt32Ptr(v.TimeInSeconds),
			Distance:      nullInt32ToInt32Ptr(v.Distance),
			Notes:         nullStringToStringPtr(v.Notes),
			Grade:         v.Grade.Int32, // Assuming grade is always valid after logging
			CreatedAt:     nullTimeToTime(v.CreatedAt),
		}
	case GetUserExercisesRow: // From GetUserExercises query result
		return &store.UserExerciseRecord{
			ID:            v.ID,
			UserID:        v.UserID,
			ExerciseID:    v.ExerciseID,
			ExerciseName:  v.ExerciseName, // Available in GetUserExercisesRow
			ExerciseType:  v.ExerciseType, // Available in GetUserExercisesRow
			Reps:          nullInt32ToInt32Ptr(v.Repetitions),
			TimeInSeconds: nullInt32ToInt32Ptr(v.TimeInSeconds),
			Distance:      nullInt32ToInt32Ptr(v.Distance),
			Notes:         nullStringToStringPtr(v.Notes),
			Grade:         v.Grade.Int32, // Assuming grade is valid
			CreatedAt:     nullTimeToTime(v.CreatedAt),
		}
	default:
		// Optionally log an error here if an unexpected type is passed
		return nil
	}
}

// GetExerciseDefinition implements store.ExerciseStore
func (s *Store) GetExerciseDefinition(ctx context.Context, exerciseID int32) (*store.Exercise, error) {
	dbEx, err := s.Queries.GetExercise(ctx, exerciseID)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, store.ErrExerciseNotFound
		}
		return nil, fmt.Errorf("failed to get exercise definition from DB: %w", err)
	}
	return toStoreExercise(dbEx), nil
}

// LogUserExercise implements store.ExerciseStore
// Note: The input `record` is a store.UserExerciseRecord which contains denormalized ExerciseName and ExerciseType.
// These are not used for DB insertion directly but are part of the domain model.
// The SQLC generated LogUserExerciseParams expects only essential IDs and metric values.
func (s *Store) LogUserExercise(ctx context.Context, record *store.UserExerciseRecord) (*store.UserExerciseRecord, error) {
	params := LogUserExerciseParams{
		UserID:        record.UserID,
		ExerciseID:    record.ExerciseID,
		Repetitions:   int32PtrToNullInt32(record.Reps),
		TimeInSeconds: int32PtrToNullInt32(record.TimeInSeconds),
		Distance:      int32PtrToNullInt32(record.Distance),
		Notes:         stringPtrToNullString(record.Notes),
		Grade:         sql.NullInt32{Int32: record.Grade, Valid: true}, // Grade is calculated by service
	}
	dbLoggedExercise, err := s.Queries.LogUserExercise(ctx, params)
	if err != nil {
		return nil, fmt.Errorf("failed to log user exercise in DB: %w", err)
	}

	// The LogUserExerciseRow doesn't have ExerciseName and ExerciseType.
	// These need to be added back if we are to return a complete store.UserExerciseRecord.
	// For now, we return what the DB gives back directly from LogUserExerciseRow,
	// the service layer will be responsible for enriching it if needed.
	resultRecord := toStoreUserExerciseRecord(dbLoggedExercise)
	if resultRecord != nil {
		// We copy over the potentially denormalized fields from the input if they were set,
		// as LogUserExerciseRow doesn't include them.
		resultRecord.ExerciseName = record.ExerciseName
		resultRecord.ExerciseType = record.ExerciseType
	}
	return resultRecord, nil
}

// GetUserExerciseLogs implements store.ExerciseStore
func (s *Store) GetUserExerciseLogs(ctx context.Context, userID int32, limit, offset int32) (*store.PaginatedUserExerciseRecords, error) {
	count, err := s.Queries.GetUserExercisesCount(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user exercises count from DB: %w", err)
	}

	if count == 0 {
		return &store.PaginatedUserExerciseRecords{
			Records:    []*store.UserExerciseRecord{},
			TotalCount: 0,
		}, nil
	}

	params := GetUserExercisesParams{
		UserID: userID,
		Limit:  limit,
		Offset: offset,
	}
	dbUserExercises, err := s.Queries.GetUserExercises(ctx, params)
	if err != nil {
		// sql.ErrNoRows is not an error if count > 0 and we just fetched an empty page
		// but if count was 0, we wouldn't be here. If dbUserExercises is empty but no error, it's fine.
		if err != sql.ErrNoRows {
			return nil, fmt.Errorf("failed to get user exercises from DB: %w", err)
		}
	}

	records := make([]*store.UserExerciseRecord, len(dbUserExercises))
	for i, dbEx := range dbUserExercises {
		records[i] = toStoreUserExerciseRecord(dbEx)
	}

	return &store.PaginatedUserExerciseRecords{
		Records:    records,
		TotalCount: count,
	}, nil
}

// ListExerciseDefinitions implements store.ExerciseStore
func (s *Store) ListExerciseDefinitions(ctx context.Context) ([]*store.Exercise, error) {
	dbExercises, err := s.Queries.ListExercises(ctx)
	if err != nil {
		// sql.ErrNoRows is okay here, means no exercises defined.
		if err == sql.ErrNoRows {
			return []*store.Exercise{}, nil
		}
		return nil, fmt.Errorf("failed to list exercise definitions from DB: %w", err)
	}

	exercises := make([]*store.Exercise, len(dbExercises))
	for i, dbEx := range dbExercises {
		exercises[i] = toStoreExercise(dbEx)
	}
	return exercises, nil
}

// --- LeaderboardStore Implementation ---

// Helper function to map SQLC leaderboard rows to store.LeaderboardEntry
// This is a generic helper; individual mapping might be slightly different based on actual sqlc structs.
func mapSqlcRowToLeaderboardEntry(userID int32, username string, displayName sql.NullString, score int32) *store.LeaderboardEntry {
	return &store.LeaderboardEntry{
		UserID:      strconv.Itoa(int(userID)),
		Username:    username,
		DisplayName: nullStringToStringPtr(displayName),
		Score:       score,
		// Rank is set by the service layer
	}
}

// GetGlobalExerciseLeaderboard implements store.LeaderboardStore
func (s *Store) GetGlobalExerciseLeaderboard(ctx context.Context, exerciseType string, limit int, startDate time.Time, endDate time.Time) ([]*store.LeaderboardEntry, error) {
	s.logger.Debug(ctx, "Store: GetGlobalExerciseLeaderboard called", "type", exerciseType, "limit", limit, "startDate", startDate, "endDate", endDate)

	var sqlStartDate sql.NullTime
	if !startDate.IsZero() {
		sqlStartDate = sql.NullTime{Time: startDate, Valid: true}
	}
	var sqlEndDate sql.NullTime
	if !endDate.IsZero() {
		sqlEndDate = sql.NullTime{Time: endDate, Valid: true}
	}

	params := GetGlobalExerciseLeaderboardParams{
		Type:      exerciseType,
		Limit:     int32(limit),
		StartDate: sqlStartDate, // Assumes sqlc generated `StartDate sql.NullTime`
		EndDate:   sqlEndDate,   // Assumes sqlc generated `EndDate sql.NullTime`
	}
	dbRows, err := s.Queries.GetGlobalExerciseLeaderboard(ctx, params)
	if err != nil {
		if err == sql.ErrNoRows {
			return []*store.LeaderboardEntry{}, nil
		}
		s.logger.Error(ctx, "Failed to get global exercise leaderboard from DB", "type", exerciseType, "error", err)
		return nil, fmt.Errorf("failed to get global exercise leaderboard from DB: %w", err)
	}

	entries := make([]*store.LeaderboardEntry, len(dbRows))
	for i, row := range dbRows {
		var score int32
		if row.Score != nil {
			if val, ok := row.Score.(int64); ok {
				score = int32(val)
			} else if val, ok := row.Score.(int32); ok {
				score = val
			} else {
				s.logger.Warn(ctx, "Unexpected type for score in GetGlobalExerciseLeaderboardRow", "score_type", fmt.Sprintf("%T", row.Score), "user_id", row.UserID)
			}
		}
		entries[i] = mapSqlcRowToLeaderboardEntry(row.UserID, row.Username, row.DisplayName, score)
	}
	return entries, nil
}

// GetGlobalAggregateLeaderboard implements store.LeaderboardStore
func (s *Store) GetGlobalAggregateLeaderboard(ctx context.Context, limit int, startDate time.Time, endDate time.Time) ([]*store.LeaderboardEntry, error) {
	s.logger.Debug(ctx, "Store: GetGlobalAggregateLeaderboard called", "limit", limit, "startDate", startDate, "endDate", endDate)

	var sqlStartDate sql.NullTime
	if !startDate.IsZero() {
		sqlStartDate = sql.NullTime{Time: startDate, Valid: true}
	}
	var sqlEndDate sql.NullTime
	if !endDate.IsZero() {
		sqlEndDate = sql.NullTime{Time: endDate, Valid: true}
	}

	params := GetGlobalAggregateLeaderboardParams{
		Limit:     int32(limit),
		StartDate: sqlStartDate, // Assumes sqlc generated `StartDate sql.NullTime`
		EndDate:   sqlEndDate,   // Assumes sqlc generated `EndDate sql.NullTime`
	}
	dbRows, err := s.Queries.GetGlobalAggregateLeaderboard(ctx, params)
	if err != nil {
		if err == sql.ErrNoRows {
			return []*store.LeaderboardEntry{}, nil
		}
		s.logger.Error(ctx, "Failed to get global aggregate leaderboard from DB", "error", err)
		return nil, fmt.Errorf("failed to get global aggregate leaderboard from DB: %w", err)
	}

	entries := make([]*store.LeaderboardEntry, len(dbRows))
	for i, row := range dbRows {
		entries[i] = mapSqlcRowToLeaderboardEntry(row.UserID, row.Username, row.DisplayName, int32(row.Score))
	}
	return entries, nil
}

// GetLocalExerciseLeaderboard implements store.LeaderboardStore
func (s *Store) GetLocalExerciseLeaderboard(ctx context.Context, exerciseType string, latitude, longitude float64, radiusMeters int, limit int, startDate time.Time, endDate time.Time) ([]*store.LeaderboardEntry, error) {
	s.logger.Debug(ctx, "Store: GetLocalExerciseLeaderboard called", "type", exerciseType, "lat", latitude, "lon", longitude, "radius", radiusMeters, "limit", limit, "startDate", startDate, "endDate", endDate)

	var sqlStartDate sql.NullTime
	if !startDate.IsZero() {
		sqlStartDate = sql.NullTime{Time: startDate, Valid: true}
	}
	var sqlEndDate sql.NullTime
	if !endDate.IsZero() {
		sqlEndDate = sql.NullTime{Time: endDate, Valid: true}
	}

	params := GetLocalExerciseLeaderboardParams{
		Type:         exerciseType,
		Longitude:    longitude,             // SQLC will expect `Longitude` based on @longitude
		Latitude:     latitude,              // SQLC will expect `Latitude` based on @latitude
		RadiusMeters: float64(radiusMeters), // SQLC will expect `RadiusMeters`
		Limit:        int32(limit),
		StartDate:    sqlStartDate, // Assumes sqlc generated `StartDate sql.NullTime`
		EndDate:      sqlEndDate,   // Assumes sqlc generated `EndDate sql.NullTime`
	}
	dbRows, err := s.Queries.GetLocalExerciseLeaderboard(ctx, params)
	if err != nil {
		if err == sql.ErrNoRows {
			return []*store.LeaderboardEntry{}, nil
		}
		s.logger.Error(ctx, "Failed to get local exercise leaderboard from DB", "type", exerciseType, "error", err)
		return nil, fmt.Errorf("failed to get local exercise leaderboard from DB: %w", err)
	}

	entries := make([]*store.LeaderboardEntry, len(dbRows))
	for i, row := range dbRows {
		var score int32
		if row.Score != nil {
			if val, ok := row.Score.(int64); ok {
				score = int32(val)
			} else if val, ok := row.Score.(int32); ok {
				score = val
			} else {
				s.logger.Warn(ctx, "Unexpected type for score in GetLocalExerciseLeaderboardRow", "score_type", fmt.Sprintf("%T", row.Score), "user_id", row.UserID)
			}
		}
		entries[i] = mapSqlcRowToLeaderboardEntry(row.UserID, row.Username, row.DisplayName, score)
	}
	return entries, nil
}

// GetLocalAggregateLeaderboard implements store.LeaderboardStore
func (s *Store) GetLocalAggregateLeaderboard(ctx context.Context, latitude, longitude float64, radiusMeters int, limit int, startDate time.Time, endDate time.Time) ([]*store.LeaderboardEntry, error) {
	s.logger.Debug(ctx, "Store: GetLocalAggregateLeaderboard called", "lat", latitude, "lon", longitude, "radius", radiusMeters, "limit", limit, "startDate", startDate, "endDate", endDate)

	var sqlStartDate sql.NullTime
	if !startDate.IsZero() {
		sqlStartDate = sql.NullTime{Time: startDate, Valid: true}
	}
	var sqlEndDate sql.NullTime
	if !endDate.IsZero() {
		sqlEndDate = sql.NullTime{Time: endDate, Valid: true}
	}

	params := GetLocalAggregateLeaderboardParams{
		Longitude:    longitude,             // SQLC will expect `Longitude`
		Latitude:     latitude,              // SQLC will expect `Latitude`
		RadiusMeters: float64(radiusMeters), // SQLC will expect `RadiusMeters`
		Limit:        int32(limit),
		StartDate:    sqlStartDate, // Assumes sqlc generated `StartDate sql.NullTime`
		EndDate:      sqlEndDate,   // Assumes sqlc generated `EndDate sql.NullTime`
	}
	dbRows, err := s.Queries.GetLocalAggregateLeaderboard(ctx, params)
	if err != nil {
		if err == sql.ErrNoRows {
			return []*store.LeaderboardEntry{}, nil
		}
		s.logger.Error(ctx, "Failed to get local aggregate leaderboard from DB", "error", err)
		return nil, fmt.Errorf("failed to get local aggregate leaderboard from DB: %w", err)
	}

	entries := make([]*store.LeaderboardEntry, len(dbRows))
	for i, row := range dbRows {
		entries[i] = mapSqlcRowToLeaderboardEntry(row.UserID, row.Username, row.DisplayName, int32(row.Score))
	}
	return entries, nil
}

// Comment out or remove old generic leaderboard methods to avoid conflict with the updated interface
/*
func (s *Store) GetExerciseTypeLeaderboard(ctx context.Context, exerciseType string, limit int) ([]*store.LeaderboardEntry, error) {
	// ... old implementation or stub ...
	return nil, fmt.Errorf("use GetGlobalExerciseLeaderboard instead")
}

func (s *Store) GetOverallLeaderboard(ctx context.Context, limit int) ([]*store.LeaderboardEntry, error) {
	// ... old implementation or stub ...
	return nil, fmt.Errorf("use specific global leaderboard methods instead")
}

func (s *Store) GetLocalLeaderboard(ctx context.Context, exerciseID int32, latitude, longitude float64, radiusMeters int, limit int) ([]*store.LeaderboardEntry, error) {
	// ... old implementation or stub ...
	return nil, fmt.Errorf("use specific local leaderboard methods instead")
}
*/

// --- WorkoutStore Implementation ---

// toStoreWorkoutRecord converts db.Workout or db.GetUserWorkoutsRow to store.WorkoutRecord
func toStoreWorkoutRecord(dbRec interface{}) *store.WorkoutRecord {
	switch v := dbRec.(type) {
	case Workout: // From CreateWorkout query
		return &store.WorkoutRecord{
			ID:              v.ID,
			UserID:          v.UserID,
			ExerciseID:      v.ExerciseID,
			ExerciseType:    v.ExerciseType, // ExerciseName would need to be fetched separately if not included
			Reps:            nullInt32ToInt32Ptr(v.Repetitions),
			DurationSeconds: nullInt32ToInt32Ptr(v.DurationSeconds),
			FormScore:       nullInt32ToInt32Ptr(v.FormScore),
			Grade:           v.Grade,
			CompletedAt:     v.CompletedAt,
			CreatedAt:       v.CreatedAt,
		}
	case GetUserWorkoutsRow: // From GetUserWorkouts query
		return &store.WorkoutRecord{
			ID:           v.ID,
			UserID:       v.UserID,
			ExerciseID:   v.ExerciseID,
			ExerciseName: v.ExerciseName, // Available from join in GetUserWorkoutsRow
			// ExerciseType is not in GetUserWorkoutsRow, but it is in db.Workout if we need it, though less useful if ExerciseName is present
			Reps:            nullInt32ToInt32Ptr(v.Repetitions),
			DurationSeconds: nullInt32ToInt32Ptr(v.DurationSeconds),
			FormScore:       nullInt32ToInt32Ptr(v.FormScore),
			Grade:           v.Grade,
			CompletedAt:     v.CompletedAt,
			CreatedAt:       v.CreatedAt,
		}
	default:
		return nil
	}
}

// CreateWorkoutRecord implements store.WorkoutStore
func (s *Store) CreateWorkoutRecord(ctx context.Context, record *store.WorkoutRecord) (*store.WorkoutRecord, error) {
	params := CreateWorkoutParams{
		UserID:          record.UserID,
		ExerciseID:      record.ExerciseID,
		ExerciseType:    record.ExerciseType,
		Repetitions:     int32PtrToNullInt32(record.Reps),
		DurationSeconds: int32PtrToNullInt32(record.DurationSeconds),
		Grade:           record.Grade,
		CompletedAt:     record.CompletedAt,
		// FormScore is not in CreateWorkoutParams for SQLc. It's in the db.Workout model returned by the query,
		// and also in db.GetUserWorkoutsRow. If it needs to be set on creation, the SQL query CreateWorkout
		// and its CreateWorkoutParams struct would need to be updated to include FormScore.
		// For now, it will be whatever the DB defaults it to or what the RETURNING clause provides if it's set by trigger/default.
		// The db.Workout model does have FormScore, so it is read back.
	}
	dbWorkout, err := s.Queries.CreateWorkout(ctx, params)
	if err != nil {
		return nil, fmt.Errorf("failed to create workout record in DB: %w", err)
	}
	newRecord := toStoreWorkoutRecord(dbWorkout)
	// If ExerciseName was part of the input store.WorkoutRecord (e.g. already known by caller),
	// we can copy it over, as db.Workout from CreateWorkout doesn't have it directly.
	if newRecord != nil && record.ExerciseName != "" {
		newRecord.ExerciseName = record.ExerciseName
	}
	return newRecord, nil
}

// GetUserWorkoutRecords implements store.WorkoutStore
func (s *Store) GetUserWorkoutRecords(ctx context.Context, userID int32, limit int32, offset int32) (*store.PaginatedWorkoutRecords, error) {
	count, err := s.Queries.GetUserWorkoutsCount(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user workout records count from DB: %w", err)
	}

	if count == 0 {
		return &store.PaginatedWorkoutRecords{
			Records:    []*store.WorkoutRecord{},
			TotalCount: 0,
		}, nil
	}

	params := GetUserWorkoutsParams{
		UserID: userID,
		Limit:  limit,
		Offset: offset,
	}
	dbWorkoutRows, err := s.Queries.GetUserWorkouts(ctx, params)
	if err != nil {
		if err != sql.ErrNoRows { // ErrNoRows is fine if count > 0 but current page is empty
			return nil, fmt.Errorf("failed to get user workout records from DB: %w", err)
		}
	}

	records := make([]*store.WorkoutRecord, len(dbWorkoutRows))
	for i, dbRow := range dbWorkoutRows {
		records[i] = toStoreWorkoutRecord(dbRow)
	}

	return &store.PaginatedWorkoutRecords{
		Records:    records,
		TotalCount: count,
	}, nil
}

// GetWorkoutRecordByID implements store.WorkoutStore
func (s *Store) GetWorkoutRecordByID(ctx context.Context, id int32) (*store.WorkoutRecord, error) {
	dbWorkout, err := s.Queries.GetWorkoutRecordByID(ctx, id)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, store.ErrWorkoutRecordNotFound
		}
		return nil, fmt.Errorf("failed to get workout record by ID from DB: %w", err)
	}
	// The db.Workout might not have ExerciseName directly, so we need to fetch it.
	// This conversion needs to be smarter or the query needs to join.
	// For now, toStoreWorkoutRecord will handle what it can.
	workout := toStoreWorkoutRecord(dbWorkout)
	if workout != nil && workout.ExerciseName == "" { // If name is missing, try to fetch exercise details
		exDef, err := s.GetExerciseDefinition(ctx, workout.ExerciseID)
		if err == nil && exDef != nil {
			workout.ExerciseName = exDef.Name
			workout.ExerciseType = exDef.Type // Ensure type is also set
		}
	}
	return workout, nil
}

// UpdateWorkoutVisibility implements store.WorkoutStore
func (s *Store) UpdateWorkoutVisibility(ctx context.Context, userID int32, workoutID int32, isPublic bool) error {
	params := UpdateWorkoutVisibilityParams{
		IsPublic: isPublic,
		ID:       workoutID,
		UserID:   userID, // Ensure user owns the workout
	}
	err := s.Queries.UpdateWorkoutVisibility(ctx, params)
	if err != nil {
		// TODO: Check if the error is because the row was not found (e.g., user_id didn't match or workout_id didn't exist)
		// sqlc exec result doesn't directly tell us rows affected easily without more complex handling.
		// The service layer should verify ownership before calling this.
		return fmt.Errorf("failed to update workout visibility in DB: %w", err)
	}
	return nil
}

// Remove the mock structs as they should now be generated by sqlc
/*
// Temporary mock structs until SQLC generates them
// These should be removed once sqlc generate is run

// SqlcGetGlobalExerciseLeaderboardRow is a mock struct for the leaderboard row
type SqlcGetGlobalExerciseLeaderboardRow struct {
	UserID            int32
	Username          string
	DisplayName       sql.NullString
	Score             int32
}

// SqlcGetGlobalExerciseLeaderboardParams is a mock struct for the leaderboard query params
type SqlcGetGlobalExerciseLeaderboardParams struct {
	Type  string
	Limit int32
}
*/
