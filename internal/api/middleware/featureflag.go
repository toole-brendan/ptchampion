package middleware

import (
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/Flagsmith/flagsmith-go-client/v2"
	"github.com/labstack/echo/v4"
)

// FeatureFlag constants
const (
	FlagGradingFormulaV2     = "grading_formula_v2"
	FlagFineTunedPushupModel = "fine_tuned_pushup_model"
	FlagTeamChallenges       = "team_challenges"
	FlagDarkModeDefault      = "dark_mode_default"
	// Add more feature flags as needed
)

// FeatureFlagConfig holds the configuration for the feature flag middleware
type FeatureFlagConfig struct {
	// Flagsmith API key
	APIKey string
	// Base URL for Flagsmith API (empty for cloud)
	BaseURL string
	// Cache TTL in seconds
	CacheTTL int
	// Default environment for flagsmith identity
	DefaultEnvironment string
}

// FeatureFlagMiddleware manages feature flags using Flagsmith
type FeatureFlagMiddleware struct {
	client     *flagsmith.Client
	config     FeatureFlagConfig
	cache      map[string]cachedFlags
	cacheMutex sync.RWMutex
	lastError  error
}

// cachedFlags represents a cached set of flags for a user/identity
type cachedFlags struct {
	flags      map[string]interface{}
	expiration time.Time
}

// NewFeatureFlagMiddleware creates a new feature flag middleware using Flagsmith
func NewFeatureFlagMiddleware(config FeatureFlagConfig) (*FeatureFlagMiddleware, error) {
	options := []flagsmith.Option{}

	// If a custom URL is provided, use it
	if config.BaseURL != "" {
		options = append(options, flagsmith.WithBaseURL(config.BaseURL))
	}

	// Set default cache TTL if not specified
	if config.CacheTTL <= 0 {
		config.CacheTTL = 300 // 5 minutes
	}

	// Create Flagsmith client
	client := flagsmith.NewClient(config.APIKey, options...)

	return &FeatureFlagMiddleware{
		client: client,
		config: config,
		cache:  make(map[string]cachedFlags),
	}, nil
}

// Middleware adds feature flag context to the request
func (m *FeatureFlagMiddleware) Middleware() echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			// Add feature flag client to context
			c.Set("featureFlagClient", m)

			// Create identity from JWT claims if available
			userID := extractUserID(c)
			if userID != "" {
				// Get user traits if any
				traits := extractUserTraits(c)

				// Add user identity to context
				c.Set("featureFlagIdentity", userID)
				c.Set("featureFlagTraits", traits)
			}

			return next(c)
		}
	}
}

// This extracts user ID from JWT claims
func extractUserID(c echo.Context) string {
	user := c.Get("user")
	if user == nil {
		return ""
	}

	// The exact way to extract user ID depends on your JWT claims structure
	// This is an example and should be adjusted to your needs
	if claims, ok := user.(map[string]interface{}); ok {
		if id, exists := claims["sub"].(string); exists {
			return id
		}
	}

	return ""
}

// This extracts user traits for targeting from JWT claims or other sources
func extractUserTraits(c echo.Context) map[string]interface{} {
	// Example traits - adjust based on your requirements
	traits := make(map[string]interface{})
	user := c.Get("user")
	if user == nil {
		return traits
	}

	// Extract relevant traits from user object
	if claims, ok := user.(map[string]interface{}); ok {
		// Example: map roles or other properties as traits
		if roles, exists := claims["roles"]; exists {
			traits["roles"] = roles
		}
	}

	// Add more traits as needed
	return traits
}

// GetFlag retrieves a feature flag value for the current context
func (m *FeatureFlagMiddleware) GetFlag(c echo.Context, flagName string, defaultValue interface{}) interface{} {
	userID := getUserID(c)

	// For anonymous users or when Flagsmith is unavailable, use defaults
	if userID == "" || m.lastError != nil {
		return defaultValue
	}

	// Check cache first
	if value, ok := m.getFlagFromCache(userID, flagName); ok {
		return value
	}

	// Get flags for this identity
	flags, err := m.getFlagsForUser(userID, extractUserTraits(c))
	if err != nil {
		log.Printf("Error getting feature flags: %v", err)
		m.lastError = err
		return defaultValue
	}

	// Return the flag value or default
	if value, exists := flags[flagName]; exists {
		return value
	}

	return defaultValue
}

// IsFlagEnabled checks if a boolean feature flag is enabled
func (m *FeatureFlagMiddleware) IsFlagEnabled(c echo.Context, flagName string, defaultValue bool) bool {
	value := m.GetFlag(c, flagName, defaultValue)
	if boolValue, ok := value.(bool); ok {
		return boolValue
	}
	return defaultValue
}

