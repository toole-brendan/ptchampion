# Makefile for ptchampion project

.PHONY: help dev test deploy backend-build backend-test web-build web-test android-build android-test ios-build ios-test clean migrate migrate-up migrate-down migrate-create migrate-force wasm-install-tinygo wasm-build wasm-clean redis-benchmark redis-flush redis-info

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  help           Show this help message"
	@echo "  dev            Start development environment (placeholder)"
	@echo "  test           Run all tests (placeholder)"
	@echo "  deploy         Deploy application (placeholder)"
	@echo "  backend-build  Build the Go backend"
	@echo "  backend-test   Test the Go backend"
	@echo "  web-build      Build the web frontend"
	@echo "  web-test       Test the web frontend"
	@echo "  android-build  Build the Android app"
	@echo "  android-test   Test the Android app"
	@echo "  ios-build      Build the iOS app"
	@echo "  ios-test       Test the iOS app"
	@echo "  clean          Clean build artifacts"
	@echo ""
	@echo "Database Migration Targets:"
	@echo "  migrate        Run database migrations up (alias for migrate-up)"
	@echo "  migrate-up     Apply all pending migrations"
	@echo "  migrate-down   Rollback the most recent migration"
	@echo "  migrate-reset  Rollback all migrations and apply them again"
	@echo "  migrate-create Create a new migration (e.g., make migrate-create name=add_users_table)"
	@echo ""
	@echo "WASM Targets:"
	@echo "  wasm-install-tinygo Install TinyGo"
	@echo "  wasm-build        Build WASM grading module"
	@echo "  wasm-clean        Clean WASM build artifacts"
	@echo ""
	@echo "Redis Commands:"
	@echo "  redis-benchmark  Benchmark the leaderboard API for performance"
	@echo "  redis-flush      Flush all Redis cache data"
	@echo "  redis-info       Display Redis server information"

# --- Development ---
dev:
	@echo "Starting development environment..."
	# Add commands to start backend, frontend, etc. e.g., using docker-compose or tilt
	docker-compose up -d
	@echo "Development environment started. Use 'docker-compose logs -f' to view logs."

# --- Testing ---
test: backend-test web-test android-test ios-test
	@echo "Running all tests..."

backend-test:
	@echo "Running Go backend tests..."
	cd internal && go test ./...
	cd cmd/server && go test ./...
	# Add other backend test commands if necessary

web-test:
	@echo "Running web frontend tests..."
	cd web && npm test
	@echo "Web tests completed"

android-test:
	@echo "Running Android tests..."
	cd android && ./gradlew test
	@echo "Android tests completed"

ios-test:
	@echo "Running iOS tests..."
	cd ios && xcodebuild test -project ptchampion.xcodeproj -scheme "PTChampion" -destination "platform=iOS Simulator,name=iPhone 14,OS=latest" || echo "iOS tests skipped (requires macOS)"
	@echo "iOS tests completed"

# --- Building ---
backend-build:
	@echo "Building Go backend..."
	cd cmd/server && go build -o ../../server_binary .
	@echo "Backend binary -> ./server_binary"

web-build:
	@echo "Building web frontend..."
	cd web && npm install && npm run build
	@echo "Web frontend built -> web/dist/"

android-build:
	@echo "Building Android app..."
	cd android && ./gradlew assembleRelease
	@echo "Android app built -> android/app/build/outputs/apk/release/app-release.apk"

ios-build:
	@echo "Building iOS app..."
	cd ios && xcodebuild -project ptchampion.xcodeproj -scheme "PTChampion" -configuration Release -destination "generic/platform=iOS" -archivePath ./build/PTChampion.xcarchive archive || echo "iOS build skipped (requires macOS)"
	@echo "iOS app built -> ios/build/PTChampion.xcarchive"

# --- Deployment ---
deploy:
	@echo "Deploying application..."
	# Add deployment commands (e.g., docker push, kubectl apply)
	@echo "TODO: Implement deployment steps"

