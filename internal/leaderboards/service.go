package leaderboards

import (
	"context"
	"fmt"
	"strings"
	"time"

	"ptchampion/internal/logging"
	"ptchampion/internal/store"
)

// Service defines the interface for leaderboard-related business logic.
type Service interface {
	GetGlobalExerciseLeaderboard(ctx context.Context, exerciseType string, limit int, timeFrame string) ([]*store.LeaderboardEntry, error)
	GetGlobalAggregateLeaderboard(ctx context.Context, limit int, timeFrame string) ([]*store.LeaderboardEntry, error)
	GetLocalExerciseLeaderboard(ctx context.Context, exerciseType string, latitude, longitude float64, radiusMeters int, limit int, timeFrame string) ([]*store.LeaderboardEntry, error)
	GetLocalAggregateLeaderboard(ctx context.Context, latitude, longitude float64, radiusMeters int, limit int, timeFrame string) ([]*store.LeaderboardEntry, error)
}

type service struct {
	leaderboardStore store.LeaderboardStore
	logger           logging.Logger
}

// NewService creates a new leaderboard service instance.
func NewService(leaderboardStore store.LeaderboardStore, logger logging.Logger) Service {
	return &service{
		leaderboardStore: leaderboardStore,
		logger:           logger,
	}
}

// parseTimeFrameToDates converts a timeFrame string to startDate and endDate.
// For "all_time", it returns zero time.Time values, which the store layer should interpret as no date filtering.
func parseTimeFrameToDates(timeFrame string) (startDate time.Time, endDate time.Time, err error) {
	now := time.Now().UTC() // Use UTC for consistency

	switch strings.ToLower(timeFrame) {
	case "daily":
		year, month, day := now.Date()
		startDate = time.Date(year, month, day, 0, 0, 0, 0, time.UTC)
		endDate = startDate.AddDate(0, 0, 1) // Start of the next day
	case "weekly":
		// Assuming week starts on Monday and ends on Sunday
		weekday := now.Weekday()
		// Calculate days to subtract to get to Monday
		// time.Monday is 1, time.Sunday is 0.
		daysToSubtract := (int(weekday) - int(time.Monday) + 7) % 7
		currentDayStart := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
		startDate = currentDayStart.AddDate(0, 0, -daysToSubtract)
		endDate = startDate.AddDate(0, 0, 7) // Start of the next week
	case "monthly":
		year, month, _ := now.Date()
		startDate = time.Date(year, month, 1, 0, 0, 0, 0, time.UTC)
		endDate = startDate.AddDate(0, 1, 0) // Start of the next month
	case "all_time":
		// Return zero values; store layer should interpret this as no date filtering.
		return time.Time{}, time.Time{}, nil
	default:
		return time.Time{}, time.Time{}, fmt.Errorf("invalid timeFrame: %s. Valid options are daily, weekly, monthly, all_time", timeFrame)
	}
	return startDate, endDate, nil
}

// assignRanks assigns ranks to a slice of leaderboard entries.
func assignRanks(entries []*store.LeaderboardEntry) {
	for i, entry := range entries {
		entry.Rank = int32(i + 1)
	}
}

// GetGlobalExerciseLeaderboard retrieves the global leaderboard for a specific exercise type.
func (s *service) GetGlobalExerciseLeaderboard(ctx context.Context, exerciseType string, limit int, timeFrame string) ([]*store.LeaderboardEntry, error) {
	s.logger.Debug(ctx, "Service: GetGlobalExerciseLeaderboard", "exerciseType", exerciseType, "limit", limit, "timeFrame", timeFrame)
	if limit <= 0 || limit > 300 {
		limit = 50 // Default/max limit
	}

	startDate, endDate, err := parseTimeFrameToDates(timeFrame)
	if err != nil {
		s.logger.Error(ctx, "Invalid timeFrame for GetGlobalExerciseLeaderboard", "timeFrame", timeFrame, "error", err)
		return nil, err
	}

	entries, err := s.leaderboardStore.GetGlobalExerciseLeaderboard(ctx, exerciseType, limit, startDate, endDate)
	if err != nil {
		s.logger.Error(ctx, "Failed to get global exercise leaderboard from store", "type", exerciseType, "error", err)
		return nil, fmt.Errorf("failed to retrieve global exercise leaderboard: %w", err)
	}
	assignRanks(entries)
	s.logger.Info(ctx, "Global exercise leaderboard retrieved", "type", exerciseType, "count", len(entries))
	return entries, nil
}

