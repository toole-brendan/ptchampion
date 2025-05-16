// internal/api/handlers/google_oauth.go
package handlers

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"io/ioutil"
	"net/http"
	"os"

	"github.com/labstack/echo/v4"
)

// In-memory state store (state -> codeVerifier) for PKCE (in production, use a shared cache or signed cookies)
var oauthStateStore = map[string]string{}

// Utility to generate random string of given length
func randomString(n int) string {
	b := make([]byte, n)
	rand.Read(b)
	// URL-safe base64 encode (without padding)
	return base64.RawURLEncoding.EncodeToString(b)[:n]
}

// GET /auth/google  (start or callback)
func handleGoogleOAuth(c echo.Context) error {
	if c.Request().Method == http.MethodGet {
		// Check if this is a redirect callback from Google
		code := c.QueryParam("code")
		state := c.QueryParam("state")
		if code == "" {
			// (A) Start OAuth flow: generate state + PKCE, redirect to Google
			// Generate state token
			state = randomString(32)
			// Generate PKCE code verifier & challenge
			codeVerifier := randomString(64)
			h := sha256.Sum256([]byte(codeVerifier))
			codeChallenge := base64.RawURLEncoding.EncodeToString(h[:])
			// Store verifier by state
			oauthStateStore[state] = codeVerifier

			// Build Google Auth URL
			clientID := os.Getenv("GOOGLE_WEB_CLIENT_ID")
			redirectURI := os.Getenv("GOOGLE_REDIRECT_URI") // e.g. "https://yourdomain/api/v1/auth/google"
			authURL := "https://accounts.google.com/o/oauth2/v2/auth" +
				"?response_type=code" +
				"&client_id=" + clientID +
				"&redirect_uri=" + redirectURI +
				"&scope=openid%20email%20profile" +
				"&state=" + state +
				"&code_challenge=" + codeChallenge +
				"&code_challenge_method=S256"
			return c.Redirect(http.StatusFound, authURL)
		}

		// (B) OAuth Callback: Google redirected back with ?code= and ?state=
		if state == "" || oauthStateStore[state] == "" {
			return c.String(http.StatusBadRequest, "Invalid state") // state missing or not found
		}
		// Verify state and get code verifier
		codeVerifier := oauthStateStore[state]
		delete(oauthStateStore, state) // one-time use

		// Exchange code for tokens at Google Token endpoint
		tokenResp, err := http.PostForm("https://oauth2.googleapis.com/token", map[string][]string{
			"code":          {code},
			"client_id":     {os.Getenv("GOOGLE_WEB_CLIENT_ID")},
			"client_secret": {os.Getenv("GOOGLE_WEB_CLIENT_SECRET")},
			"redirect_uri":  {os.Getenv("GOOGLE_REDIRECT_URI")},
			"grant_type":    {"authorization_code"},
			"code_verifier": {codeVerifier},
		})
		if err != nil {
			return c.String(http.StatusInternalServerError, "Failed to exchange code: "+err.Error())
		}
		defer tokenResp.Body.Close()
		body, _ := ioutil.ReadAll(tokenResp.Body)
		if tokenResp.StatusCode != http.StatusOK {
			return c.String(http.StatusBadGateway, "Token exchange failed: "+string(body))
		}
		// Parse token JSON (contains id_token, access_token, etc.)
		var tokenData struct {
			IdToken      string `json:"id_token"`
			AccessToken  string `json:"access_token"`
			RefreshToken string `json:"refresh_token"`
			ExpiresIn    int    `json:"expires_in"`
			TokenType    string `json:"token_type"`
		}
		json.Unmarshal(body, &tokenData)
		idToken := tokenData.IdToken

		// Verify Google ID token (signature & claims)
		// **Best practice**: use Google's certs or their OAuth2 library to verify JWT.
		// Here, for brevity, we perform minimal checks:
		if idToken == "" {
			return c.String(http.StatusBadGateway, "No ID token received")
		}
		// (Pseudo-code for verification; in production use a JWT library + Google's public keys)
		// e.g., parse JWT header to get kid, fetch Google's cert, verify signature...
		// Simplified: call Google's tokeninfo endpoint to validate (not ideal for production, but okay for initial testing):
		resp, _ := http.Get("https://oauth2.googleapis.com/tokeninfo?id_token=" + idToken)
		if resp == nil || resp.StatusCode != 200 {
			return c.String(http.StatusUnauthorized, "Invalid Google ID token")
		}
		// Optional: parse token claims to get user info
		var claims struct {
			Sub           string `json:"sub"`
			Email         string `json:"email"`
			EmailVerified string `json:"email_verified"`
			Name          string `json:"name"`
			Picture       string `json:"picture"`
			Aud           string `json:"aud"`
			Iss           string `json:"iss"`
		}
		json.NewDecoder(resp.Body).Decode(&claims)
		resp.Body.Close()
		// Security: Check audience and issuer
		allowedAudiences := map[string]bool{
			os.Getenv("GOOGLE_WEB_CLIENT_ID"): true,
			os.Getenv("GOOGLE_IOS_CLIENT_ID"): true,
		}
		if !allowedAudiences[claims.Aud] || claims.Iss != "accounts.google.com" {
			return c.String(http.StatusUnauthorized, "Google token aud/iss mismatch")
		}
		// At this point, the token is valid and comes from Google.
		userGoogleID := claims.Sub
		userEmail := claims.Email

		// Find or create user in DB by Google ID
		user, err := findOrCreateUserBySocialID("google", userGoogleID, userEmail)
		if err != nil {
			return c.String(http.StatusInternalServerError, "Database error: "+err.Error())
		}
		// Generate our own JWT for the user
		jwtToken, err := generateAuthToken(user) // assume this creates a signed JWT for our app
		if err != nil {
			return c.String(http.StatusInternalServerError, "Failed to generate auth token")
		}
		// If this is a popup window, we want to send the token to the opener; otherwise, redirect
		// Serve a tiny HTML page with JS to communicate the result:
		return c.HTML(http.StatusOK, `<html>
<script>
  (function(){
    var auth = { token: "`+jwtToken+`", user: `+user.ToJSON()+` };
    if (window.opener) {
      window.opener.postMessage(auth, window.location.origin);
      window.close();
    } else {
      // No popup opener: store token and redirect to app
      localStorage.setItem('authToken', auth.token);
      localStorage.setItem('userData', JSON.stringify(auth.user));
      window.location = "/";  // go to homepage or dashboard
    }
  })();
</script>
</html>`)
	}

	// (C) Mobile flow (POST /auth/google with token)
	// Expect JSON body: { "token": "<GoogleIDToken>", "provider": "google" }
	var reqBody struct {
		Token    string `json:"token"`
		Provider string `json:"provider"`
	}
	if err := c.Bind(&reqBody); err != nil {
		return c.String(http.StatusBadRequest, "Invalid request body")
	}
	idToken := reqBody.Token
	if idToken == "" {
		return c.String(http.StatusBadRequest, "Token is required")
	}
	// Verify Google ID token from mobile
	// (Same verification steps as above)
	resp, _ := http.Get("https://oauth2.googleapis.com/tokeninfo?id_token=" + idToken)
	if resp == nil || resp.StatusCode != 200 {
		return c.JSON(http.StatusUnauthorized, echo.Map{"error": "Invalid Google token"})
	}
	var claims struct {
		Sub   string `json:"sub"`
		Email string `json:"email"`
		Aud   string `json:"aud"`
		Iss   string `json:"iss"`
	}
	json.NewDecoder(resp.Body).Decode(&claims)
	resp.Body.Close()

	// Check allowed audiences
	allowedAudiences := map[string]bool{
		os.Getenv("GOOGLE_WEB_CLIENT_ID"): true,
		os.Getenv("GOOGLE_IOS_CLIENT_ID"): true,
	}
	claimsValid := claims.Iss == "accounts.google.com" && allowedAudiences[claims.Aud]
	if !claimsValid {
		return c.JSON(http.StatusUnauthorized, echo.Map{"error": "Google token validation failed"})
	}

	// Get or create user
	user, err := findOrCreateUserBySocialID("google", claims.Sub, claims.Email)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, echo.Map{"error": "DB error"})
	}
	jwtToken, err := generateAuthToken(user)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, echo.Map{"error": "Token generation failed"})
	}
	// Return AuthResponse (token + user info) as JSON
	return c.JSON(http.StatusOK, echo.Map{
		"token": jwtToken,
		"user":  user, // include user fields per AuthResponse schema
	})
}

// These functions will need to be implemented separately
// findOrCreateUserBySocialID finds a user by social provider ID or creates a new one
func findOrCreateUserBySocialID(provider, providerID, email string) (*User, error) {
	// TODO: Implementation to be added
	// 1. Look up user_social_accounts for provider & providerID
	// 2. If found, return the associated user
	// 3. If not found, create a new user and social account link
	return nil, nil
}

// generateAuthToken creates a JWT token for the user
func generateAuthToken(user *User) (string, error) {
	// TODO: Implementation to be added
	// Generate a JWT token using the user's ID and other claims
	return "", nil
}

// User is a placeholder for the actual User model
type User struct {
	// User fields will be defined elsewhere
}

// ToJSON returns a JSON string representation of the user
func (u *User) ToJSON() string {
	// TODO: Implementation to be added
	return "{}"
}
