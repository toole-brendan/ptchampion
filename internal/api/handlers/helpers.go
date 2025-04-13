package handlers

import (
	"database/sql"
	"errors"
	"time"

	"github.com/labstack/echo/v4"
)

// GetUserIDFromContext retrieves the user ID from the Echo context.
// It assumes the user ID was set by an authentication middleware.
func GetUserIDFromContext(c echo.Context) (int32, error) {
	userIDClaim := c.Get("user_id")
	if userIDClaim == nil {
		return 0, errors.New("user_id not found in context")
	}

	userID, ok := userIDClaim.(int32) // Assert the type to int32
	if !ok {
		// Handle potential type mismatch (e.g., if it was stored as float64 from JWT parsing)
		if floatID, isFloat := userIDClaim.(float64); isFloat {
			userID = int32(floatID)
			ok = true
		} else {
			return 0, errors.New("user_id in context is not of expected type int32")
		}
	}

	return userID, nil
}

// --- Helper functions for nullable types ---

// getNullString safely gets string value from sql.NullString
func getNullString(ns sql.NullString) string {
	if ns.Valid {
		return ns.String
	}
	return ""
}

// getNullTime safely gets time.Time value from sql.NullTime
func getNullTime(nt sql.NullTime) time.Time {
	if nt.Valid {
		return nt.Time
	}
	return time.Time{} // Return zero time
}

// int32PtrToNullInt32 converts a *int32 to sql.NullInt32.
func int32PtrToNullInt32(ptr *int32) sql.NullInt32 {
	if ptr == nil {
		return sql.NullInt32{}
	}
	return sql.NullInt32{Int32: *ptr, Valid: true}
}

// stringPtrToNullString converts a *string to sql.NullString.
func stringPtrToNullString(ptr *string) sql.NullString {
	if ptr == nil {
		return sql.NullString{}
	}
	return sql.NullString{String: *ptr, Valid: true}
}

// nullInt32ToInt32Ptr converts sql.NullInt32 to *int32.
func nullInt32ToInt32Ptr(ni sql.NullInt32) *int32 {
	if !ni.Valid {
		return nil
	}
	val := ni.Int32
	return &val
}

// nullStringToStringPtr converts sql.NullString to *string.
func nullStringToStringPtr(ns sql.NullString) *string {
	if !ns.Valid {
		return nil
	}
	val := ns.String
	return &val
}

// DerefString safely dereferences a *string, returning "" if nil
func DerefString(s *string) string {
	if s == nil {
		return ""
	}
	return *s
}

// NullTimeToRFC3339StringPtr converts sql.NullTime to a pointer to an RFC3339 formatted string
func NullTimeToRFC3339StringPtr(nt sql.NullTime) *string {
	if !nt.Valid {
		return nil
	}
	formatted := nt.Time.Format(time.RFC3339)
	return &formatted
}

// NullStringToStringPtr converts sql.NullString to *string
func NullStringToStringPtr(ns sql.NullString) *string {
	if !ns.Valid {
		return nil
	}
	val := ns.String // Create a new variable to take the address of
	return &val
}
