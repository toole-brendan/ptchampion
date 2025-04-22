#!/bin/bash
# Script to test DB connection from local machine to Azure PostgreSQL

set -e  # Exit on any error

# Configuration (taken from App Service settings)
DB_HOST="ptchampion-db.postgres.database.azure.com"
DB_PORT="5432"
DB_USER="ptadmin"
DB_NAME="ptchampion"
DB_SSL_MODE="require"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display status messages
status() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

# Function to display warning messages
warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to display error messages
error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Prompt for password (don't store in script)
read -sp "Enter database password: " DB_PASSWORD
echo ""

# Test basic connectivity to database host and port
status "Testing TCP connectivity to ${DB_HOST}:${DB_PORT}..."
if nc -z -w 5 ${DB_HOST} ${DB_PORT}; then
  status "✅ TCP connection to ${DB_HOST}:${DB_PORT} succeeded."
else
  error "❌ TCP connection to ${DB_HOST}:${DB_PORT} failed. Check network connectivity and firewall rules."
  exit 1
fi

# Test authentication using psql
status "Testing database authentication..."
if PGPASSWORD="${DB_PASSWORD}" psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "SELECT 1;" > /dev/null 2>&1; then
  status "✅ Authentication to database succeeded."
else
  error "❌ Authentication failed. Check username, password, and database name."
  status "Running detailed diagnostics..."
  PGPASSWORD="${DB_PASSWORD}" psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "SELECT 1;" || true
  exit 1
fi

# Check for specific tables to verify schema is properly loaded
status "Checking database schema..."
TABLE_COUNT=$(PGPASSWORD="${DB_PASSWORD}" psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
TABLE_COUNT=$(echo ${TABLE_COUNT} | tr -d '[:space:]')

if [ "${TABLE_COUNT}" -gt "0" ]; then
  status "✅ Database has ${TABLE_COUNT} tables in the public schema."
  
  # List tables
  status "Tables in database:"
  PGPASSWORD="${DB_PASSWORD}" psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"
else
  warning "⚠️ No tables found in public schema. Database may not be initialized."
fi

# Check server version
status "Checking PostgreSQL server version..."
PGPASSWORD="${DB_PASSWORD}" psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "SELECT version();"

# Check connection count
status "Checking current connection count..."
PGPASSWORD="${DB_PASSWORD}" psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -c "SELECT count(*) FROM pg_stat_activity;"

status "Database connection tests completed successfully! ✅"
status "Next steps:"
status "1. Verify that the App Service has the correct database connection strings"
status "2. Check if Azure App Service IP is allowed in PostgreSQL firewall rules"
status "3. Verify the container's entrypoint script can handle the DB_SSL_MODE correctly"
