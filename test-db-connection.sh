#\!/bin/bash
# Test database connection before updating deployment

# Database configuration from .env.production
DB_HOST="ptchampion-db.postgres.database.azure.com"
DB_PORT="5432"
DB_USER="ptadmin"
DB_PASSWORD="Dunlainge1"
DB_NAME="ptchampion"
DB_SSL_MODE="require"

echo "Testing database connection..."
echo "Host: $DB_HOST"
echo "Port: $DB_PORT"
echo "Database: $DB_NAME"
echo "User: $DB_USER"
echo "SSL Mode: $DB_SSL_MODE"
echo ""

# Test with psql if available
if command -v psql >/dev/null 2>&1; then
    echo "Testing with psql..."
    PGPASSWORD=$DB_PASSWORD psql "host=$DB_HOST port=$DB_PORT dbname=$DB_NAME user=$DB_USER sslmode=$DB_SSL_MODE" -c "SELECT 1" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Database connection successful with psql\!"
    else
        echo "❌ Database connection failed with psql"
    fi
else
    echo "psql not found, skipping psql test"
fi

# Test with curl to check if host is reachable
echo ""
echo "Testing host reachability..."
timeout 5 bash -c "echo >/dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Host is reachable on port $DB_PORT"
else
    echo "❌ Host is not reachable on port $DB_PORT"
fi

# Test Azure CLI access to check current app settings
echo ""
echo "Checking current App Service settings..."
if command -v az >/dev/null 2>&1; then
    CURRENT_DB_HOST=$(az webapp config appsettings list \
        --name ptchampion-api-westus \
        --resource-group ptchampion-rg \
        --query "[?name=='DB_HOST'].value" -o tsv 2>/dev/null)
    
    if [ -n "$CURRENT_DB_HOST" ]; then
        echo "Current DB_HOST in App Service: $CURRENT_DB_HOST"
        if [ "$CURRENT_DB_HOST" \!= "$DB_HOST" ]; then
            echo "⚠️ WARNING: Current DB_HOST differs from .env.production\!"
        fi
    else
        echo "❌ DB_HOST not found in App Service settings"
    fi
else
    echo "Azure CLI not available"
fi

echo ""
echo "Database configuration test complete."
