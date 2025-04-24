package logging

import (
	"fmt"
	"log"
	"os"
)

// Logger defines the interface for logging
type Logger interface {
	Debug(message string, args ...interface{})
	Info(message string, args ...interface{})
	Warn(message string, args ...interface{})
	Error(message string, args ...interface{})
	Fatal(message string, err error, args ...interface{})
}

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

// Debug logs a debug message
func (l *SimpleLogger) Debug(message string, args ...interface{}) {
	if len(args) > 0 {
		l.debugLogger.Printf("%s: %v", message, args)
	} else {
		l.debugLogger.Println(message)
	}
}

// Info logs an info message
func (l *SimpleLogger) Info(message string, args ...interface{}) {
	if len(args) > 0 {
		l.infoLogger.Printf("%s: %v", message, args)
	} else {
		l.infoLogger.Println(message)
	}
}

// Warn logs a warning message
func (l *SimpleLogger) Warn(message string, args ...interface{}) {
	if len(args) > 0 {
		l.warnLogger.Printf("%s: %v", message, args)
	} else {
		l.warnLogger.Println(message)
	}
}

// Error logs an error message
func (l *SimpleLogger) Error(message string, args ...interface{}) {
	if len(args) > 0 {
		l.errorLogger.Printf("%s: %v", message, args)
	} else {
		l.errorLogger.Println(message)
	}
}

// Fatal logs a fatal error message and exits the program
func (l *SimpleLogger) Fatal(message string, err error, args ...interface{}) {
	if err != nil {
		message = fmt.Sprintf("%s: %v", message, err)
	}

	if len(args) > 0 {
		l.fatalLogger.Fatalf("%s: %v", message, args)
	} else {
		l.fatalLogger.Fatalln(message)
	}
}
