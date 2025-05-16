package auth

import (
	"crypto/rsa"
	"crypto/x509"
	"encoding/base64"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"io/ioutil"
	"math/big"
	"net/http"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"ptchampion/internal/config"
	"ptchampion/internal/logging"
)

// SocialAuthProvider represents a social authentication provider
type SocialAuthProvider string

const (
	GoogleProvider SocialAuthProvider = "google"
	AppleProvider  SocialAuthProvider = "apple"
)

// SocialAuthRequest represents a request for social authentication
type SocialAuthRequest struct {
	Provider SocialAuthProvider `json:"provider"`
	Token    string             `json:"token"`          // ID token from the provider
	Code     string             `json:"code,omitempty"` // Authorization code (used for Apple)
}

// SocialUser represents user data from a social provider
type SocialUser struct {
	ID            string `json:"id"`
	Email         string `json:"email"`
	EmailVerified bool   `json:"email_verified"`
	Name          string `json:"name,omitempty"`
	FirstName     string `json:"first_name,omitempty"`
	LastName      string `json:"last_name,omitempty"`
	Picture       string `json:"picture,omitempty"`
}

// SocialAuthService handles social authentication (Google, Apple, etc.)
type SocialAuthService struct {
	config *config.Config
	logger logging.Logger
}

// NewSocialAuthService creates a new social authentication service
func NewSocialAuthService(config *config.Config, logger logging.Logger) *SocialAuthService {
	return &SocialAuthService{
		config: config,
		logger: logger,
	}
}

// VerifyGoogleToken validates a Google ID token and extracts user information
func (s *SocialAuthService) VerifyGoogleToken(idToken string) (*SocialUser, error) {
	// Google's token verification endpoint
	url := fmt.Sprintf("https://oauth2.googleapis.com/tokeninfo?id_token=%s", idToken)

	resp, err := http.Get(url)
	if err != nil {
		s.logger.Error(nil, "Failed to verify Google token", err)
		return nil, fmt.Errorf("failed to verify token: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		s.logger.Error(nil, "Google token verification failed", fmt.Errorf("status code: %d", resp.StatusCode))
		return nil, errors.New("invalid token")
	}

	var tokenInfo struct {
		Sub           string `json:"sub"` // User ID
		Email         string `json:"email"`
		EmailVerified string `json:"email_verified"` // "true" or "false"
		Name          string `json:"name,omitempty"`
		GivenName     string `json:"given_name,omitempty"`
		FamilyName    string `json:"family_name,omitempty"`
		Picture       string `json:"picture,omitempty"`
		Aud           string `json:"aud"` // Client ID
	}

	if err := json.NewDecoder(resp.Body).Decode(&tokenInfo); err != nil {
		s.logger.Error(nil, "Failed to decode Google token info", err)
		return nil, fmt.Errorf("failed to decode token info: %w", err)
	}

	// Validate client ID (audience)
	validAudience := false
	validAuds := []string{s.config.GoogleOAuth.WebClientID, s.config.GoogleOAuth.IOSClientID}
	for _, aud := range validAuds {
		if tokenInfo.Aud == aud {
			validAudience = true
			break
		}
	}

	if !validAudience {
		s.logger.Error(nil, "Invalid Google token audience", fmt.Errorf("invalid aud: %s", tokenInfo.Aud))
		return nil, errors.New("invalid token audience")
	}

	// Convert email_verified from string to bool
	emailVerified := tokenInfo.EmailVerified == "true"

	user := &SocialUser{
		ID:            tokenInfo.Sub,
		Email:         tokenInfo.Email,
		EmailVerified: emailVerified,
		Name:          tokenInfo.Name,
		FirstName:     tokenInfo.GivenName,
		LastName:      tokenInfo.FamilyName,
		Picture:       tokenInfo.Picture,
	}

	return user, nil
}

// VerifyAppleToken validates an Apple ID token and extracts user information
func (s *SocialAuthService) VerifyAppleToken(idToken string) (*SocialUser, error) {
	// Parse the JWT
	token, err := jwt.Parse(idToken, func(token *jwt.Token) (interface{}, error) {
		// Apple uses RS256
		if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}

		// Apple provides these keys at their JWKS endpoint
		// In a production app, you should cache these keys and refresh periodically
		keys, err := s.fetchApplePublicKeys()
		if err != nil {
			return nil, err
		}

		// Find the key that matches the key ID in the token header
		kid, ok := token.Header["kid"].(string)
		if !ok {
			return nil, errors.New("kid header not found in token")
		}

		if key, ok := keys[kid]; ok {
			return key, nil
		}

		return nil, errors.New("matching key not found")
	})

	if err != nil {
		s.logger.Error(nil, "Failed to parse Apple token", err)
		return nil, fmt.Errorf("invalid token: %w", err)
	}

	if !token.Valid {
		s.logger.Error(nil, "Invalid Apple token", errors.New("token validation failed"))
		return nil, errors.New("invalid token")
	}

	// Extract claims
	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		s.logger.Error(nil, "Failed to extract claims from Apple token", errors.New("invalid claims"))
		return nil, errors.New("invalid token claims")
	}

	// Validate issuer (iss) - should be "https://appleid.apple.com"
	if iss, ok := claims["iss"].(string); !ok || iss != "https://appleid.apple.com" {
		s.logger.Error(nil, "Invalid Apple token issuer", fmt.Errorf("invalid iss: %v", claims["iss"]))
		return nil, errors.New("invalid token issuer")
	}

	// Validate audience (aud) - should match our Service ID
	validAudience := false
	if aud, ok := claims["aud"].(string); ok {
		if aud == s.config.AppleOAuth.ServiceID || aud == s.config.AppleOAuth.AppBundleID {
			validAudience = true
		}
	}

	if !validAudience {
		s.logger.Error(nil, "Invalid Apple token audience", fmt.Errorf("invalid aud: %v", claims["aud"]))
		return nil, errors.New("invalid token audience")
	}

	// Extract user information
	sub, _ := claims["sub"].(string) // User ID
	email, _ := claims["email"].(string)
	emailVerified := false
	if ev, ok := claims["email_verified"].(bool); ok {
		emailVerified = ev
	}

	// Name might be in a separate payload for first-time sign-ins
	firstName := ""
	lastName := ""

	user := &SocialUser{
		ID:            sub,
		Email:         email,
		EmailVerified: emailVerified,
		FirstName:     firstName,
		LastName:      lastName,
	}

	return user, nil
}

