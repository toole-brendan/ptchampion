#!/bin/bash
set -e

# Source environment variables if .env file exists
if [ -f .env ]; then
  echo "Loading environment variables from .env file..."
  export $(grep -v '^#' .env | xargs)
fi

# Set default values or use environment variables
DB_HOST=${DB_HOST:-"ptchampion-db.postgres.database.azure.com"}
DB_PORT=${DB_PORT:-5432}
DB_USER=${DB_USER:-"ptadmin"}
DB_NAME=${DB_NAME:-"ptchampion"}
DB_SSL_MODE=${DB_SSL_MODE:-"require"}

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
  # Check if DB_PASSWORD is set
  if [ -z "$DB_PASSWORD" ]; then
    echo "Error: DATABASE_URL or DB_PASSWORD must be set."
    exit 1
  fi
  DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSL_MODE}"
fi

# Mask password in displayed URL
MASKED_URL=${DATABASE_URL//:*@/:***@}
echo "Using database URL: $MASKED_URL"

# Run the migration
echo "Applying username to display_name migration..."
psql "$DATABASE_URL" -f sql/migrations/set_display_name_from_username.sql

echo "Migration completed successfully!" 