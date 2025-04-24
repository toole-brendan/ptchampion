package middleware

import (
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
	// We're keeping UsernameContextKey but removing UserIDContextKey as we'll use "user_id" directly
	UsernameContextKey ContextKey = "username"
)

// JWTAuthMiddleware creates a middleware for JWT token verification using Echo framework
func JWTAuthMiddleware(accessSecret, refreshSecret string, refreshStore redis.RefreshStore) echo.MiddlewareFunc {
	tokenService := auth.NewTokenService(accessSecret, refreshSecret, refreshStore)

	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			// Extract the token from the Authorization header
			authHeader := c.Request().Header.Get("Authorization")
			if authHeader == "" {
				return echo.NewHTTPError(http.StatusUnauthorized, "Authorization header is required")
			}

			// Check for Bearer token
			parts := strings.Split(authHeader, " ")
			if len(parts) != 2 || parts[0] != "Bearer" {
				return echo.NewHTTPError(http.StatusUnauthorized, "Authorization header must be Bearer token")
			}

			tokenString := parts[1]
			if tokenString == "" {
				return echo.NewHTTPError(http.StatusUnauthorized, "Token is required")
			}

			// Verify the token - first check token type before full validation
			claims, err := tokenService.ValidateAccessToken(tokenString)
			if err != nil {
				return echo.NewHTTPError(http.StatusUnauthorized, "Invalid or expired token")
			}

			// Parse the user ID string to int32 for compatibility with handlers
			userIDInt, err := strconv.ParseInt(claims.UserID, 10, 32)
			if err != nil {
				return echo.NewHTTPError(http.StatusUnauthorized, "Invalid user ID in token")
			}

			// Set user_id as int32 with snake-case key for handlers
			c.Set("user_id", int32(userIDInt))

			// Set username in context for handlers to access
			c.Set(string(UsernameContextKey), claims.Subject)

			return next(c)
		}
	}
}

// GetUserID extracts the user ID from the context
func GetUserID(c echo.Context) (int32, bool) {
	// Updated to return int32 instead of string
	userID, ok := c.Get("user_id").(int32)
	return userID, ok
}

// GetUsername extracts the username from the context
func GetUsername(c echo.Context) (string, bool) {
	username, ok := c.Get(string(UsernameContextKey)).(string)
	return username, ok
}
