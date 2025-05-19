package logging

import (
	"context"
	"errors"
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"github.com/getsentry/sentry-go"
)

// Logger defines the interface for logging
type Logger interface {
	Debug(ctx context.Context, message string, args ...interface{})
	Info(ctx context.Context, message string, args ...interface{})
	Warn(ctx context.Context, message string, args ...interface{})
	Error(ctx context.Context, message string, args ...interface{})
	Fatal(ctx context.Context, message string, err error, args ...interface{})
}

// Context keys used by logger (assuming these are set by middleware)
const (
	ContextKeyRequestID = "request_id" // Assuming middleware sets this key
	ContextKeyUserID    = "user_id"    // Key used by auth middleware
)

// SimpleLogger is a basic logger implementation using the standard library
type SimpleLogger struct {
	debugLogger *log.Logger
	infoLogger  *log.Logger
	warnLogger  *log.Logger
	errorLogger *log.Logger
	fatalLogger *log.Logger
}

// NewDefaultLogger creates a new SimpleLogger with default settings
func NewDefaultLogger() Logger {
	debugLogger := log.New(os.Stdout, "[DEBUG] ", log.Ldate|log.Ltime|log.Lshortfile)
	infoLogger := log.New(os.Stdout, "[INFO] ", log.Ldate|log.Ltime)
	warnLogger := log.New(os.Stdout, "[WARN] ", log.Ldate|log.Ltime)
	errorLogger := log.New(os.Stderr, "[ERROR] ", log.Ldate|log.Ltime|log.Lshortfile)
	fatalLogger := log.New(os.Stderr, "[FATAL] ", log.Ldate|log.Ltime|log.Lshortfile)

	return &SimpleLogger{
		debugLogger: debugLogger,
		infoLogger:  infoLogger,
		warnLogger:  warnLogger,
		errorLogger: errorLogger,
		fatalLogger: fatalLogger,
	}
}

// Helper to format context fields for log lines
func formatCtxFields(ctx context.Context) string {
	reqIDStr := "-"
	userIDStr := "-"
	if reqID, ok := ctx.Value(ContextKeyRequestID).(string); ok && reqID != "" {
		reqIDStr = reqID
	}
	if userID, ok := ctx.Value(ContextKeyUserID).(int32); ok && userID != 0 {
		userIDStr = strconv.Itoa(int(userID))
	} else if userIDStrFromClaims, ok := ctx.Value(ContextKeyUserID).(string); ok && userIDStrFromClaims != "" {
		// Handle case where user ID might be string from claims initially?
		userIDStr = userIDStrFromClaims
	}
	return fmt.Sprintf("[req:%s user:%s]", reqIDStr, userIDStr)
}

// Debug logs a debug message
func (l *SimpleLogger) Debug(ctx context.Context, message string, args ...interface{}) {
	ctxFields := formatCtxFields(ctx)
	logMessage := fmt.Sprintf("%s %s", ctxFields, message)
	if len(args) > 0 {
		if len(args)%2 == 0 { // Key-value pairs
			for i := 0; i < len(args); i += 2 {
				logMessage += fmt.Sprintf(" %v=\"%v\"", args[i], args[i+1])
			}
		} else {
			logMessage = fmt.Sprintf("%s: %v", logMessage, args)
		}
	}
	l.debugLogger.Println(logMessage)
}

// Info logs an info message
func (l *SimpleLogger) Info(ctx context.Context, message string, args ...interface{}) {
	ctxFields := formatCtxFields(ctx)
	logMessage := fmt.Sprintf("%s %s", ctxFields, message)
	if len(args) > 0 {
		if len(args)%2 == 0 { // Key-value pairs
			for i := 0; i < len(args); i += 2 {
				logMessage += fmt.Sprintf(" %v=\"%v\"", args[i], args[i+1])
			}
		} else {
			logMessage = fmt.Sprintf("%s: %v", logMessage, args)
		}
	}
	l.infoLogger.Println(logMessage)
}

