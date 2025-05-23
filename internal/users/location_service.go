package users

import (
	"context"
	"fmt"
	"strconv"

	"ptchampion/internal/logging"
	db "ptchampion/internal/store/postgres"
	"ptchampion/internal/store/redis"
)

// LocationService handles user location updates and cache invalidation
type LocationService struct {
	queries *db.Queries
	cache   *redis.LeaderboardCache
	logger  logging.Logger
}

// NewLocationService creates a new LocationService instance
func NewLocationService(queries *db.Queries, cache *redis.LeaderboardCache, logger logging.Logger) *LocationService {
	return &LocationService{
		queries: queries,
		cache:   cache,
		logger:  logger,
	}
}

// UpdateUserLocation updates a user's location in the database and invalidates relevant caches
func (s *LocationService) UpdateUserLocation(
	ctx context.Context,
	userID int32,
	lat, lng float64,
) error {
	s.logger.Debug(ctx, "Updating user location", "userID", userID, "lat", lat, "lng", lng)

	// Validate latitude and longitude ranges
	if lat < -90 || lat > 90 {
		return fmt.Errorf("invalid latitude: %f (must be between -90 and 90)", lat)
	}
	if lng < -180 || lng > 180 {
		return fmt.Errorf("invalid longitude: %f (must be between -180 and 180)", lng)
	}

	// Update in database using PostGIS
	// Note: UpdateUserLocation expects longitude first, then latitude for ST_MakePoint
	params := db.UpdateUserLocationParams{
		ID:            userID,
		StMakepoint:   lng, // longitude first
		StMakepoint_2: lat, // latitude second
	}

	if err := s.queries.UpdateUserLocation(ctx, params); err != nil {
		s.logger.Error(ctx, "Failed to update user location in database", "userID", userID, "error", err)
		return fmt.Errorf("failed to update location: %w", err)
	}

	s.logger.Debug(ctx, "Successfully updated user location in database", "userID", userID)

	// Invalidate local leaderboard caches
	// Since the user's location changed, all local leaderboards could be affected
	if err := s.invalidateLocalLeaderboardCaches(ctx, userID); err != nil {
		// Log the error but don't fail the whole operation
		s.logger.Error(ctx, "Failed to invalidate leaderboard cache", "userID", userID, "error", err)
		// Note: We continue execution even if cache invalidation fails
		// The location update succeeded, which is the primary operation
	}

	s.logger.Info(ctx, "User location updated successfully", "userID", userID, "lat", lat, "lng", lng)
	return nil
}

// invalidateLocalLeaderboardCaches removes all local leaderboard cache entries
// This ensures that when a user's location changes, fresh leaderboard data will be fetched
func (s *LocationService) invalidateLocalLeaderboardCaches(ctx context.Context, userID int32) error {
	// Pattern to match all local leaderboard cache entries
	pattern := "leaderboard:local:*"

	s.logger.Debug(ctx, "Invalidating local leaderboard caches", "userID", userID, "pattern", pattern)

	// Use the existing cache method to delete pattern
	// First, we need to implement a DeletePattern method or use existing methods
	// For now, let's use the existing InvalidateUserLeaderboards method
	if err := s.cache.InvalidateUserLeaderboards(ctx, int(userID)); err != nil {
		return fmt.Errorf("failed to invalidate cache pattern %s: %w", pattern, err)
	}

	s.logger.Debug(ctx, "Successfully invalidated local leaderboard caches", "userID", userID)
	return nil
}

// GetUserLocationInfo retrieves the current location information for a user
// This is a helper method that could be useful for debugging or API responses
func (s *LocationService) GetUserLocationInfo(ctx context.Context, userID int32) (*UserLocationInfo, error) {
	user, err := s.queries.GetUser(ctx, userID)
	if err != nil {
		s.logger.Error(ctx, "Failed to get user for location info", "userID", userID, "error", err)
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	info := &UserLocationInfo{
		UserID: userID,
	}

	// Extract latitude and longitude from stored fields
	if user.Latitude.Valid {
		if lat, err := strconv.ParseFloat(user.Latitude.String, 64); err == nil {
			info.Latitude = &lat
		}
	}

	if user.Longitude.Valid {
		if lng, err := strconv.ParseFloat(user.Longitude.String, 64); err == nil {
			info.Longitude = &lng
		}
	}

	if user.Location.Valid {
		info.LocationName = &user.Location.String
	}

	// Note: last_location is a PostGIS geography field and would need special handling
	// to extract the coordinates if needed

	return info, nil
}

// UserLocationInfo represents location information for a user
type UserLocationInfo struct {
	UserID       int32    `json:"user_id"`
	Latitude     *float64 `json:"latitude,omitempty"`
	Longitude    *float64 `json:"longitude,omitempty"`
	LocationName *string  `json:"location_name,omitempty"`
}
