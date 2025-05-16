// If file doesn't exist, create it with placeholders for social login endpoints

package routes

import (
	"database/sql"
	"fmt"
	"net/http"

	"github.com/labstack/echo/v4"

	"ptchampion/internal/auth"
	"ptchampion/internal/config"
	"ptchampion/internal/logging"
	"ptchampion/internal/store"
)

// SocialAuthRequest represents the request body for social authentication
type SocialAuthRequest struct {
	Provider string `json:"provider"`
	Token    string `json:"token"`
	Code     string `json:"code,omitempty"`
}

// SocialAuthHandler handles social authentication endpoints
type SocialAuthHandler struct {
	userStore         store.UserStore
	tokenService      *auth.TokenService
	socialAuthService *auth.SocialAuthService
	config            *config.Config
	logger            logging.Logger
}

// NewSocialAuthHandler creates a new social auth handler
func NewSocialAuthHandler(
	userStore store.UserStore,
	tokenService *auth.TokenService,
	socialAuthService *auth.SocialAuthService,
	config *config.Config,
	logger logging.Logger,
) *SocialAuthHandler {
	return &SocialAuthHandler{
		userStore:         userStore,
		tokenService:      tokenService,
		socialAuthService: socialAuthService,
		config:            config,
		logger:            logger,
	}
}

// RegisterSocialAuthRoutes registers routes for social authentication
func RegisterSocialAuthRoutes(g *echo.Group, handler *SocialAuthHandler) {
	g.POST("/google", handler.HandleGoogleAuth)
	g.POST("/apple", handler.HandleAppleAuth)
}

// HandleGoogleAuth handles Google OAuth authentication
func (h *SocialAuthHandler) HandleGoogleAuth(c echo.Context) error {
	var req SocialAuthRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request payload"})
	}

	// Verify the Google ID token
	socialUser, err := h.socialAuthService.VerifyGoogleToken(req.Token)
	if err != nil {
		h.logger.Error(c.Request().Context(), "Google token verification failed", err)
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": "Invalid Google token"})
	}

	// Check if the user exists in our database
	user, err := h.userStore.GetUserByEmail(c.Request().Context(), socialUser.Email)
	if err != nil {
		if err != sql.ErrNoRows {
			h.logger.Error(c.Request().Context(), "Database error when checking for existing user", err)
			return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Internal server error"})
		}

		// User doesn't exist, create a new user
		newUser := &store.User{
			Email:             socialUser.Email,
			FirstName:         socialUser.FirstName,
			LastName:          socialUser.LastName,
			Username:          socialUser.Email, // Default to email as username
			Provider:          "google",
			ProviderId:        socialUser.ID,
			ProfilePictureURL: socialUser.Picture,
			EmailVerified:     socialUser.EmailVerified,
		}

		// Create user in the database
		createdUser, err := h.userStore.CreateUser(c.Request().Context(), newUser)
		if err != nil {
			h.logger.Error(c.Request().Context(), "Failed to create user from Google auth", err)
			return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to create user account"})
		}

		user = createdUser
	} else {
		// User exists, update their provider details if needed
		if user.Provider != "google" || user.ProviderId != socialUser.ID {
			user.Provider = "google"
			user.ProviderId = socialUser.ID
			user.ProfilePictureURL = socialUser.Picture
			user.EmailVerified = socialUser.EmailVerified

			// Update user in the database
			_, err = h.userStore.UpdateUser(c.Request().Context(), user)
			if err != nil {
				h.logger.Error(c.Request().Context(), "Failed to update user provider details", err)
				// Continue anyway, this is not a critical error
			}
		}
	}

	// Generate JWT token
	tokenPair, err := h.tokenService.GenerateTokenPair(c.Request().Context(), user.ID)
	if err != nil {
		h.logger.Error(c.Request().Context(), "Failed to generate JWT token", err)
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to generate authentication token"})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"token":         tokenPair.AccessToken,
		"refresh_token": tokenPair.RefreshToken,
		"expires_at":    tokenPair.AccessTokenExpiresAt,
		"user": map[string]interface{}{
			"id":         user.ID,
			"email":      user.Email,
			"first_name": user.FirstName,
			"last_name":  user.LastName,
			"username":   user.Username,
		},
	})
}

// HandleAppleAuth handles Apple OAuth authentication
func (h *SocialAuthHandler) HandleAppleAuth(c echo.Context) error {
	var req SocialAuthRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request payload"})
	}

	// Verify the Apple ID token
	socialUser, err := h.socialAuthService.VerifyAppleToken(req.Token)
	if err != nil {
		h.logger.Error(c.Request().Context(), "Apple token verification failed", err)
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": "Invalid Apple token"})
	}

	// For Apple Sign-In, the email might not be available on subsequent sign-ins
	// So we need to find the user by their Apple provider ID first
	var user *store.User
	if socialUser.ID != "" {
		user, err = h.userStore.GetUserByProviderID(c.Request().Context(), "apple", socialUser.ID)
		if err != nil && err != sql.ErrNoRows {
			h.logger.Error(c.Request().Context(), "Database error when checking for existing user by provider ID", err)
			return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Internal server error"})
		}
	}

	// If not found by provider ID and we have an email, try by email
	if user == nil && socialUser.Email != "" {
		user, err = h.userStore.GetUserByEmail(c.Request().Context(), socialUser.Email)
		if err != nil && err != sql.ErrNoRows {
			h.logger.Error(c.Request().Context(), "Database error when checking for existing user by email", err)
			return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Internal server error"})
		}
	}

	// If user still not found, create a new user
	if user == nil {
		// Parse first name and last name, if provided in the authorization response
		firstName := socialUser.FirstName
		lastName := socialUser.LastName

		// If email is missing (which can happen with Apple Sign-In), generate a placeholder
		email := socialUser.Email
		if email == "" {
			email = fmt.Sprintf("apple.%s@example.com", socialUser.ID)
		}

		// Create a new user
		newUser := &store.User{
			Email:         email,
			FirstName:     firstName,
			LastName:      lastName,
			Username:      email, // Default to email as username
			Provider:      "apple",
			ProviderId:    socialUser.ID,
			EmailVerified: socialUser.EmailVerified,
		}

		// Create user in the database
		createdUser, err := h.userStore.CreateUser(c.Request().Context(), newUser)
		if err != nil {
			h.logger.Error(c.Request().Context(), "Failed to create user from Apple auth", err)
			return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to create user account"})
		}

		user = createdUser
	} else {
		// User exists, update their provider details if needed
		if user.Provider != "apple" || user.ProviderId != socialUser.ID {
			user.Provider = "apple"
			user.ProviderId = socialUser.ID
			user.EmailVerified = socialUser.EmailVerified

			// Update user in the database
			_, err = h.userStore.UpdateUser(c.Request().Context(), user)
			if err != nil {
				h.logger.Error(c.Request().Context(), "Failed to update user provider details", err)
				// Continue anyway, this is not a critical error
			}
		}
	}

	// Generate JWT token
	tokenPair, err := h.tokenService.GenerateTokenPair(c.Request().Context(), user.ID)
	if err != nil {
		h.logger.Error(c.Request().Context(), "Failed to generate JWT token", err)
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to generate authentication token"})
	}

	return c.JSON(http.StatusOK, map[string]interface{}{
		"token":         tokenPair.AccessToken,
		"refresh_token": tokenPair.RefreshToken,
		"expires_at":    tokenPair.AccessTokenExpiresAt,
		"user": map[string]interface{}{
			"id":         user.ID,
			"email":      user.Email,
			"first_name": user.FirstName,
			"last_name":  user.LastName,
			"username":   user.Username,
		},
	})
}
