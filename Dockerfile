# Use the official Golang image as a build stage
FROM golang:1.22-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download all dependencies. Dependencies will be cached if the go.mod and go.sum files are not changed
RUN go mod download

# Copy the source code into the container
COPY . .

# Build the Go app
# CGO_ENABLED=0 produces a statically linked executable
# -ldflags="-s -w" strips debug information, reducing binary size
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o server_binary ./cmd/server

# Start a new stage from scratch using a minimal base image
FROM alpine:latest

# Install certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

# Set the working directory
WORKDIR /app

# Copy the pre-built binary file from the previous stage
COPY --from=builder /app/server_binary .

# Copy env files if needed
COPY .env.production .env

# Set environment variable for production
ENV NODE_ENV=production
ENV PORT=8080

# Expose the port that Azure App Service expects (8080 is the default)
EXPOSE 8080

# Command to run the executable
CMD ["./server_binary"]
