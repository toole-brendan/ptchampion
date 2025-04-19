package middleware

import (
	"crypto/rand"
	"encoding/base64"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

// generateNonce creates a random nonce for CSP
func generateNonce() string {
	b := make([]byte, 16)
	_, err := rand.Read(b)
	if err != nil {
		return ""
	}
	return base64.StdEncoding.EncodeToString(b)
}

// SecurityHeaders adds OWASP recommended security headers to each response
func SecurityHeaders() echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			// Generate a nonce for this request
			nonce := generateNonce()

			// Store the nonce in the context for templates to use
			c.Set("csp-nonce", nonce)

			// Content Security Policy
			c.Response().Header().Set("Content-Security-Policy",
				"default-src 'self'; "+
					"script-src 'self' 'nonce-"+nonce+"'; "+
					"img-src 'self' data:; "+
					"style-src 'self' 'nonce-"+nonce+"'; "+
					"connect-src 'self'; "+
					"frame-ancestors 'none'; "+
					"form-action 'self'")

			// HTTP Strict Transport Security (HSTS)
			c.Response().Header().Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains")

			// X-Content-Type-Options
			c.Response().Header().Set("X-Content-Type-Options", "nosniff")

			// X-Frame-Options
			c.Response().Header().Set("X-Frame-Options", "DENY")

			// X-XSS-Protection
			c.Response().Header().Set("X-XSS-Protection", "1; mode=block")

			// Referrer-Policy
			c.Response().Header().Set("Referrer-Policy", "strict-origin-when-cross-origin")

			// Permissions-Policy
			c.Response().Header().Set("Permissions-Policy", "camera=(), geolocation=(), microphone=()")

			// Cross-Origin-Opener-Policy for stronger isolation
			c.Response().Header().Set("Cross-Origin-Opener-Policy", "same-origin")

			// Cross-Origin-Embedder-Policy
			c.Response().Header().Set("Cross-Origin-Embedder-Policy", "require-corp")

			return next(c)
		}
	}
}

// SecureConfig returns a middleware.SecureConfig with sensible defaults
func SecureConfig() middleware.SecureConfig {
	// NOTE: This function is deprecated; use SecurityHeaders middleware instead
	// which includes nonce-based CSP
	config := middleware.SecureConfig{
		XSSProtection:         "1; mode=block",
		ContentTypeNosniff:    "nosniff",
		XFrameOptions:         "DENY",
		HSTSMaxAge:            31536000,
		HSTSExcludeSubdomains: false,
		ContentSecurityPolicy: "default-src 'self'; script-src 'self'; img-src 'self' data:; style-src 'self'; connect-src 'self';",
		ReferrerPolicy:        "strict-origin-when-cross-origin",
	}
	return config
}

// CORSConfig returns a CORS middleware configuration with secure defaults
func CORSConfig() middleware.CORSConfig {
	return middleware.CORSConfig{
		AllowOrigins:     []string{"https://ptchampion.com", "https://staging.ptchampion.com", "http://localhost:5173"},
		AllowMethods:     []string{echo.GET, echo.PUT, echo.POST, echo.DELETE, echo.OPTIONS},
		AllowHeaders:     []string{echo.HeaderOrigin, echo.HeaderContentType, echo.HeaderAccept, echo.HeaderAuthorization},
		ExposeHeaders:    []string{echo.HeaderContentLength},
		AllowCredentials: true,
		MaxAge:           86400, // 24 hours
	}
}
