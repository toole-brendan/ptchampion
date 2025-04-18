# --- Frontend Build Stage ---
# Use a Node.js image matching the project requirements (e.g., Node 20)
FROM node:20-alpine AS frontend-builder

# Set working directory for frontend build
WORKDIR /app/web

# Copy package.json and package-lock.json (or yarn.lock)
COPY web/package*.json ./

# Install frontend dependencies
RUN npm install

# Copy the rest of the web source code
COPY web/ ./

# Build the frontend application
# This should output files to /app/web/dist by default (Vite standard)
RUN npm run build
RUN ls -la /app/web/dist || echo "Dist directory not found!"

# --- Go Build Stage ---
# Use the official Go image as a builder image
# Rename alias for clarity
FROM golang:1.24-alpine AS builder

# Set the Current Working Directory inside the container
WORKDIR /app

# Copy go module and sum files
COPY go.mod go.sum ./

# Download all dependencies. Dependencies will be cached if the go.mod and go.sum files are not changed
RUN go mod download

# Copy the source code into the container
COPY . .

# Build the Go app
# CGO_ENABLED=0 produces a statically linked binary
# -ldflags="-w -s" reduces the size of the binary by removing debug information
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /ptchampion_server ./cmd/server/main.go

# --- Runtime Stage ---
# Switch to Alpine for easier debugging
# Consider pinning to a specific version, e.g., alpine:3.19
FROM alpine:latest

# Install packages needed for troubleshooting, runtime, and migrations
# Adding migrate tool - see https://github.com/golang-migrate/migrate/blob/master/cmd/migrate/README.md
RUN apk --no-cache add ca-certificates tzdata curl tar postgresql-client && \
    curl -L https://github.com/golang-migrate/migrate/releases/download/v4.17.1/migrate.linux-amd64.tar.gz | tar xvz && \
    mv migrate /usr/local/bin/migrate && \
    chmod +x /usr/local/bin/migrate

# Create a non-root user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set the Current Working Directory inside the container
WORKDIR /app

# Copy the pre-built binary file from the previous stage
COPY --from=builder /ptchampion_server .

# Copy migrations
COPY db/migrations ./db/migrations

# Copy entrypoint script
COPY scripts/entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh

# Copy built frontend assets to the static directory
COPY --from=frontend-builder /app/web/dist ./static
# For debugging: List the contents of the static directory
RUN ls -la ./static || echo "Static directory is empty or missing!"

# Change ownership of the app directory to the non-root user
RUN chown -R appuser:appgroup /app

# Switch to the non-root user
USER appuser

# Expose port 8080 to the outside world (adjust if your config uses a different default)
# Note: Non-root users cannot bind to ports below 1024 by default
EXPOSE 8080

# Use the entrypoint script to run migrations before starting the app
ENTRYPOINT ["/app/entrypoint.sh"]

# Command to run the executable
CMD ["./ptchampion_server"] 