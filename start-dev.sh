#!/bin/bash

# Start-dev script for PT Champion development
# Starts both the frontend and backend servers

# Kill processes on exit
trap 'kill $(jobs -p) 2>/dev/null' EXIT

# Get a random available port for the backend
get_free_port() {
  local port
  # Try ports in range 3000-4000
  for port in $(seq 3000 4000); do
    # Check if port is free
    if ! lsof -i :"$port" > /dev/null 2>&1; then
      echo "$port"
      return 0
    fi
  done
  # Fallback to a default port if all are busy
  echo "3000" 
}

# Determine port for the backend
BACKEND_PORT=$(get_free_port)
echo "Starting backend on port $BACKEND_PORT"

# Determine the frontend port - Choose 5173 as starting point (Vite default)
FRONTEND_PORT=5173
while lsof -i :"$FRONTEND_PORT" > /dev/null 2>&1; do
  echo "Port $FRONTEND_PORT is in use, trying next one..."
  FRONTEND_PORT=$((FRONTEND_PORT + 1))
done
echo "Frontend will use port $FRONTEND_PORT"

# Save the root directory path
ROOT_DIR=$(pwd)

# Update client environment to use the selected port
echo "VITE_API_URL=http://localhost:$BACKEND_PORT/api/v1" > client/.env.local
echo "VITE_AUTO_DISCOVER_PORT=true" >> client/.env.local

# Get the DATABASE_URL from .env or use a default if not found
if grep -q DATABASE_URL .env; then
  DB_URL=$(grep DATABASE_URL .env | cut -d= -f2-)
  echo "Using DATABASE_URL from .env file"
else
  # Use the default value from .env.production or a hardcoded value
  if grep -q DATABASE_URL .env.production; then
    DB_URL=$(grep DATABASE_URL .env.production | cut -d= -f2-)
    echo "Using DATABASE_URL from .env.production file"
  else
    DB_URL="postgres://postgres:Dunlainge1!@ptchampion-1-instance-1.ck9iecaw2h6w.us-east-1.rds.amazonaws.com:5432/postgres"
    echo "Using default DATABASE_URL"
  fi
fi

# Get JWT_SECRET or generate one if not found
if grep -q JWT_SECRET .env; then
  JWT_SECRET_VAL=$(grep JWT_SECRET .env | cut -d= -f2-)
  echo "Using JWT_SECRET from .env file"
elif grep -q JWT_SECRET .env.production; then
  JWT_SECRET_VAL=$(grep JWT_SECRET .env.production | cut -d= -f2-)
  echo "Using JWT_SECRET from .env.production file"
else
  JWT_SECRET_VAL="f8a4c3ff94e950fa7b1245d3fe57562d148c371aab9233428c849e9d7ba6d251"
  echo "Using default JWT_SECRET"
fi

# Create temp config for the root directory
cat > .env.dev <<EOF
NODE_ENV=development
PORT=$BACKEND_PORT
DATABASE_URL=$DB_URL
JWT_SECRET=$JWT_SECRET_VAL
CLIENT_ORIGIN=http://localhost:$FRONTEND_PORT
EOF

# Create .env file in the cmd/server directory (critical for Go app to find it)
cat > cmd/server/.env <<EOF
DATABASE_URL=$DB_URL
PORT=$BACKEND_PORT
JWT_SECRET=$JWT_SECRET_VAL
CLIENT_ORIGIN=http://localhost:$FRONTEND_PORT
EOF

echo "Created .env files with the following configuration:"
echo "----------------------------------------"
echo "NODE_ENV=development"
echo "PORT=$BACKEND_PORT"
echo "DATABASE_URL=$DB_URL"
echo "CLIENT_ORIGIN=http://localhost:$FRONTEND_PORT"
echo "JWT_SECRET=********" # Don't show the actual JWT secret
echo "----------------------------------------"

# Start the backend server with environment variables exported directly
cd cmd/server
export DATABASE_URL="$DB_URL"
export PORT="$BACKEND_PORT"
export JWT_SECRET="$JWT_SECRET_VAL"
export CLIENT_ORIGIN="http://localhost:$FRONTEND_PORT"
echo "Starting Go server with exported environment variables"
go run . &
BACKEND_PID=$!

echo "Backend server started with PID $BACKEND_PID"

# Wait for backend to initialize
sleep 2

# Return to root and start the frontend development server
cd "$ROOT_DIR/client" && npm run dev -- --port $FRONTEND_PORT &
FRONTEND_PID=$!

echo "Frontend server started with PID $FRONTEND_PID"

# Wait for both processes
wait $BACKEND_PID $FRONTEND_PID 