// Warn logs a warning message
func (l *SimpleLogger) Warn(ctx context.Context, message string, args ...interface{}) {
	ctxFields := formatCtxFields(ctx)
	logMessage := fmt.Sprintf("%s %s", ctxFields, message)
	var capturedArgs []interface{}
	var firstError error

	if len(args) > 0 {
		if len(args)%2 == 0 {
			for i := 0; i < len(args); i += 2 {
				logMessage += fmt.Sprintf(" %v=\"%v\"", args[i], args[i+1])
				if err, ok := args[i+1].(error); ok && firstError == nil {
					firstError = err
				}
			}
		} else {
			logMessage = fmt.Sprintf("%s: %v", logMessage, args)
			for _, arg := range args {
				if err, ok := arg.(error); ok && firstError == nil {
					firstError = err
					break
				}
			}
		}
		capturedArgs = args
	}
	l.warnLogger.Println(logMessage)

	// --- Corrected Sentry Capture Logic for Warn ---
	var extras map[string]interface{}
	if len(capturedArgs) > 0 {
		extras = make(map[string]interface{})
		if len(capturedArgs)%2 == 0 {
			for i := 0; i < len(capturedArgs); i += 2 {
				extras[fmt.Sprintf("%v", capturedArgs[i])] = capturedArgs[i+1]
			}
		} else {
			extras["details"] = capturedArgs
		}
	}

	hub := sentry.GetHubFromContext(ctx)
	if hub == nil {
		hub = sentry.CurrentHub().Clone()
	}

	if firstError != nil {
		// Capture the error as an exception
		hub.ConfigureScope(func(scope *sentry.Scope) {
			scope.SetLevel(sentry.LevelWarning)
			if reqID, ok := ctx.Value(ContextKeyRequestID).(string); ok {
				scope.SetTag("request_id", reqID)
			}
			if userID, ok := ctx.Value(ContextKeyUserID).(int32); ok {
				scope.SetTag("user_id", strconv.Itoa(int(userID)))
			} else if userIDStr, ok := ctx.Value(ContextKeyUserID).(string); ok {
				scope.SetTag("user_id", userIDStr)
			}
			if extras != nil {
				scope.SetExtras(extras)
			}
		})
		hub.CaptureException(firstError)
	} else {
		// Capture the log message as a Sentry event
		event := sentry.NewEvent()
		event.Level = sentry.LevelWarning
		event.Message = message // Use the original message for the event
		if extras != nil {
			event.Extra = extras
		}
		// Add tags to the event itself
		if reqID, ok := ctx.Value(ContextKeyRequestID).(string); ok {
			event.Tags["request_id"] = reqID
		}
		if userID, ok := ctx.Value(ContextKeyUserID).(int32); ok {
			event.Tags["user_id"] = strconv.Itoa(int(userID))
		} else if userIDStr, ok := ctx.Value(ContextKeyUserID).(string); ok {
			event.Tags["user_id"] = userIDStr
		}

		hub.CaptureEvent(event) // Use the hub to capture the message event
	}
}

