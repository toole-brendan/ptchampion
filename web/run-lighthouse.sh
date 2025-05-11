#!/bin/bash

# Run PWA build and then run Lighthouse checks
echo "Building PWA..."
npm run build

# Start a local server
echo "Starting local server..."
npx serve -s dist &
SERVER_PID=$!

# Wait for server to start
echo "Waiting for server to start..."
sleep 3

# Run Lighthouse
echo "Running Lighthouse..."
npx lighthouse http://localhost:3000 \
  --output=html \
  --output=json \
  --output=csv \
  --output-path=./lighthouse-report \
  --only-categories=performance,accessibility,best-practices,seo,pwa \
  --view

# Kill the server
echo "Cleaning up..."
kill $SERVER_PID

echo "Lighthouse report completed and saved to ./lighthouse-report" 