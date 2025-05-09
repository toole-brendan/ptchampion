package leaderboards

import (
	"context"
	"fmt"

	"ptchampion/internal/logging"
	"ptchampion/internal/store"
)

// Service defines the interface for leaderboard-related business logic.
type Service interface {
	GetGlobalExerciseLeaderboard(ctx context.Context, exerciseType string, limit int) ([]*store.LeaderboardEntry, error)
	GetGlobalAggregateLeaderboard(ctx context.Context, limit int) ([]*store.LeaderboardEntry, error)
	GetLocalExerciseLeaderboard(ctx context.Context, exerciseType string, latitude, longitude float64, radiusMeters int, limit int) ([]*store.LeaderboardEntry, error)
	GetLocalAggregateLeaderboard(ctx context.Context, latitude, longitude float64, radiusMeters int, limit int) ([]*store.LeaderboardEntry, error)
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

// assignRanks assigns ranks to a slice of leaderboard entries.
func assignRanks(entries []*store.LeaderboardEntry) {
	for i, entry := range entries {
		entry.Rank = int32(i + 1)
	}
}

// GetGlobalExerciseLeaderboard retrieves the global leaderboard for a specific exercise type.
func (s *service) GetGlobalExerciseLeaderboard(ctx context.Context, exerciseType string, limit int) ([]*store.LeaderboardEntry, error) {
	s.logger.Debug(ctx, "Service: GetGlobalExerciseLeaderboard", "exerciseType", exerciseType, "limit", limit)
	if limit <= 0 || limit > 300 {
		limit = 50
	} // Default/max limit

	entries, err := s.leaderboardStore.GetGlobalExerciseLeaderboard(ctx, exerciseType, limit)
	if err != nil {
		s.logger.Error(ctx, "Failed to get global exercise leaderboard from store", "type", exerciseType, "error", err)
		return nil, fmt.Errorf("failed to retrieve global exercise leaderboard: %w", err)
	}
	assignRanks(entries)
	s.logger.Info(ctx, "Global exercise leaderboard retrieved", "type", exerciseType, "count", len(entries))
	return entries, nil
}

// GetGlobalAggregateLeaderboard retrieves the global aggregate leaderboard.
func (s *service) GetGlobalAggregateLeaderboard(ctx context.Context, limit int) ([]*store.LeaderboardEntry, error) {
	s.logger.Debug(ctx, "Service: GetGlobalAggregateLeaderboard", "limit", limit)
	if limit <= 0 || limit > 300 {
		limit = 50
	} // Default/max limit

	entries, err := s.leaderboardStore.GetGlobalAggregateLeaderboard(ctx, limit)
	if err != nil {
		s.logger.Error(ctx, "Failed to get global aggregate leaderboard from store", "error", err)
		return nil, fmt.Errorf("failed to retrieve global aggregate leaderboard: %w", err)
	}
	assignRanks(entries)
	s.logger.Info(ctx, "Global aggregate leaderboard retrieved", "count", len(entries))
	return entries, nil
}

// GetLocalExerciseLeaderboard retrieves a local leaderboard for a specific exercise.
func (s *service) GetLocalExerciseLeaderboard(ctx context.Context, exerciseType string, latitude, longitude float64, radiusMeters int, limit int) ([]*store.LeaderboardEntry, error) {
	s.logger.Debug(ctx, "Service: GetLocalExerciseLeaderboard", "type", exerciseType, "lat", latitude, "lon", longitude, "radiusM", radiusMeters, "limit", limit)
	if limit <= 0 || limit > 300 {
		limit = 25
	}
	if radiusMeters <= 0 || radiusMeters > 8050 {
		radiusMeters = 8047
	} // Approx 5 miles

	entries, err := s.leaderboardStore.GetLocalExerciseLeaderboard(ctx, exerciseType, latitude, longitude, radiusMeters, limit)
	if err != nil {
		s.logger.Error(ctx, "Failed to get local exercise leaderboard from store", "type", exerciseType, "error", err)
		return nil, fmt.Errorf("failed to retrieve local exercise leaderboard: %w", err)
	}
	assignRanks(entries)
	s.logger.Info(ctx, "Local exercise leaderboard retrieved", "type", exerciseType, "count", len(entries))
	return entries, nil
}

// GetLocalAggregateLeaderboard retrieves a local aggregate leaderboard.
func (s *service) GetLocalAggregateLeaderboard(ctx context.Context, latitude, longitude float64, radiusMeters int, limit int) ([]*store.LeaderboardEntry, error) {
	s.logger.Debug(ctx, "Service: GetLocalAggregateLeaderboard", "lat", latitude, "lon", longitude, "radiusM", radiusMeters, "limit", limit)
	if limit <= 0 || limit > 300 {
		limit = 25
	}
	if radiusMeters <= 0 || radiusMeters > 8050 {
		radiusMeters = 8047
	} // Approx 5 miles

	entries, err := s.leaderboardStore.GetLocalAggregateLeaderboard(ctx, latitude, longitude, radiusMeters, limit)
	if err != nil {
		s.logger.Error(ctx, "Failed to get local aggregate leaderboard from store", "error", err)
		return nil, fmt.Errorf("failed to retrieve local aggregate leaderboard: %w", err)
	}
	assignRanks(entries)
	s.logger.Info(ctx, "Local aggregate leaderboard retrieved", "count", len(entries))
	return entries, nil
}