// Error logs an error message
func (l *SimpleLogger) Error(ctx context.Context, message string, args ...interface{}) {
	logMessage := message
	var capturedArgs []interface{}
	var firstError error

	if len(args) > 0 {
		// Prepare for structured logging and find the first error for Sentry
		if len(args)%2 == 0 { // Key-value pairs
			for i := 0; i < len(args); i += 2 {
				logMessage += fmt.Sprintf(" %v=\"%v\"", args[i], args[i+1])
				if err, ok := args[i+1].(error); ok && firstError == nil {
					firstError = err
				}
			}
		} else { // Simple list of args
			logMessage = fmt.Sprintf("%s: %v", message, args)
			for _, arg := range args {
				if err, ok := arg.(error); ok && firstError == nil {
					firstError = err
					break
				}
			}
		}
		capturedArgs = args
	}
	l.errorLogger.Println(logMessage)

	// Capture error with Sentry
	hub := sentry.GetHubFromContext(ctx)
	if hub == nil {
		hub = sentry.CurrentHub().Clone()
	}
	hub.ConfigureScope(func(scope *sentry.Scope) {
		scope.SetLevel(sentry.LevelError)
		scope.SetTag("log_message", message)
		if reqID, ok := ctx.Value(ContextKeyRequestID).(string); ok {
			scope.SetTag("request_id", reqID)
		}
		if userID, ok := ctx.Value(ContextKeyUserID).(int32); ok {
			scope.SetTag("user_id", strconv.Itoa(int(userID)))
		} else {
			if userIDStr, ok := ctx.Value(ContextKeyUserID).(string); ok {
				scope.SetTag("user_id", userIDStr)
			}
		}

		if len(capturedArgs) > 0 {
			extras := make(map[string]interface{})
			if len(capturedArgs)%2 == 0 {
				for i := 0; i < len(capturedArgs); i += 2 {
					extras[fmt.Sprintf("%v", capturedArgs[i])] = capturedArgs[i+1]
				}
			} else {
				extras["details"] = capturedArgs
			}
			scope.SetExtras(extras)
		}
	})

	if firstError != nil {
		hub.CaptureException(firstError) // Capture the specific error object
	} else {
		// If no specific error object, capture the message as a Sentry message
		hub.CaptureMessage(message)
	}
}

// Fatal logs a fatal error message and exits the program
func (l *SimpleLogger) Fatal(ctx context.Context, message string, err error, args ...interface{}) {
	logMessage := message
	if err != nil {
		logMessage = fmt.Sprintf("%s: %v", message, err)
	}
	if len(args) > 0 {
		if len(args)%2 == 0 { // Key-value pairs
			for i := 0; i < len(args); i += 2 {
				logMessage += fmt.Sprintf(" %v=\"%v\"", args[i], args[i+1])
			}
		} else {
			logMessage = fmt.Sprintf("%s: %v", logMessage, args) // Append to existing message with error
		}
	}
	l.fatalLogger.Println(logMessage) // Use Println to match original behavior more closely before Fatalln

	// Capture fatal error with Sentry
	hub := sentry.GetHubFromContext(ctx)
	if hub == nil {
		hub = sentry.CurrentHub().Clone()
	}
	hub.ConfigureScope(func(scope *sentry.Scope) {
		scope.SetLevel(sentry.LevelFatal)
		scope.SetTag("log_message", message)
		if reqID, ok := ctx.Value(ContextKeyRequestID).(string); ok {
			scope.SetTag("request_id", reqID)
		}
		if userID, ok := ctx.Value(ContextKeyUserID).(int32); ok {
			scope.SetTag("user_id", strconv.Itoa(int(userID)))
		} else {
			if userIDStr, ok := ctx.Value(ContextKeyUserID).(string); ok {
				scope.SetTag("user_id", userIDStr)
			}
		}

		if len(args) > 0 {
			extras := make(map[string]interface{})
			if len(args)%2 == 0 {
				for i := 0; i < len(args); i += 2 {
					extras[fmt.Sprintf("%v", args[i])] = args[i+1]
				}
			} else {
				extras["details"] = args
			}
			scope.SetExtras(extras)
		}
	})
	if err != nil {
		hub.CaptureException(err)
	} else {
		// Create an error from the message if no error object was passed
		hub.CaptureException(errors.New(message))
	}
	sentry.Flush(2 * time.Second) // Ensure Sentry sends the event before os.Exit
	os.Exit(1)                    // Original SimpleLogger fatal does not os.Exit, log.Fatalln does.
	// Reverting to log.Fatalln to match original behavior of SimpleLogger more closely.
	// l.fatalLogger.Fatalln(logMessage) // This line was an issue. The os.Exit(1) is how log.Fatal behaves.
}
