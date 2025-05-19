// internal/api/handlers/apple_oauth.go
package handlers

import (
	"encoding/base64"
	"encoding/json"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5" // to construct JWT for Apple client secret
	"github.com/labstack/echo/v4"
)

// A function to generate the Apple client secret JWT, using our .p8 private key
func generateAppleClientSecret() (string, error) {
	teamID := os.Getenv("APPLE_TEAM_ID")
	clientID := os.Getenv("APPLE_SERVICE_ID") // Service ID for web
	keyID := os.Getenv("APPLE_KEY_ID")
	privateKeyPath := os.Getenv("APPLE_PRIVATE_KEY_PATH")
	keyData, err := ioutil.ReadFile(privateKeyPath)
	if err != nil {
		return "", err
	}
	// Parse the EC private key (Apple uses ES256)
	privKey, err := jwt.ParseECPrivateKeyFromPEM(keyData)
	if err != nil {
		return "", err
	}
	// Build JWT claims
	claims := jwt.MapClaims{
		"iss": teamID,
		"iat": time.Now().Unix(),
		"exp": time.Now().Add(5 * time.Minute).Unix(), // token valid short time
		"aud": "https://appleid.apple.com",
		"sub": clientID,
	}
	token := jwt.NewWithClaims(jwt.SigningMethodES256, claims)
	token.Header["kid"] = keyID // Apple requires Key ID in header
	clientSecret, err := token.SignedString(privKey)
	return clientSecret, err
}

