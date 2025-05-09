package middleware

import (
	"log"
	"net/http"
	"strconv"
	"strings"

	"ptchampion/internal/auth"
	"ptchampion/internal/store/redis"

	"github.com/labstack/echo/v4"
)

// ContextKey is a custom type for context keys to avoid collisions
type ContextKey string

const (
	// UserIDKey is the key used to store the user ID in the context
	UserIDKey ContextKey = "user_id"
)

// JWTAuthMiddleware creates a middleware for JWT token verification using Echo framework
func JWTAuthMiddleware(accessSecret, refreshSecret string, refreshStore redis.RefreshStore) echo.MiddlewareFunc {
	// TokenService created once when the middleware is configured.
	tokenService := auth.NewTokenService(accessSecret, refreshSecret, refreshStore)
	log.Printf("DEBUG: JWT middleware initialized with accessSecret starting with %s...", accessSecret[:5])

	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			log.Printf("DEBUG: JWT middleware processing request to %s %s", c.Request().Method, c.Request().URL.Path)

			// Skip authentication for health check endpoint
			if c.Request().URL.Path == "/api/v1/health" {
				log.Printf("DEBUG: Skipping authentication for health check endpoint")
				return next(c)
			}

			// Extract the token from the Authorization header
			authHeader := c.Request().Header.Get("Authorization")
			if authHeader == "" {
				log.Printf("ERROR: Missing Authorization header in request to %s", c.Request().URL.Path)
				// Use Echo's built-in unauthorized error
				return echo.ErrUnauthorized
			}
			log.Printf("DEBUG: Authorization header found: %s...", authHeader[:15])

			// Check for Bearer token (case-insensitive)
			parts := strings.Split(authHeader, " ")
			// Use strings.EqualFold for case-insensitive comparison
			if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
				log.Printf("ERROR: Invalid Authorization header format: %s", authHeader[:15])
				// Use echo.ErrUnauthorized, wrapping a specific message if needed
				return echo.NewHTTPError(http.StatusUnauthorized, "Authorization header must be Bearer token")
			}

			tokenString := parts[1]
			if tokenString == "" {
				log.Printf("ERROR: Empty token in Authorization header")
				// Use Echo's built-in unauthorized error
				return echo.ErrUnauthorized
			}
			log.Printf("DEBUG: Token extracted from header: %s...", tokenString[:15])

			// Verify the token - first check token type before full validation
			log.Printf("DEBUG: Validating access token...")
			claims, err := tokenService.ValidateAccessToken(tokenString)
			if err != nil {
				log.Printf("ERROR: Token validation failed: %v", err)
				// Use Echo's built-in unauthorized error (covers invalid/expired)
				return echo.ErrUnauthorized
			}
			log.Printf("DEBUG: Token validated successfully for user_id: %s", claims.UserID)

			// Parse the user ID string to int32 for compatibility with handlers
			userIDInt, err := strconv.ParseInt(claims.UserID, 10, 32)
			if err != nil {
				log.Printf("ERROR: Failed to parse user_id string to int32: %v", err)
				return echo.NewHTTPError(http.StatusUnauthorized, "Invalid user ID format")
			}

			// Set user_id as int32 with consistent key
			c.Set(string(UserIDKey), int32(userIDInt))
			log.Printf("DEBUG: Set user_id in context as int32: %d", int32(userIDInt))

			return next(c)
		}
	}
}

// GetUserID extracts the user ID from the context
func GetUserID(c echo.Context) (int32, bool) {
	// Get user ID as int32
	userID, ok := c.Get(string(UserIDKey)).(int32)
	if !ok {
		log.Printf("ERROR: Failed to extract user ID from context, value found: %v (type: %T)", c.Get(string(UserIDKey)), c.Get(string(UserIDKey)))
	} else {
		log.Printf("DEBUG: GetUserID successfully extracted user ID: %d", userID)
	}
	return userID, ok
}

// NOTE: Removed GetUsername function as it was based on claims.Subject which was the same as UserID