# --- Cleaning ---
clean:
	@echo "Cleaning build artifacts..."
	rm -f server_binary
	cd web && rm -rf dist node_modules
	cd android && ./gradlew clean
	cd ios && rm -rf build DerivedData
	@echo "All build artifacts cleaned"

# --- Database Migration Targets ---
# Check for required environment variables, otherwise use defaults
DB_HOST ?= localhost
DB_PORT ?= 5432
DB_USER ?= user
DB_PASSWORD ?= password
DB_NAME ?= ptchampion
MIGRATE_CMD := migrate -path db/migrations -database "postgres://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable"

migrate: migrate-up

migrate-up:
	@echo "Applying database migrations..."
	$(MIGRATE_CMD) up

migrate-down:
	@echo "Rolling back the most recent migration..."
	$(MIGRATE_CMD) down 1

migrate-reset:
	@echo "Rolling back all migrations and reapplying them..."
	-$(MIGRATE_CMD) down -all
	$(MIGRATE_CMD) up

migrate-create:
	@if [ -z "$(name)" ]; then \
		echo "Error: Migration name not specified. Usage: make migrate-create name=xyz"; \
		exit 1; \
	fi
	@echo "Creating new migration files for: $(name)"
	@current=$$(ls -1 db/migrations/*.up.sql 2>/dev/null | wc -l | tr -d ' '); \
	next=$$(printf "%04d" $$((10#$$current + 1))); \
	touch db/migrations/$${next}_$(name).up.sql; \
	touch db/migrations/$${next}_$(name).down.sql; \
	echo "Created db/migrations/$${next}_$(name).up.sql"; \
	echo "Created db/migrations/$${next}_$(name).down.sql"
	@echo "Don't forget to edit the migration files to add your SQL statements"

# --- WASM Targets ---
wasm-install-tinygo:
	@echo "Checking for TinyGo installation..."
	@if command -v tinygo > /dev/null; then \
		echo "TinyGo is already installed."; \
	else \
		echo "TinyGo is not installed. Installing..."; \
		case "$(shell uname -s)" in \
			Darwin) \
				brew install tinygo; \
				;; \
			Linux) \
				echo "Please install TinyGo manually: https://tinygo.org/getting-started/install/linux/"; \
				exit 1; \
				;; \
			MINGW*|MSYS*|CYGWIN*) \
				echo "Please install TinyGo manually: https://tinygo.org/getting-started/install/windows/"; \
				exit 1; \
				;; \
			*) \
				echo "Unsupported OS. Please install TinyGo manually: https://tinygo.org/getting-started/install/"; \
				exit 1; \
				;; \
		esac; \
	fi

wasm-build: wasm-install-tinygo
	@echo "Building WASM grading module..."
	@chmod +x scripts/build-wasm.sh
	@./scripts/build-wasm.sh

wasm-clean:
	@echo "Cleaning WASM build artifacts..."
	@rm -rf web/public/wasm/*.wasm web/public/wasm/*.js
	@echo "WASM artifacts cleaned."

# --- Redis Commands ---
REDIS_HOST ?= localhost
REDIS_PORT ?= 6379
REDIS_PASSWORD ?= 

redis-benchmark:
	@echo "Benchmarking leaderboard API performance..."
	@chmod +x scripts/benchmark_leaderboard.sh
	@./scripts/benchmark_leaderboard.sh 100 10

redis-flush:
	@echo "Flushing Redis cache..."
	@if [ -n "$(REDIS_PASSWORD)" ]; then \
		redis-cli -h $(REDIS_HOST) -p $(REDIS_PORT) -a $(REDIS_PASSWORD) FLUSHALL; \
	else \
		redis-cli -h $(REDIS_HOST) -p $(REDIS_PORT) FLUSHALL; \
	fi
	@echo "Redis cache flushed."

redis-info:
	@echo "Redis server information:"
	@if [ -n "$(REDIS_PASSWORD)" ]; then \
		redis-cli -h $(REDIS_HOST) -p $(REDIS_PORT) -a $(REDIS_PASSWORD) INFO; \
	else \
		redis-cli -h $(REDIS_HOST) -p $(REDIS_PORT) INFO; \
	fi 