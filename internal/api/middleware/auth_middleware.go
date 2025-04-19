package middleware

import (
	"net/http"
	"strings"

	"ptchampion/internal/auth"

	"github.com/labstack/echo/v4"
)

// ContextKey is a custom type for context keys to avoid collisions
type ContextKey string

const (
	UserIDContextKey   ContextKey = "userID"
	UsernameContextKey ContextKey = "username"
)

// JWTAuthMiddleware creates a middleware for JWT token verification using Echo framework
func JWTAuthMiddleware(accessSecret, refreshSecret string) echo.MiddlewareFunc {
	tokenService := auth.NewTokenService(accessSecret, refreshSecret)

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

			// Verify the token
			claims, err := tokenService.VerifyAccessToken(tokenString)
			if err != nil {
				return echo.NewHTTPError(http.StatusUnauthorized, "Invalid or expired token")
			}

			// Set user ID and username in context for handlers to access
			c.Set(string(UserIDContextKey), claims.UserID)
			c.Set(string(UsernameContextKey), claims.Username)

			return next(c)
		}
	}
}

// GetUserID extracts the user ID from the context
func GetUserID(c echo.Context) (int64, bool) {
	userID, ok := c.Get(string(UserIDContextKey)).(int64)
	return userID, ok
}

// GetUsername extracts the username from the context
func GetUsername(c echo.Context) (string, bool) {
	username, ok := c.Get(string(UsernameContextKey)).(string)
	return username, ok
}
