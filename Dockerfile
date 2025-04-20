# Use the official Golang image as a build stage
FROM golang:1.24-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download all dependencies
RUN go mod download

# Install git (required for go install to fetch repositories)
RUN apk add --no-cache git

# Install oapi-codegen for OpenAPI code generation
RUN go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@v2.4.1

# First copy only the OpenAPI spec file to verify it exists
COPY openapi.yaml ./
RUN ls -la openapi.yaml

# Now copy the rest of the source code
COPY . .

# Generate API code from OpenAPI spec
RUN oapi-codegen -generate types,echo-server \
    -package api \
    -o internal/api/openapi.gen.go openapi.yaml

# Build the Go app
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