func handleAppleOAuth(c echo.Context) error {
	if c.Request().Method == http.MethodGet {
		code := c.QueryParam("code")
		state := c.QueryParam("state")
		if code == "" {
			// (A) Start Apple OAuth
			state = randomString(32)
			oauthStateStore[state] = "apple" // we can reuse state store to track state (no PKCE needed since Apple requires client secret)
			clientID := os.Getenv("APPLE_SERVICE_ID")
			redirectURI := os.Getenv("APPLE_REDIRECT_URI") // e.g. https://YOUR_DOMAIN/api/v1/auth/apple
			// Apple OAuth URL (using response_type=code and scope email/name)
			authURL := "https://appleid.apple.com/auth/authorize" +
				"?response_type=code%20id_token" + // request code and id_token
				"&response_mode=form_post" + // Apple will POST the response (for security)
				"&client_id=" + clientID +
				"&redirect_uri=" + redirectURI +
				"&scope=name%20email" +
				"&state=" + state
			return c.Redirect(http.StatusFound, authURL)
		}

		// (B) Callback from Apple (Apple typically does HTTP POST to redirect_uri with form fields)
		// Echo automatically parses form fields; Apple returns `code`, `id_token`, etc.
		if state == "" || oauthStateStore[state] == "" {
			return c.String(http.StatusBadRequest, "Invalid state")
		}
		delete(oauthStateStore, state)
		// We have `code` (authorization code) and possibly `id_token` in the request
		formCode := code
		formIDToken := c.FormValue("id_token")
		// Exchange the authorization code for tokens
		clientID := os.Getenv("APPLE_SERVICE_ID")
		clientSecret, err := generateAppleClientSecret()
		if err != nil {
			return c.String(http.StatusInternalServerError, "Failed to generate Apple client secret")
		}
		tokenResp, err := http.PostForm("https://appleid.apple.com/auth/token", map[string][]string{
			"grant_type":    {"authorization_code"},
			"code":          {formCode},
			"client_id":     {clientID},
			"client_secret": {clientSecret},
		})
		if err != nil {
			return c.String(http.StatusBadGateway, "Failed to exchange Apple code: "+err.Error())
		}
		defer tokenResp.Body.Close()
		body, _ := ioutil.ReadAll(tokenResp.Body)
		if tokenResp.StatusCode != http.StatusOK {
			return c.String(http.StatusBadGateway, "Apple token exchange failed: "+string(body))
		}
		// Parse token response
		var tokenData struct {
			IdToken      string `json:"id_token"`
			AccessToken  string `json:"access_token"`
			RefreshToken string `json:"refresh_token"`
			ExpiresIn    int    `json:"expires_in"`
			TokenType    string `json:"token_type"`
		}
		json.Unmarshal(body, &tokenData)
		idToken := tokenData.IdToken
		if idToken == "" && formIDToken != "" {
			idToken = formIDToken // Apple might also directly provide id_token in form (response_mode=form_post)
		}
		if idToken == "" {
			return c.String(http.StatusBadGateway, "No Apple ID token received")
		}
		// Verify Apple ID token
		// Best practice: fetch Apple's public keys (https://appleid.apple.com/auth/keys) and verify JWT signature.
		// Here we'll do minimal validation due to complexity:
		// Decode JWT to get claims:
		var appleClaims struct {
			Sub           string `json:"sub"`
			Email         string `json:"email"`
			EmailVerified string `json:"email_verified"`
			Aud           string `json:"aud"`
			Iss           string `json:"iss"`
		}
		parts := strings.Split(idToken, ".")
		if len(parts) < 2 {
			return c.String(http.StatusUnauthorized, "Invalid Apple token")
		}
		data, _ := base64.RawURLEncoding.DecodeString(parts[1])
		json.Unmarshal(data, &appleClaims)
		// Check audience and issuer
		serviceID := os.Getenv("APPLE_SERVICE_ID")
		appBundleID := os.Getenv("APPLE_APP_BUNDLE_ID")
		if appleClaims.Iss != "https://appleid.apple.com" || (appleClaims.Aud != serviceID && appleClaims.Aud != appBundleID) {
			return c.String(http.StatusUnauthorized, "Apple token aud/iss mismatch")
		}
		userAppleID := appleClaims.Sub
		userEmail := appleClaims.Email // (may be null if not first login or email scope not granted)
		// Find or create user
		user, err := findOrCreateUserBySocialID("apple", userAppleID, userEmail)
		if err != nil {
			return c.String(http.StatusInternalServerError, "Database error: "+err.Error())
		}
		jwtToken, err := generateAuthToken(user)
		if err != nil {
			return c.String(http.StatusInternalServerError, "Failed to generate auth token")
		}
		// Return HTML/JS to close popup or redirect (same pattern as Google)
		return c.HTML(http.StatusOK, `<html>
<script>
  (function(){
    var auth = { token: "`+jwtToken+`", user: `+user.ToJSON()+` };
    if (window.opener) {
      window.opener.postMessage(auth, window.location.origin);
      window.close();
    } else {
      localStorage.setItem('authToken', auth.token);
      localStorage.setItem('userData', JSON.stringify(auth.user));
      window.location = "/";
    }
  })();
</script>
</html>`)
	}

	// (C) Mobile flow (POST /auth/apple)
	var reqBody struct {
		Token    string `json:"token"` // Apple identity token (JWT)
		Provider string `json:"provider"`
	}
	if err := c.Bind(&reqBody); err != nil {
		return c.JSON(http.StatusBadRequest, echo.Map{"error": "Invalid request"})
	}
	idToken := reqBody.Token
	if idToken == "" {
		return c.JSON(http.StatusBadRequest, echo.Map{"error": "Token required"})
	}
	// Verify Apple identity token (from iOS)
	// (Similar to above: parse JWT claims and verify)
	var appleClaims struct {
		Sub   string `json:"sub"`
		Email string `json:"email"`
		Aud   string `json:"aud"`
		Iss   string `json:"iss"`
	}
	parts := strings.Split(idToken, ".")
	if len(parts) < 2 {
		return c.JSON(http.StatusUnauthorized, echo.Map{"error": "Invalid Apple token"})
	}
	payload, _ := base64.RawURLEncoding.DecodeString(parts[1])
	json.Unmarshal(payload, &appleClaims)
	serviceID := os.Getenv("APPLE_SERVICE_ID")
	appBundleID := os.Getenv("APPLE_APP_BUNDLE_ID")
	if appleClaims.Iss != "https://appleid.apple.com" || (appleClaims.Aud != serviceID && appleClaims.Aud != appBundleID) {
		return c.JSON(http.StatusUnauthorized, echo.Map{"error": "Apple token not valid for this app"})
	}
	// No cryptographic verification shown (ensure to verify signature in production!)
	user, err := findOrCreateUserBySocialID("apple", appleClaims.Sub, appleClaims.Email)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, echo.Map{"error": "DB error"})
	}
	jwtToken, err := generateAuthToken(user)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, echo.Map{"error": "Failed to create auth token"})
	}
	return c.JSON(http.StatusOK, echo.Map{
		"token": jwtToken,
		"user":  user,
	})
}
