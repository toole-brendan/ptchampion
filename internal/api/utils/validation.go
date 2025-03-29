package utils

import (
	"fmt"

	"github.com/go-playground/validator/v10"
)

// Validate holds the shared validator instance.
var Validate = validator.New()

// ValidationErrorResponse creates a user-friendly validation error response map.
func ValidationErrorResponse(err error) map[string]interface{} {
	resp := map[string]interface{}{"error": "Validation failed"} // Default message
	if errs, ok := err.(validator.ValidationErrors); ok {
		fieldErrors := make(map[string]string)
		for _, e := range errs {
			// Use Field() for struct field name, Namespace() for nested path if needed
			fieldName := e.Field() // Use Field() for top-level fields
			message := fmt.Sprintf("Failed validation on rule: '%s'", e.Tag())

			// Add more specific messages based on the tag
			switch e.Tag() {
			case "required":
				message = fmt.Sprintf("Field '%s' is required", fieldName)
			case "min":
				message = fmt.Sprintf("Field '%s' must be at least %s characters long", fieldName, e.Param())
			case "max":
				message = fmt.Sprintf("Field '%s' must be at most %s characters long", fieldName, e.Param())
			case "alphanum":
				message = fmt.Sprintf("Field '%s' must contain only alphanumeric characters", fieldName)
			case "url":
				message = fmt.Sprintf("Field '%s' must be a valid URL", fieldName)
			case "latitude":
				message = fmt.Sprintf("Field '%s' must be a valid latitude", fieldName)
			case "longitude":
				message = fmt.Sprintf("Field '%s' must be a valid longitude", fieldName)
			case "gt":
				message = fmt.Sprintf("Field '%s' must be greater than %s", fieldName, e.Param())
			}
			fieldErrors[fieldName] = message
		}
		resp["details"] = fieldErrors
	}
	return resp
}
