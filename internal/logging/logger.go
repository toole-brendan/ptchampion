package logging

import (
	"context"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// Logger is a simplified interface for logging
type Logger interface {
	Debug(msg string, fields ...zapcore.Field)
	Info(msg string, fields ...zapcore.Field)
	Warn(msg string, fields ...zapcore.Field)
	Error(msg string, fields ...zapcore.Field)
	Fatal(msg string, fields ...zapcore.Field)
	With(fields ...zapcore.Field) Logger
	WithContext(ctx context.Context) Logger
}

// zapLogger implements the Logger interface using zap
type zapLogger struct {
	logger *zap.Logger
}

// New creates a new Logger with the specified settings
func New(level string, isDevelopment bool) (Logger, error) {
	var zapConfig zap.Config

	if isDevelopment {
		zapConfig = zap.NewDevelopmentConfig()
		// More readable timestamps in development
		zapConfig.EncoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder
	} else {
		zapConfig = zap.NewProductionConfig()
		// JSON in production for better log aggregation
		zapConfig.EncoderConfig.MessageKey = "message"
		zapConfig.EncoderConfig.LevelKey = "severity"
		zapConfig.EncoderConfig.TimeKey = "timestamp"
	}

	// Set log level
	var logLevel zapcore.Level
	if err := logLevel.UnmarshalText([]byte(level)); err != nil {
		logLevel = zapcore.InfoLevel
	}
	zapConfig.Level = zap.NewAtomicLevelAt(logLevel)

	// Create the logger
	logger, err := zapConfig.Build(zap.AddCallerSkip(1))
	if err != nil {
		return nil, err
	}

	// Replace the global logger
	zap.ReplaceGlobals(logger)

	// Redirect standard library log to zap
	zap.RedirectStdLog(logger)

	return &zapLogger{logger: logger}, nil
}

// Debug logs a message at debug level
func (l *zapLogger) Debug(msg string, fields ...zapcore.Field) {
	l.logger.Debug(msg, fields...)
}

// Info logs a message at info level
func (l *zapLogger) Info(msg string, fields ...zapcore.Field) {
	l.logger.Info(msg, fields...)
}

// Warn logs a message at warn level
func (l *zapLogger) Warn(msg string, fields ...zapcore.Field) {
	l.logger.Warn(msg, fields...)
}

// Error logs a message at error level
func (l *zapLogger) Error(msg string, fields ...zapcore.Field) {
	l.logger.Error(msg, fields...)
}

// Fatal logs a message at fatal level and then calls os.Exit(1)
func (l *zapLogger) Fatal(msg string, fields ...zapcore.Field) {
	l.logger.Fatal(msg, fields...)
	// zap.Fatal calls os.Exit(1) after logging
}

// With creates a child logger with the given fields added to it
func (l *zapLogger) With(fields ...zapcore.Field) Logger {
	return &zapLogger{logger: l.logger.With(fields...)}
}

// contextKey is the key used to store/retrieve a request ID from context
type contextKey string

const (
	requestIDKey contextKey = "requestID"
	userIDKey    contextKey = "userID"
)

// WithContext adds context values like request ID and user ID to the logger
func (l *zapLogger) WithContext(ctx context.Context) Logger {
	if ctx == nil {
		return l
	}

	logger := l.logger

	// Add request ID if present
	if reqID, ok := ctx.Value(requestIDKey).(string); ok && reqID != "" {
		logger = logger.With(zap.String("request_id", reqID))
	}

	// Add user ID if present
	if userID, ok := ctx.Value(userIDKey).(string); ok && userID != "" {
		logger = logger.With(zap.String("user_id", userID))
	}

	return &zapLogger{logger: logger}
}

// AddRequestID adds a request ID to the context
func AddRequestID(ctx context.Context, requestID string) context.Context {
	return context.WithValue(ctx, requestIDKey, requestID)
}

// AddUserID adds a user ID to the context
func AddUserID(ctx context.Context, userID string) context.Context {
	return context.WithValue(ctx, userIDKey, userID)
}
