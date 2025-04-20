# Use the official Golang image as a build stage
FROM golang:1.24-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download all dependencies
RUN go mod download

# Copy the source code
COPY . .

# Build the Go app with simplified command
RUN CGO_ENABLED=0 GOOS=linux go build -o server_binary ./cmd/server

# Use a minimal base image
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /app
COPY --from=builder /app/server_binary .

ENV NODE_ENV=production
ENV PORT=8080

EXPOSE 8080
CMD ["./server_binary"]
