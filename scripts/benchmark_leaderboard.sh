#!/bin/bash
# Benchmark script for leaderboard API performance
# Usage: ./benchmark_leaderboard.sh [num_requests] [concurrency]

NUM_REQUESTS=${1:-100}
CONCURRENCY=${2:-10}
API_URL=${API_URL:-"http://localhost:8080"}
ENDPOINT="/leaderboard/local"

# Parameters for the local leaderboard
EXERCISE_ID=1
LAT=37.7749
LON=-122.4194
RADIUS=8047

echo "Benchmarking local leaderboard performance..."
echo "Endpoint: ${API_URL}${ENDPOINT}?exercise_id=${EXERCISE_ID}&latitude=${LAT}&longitude=${LON}&radius_meters=${RADIUS}"
echo "Number of requests: ${NUM_REQUESTS}, Concurrency: ${CONCURRENCY}"
echo

# First run - should be uncached
echo "First run (cold cache):"
ab -n 1 -v 2 "${API_URL}${ENDPOINT}?exercise_id=${EXERCISE_ID}&latitude=${LAT}&longitude=${LON}&radius_meters=${RADIUS}"
echo

# Wait a moment
sleep 1

# Run the benchmark
echo "Running benchmark..."
ab -n ${NUM_REQUESTS} -c ${CONCURRENCY} -v 1 "${API_URL}${ENDPOINT}?exercise_id=${EXERCISE_ID}&latitude=${LAT}&longitude=${LON}&radius_meters=${RADIUS}"

echo
echo "Benchmark complete!" 