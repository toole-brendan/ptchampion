package middleware

import (
	"context"
	"net/http"

	"github.com/go-chi/jwtauth/v5"
)

// ContextKey is a custom type for context keys to avoid collisions
type ContextKey string

const UserIDContextKey ContextKey = "userID"

// AuthMiddleware creates a new JWT authenticator middleware
func AuthMiddleware(jwtSecret string) func(http.Handler) http.Handler {
	tokenAuth := jwtauth.New("HS256", []byte(jwtSecret), nil)

	verifier := jwtauth.Verifier(tokenAuth)
	authenticator := func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			token, claims, err := jwtauth.FromContext(r.Context())

			if err != nil {
				// Error means token is missing, expired, or signature is invalid
				http.Error(w, "Unauthorized: "+err.Error(), http.StatusUnauthorized)
				return
			}

			if token == nil { // Should not happen if err is nil, but check for safety
				http.Error(w, "Unauthorized: Invalid token", http.StatusUnauthorized)
				return
			}

			// Token is considered valid if we reach here without errors

			// Extract user ID (assuming it's stored in 'sub' claim)
			if userIDFloat, ok := claims["sub"].(float64); ok {
				userID := int32(userIDFloat) // Convert to int32
				ctx := context.WithValue(r.Context(), UserIDContextKey, userID)
				next.ServeHTTP(w, r.WithContext(ctx))
			} else {
				http.Error(w, "Unauthorized: Invalid user ID in token", http.StatusUnauthorized)
				return
			}
		})
	}

	// Return the chained middleware
	return func(next http.Handler) http.Handler {
		return verifier(authenticator(next))
	}
}
