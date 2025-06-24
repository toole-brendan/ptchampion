#!/bin/bash
set -e

echo "🔧 Running database migration to add test user for App Store review..."

# Use the Azure PostgreSQL credentials
DB_HOST="ptchampion-db.postgres.database.azure.com"
DB_PORT="5432"
DB_USER="ptadmin"
DB_NAME="ptchampion"
DB_SSL_MODE="require"

# Prompt for password (more secure than hardcoding)
echo "Enter the database password for $DB_USER@$DB_HOST:"
read -s DB_PASSWORD
echo

# Construct the connection string
DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSL_MODE}"

# Execute the migration file
echo "🔧 Executing test user migration SQL against database..."
echo "👉 Using database URL: ${DATABASE_URL//:.*@/:***@}"  # Mask the password in logs

# Run the SQL file against the database
psql "$DATABASE_URL" -f sql/migrations/20250127_add_test_user_for_app_store_review.up.sql

echo "✅ Test user migration successfully applied!"
echo "📧 Test user credentials:"
echo "   Email: testuser@ptchampion.ai"
echo "   Password: TestUser123!"