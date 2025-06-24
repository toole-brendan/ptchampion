#!/bin/bash
set -e

echo "🔍 Verifying test user in database..."

# Use the Azure PostgreSQL credentials
DB_HOST="ptchampion-db.postgres.database.azure.com"
DB_PORT="5432"
DB_USER="ptadmin"
DB_NAME="ptchampion"
DB_SSL_MODE="require"

# Use the password provided
DB_PASSWORD="Dunlainge1"

# Construct the connection string
DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSL_MODE}"

# Query to check the test user
echo "🔍 Checking test user details..."
psql "$DATABASE_URL" -c "SELECT id, email, username, password_hash, first_name, last_name FROM users WHERE email = 'testuser@ptchampion.ai';"

echo ""
echo "📋 Expected values:"
echo "   Email: testuser@ptchampion.ai"
echo "   Username: testuser"
echo "   Password: TestUser123!"
echo "   Expected hash: \$2a\$14\$T6noL1xxibNzQgDAZuygmOH6Oygem/SMiFtjaLvp0d1yX.6hi3pXK"