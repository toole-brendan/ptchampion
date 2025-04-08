package handlers

import (
	"database/sql"
	"time"
)

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

// int32PtrToNullInt32 converts *int32 to sql.NullInt32
func int32PtrToNullInt32(i *int32) sql.NullInt32 {
	if i == nil {
		return sql.NullInt32{Valid: false}
	}
	return sql.NullInt32{Int32: *i, Valid: true}
}

// stringPtrToNullString converts *string to sql.NullString
func stringPtrToNullString(s *string) sql.NullString {
	if s == nil {
		return sql.NullString{Valid: false}
	}
	return sql.NullString{String: *s, Valid: true}
}

// nullInt32ToInt32Ptr converts sql.NullInt32 to *int32
func nullInt32ToInt32Ptr(ni sql.NullInt32) *int32 {
	if !ni.Valid {
		return nil
	}
	val := ni.Int32 // Create a new variable to take the address of
	return &val
}

// nullStringToStringPtr converts sql.NullString to *string
func nullStringToStringPtr(ns sql.NullString) *string {
	if !ns.Valid {
		return nil
	}
	val := ns.String // Create a new variable to take the address of
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
