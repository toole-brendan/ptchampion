# PT Champion

PT Champion is a cross-platform fitness evaluation system that uses computer vision to track and evaluate military exercises. The ecosystem includes a web application and native mobile apps for iOS and Android, all sharing a common backend. The platform features global and local leaderboards, exercise tracking, and form analysis powered by MediaPipe.

## Features

- **Exercise Tracking**: Monitor push-ups, pull-ups, sit-ups, and running performance
- **Computer Vision Analysis**: Real-time form analysis and feedback using MediaPipe
- **Leaderboards**: Compare your performance with others globally or locally
- **Progress Tracking**: Monitor your performance over time with detailed history
- **Cross-Platform Synchronization**: Seamlessly sync your data between web and mobile apps
- **Offline Support**: Continue using the mobile apps without an internet connection
- **Bluetooth Integration**: Connect to fitness devices for heart rate and running metrics

## Project Structure

```
/ (Root - Web Application)
├── cmd/
│   └── server/                  # Main Go application entry point
│       └── main.go
├── internal/                  # Private Go application code
│   ├── api/                   # HTTP handlers & routing
│   │   ├── handlers/          # Request handlers (exercises, users, leaderboard, etc.)
│   │   │   ├── auth_handler.go
│   │   │   ├── exercise_handler.go
│   │   │   ├── leaderboard_handler.go
│   │   │   └── user_handler.go
│   │   ├── middleware/        # HTTP middleware (auth, logging, etc.)
│   │   │   └── auth_middleware.go
│   │   └── router.go          # API route definitions
│   │
│   ├── auth/                  # Authentication logic (interfacing with service or libs)
│   │   └── auth.go
│   ├── config/                # Configuration loading
│   │   └── config.go
│   ├── store/                 # Data access layer
│   │   ├── postgres/          # PostgreSQL specific implementation
│   │   │   ├── db.go          # Database connection setup
│   │   │   ├── querier.go     # Interface for sqlc generated queries
│   │   │   └── models.go      # sqlc generated Go models from schema
│   │   └── store.go           # Generic data store interfaces
│   │
│   └── models/                # Core application domain models (if different from DB models)
│       └── exercise.go
│
├── sql/                     # SQL files for sqlc
│   ├── queries/             # SQL queries for sqlc generation
│   │   ├── exercise.sql
│   │   ├── session.sql
│   │   ├── user.sql
│   │   └── leaderboard.sql
│   └── schema/              # Database schema definitions
│       └── schema.sql
│
├── client/                  # Web frontend (React) - Structure largely similar
│   ├── public/
│   ├── src/
│   │   ├── components/      # Reusable UI components (shadcn)
│   │   ├── hooks/           # Custom React hooks
│   │   ├── lib/             # Utility functions and services
│   │   │   ├── apiClient.ts     # Functions to call the Go backend API
│   │   │   ├── auth.ts          # Frontend auth helpers
│   │   │   ├── mediapipe.ts     # MediaPipe integration logic
│   │   │   ├── queryClient.ts   # React Query or similar setup
│   │   │   └── utils.ts         # General utilities
│   │   │
│   │   ├── pages/          # Application pages
│   │   │   ├── auth/          # Login/Register pages
│   │   │   ├── exercises/     # Exercise tracking pages (Pushups, Situps, etc.)
│   │   │   ├── history/       # User progress/history page
│   │   │   ├── leaderboard/   # Leaderboard page
│   │   │   ├── profile/       # User profile page
│   │   │   └── Dashboard.tsx  # Main dashboard/home page
│   │   │
│   │   ├── App.tsx         # Main app component & routing
│   │   └── main.tsx        # Application entry point
│   │
│   ├── package.json
│   ├── tsconfig.json
│   └── tailwind.config.ts  # Tailwind CSS configuration
│
├── scripts/                 # Build, migration scripts
│   └── migrate.sh           # Database migration script helper
│
├── go.mod                   # Go module definition
├── go.sum                   # Go module checksums
├── Dockerfile               # Optional: Docker configuration for deployment
│
├── PTChampion-Swift/           # iOS Application (Swift + SwiftUI)
│   ├── Views/                  # UI layer
│   │   ├── Auth/               # Authentication screens
│   │   ├── Dashboard/          # Main dashboard screens
│   │   ├── Exercises/          # Exercise-specific views
│   │   ├── History/            # Training history views
│   │   ├── Profile/            # User profile views
│   │   └── Components/         # Reusable UI components
│   │
│   ├── Services/               # Business logic and services
│   │   ├── API/                # API client for backend communication
│   │   ├── Vision/             # Computer vision with Apple Vision framework
│   │   ├── Bluetooth/          # Bluetooth connectivity for fitness devices
│   │   └── Storage/            # Local storage with Core Data
│   │
│   ├── Models/                 # Data models
│   ├── Utilities/              # Helper utilities
│   └── Resources/              # App resources (images, fonts, etc.)
│
└── PTChampion-Kotlin/          # Android Application (Kotlin + Jetpack Compose)
    ├── app/
    │   └── src/
    │       └── main/
    │           ├── kotlin/com/ptchampion/
    │           │   ├── ui/                # UI layer (Jetpack Compose)
    │           │   │   ├── auth/          # Authentication screens
    │           │   │   ├── dashboard/     # Main dashboard screens
    │           │   │   ├── exercises/     # Exercise-specific views
    │           │   │   ├── history/       # Training history views
    │           │   │   ├── profile/       # User profile views
    │           │   │   └── components/    # Reusable UI components
    │           │   │
    │           │   ├── data/              # Data layer
    │           │   │   ├── api/           # API services for backend communication
    │           │   │   ├── repository/    # Repository implementations
    │           │   │   └── local/         # Local storage with Room
    │           │   │
    │           │   ├── domain/            # Business logic
    │           │   │   ├── model/         # Domain models
    │           │   │   └── usecase/       # Business use cases
    │           │   │
    │           │   └── util/              # Utility classes
    │           │
    │           └── res/                   # Resources (layouts, drawables, etc.)
    │
    └── build.gradle                       # Gradle build configuration
```

## Technology Stack

### Web Application

- **Frontend**: TypeScript with Tailwind CSS and shadcn UI components
- **Backend**: Go
- **Database**: PostgreSQL with `sqlc` for data access
- **Authentication**: Auth-as-a-Service (e.g., Supabase Auth, Clerk) or Go standard libraries (`golang-jwt/jwt/v5`, `alexedwards/scs/v2`)
- **Computer Vision**: MediaPipe

### iOS Application

- **UI Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Networking**: URLSession with Combine
- **Local Storage**: Core Data
- **Vision Processing**: Apple Vision framework
- **Bluetooth**: CoreBluetooth for fitness device connectivity

### Android Application

- **UI Framework**: Jetpack Compose
- **Architecture**: MVVM with Clean Architecture
- **Networking**: Retrofit with Kotlin Coroutines
- **Local Storage**: Room Database
- **Dependency Injection**: Hilt
- **Vision Processing**: TensorFlow Lite and ML Kit
- **Bluetooth**: Bluetooth Low Energy (BLE) APIs

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

