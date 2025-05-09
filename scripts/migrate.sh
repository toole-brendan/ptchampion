#!/bin/bash

# Check for DATABASE_URL in environment first
if [ -z "$DATABASE_URL" ]; then
    # If DATABASE_URL not set, try to load from .env file
    if [ -f .env ]; then
        echo "Loading DATABASE_URL from .env file..."
        export $(grep -v '^#' .env | grep DATABASE_URL)
    fi

    # If still not set, use components
    if [ -z "$DATABASE_URL" ]; then
        echo "DATABASE_URL not found in environment or .env, constructing from components..."
        # Database connection settings - should match your application's config
        DB_USER=${DB_USER:-postgres}
        DB_PASSWORD=${DB_PASSWORD:-postgres}
        DB_NAME=${DB_NAME:-ptchampion}
        DB_HOST=${DB_HOST:-localhost}
        DB_PORT=${DB_PORT:-5432}
        DB_SSL_MODE=${DB_SSL_MODE:-disable}

        # Construct the database URL
        DATABASE_URL="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSL_MODE}"
    fi
fi

echo "Using database URL: ${DATABASE_URL//:.*@/:***@}" # Log URL with password hidden

# Migration files directory - Updated to use sql/migrations instead of db/migrations
MIGRATIONS_DIR="./sql/migrations"

# Function to display usage information
usage() {
    echo "Usage: $0 [COMMAND]"
    echo "Commands:"
    echo "  up           Apply all available migrations"
    echo "  down         Revert last migration"
    echo "  create NAME  Create a new migration with the specified name"
    echo "  version      Print current migration version"
    echo "  force V      Force migration version"
    echo "  help         Display this help message"
    exit 1
}

# Check if migrate command is available
command -v migrate >/dev/null 2>&1 || { 
    echo >&2 "Error: migrate command not found. Install with: go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest"
    exit 1 
}

# Check if at least one argument is provided
if [ $# -lt 1 ]; then
    usage
fi

# Process commands
case "$1" in
    up)
        echo "Applying all migrations..."
        migrate -database ${DATABASE_URL} -path ${MIGRATIONS_DIR} up
        ;;
    down)
        echo "Reverting last migration..."
        migrate -database ${DATABASE_URL} -path ${MIGRATIONS_DIR} down 1
        ;;
    create)
        if [ $# -lt 2 ]; then
            echo "Error: Migration name is required"
            usage
        fi
        NAME=$2
        echo "Creating new migration: $NAME"
        migrate create -ext sql -dir ${MIGRATIONS_DIR} -seq ${NAME}
        ;;
    version)
        echo "Current migration version:"
        migrate -database ${DATABASE_URL} -path ${MIGRATIONS_DIR} version
        ;;
    force)
        if [ $# -lt 2 ]; then
            echo "Error: Version number is required"
            usage
        fi
        VERSION=$2
        echo "Forcing migration version to $VERSION..."
        migrate -database ${DATABASE_URL} -path ${MIGRATIONS_DIR} force $VERSION
        ;;
    help|*)
        usage
        ;;
esac

# Check if the last command executed successfully
if [ $? -eq 0 ]; then
    echo "Done!"
else
    echo "Failed!"
    exit 1
fi 