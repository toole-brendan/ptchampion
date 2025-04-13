# PT Champion

PT Champion is a cross-platform fitness evaluation system that uses computer vision to track and evaluate military exercises. The ecosystem includes a web application and native mobile apps for iOS and Android, all sharing a common backend. The platform features global and local leaderboards, exercise tracking, and form analysis powered by MediaPipe.

## Features

- **Exercise Tracking**: Monitor push-ups, pull-ups, sit-ups, and running performance
- **Computer Vision Analysis**: Real-time form analysis and feedback using MediaPipe
- **Leaderboards**: Compare your performance with others globally or locally
- **Local Leaderboards**: Compare your performance with others within a defined radius (e.g., 5 miles) of your current location.
- **Progress Tracking**: Monitor your performance over time with detailed history
- **Cross-Platform Synchronization**: Seamlessly sync your data between web and mobile apps
- **Offline Support**: Continue using the mobile apps without an internet connection
- **Bluetooth Integration**: Connect to fitness devices for heart rate and running metrics

## Project Structure

```
/
├── cmd/
│   └── server/                  # Main Go application entry point (Echo framework)
│       └── main.go
├── internal/                  # Private Go application code
│   ├── api/                   # HTTP handlers, routing (Echo), middleware, generated code
│   │   ├── handlers/          # Request handler implementations
│   │   ├── middleware/        # Custom middleware (e.g., auth)
│   │   ├── api_handler.go     # Connects generated interface to handlers
│   │   ├── openapi.gen.go     # Generated code from OpenAPI spec (oapi-codegen)
│   │   └── router.go          # Echo router setup & static file serving
│   ├── auth/                  # Authentication logic helpers
│   ├── config/                # Configuration loading (env vars)
│   ├── grading/               # Exercise grading logic
│   ├── store/                 # Data access layer interfaces/implementations
│   │   └── postgres/          # PostgreSQL specific implementation using sqlc
│   │       ├── db.go          # Database connection & sqlc Querier setup
│   │       ├── models.go      # sqlc generated Go structs from schema
│   │       └── query.sql.go   # sqlc generated Go methods from queries
│   └── models/                # (Potentially unused - models seem defined via sqlc/OpenAPI)
│
├── pkg/                     # (Currently unused) Shared Go libraries
│
├── sql/                     # SQL files for sqlc and schema definition
│   ├── queries/             # SQL queries (.sql) for sqlc generation
│   ├── schema/              # Base database schema (.sql)
│   └── migrations/          # (Seems unused by backend? Migrations in db/)
│
├── db/                      # Database migrations (sql-migrate or similar)
│   └── migrations/          # .sql migration files (up/down)
│
├── client/                  # Web frontend (React + Vite + TypeScript)
│   ├── public/              # Static assets
│   ├── src/
│   │   ├── assets/          # Project-specific assets (images, etc.)
│   │   ├── components/      # Reusable UI components (using shadcn/ui)
│   │   ├── lib/             # Core logic, API client, auth, state management
│   │   │   ├── apiClient.ts # Typed client for backend API calls (fetch)
│   │   │   ├── authContext.tsx# React Context for authentication state
│   │   │   ├── config.ts    # Frontend configuration (e.g., API URL)
│   │   │   ├── types.ts     # TypeScript types for API/data
│   │   │   └── utils.ts     # General utility functions
│   │   ├── pages/           # Route components (views) for different app sections
│   │   ├── App.tsx          # Main app component (Routing setup with react-router-dom)
│   │   └── main.tsx         # Application entry point (React DOM render)
│   ├── index.html           # HTML entry point for Vite
│   ├── package.json         # Node dependencies
│   ├── tsconfig.json        # TypeScript configuration
│   └── vite.config.ts     # Vite build configuration
│   └── tailwind.config.cjs # Tailwind CSS configuration
│
├── PTChampion-Swift/        # iOS Application (Swift + SwiftUI - Placeholder/Structure)
│   ├── Views/
│   ├── Services/
│   ├── Models/
│   └── ...                 # Standard iOS project structure
│
├── PTChampion-Kotlin/       # Android Application (Kotlin + Jetpack Compose)
│   ├── app/
│   │   ├── build.gradle.kts # Module-level Gradle build script
│   │   └── src/main/
│   │       ├── assets/      # Assets (if any)
│   │       ├── java/        # (Likely contains generated Hilt/other code)
│   │       │    └── com/example/ptchampion/ # Root package
│   │       │        ├── data/         # Data layer (API, Repositories, DataStore)
│   │       │        ├── di/           # Dependency Injection (Hilt modules)
│   │       │        ├── domain/       # Business logic (Use Cases, Models, Analyzers)
│   │       │        ├── model/        # Data models (shared or UI specific)
│   │       │        ├── ui/           # UI layer (Compose Screens, ViewModels)
│   │       │        ├── util/         # Utility classes & helpers
│   │       │        └── MainActivity.kt # Main Activity
│   │       └── res/             # Android resources (drawables, values, etc.)
│   ├── build.gradle.kts      # Project-level Gradle build script
│   └── settings.gradle.kts   # Gradle settings script
│
├── scripts/                 # Utility scripts (build, deploy, etc.)
├── Dockerfile               # Docker configuration for Go backend deployment
├── openapi.yaml             # OpenAPI (Swagger) specification for the backend API
├── go.mod                   # Go module definition
├── go.sum                   # Go module checksums
└── README.md                # This file
```