// fetchApplePublicKeys retrieves the public keys from Apple's JWKS endpoint
func (s *SocialAuthService) fetchApplePublicKeys() (map[string]interface{}, error) {
	resp, err := http.Get("https://appleid.apple.com/auth/keys")
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("failed to fetch Apple public keys: %d", resp.StatusCode)
	}

	var jwks struct {
		Keys []struct {
			Kty string `json:"kty"`
			Kid string `json:"kid"`
			Use string `json:"use"`
			Alg string `json:"alg"`
			N   string `json:"n"`
			E   string `json:"e"`
		} `json:"keys"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&jwks); err != nil {
		return nil, err
	}

	keys := make(map[string]interface{})

	for _, key := range jwks.Keys {
		if key.Kty != "RSA" || key.Alg != "RS256" {
			continue
		}

		// Decode the base64 modulus and exponent
		n, err := base64.RawURLEncoding.DecodeString(key.N)
		if err != nil {
			continue
		}

		e, err := base64.RawURLEncoding.DecodeString(key.E)
		if err != nil {
			continue
		}

		// Convert to *rsa.PublicKey
		publicKey := &rsa.PublicKey{
			N: new(big.Int).SetBytes(n),
			E: int(new(big.Int).SetBytes(e).Int64()),
		}

		keys[key.Kid] = publicKey
	}

	return keys, nil
}

// GenerateAppleClientSecret creates a client secret JWT for Apple API requests
func (s *SocialAuthService) GenerateAppleClientSecret() (string, error) {
	// Read the private key file
	keyData, err := ioutil.ReadFile(s.config.AppleOAuth.PrivateKeyPath)
	if err != nil {
		return "", fmt.Errorf("failed to read private key: %w", err)
	}

	// Parse the private key
	block, _ := pem.Decode(keyData)
	if block == nil {
		return "", errors.New("failed to parse PEM block containing the key")
	}

	privateKey, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		return "", fmt.Errorf("failed to parse private key: %w", err)
	}

	rsaKey, ok := privateKey.(*rsa.PrivateKey)
	if !ok {
		return "", errors.New("key is not a valid RSA private key")
	}

	// Current time and expiry (10 minutes)
	now := time.Now()
	exp := now.Add(10 * time.Minute)

	// Create the JWT claims
	claims := jwt.MapClaims{
		"iss": s.config.AppleOAuth.TeamID,
		"iat": now.Unix(),
		"exp": exp.Unix(),
		"aud": "https://appleid.apple.com",
		"sub": s.config.AppleOAuth.ServiceID,
	}

	// Create the token with claims
	token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
	token.Header["kid"] = s.config.AppleOAuth.KeyID

	// Sign the token with the private key
	clientSecret, err := token.SignedString(rsaKey)
	if err != nil {
		return "", fmt.Errorf("failed to sign client secret: %w", err)
	}

	return clientSecret, nil
}
