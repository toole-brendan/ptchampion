# --- Frontend Build Stage ---
# Use a Node.js image matching the project requirements (e.g., Node 20)
FROM node:20-alpine AS frontend-builder

# Set working directory for frontend build
WORKDIR /app/client

# Copy package.json and package-lock.json (or yarn.lock)
COPY client/package*.json ./

# Install frontend dependencies
RUN npm install

# Copy the rest of the client source code
COPY client/ ./

# Build the frontend application
# This should output files to /app/client/dist by default (Vite standard)
RUN npm run build
RUN ls -la /app/client/dist || echo "Dist directory not found!"

# --- Go Build Stage ---
# Use the official Go image as a builder image
# Rename alias for clarity
FROM golang:1.24-alpine AS go-builder

# Set the Current Working Directory inside the container
WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download all dependencies. Dependencies will be cached if the go.mod and go.sum files are not changed
RUN go mod download

# Copy the source code into the container
# Note: This copies everything, including the client dir again, but it's simpler.
# For optimization, you could copy only specific Go related folders.
COPY . .

# Build the Go app
# -ldflags "-w -s" reduces the size of the binary by removing debug information
# CGO_ENABLED=0 builds a static binary which is important for distroless/alpine images
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /server cmd/server/main.go

# --- Runtime Stage ---
# Switch to Alpine for easier debugging
# Consider pinning to a specific version, e.g., alpine:3.19
FROM alpine:latest

# Create a non-root user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Install packages needed for troubleshooting and runtime
RUN apk --no-cache add ca-certificates tzdata curl

# Set the Current Working Directory inside the container
WORKDIR /app

# Copy the Pre-built Go binary file from the go-builder stage
COPY --from=go-builder /server /app/server

# Copy the built frontend assets from the frontend-builder stage
# The Go app should be configured to serve files from this directory
COPY --from=frontend-builder /app/client/dist /app/static

# Change ownership of the app directory to the non-root user
RUN chown -R appuser:appgroup /app

# For debugging: List the contents of the static directory
RUN ls -la /app/static || echo "Static directory is empty or missing!"

# Switch to the non-root user
USER appuser

# Expose port 8080 to the outside world (adjust if your config uses a different default)
# Note: Non-root users cannot bind to ports below 1024 by default
EXPOSE 8080

# Command to run the executable
ENTRYPOINT ["/app/server"] 