## Technology Stack

### Backend (Go)

- **Framework**: [Echo](https://echo.labstack.com/) (Web Framework)
- **Database**: PostgreSQL
- **ORM/Data Access**: [sqlc](https://sqlc.dev/) (Generate Go code from SQL)
- **Migrations**: [migrate](https://github.com/golang-migrate/migrate) or similar (SQL-based migrations)
- **API Specification**: OpenAPI 3.0 (`openapi.yaml`)
- **Code Generation**: [oapi-codegen](https://github.com/deepmap/oapi-codegen) (Generate Echo server code from OpenAPI spec)
- **Configuration**: Environment Variables
- **Authentication**: JWT (using `golang-jwt/jwt/v5` likely implemented in handlers/middleware)

### Web Frontend (React)

- **Framework/Library**: [React](https://reactjs.org/) with [TypeScript](https://www.typescriptlang.org/)
- **Build Tool**: [Vite](https://vitejs.dev/)
- **Styling**: [Tailwind CSS](https://tailwindcss.com/)
- **UI Components**: [shadcn/ui](https://ui.shadcn.com/)
- **Routing**: [React Router DOM](https://reactrouter.com/)
- **State Management / Data Fetching**: [TanStack Query (React Query)](https://tanstack.com/query/latest)
- **API Client**: Native `fetch` API within a typed client (`apiClient.ts`)

### iOS Application (Swift)

- **UI Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Networking**: URLSession with Combine/AsyncAwait
- **Local Storage**: Core Data (Planned/Typical)
- **Vision Processing**: Apple Vision framework (Planned)
- **Bluetooth**: CoreBluetooth (Planned)

### Android Application (Kotlin)

- **UI Framework**: [Jetpack Compose](https://developer.android.com/jetpack/compose)
- **Architecture**: MVVM with elements of Clean Architecture (using Use Cases)
- **Networking**: [Retrofit](https://square.github.io/retrofit/) with [OkHttp](https://square.github.io/okhttp/) and [Kotlinx Serialization](https://github.com/Kotlin/kotlinx.serialization)
- **Asynchronous Programming**: Kotlin Coroutines
- **Local Storage**: [Jetpack DataStore (Preferences)](https://developer.android.com/topic/libraries/architecture/datastore) (for auth token/settings)
- **Dependency Injection**: [Hilt](https://developer.android.com/training/dependency-injection/hilt-android)
- **Navigation**: [Jetpack Navigation Compose](https://developer.android.com/jetpack/compose/navigation)
- **Vision Processing**: [MediaPipe](https://developers.google.com/mediapipe) (via `PoseLandmarker` for exercise analysis)
- **Camera**: [CameraX](https://developer.android.com/training/camerax)
- **Location**: Fused Location Provider (for local leaderboards)
- **Bluetooth**: Nordic BLE Library or Android BLE APIs (Planned)

### Cross-Cutting

- **Computer Vision**: MediaPipe (Intended primary library for pose analysis across platforms)
- **API Design**: OpenAPI (Swagger) driving backend API structure

## Getting Started

### Prerequisites

For the Web Application:
- Node.js (v18+)
- PostgreSQL database
- Git

For iOS Development:
- macOS with Xcode 14+
- iOS 16+ device or simulator
- Apple Developer account (for testing on physical devices)

For Android Development:
- Android Studio (latest version)
- Android SDK 29+ 
- JDK 11+
- Android device or emulator with API level 29+

### Deployment

For Docker deployment instructions, see [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md).

## Usage

1. **Register/Login**: Create an account or login to access the application
2. **Select Exercise**: Choose from push-ups, pull-ups, sit-ups, or running
3. **Allow Camera Access**: Position yourself so the camera can track your form
4. **Perform Exercise**: Follow the on-screen guidance and receive real-time feedback
5. **Complete Session**: Finish your workout to save your score and form rating
6. **View Progress**: Check your history and leaderboard ranking

