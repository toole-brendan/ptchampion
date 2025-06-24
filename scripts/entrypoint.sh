#!/bin/sh
set -e

echo "Starting PT Champion service with auto-migration..."

# Check if environment variables exist
if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ] || [ -z "$DB_NAME" ]; then
    echo "Error: Required database environment variables are not set."
    echo "Required: DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME"
    exit 1
fi

# Use DB_SSL_MODE if specified, otherwise default to disable
DB_SSL_MODE=${DB_SSL_MODE:-disable}
echo "Using SSL mode: $DB_SSL_MODE"

# Build database connection string with proper SSL mode
DB_URL="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSL_MODE}"

# Wait for database to be ready with more verbose output
echo "Waiting for database at ${DB_HOST}:${DB_PORT} to be ready..."
for i in $(seq 1 30); do
    echo "Attempt ${i}/30: Checking database connection..."
    if pg_isready -h $DB_HOST -p $DB_PORT -U $DB_USER; then
        echo "Successfully connected to database!"
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo "Error: Could not connect to database after 30 attempts."
        echo "Last attempt details:"
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1" || echo "Connection failed with error code: $?"
        
        # Set this if you want to continue despite database connection failure
        if [ -z "$IGNORE_DB_CONNECTION_FAILURE" ]; then
            exit 1
        else
            echo "Continuing despite database connection failure because IGNORE_DB_CONNECTION_FAILURE is set."
        fi
    fi
    
    echo "Waiting for database connection (${i}/30)..."
    sleep 2
done

# Run the column rename migration if needed
echo "Running column fix migration..."
echo "ALTER TABLE users RENAME COLUMN password TO password_hash;" > /tmp/fix_column.sql
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=0 -c "DO \$\$ BEGIN ALTER TABLE users RENAME COLUMN password TO password_hash; EXCEPTION WHEN undefined_column OR duplicate_column THEN RAISE NOTICE 'column rename skipped'; END \$\$;"

# Add the display_name column if it doesn't exist
echo "Adding display_name column if needed..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=0 -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='display_name') THEN ALTER TABLE users ADD COLUMN display_name TEXT; END IF; END \$\$;"

# Add the gender column if it doesn't exist
echo "Adding gender column if needed..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=0 -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='gender') THEN ALTER TABLE users ADD COLUMN gender TEXT; END IF; END \$\$;"

# Add the date_of_birth column if it doesn't exist
echo "Adding date_of_birth column if needed..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -v ON_ERROR_STOP=0 -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='date_of_birth') THEN ALTER TABLE users ADD COLUMN date_of_birth DATE; END IF; END \$\$;"

echo "Database schema migration completed."

# Start the main application
echo "Starting PT Champion server..."
exec "$@"