// GetGlobalAggregateLeaderboard retrieves the global aggregate leaderboard.
func (s *service) GetGlobalAggregateLeaderboard(ctx context.Context, limit int, timeFrame string) ([]*store.LeaderboardEntry, error) {
	s.logger.Debug(ctx, "Service: GetGlobalAggregateLeaderboard", "limit", limit, "timeFrame", timeFrame)
	if limit <= 0 || limit > 300 {
		limit = 50 // Default/max limit
	}

	startDate, endDate, err := parseTimeFrameToDates(timeFrame)
	if err != nil {
		s.logger.Error(ctx, "Invalid timeFrame for GetGlobalAggregateLeaderboard", "timeFrame", timeFrame, "error", err)
		return nil, err
	}

	entries, err := s.leaderboardStore.GetGlobalAggregateLeaderboard(ctx, limit, startDate, endDate)
	if err != nil {
		s.logger.Error(ctx, "Failed to get global overall leaderboard from store", "error", err)
		return nil, fmt.Errorf("failed to retrieve global overall leaderboard: %w", err)
	}
	assignRanks(entries)
	s.logger.Info(ctx, "Global overall leaderboard retrieved", "count", len(entries))
	return entries, nil
}

// GetLocalExerciseLeaderboard retrieves a local leaderboard for a specific exercise.
func (s *service) GetLocalExerciseLeaderboard(ctx context.Context, exerciseType string, latitude, longitude float64, radiusMeters int, limit int, timeFrame string) ([]*store.LeaderboardEntry, error) {
	s.logger.Debug(ctx, "Service: GetLocalExerciseLeaderboard", "type", exerciseType, "lat", latitude, "lon", longitude, "radiusM", radiusMeters, "limit", limit, "timeFrame", timeFrame)
	if limit <= 0 || limit > 300 {
		limit = 25
	}
	if radiusMeters <= 0 || radiusMeters > 80500 { // Increased max radius to 50 miles (approx 80500m)
		radiusMeters = 8047 // Approx 5 miles default
	}

	startDate, endDate, err := parseTimeFrameToDates(timeFrame)
	if err != nil {
		s.logger.Error(ctx, "Invalid timeFrame for GetLocalExerciseLeaderboard", "timeFrame", timeFrame, "error", err)
		return nil, err
	}

	entries, err := s.leaderboardStore.GetLocalExerciseLeaderboard(ctx, exerciseType, latitude, longitude, radiusMeters, limit, startDate, endDate)
	if err != nil {
		s.logger.Error(ctx, "Failed to get local exercise leaderboard from store", "type", exerciseType, "error", err)
		return nil, fmt.Errorf("failed to retrieve local exercise leaderboard: %w", err)
	}
	assignRanks(entries)
	s.logger.Info(ctx, "Local exercise leaderboard retrieved", "type", exerciseType, "count", len(entries))
	return entries, nil
}

// GetLocalAggregateLeaderboard retrieves a local aggregate leaderboard.
func (s *service) GetLocalAggregateLeaderboard(ctx context.Context, latitude, longitude float64, radiusMeters int, limit int, timeFrame string) ([]*store.LeaderboardEntry, error) {
	s.logger.Debug(ctx, "Service: GetLocalAggregateLeaderboard", "lat", latitude, "lon", longitude, "radiusM", radiusMeters, "limit", limit, "timeFrame", timeFrame)
	if limit <= 0 || limit > 300 {
		limit = 25
	}
	if radiusMeters <= 0 || radiusMeters > 80500 { // Increased max radius to 50 miles
		radiusMeters = 8047 // Approx 5 miles default
	}

	startDate, endDate, err := parseTimeFrameToDates(timeFrame)
	if err != nil {
		s.logger.Error(ctx, "Invalid timeFrame for GetLocalAggregateLeaderboard", "timeFrame", timeFrame, "error", err)
		return nil, err
	}

	entries, err := s.leaderboardStore.GetLocalAggregateLeaderboard(ctx, latitude, longitude, radiusMeters, limit, startDate, endDate)
	if err != nil {
		s.logger.Error(ctx, "Failed to get local overall leaderboard from store", "error", err)
		return nil, fmt.Errorf("failed to retrieve local overall leaderboard: %w", err)
	}
	assignRanks(entries)
	s.logger.Info(ctx, "Local overall leaderboard retrieved", "count", len(entries))
	return entries, nil
}
