#!/bin/bash

# Script to apply the first_name/last_name migration to Azure PostgreSQL
echo "Starting migration to add first_name and last_name fields..."

# Database connection string
DATABASE_URL="postgresql://ptadmin:NewStrongPassword123!@ptchampion-db.postgres.database.azure.com:5432/ptchampion?sslmode=require"

# Check if psql is available
if ! command -v psql &> /dev/null; then
    echo "Error: psql command not found. Please install PostgreSQL client."
    exit 1
fi

# Verify database connection
echo "Verifying database connection..."
if ! psql "$DATABASE_URL" -c "SELECT 1;" > /dev/null 2>&1; then
    echo "Error: Could not connect to the database. Please check your connection details."
    exit 1
fi

echo "Connection successful. Running migration..."

# Apply the migration
if psql "$DATABASE_URL" -f sql/migrations/202505141730_add_first_last_name.up.sql; then
    echo "Migration completed successfully!"
    
    # Verify columns were added
    echo "Verifying new columns..."
    psql "$DATABASE_URL" -c "SELECT column_name FROM information_schema.columns WHERE table_name = 'users' AND (column_name = 'first_name' OR column_name = 'last_name');"
    
    # Verify display_name was removed
    echo "Verifying display_name removal..."
    psql "$DATABASE_URL" -c "SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'display_name';"
else
    echo "Error: Migration failed."
    exit 1
fi

echo "Migration successfully applied. Users now have first_name and last_name fields instead of display_name." 