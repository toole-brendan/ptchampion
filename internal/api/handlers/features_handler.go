package handlers

import (
	"net/http"

	"github.com/labstack/echo/v4"
)

// FeaturesHandler returns a simple feature flags response
// This is a fallback when the feature flag middleware isn't initialized
func (h *Handler) FeaturesHandler(c echo.Context) error {
	// Return an empty features object
	return c.JSON(http.StatusOK, map[string]interface{}{
		"features": map[string]interface{}{},
	})
}
