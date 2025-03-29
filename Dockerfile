# --- Build Stage ---
# Use the official Go image as a builder image
# Make sure the Go version matches your go.mod file (e.g., 1.24)
FROM golang:1.24-alpine AS builder

# Set the Current Working Directory inside the container
WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download all dependencies. Dependencies will be cached if the go.mod and go.sum files are not changed
RUN go mod download

# Copy the source code into the container
COPY . .

# Build the Go app
# -ldflags "-w -s" reduces the size of the binary by removing debug information
# CGO_ENABLED=0 builds a static binary which is important for distroless/alpine images
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o /server cmd/server/main.go

# --- Runtime Stage ---
# Use a minimal image for the runtime environment
# Using distroless static image which is very small and secure
FROM gcr.io/distroless/static-debian12
# Or use alpine for a slightly larger but still small base with a shell (useful for debugging)
# FROM alpine:latest
# RUN apk --no-cache add ca-certificates tzdata

# Set the Current Working Directory inside the container
WORKDIR /app

# Copy the Pre-built binary file from the previous stage
COPY --from=builder /server /app/server

# Copy .env file if needed, although using environment variables is preferred for production
# COPY .env.production .env

# Expose port 8080 to the outside world (adjust if your config uses a different default)
EXPOSE 8080

# Command to run the executable
# The ENTRYPOINT ensures that this is the command run when the container starts
ENTRYPOINT ["/app/server"] 