// GetFlagString retrieves a string feature flag value
func (m *FeatureFlagMiddleware) GetFlagString(c echo.Context, flagName string, defaultValue string) string {
	value := m.GetFlag(c, flagName, defaultValue)
	if strValue, ok := value.(string); ok {
		return strValue
	}
	return defaultValue
}

// GetFlagNumber retrieves a numeric feature flag value
func (m *FeatureFlagMiddleware) GetFlagNumber(c echo.Context, flagName string, defaultValue float64) float64 {
	value := m.GetFlag(c, flagName, defaultValue)
	if numValue, ok := value.(float64); ok {
		return numValue
	}
	return defaultValue
}

// getFlagsForUser gets all flags for a user, using cache when possible
func (m *FeatureFlagMiddleware) getFlagsForUser(userID string, traits map[string]interface{}) (map[string]interface{}, error) {
	// Check cache first
	if cachedValue, ok := m.getCachedFlags(userID); ok {
		return cachedValue, nil
	}

	// Convert traits map to Flagsmith traits
	flagsmithTraits := make([]*flagsmith.Trait, 0, len(traits))
	for key, value := range traits {
		flagsmithTraits = append(flagsmithTraits, &flagsmith.Trait{
			TraitKey:   key,
			TraitValue: value,
		})
	}

	// Get flags from Flagsmith
	flags, err := m.client.GetIdentityFlags(userID, flagsmithTraits)
	if err != nil {
		return nil, err
	}

	// Convert flags to map and cache them
	flagMap := make(map[string]interface{})
	allFlags := flags.AllFlags()
	for _, flag := range allFlags {
		// Get flag value
		value, err := flags.GetFeatureValue(flag.FeatureName)
		if err != nil {
			// Log error but continue processing other flags
			log.Printf("Error getting feature value for %s: %v", flag.FeatureName, err)
			continue
		}

		// Store the value
		flagMap[flag.FeatureName] = value
	}

	// Cache the flags
	m.cacheFlags(userID, flagMap)

	return flagMap, nil
}

// Get user ID from context
func getUserID(c echo.Context) string {
	if id, ok := c.Get("featureFlagIdentity").(string); ok {
		return id
	}
	return ""
}

// Cache operations
func (m *FeatureFlagMiddleware) cacheFlags(userID string, flags map[string]interface{}) {
	m.cacheMutex.Lock()
	defer m.cacheMutex.Unlock()

	m.cache[userID] = cachedFlags{
		flags:      flags,
		expiration: time.Now().Add(time.Duration(m.config.CacheTTL) * time.Second),
	}
}

func (m *FeatureFlagMiddleware) getCachedFlags(userID string) (map[string]interface{}, bool) {
	m.cacheMutex.RLock()
	defer m.cacheMutex.RUnlock()

	if cached, exists := m.cache[userID]; exists && time.Now().Before(cached.expiration) {
		return cached.flags, true
	}
	return nil, false
}

func (m *FeatureFlagMiddleware) getFlagFromCache(userID string, flagName string) (interface{}, bool) {
	if flags, ok := m.getCachedFlags(userID); ok {
		if value, exists := flags[flagName]; exists {
			return value, true
		}
	}
	return nil, false
}

// GetAllFeatureFlags returns all feature flags for the given context
func (m *FeatureFlagMiddleware) GetAllFeatureFlags(c echo.Context) map[string]interface{} {
	userID := getUserID(c)

	// For anonymous users or when Flagsmith is unavailable, return empty map
	if userID == "" || m.lastError != nil {
		return make(map[string]interface{})
	}

	// Get all flags for this identity
	flags, err := m.getFlagsForUser(userID, extractUserTraits(c))
	if err != nil {
		log.Printf("Error getting feature flags: %v", err)
		m.lastError = err
		return make(map[string]interface{})
	}

	return flags
}

// InvalidateCache invalidates the cache for a specific user or all users
func (m *FeatureFlagMiddleware) InvalidateCache(userID string) {
	m.cacheMutex.Lock()
	defer m.cacheMutex.Unlock()

	if userID == "" {
		// Invalidate all cache
		m.cache = make(map[string]cachedFlags)
	} else {
		// Invalidate only specific user
		delete(m.cache, userID)
	}
}

// FeaturesHandler creates an HTTP handler for getting all feature flags
func (m *FeatureFlagMiddleware) FeaturesHandler() echo.HandlerFunc {
	return func(c echo.Context) error {
		flags := m.GetAllFeatureFlags(c)
		return c.JSON(http.StatusOK, map[string]interface{}{
			"features": flags,
		})
	}
}
