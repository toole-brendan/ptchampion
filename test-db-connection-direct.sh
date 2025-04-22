#!/bin/bash
# Script to directly test the database connection using the same parameters as the web app

set -e  # Exit on any error

# Configuration (taken from App Service settings)
DB_HOST="ptchampion-db.postgres.database.azure.com"
DB_PORT="5432"
DB_USER="ptadmin"
DB_NAME="ptchampion"
DB_SSL_MODE="require"
DB_PASSWORD="NewStrongPassword123!"

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

# Explicitly test with the DB_SSL_MODE setting
status "Testing with SSL Mode: ${DB_SSL_MODE}..."
if PGPASSWORD="${DB_PASSWORD}" psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} "sslmode=${DB_SSL_MODE}" -c "SELECT 1;" > /dev/null 2>&1; then
  status "✅ SSL Mode ${DB_SSL_MODE} connection succeeded."
else
  warning "⚠️ SSL Mode ${DB_SSL_MODE} connection failed. Trying other SSL modes..."
  for mode in require verify-ca verify-full prefer disable; do
    if [ "$mode" != "$DB_SSL_MODE" ]; then
      status "Testing SSL Mode: $mode..."
      if PGPASSWORD="${DB_PASSWORD}" psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} "sslmode=$mode" -c "SELECT 1;" > /dev/null 2>&1; then
        status "✅ SSL Mode $mode connection succeeded."
        warning "Consider changing DB_SSL_MODE to '$mode' in the app settings."
        break
      else
        warning "❌ SSL Mode $mode connection failed."
      fi
    fi
  done
fi

# Test constructed connection string format
CONNECTION_STRING="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSL_MODE}"
status "Testing with constructed connection string..."
if PGPASSWORD="${DB_PASSWORD}" psql "${CONNECTION_STRING}" -c "SELECT 1;" > /dev/null 2>&1; then
  status "✅ Connection string format works."
else
  error "❌ Connection string format failed. App might be constructing the string incorrectly."
  status "Try adding a properly encoded DATABASE_URL setting to the web app."
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

status "All database connection tests completed! ✅"
