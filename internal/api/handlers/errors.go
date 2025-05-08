package handlers

import (
	"encoding/json"

	"github.com/labstack/echo/v4"
)

// Error codes used in API responses
const (
	ErrCodeBadRequest      = "BAD_REQUEST"
	ErrCodeValidation      = "VALIDATION_FAILED"
	ErrCodeUnauthorized    = "UNAUTHORIZED"
	ErrCodeForbidden       = "FORBIDDEN"
	ErrCodeNotFound        = "NOT_FOUND"
	ErrCodeConflict        = "CONFLICT"
	ErrCodeInternalServer  = "INTERNAL_SERVER_ERROR"
	ErrCodeTokenGeneration = "TOKEN_GENERATION_FAILED"
	ErrCodeDatabase        = "DATABASE_ERROR"
	// Add more specific codes as needed
)

// ErrorDetail represents the structured error details.
type ErrorDetail struct {
	Code    string `json:"code"`
	Message string `json:"message"`
	// Optional: Fields map[string]string `json:"fields,omitempty"` // For validation errors
}

// APIErrorResponse is the standard error response envelope.
type APIErrorResponse struct {
	Error ErrorDetail `json:"error"`
}

// NewAPIError creates an echo.HTTPError with a standardized JSON body
func NewAPIError(statusCode int, code string, message string) *echo.HTTPError {
	apiResp := APIErrorResponse{
		Error: ErrorDetail{
			Code:    code,
			Message: message,
		},
	}
	// Marshal the response to JSON string to store in HTTPError message field
	// The custom error handler will try to unmarshal this.
	jsonBytes, err := json.Marshal(apiResp)
	if err != nil {
		// Fallback if marshalling fails (should not happen with this struct)
		return echo.NewHTTPError(statusCode, `{"error":{"code":"INTERNAL_SERVER_ERROR","message":"Failed to marshal error response"}}`)
	}
	return echo.NewHTTPError(statusCode, string(jsonBytes))
}
