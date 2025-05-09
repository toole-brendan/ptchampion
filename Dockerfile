# Use the official Golang image as a build stage
FROM golang:1.23.1-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download all dependencies
RUN go mod download

# Install git (required for go install to fetch repositories)
RUN apk add --no-cache git

# IMPORTANT: When building on Apple Silicon (M-series) Macs, you MUST use:
# docker build --platform linux/amd64 -t <image-name> .
# This ensures the image will work in Azure App Service which requires AMD64 architecture.

# We no longer regenerate openapi.gen.go inside the container. The file is
# committed to the repository and kept in sync via `go generate` during
# development. This prevents the build from picking up an empty/placeholder
# spec that CI might create.

# Copy the source code
COPY . .

# Build the Go app
RUN CGO_ENABLED=0 GOOS=linux go build -o server_binary ./cmd/server

# Use a minimal base image
FROM alpine:latest

# Install PostgreSQL client for migrations and health checks, and netcat for health check endpoint
RUN apk --no-cache add ca-certificates postgresql-client netcat-openbsd

WORKDIR /app

# Copy the server binary from the builder stage
COPY --from=builder /app/server_binary .

# Copy the entrypoint script to run migrations before starting the server
COPY scripts/entrypoint.sh .
RUN chmod +x /app/entrypoint.sh

ENV NODE_ENV=production

EXPOSE 8080

# Use the entrypoint script to run migrations, then start the server
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["./server_binary"]
