#!/bin/sh
set -e

echo "Starting PT Champion service with auto-migration..."

# Check if environment variables exist
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ] || [ -z "$DB_NAME" ]; then
    echo "Error: Required database environment variables are not set."
    echo "Required: DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME"
    exit 1
fi

# Build database connection string
DB_URL="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=disable"

# Wait for database to be ready
echo "Waiting for database at ${DB_HOST}:${DB_PORT} to be ready..."
for i in $(seq 1 30); do
    pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USER && break
    echo "Waiting for database connection (${i}/30)..."
    sleep 2
done

if ! pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USER; then
    echo "Error: Could not connect to database after 30 attempts."
    exit 1
fi

# Run database migrations
echo "Running database migrations..."
migrate -path db/migrations -database "${DB_URL}" up

# Check migration status
if [ $? -ne 0 ]; then
    echo "Migration failed. Check logs for details."
    # Continue despite migration failure if IGNORE_MIGRATION_FAILURE is set
    if [ -z "$IGNORE_MIGRATION_FAILURE" ]; then
        exit 1
    else
        echo "Continuing despite migration failure because IGNORE_MIGRATION_FAILURE is set."
    fi
else
    echo "Migrations completed successfully."
fi

echo "Starting server..."
exec "$@" 