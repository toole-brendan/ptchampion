# PT Champion

PT Champion is a cross-platform fitness evaluation system that uses computer vision to track and evaluate military exercises. The ecosystem includes a web application and native mobile apps for iOS and Android, all sharing a common backend. The platform features global and local leaderboards, exercise tracking, and form analysis powered by MediaPipe.

## Features

- **Exercise Tracking**: Monitor push-ups, pull-ups, sit-ups, and running performance using device cameras or connected watches.
- **Computer Vision Analysis**: Real-time form analysis and rep counting using MediaPipe (Web, Android) and Apple Vision (iOS).
- **Leaderboards**: Compare performance globally or locally (within a defined radius).
- **Progress Tracking**: Monitor performance over time with detailed history and visualizations.
- **Cross-Platform Synchronization**: Sync data between web and mobile apps (details TBC based on sync implementation).
- **Offline Support**: Mobile apps and Web PWA support offline data storage (using SwiftData, IndexedDB) and background synchronization.
- **Bluetooth Integration**: Connect to fitness devices:
  - **GPS Watch Integration**: Specialized support for Garmin, Polar, Suunto, and other GPS fitness watches (fetching location/metrics).
  - **Heart Rate Monitoring**: Real-time heart rate data from Bluetooth LE devices (supported on mobile and Web Bluetooth-compatible browsers).
  - **Pace and Cadence**: Running metrics from compatible fitness devices.

## Project Structure

```
/
├── cmd/
│   ├── server/                  # Main Go application entry point (Echo framework)
│   │   └── main.go
│   └── wasm/                    # (Experimental/Unused) Potential WASM compilation target
├── internal/                  # Private Go application code
│   ├── api/                   # HTTP handlers, routing (Echo), middleware, generated code
│   │   ├── handlers/          # Request handler implementations
│   │   ├── middleware/        # Custom middleware (e.g., auth, OTEL)
│   │   ├── api_handler.go     # Connects generated interface to handlers
│   │   ├── openapi.gen.go     # Generated code from OpenAPI spec (oapi-codegen)
│   │   └── router.go          # Echo router setup & static file serving
│   ├── auth/                  # Authentication logic helpers
│   ├── config/                # Configuration loading (env vars, AWS Secrets Manager)
│   ├── grading/               # Exercise grading logic (backend-side)
│   └── store/                 # Data access layer interfaces/implementations
│       ├── postgres/          # PostgreSQL specific implementation (using sqlc)
│       │   ├── db.go          # Database connection & sqlc Querier setup
│       │   ├── models.go      # sqlc generated Go structs from schema
│       │   └── query.sql.go   # sqlc generated Go methods from queries
│       └── redis/             # Redis implementation (e.g., leaderboard caching)
│           ├── config.go
│           └── leaderboard_cache.go
│
├── pkg/                     # (Currently unused) Shared Go libraries
│
├── db/                      # Database migration files
│   └── migrations/          # .sql migration files (up/down) using golang-migrate
│
├── shared/                  # Shared TypeScript code (potentially across frontend/backend)
│   └── schema.ts            # Drizzle ORM schema definitions, Zod validation schemas, shared types
│
├── web/                     # Web frontend (React + Vite + TypeScript PWA)
│   ├── public/              # Static assets
│   ├── src/
│   │   ├── assets/          # Project-specific assets (images, etc.)
│   │   ├── components/      # Reusable UI components (using shadcn/ui)
│   │   ├── lib/             # Core logic, API client, auth, state management, utils
│   │   │   ├── apiClient.ts # Typed client for backend API calls (fetch)
│   │   │   ├── authContext.tsx # React Context for authentication state (uses TanStack Query)
│   │   │   ├── config.ts    # Frontend configuration (e.g., API URL)
│   │   │   ├── db/          # IndexedDB logic (using idb library)
│   │   │   │   └── indexedDB.ts
│   │   │   ├── hooks/       # Custom React Hooks
│   │   │   │   ├── useBluetoothHRM.ts # Web Bluetooth API hook for HRM
│   │   │   │   └── usePoseDetector.ts # MediaPipe pose detection hook
│   │   │   ├── types.ts     # TypeScript types (consider merging/linking with shared/schema.ts)
│   │   │   └── utils.ts     # General utility functions
│   │   ├── pages/           # Route components (views) for different app sections
│   │   ├── App.tsx          # Main app component (Routing setup with react-router-dom, TanStack Query setup)
│   │   ├── main.tsx         # Application entry point (React DOM render)
│   │   ├── serviceWorker.ts # Service Worker logic for PWA features (offline caching)
│   │   └── serviceWorkerRegistration.ts # Service Worker registration and sync logic
│   ├── index.html           # HTML entry point for Vite
│   ├── package.json         # Node dependencies
│   ├── tsconfig.json        # TypeScript configuration
│   └── vite.config.ts       # Vite build configuration
│   └── tailwind.config.cjs  # Tailwind CSS configuration
│
├── ios/                     # iOS Application (Swift + SwiftUI)
│   ├── ptchampion/          # Main iOS project directory
│   │   ├── Views/           # SwiftUI views
│   │   ├── ViewModels/      # View models implementing MVVM
│   │   ├── Services/        # API clients, Bluetooth, Location, Pose Detection, etc.
│   │   └── Models/          # Data models (including SwiftData models like WorkoutResultSwiftData)
│
├── android/                 # Android Application (Kotlin + Jetpack Compose)
│   ├── app/
│   │   ├── build.gradle.kts # Module-level Gradle build script
│   │   └── src/main/
│   │       ├── assets/      # MediaPipe models (.task files), etc.
│   │       ├── java/        # (Likely contains generated Hilt/other code)
│   │       │    └── com/example/ptchampion/ # Root package
│   │       │        ├── data/         # Data layer (API impls, Repositories, DataStore)
│   │       │        ├── di/           # Dependency Injection (Hilt modules)
│   │       │        ├── domain/       # Business logic (Use Cases, Models, Analyzers, Repositories Interfaces)
│   │       │        ├── model/        # Data models (shared or UI specific)
│   │       │        ├── ui/           # UI layer (Compose Screens, ViewModels, Navigation)
│   │       │        ├── util/         # Utility classes & helpers
│   │       │        ├── posedetection/# MediaPipe PoseLandmarker integration code
│   │       │        └── MainActivity.kt # Main Activity
│   │       └── res/             # Android resources (drawables, values, etc.)
│   ├── build.gradle.kts      # Project-level Gradle build script
│   └── settings.gradle.kts   # Gradle settings script
│   ├── api_client/          # (Purpose TBD - Potentially shared Kotlin API client?)
│
├── scripts/                 # Utility scripts (e.g., OpenAPI generation)
├── docs/                    # Documentation files (how-to guides, etc.)
├── Dockerfile               # Docker configuration for Go backend deployment
├── docker-compose.yml       # Docker Compose for local development (Postgres, Backend)
├── openapi.yaml             # OpenAPI (Swagger) specification for the backend API
├── .devcontainer.json       # Dev container configuration for VS Code
├── Makefile                 # Build and development tasks (including migrations)
├── go.mod                   # Go module definition
├── go.sum                   # Go module checksums
└── README.md                # This file
```

## Technology Stack

### Backend (Go)

- **Framework**: [Echo](https://echo.labstack.com/) (Web Framework)
- **Database**: PostgreSQL
- **Data Access**: [sqlc](https://sqlc.dev/) (Generate Go code from SQL)
- **Caching**: Redis (using [go-redis/redis](https://github.com/go-redis/redis)) for leaderboard caching
- **Migrations**: [golang-migrate](https://github.com/golang-migrate/migrate) (SQL-based migrations managed via `Makefile`)
- **API Specification**: OpenAPI 3.0 (`openapi.yaml`)
- **Code Generation**: [oapi-codegen](https://github.com/deepmap/oapi-codegen) (Generate Echo server code from OpenAPI spec)
- **Configuration**: Environment Variables, `.env` files, [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/) integration
- **Authentication**: JWT (using `golang-jwt/jwt/v5`)
- **Schema/Types (Potentially)**: [Drizzle ORM](https://orm.drizzle.team/) + [Zod](https://zod.dev/) via `shared/schema.ts` (Needs confirmation on backend integration)

### Web Frontend (React - PWA)

- **Framework/Library**: [React](https://reactjs.org/) with [TypeScript](https://www.typescriptlang.org/)
- **Build Tool**: [Vite](https://vitejs.dev/)
- **Styling**: [Tailwind CSS](https://tailwindcss.com/)
- **UI Components**: [shadcn/ui](https://ui.shadcn.com/)
- **Routing**: [React Router DOM](https://reactrouter.com/)
- **State Management / Data Fetching**: [TanStack Query (React Query)](https://tanstack.com/query/latest)
- **API Client**: Native `fetch` API within a typed client (`apiClient.ts`)
- **Offline Storage**: IndexedDB (using [idb](https://github.com/jakearchibald/idb) library)
- **PWA Features**: Service Workers for caching and background sync (`serviceWorker.ts`)
- **Vision Processing**: [MediaPipe Tasks Vision](https://developers.google.com/mediapipe/solutions/vision/pose_landmarker/web_js) (via `@mediapipe/tasks-vision` for pose detection)
- **Bluetooth**: Web Bluetooth API (via `useBluetoothHRM` hook, requires compatible browser like Chrome/Edge)

### iOS Application (Swift)

- **UI Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Networking**: URLSession with Combine/AsyncAwait (via `NetworkClient.swift`)
- **Local Storage**: [SwiftData](https://developer.apple.com/xcode/swiftdata/)
- **Vision Processing**: [Apple Vision framework](https://developer.apple.com/documentation/vision) (for pose detection)
- **Bluetooth**: [CoreBluetooth](https://developer.apple.com/documentation/corebluetooth) (for HRM and GPS watch integration)
- **Location**: CoreLocation
- **Authentication**: Keychain for secure token storage (`KeychainService.swift`)

### Android Application (Kotlin)

- **UI Framework**: [Jetpack Compose](https://developer.android.com/jetpack/compose)
- **Architecture**: MVVM with elements of Clean Architecture (using Use Cases in `domain` layer)
- **Networking**: [Retrofit](https://square.github.io/retrofit/) with [OkHttp](https://square.github.io/okhttp/) and [Kotlinx Serialization](https://github.com/Kotlin/kotlinx.serialization)
- **Asynchronous Programming**: Kotlin Coroutines
- **Local Storage**: [Jetpack DataStore (Preferences)](https://developer.android.com/topic/libraries/architecture/datastore) (for auth token/settings)
- **Dependency Injection**: [Hilt](https://developer.android.com/training/dependency-injection/hilt-android)
- **Navigation**: [Jetpack Navigation Compose](https://developer.android.com/jetpack/compose/navigation)
- **Vision Processing**: [MediaPipe](https://developers.google.com/mediapipe) (via `PoseLandmarker` task library for exercise analysis)
- **Camera**: [CameraX](https://developer.android.com/training/camerax)
- **Location**: Fused Location Provider (likely)
- **Bluetooth**: Android Bluetooth Low Energy API (via `BluetoothService`) with specialized handling for GPS-enabled fitness devices (Garmin, Polar, Suunto).

### Cross-Cutting

- **API Design**: OpenAPI (Swagger) driving backend API structure and potentially client generation.
- **Data Synchronization**: Custom sync logic likely used (inferred from `shared/schema.ts` sync types and PWA/offline features).
- **Shared Schema**: Drizzle ORM + Zod used in `shared/schema.ts` for defining DB schema, validation, and TypeScript types.

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

### Running with Docker Compose

This is the recommended way to run the backend and its database dependency locally for development and testing.

**Prerequisites:**

*   [Docker](https://docs.docker.com/get-docker/) installed and running.
*   [Docker Compose](https://docs.docker.com/compose/install/) installed (usually included with Docker Desktop).

**Configuration:**

1.  **Create `.env` file:** If it doesn't exist, create a file named `.env` in the project root directory (`/Users/brendantoole/projects/ptchampion`).
2.  **Populate `.env`:** Copy the contents from `.env.example` (if one exists) or add the following variables, replacing placeholder values as needed:

    ```dotenv
    # PostgreSQL Configuration for Docker Compose
    DB_HOST=db
    DB_PORT=5432
    DB_USER=user        # Change if needed
    DB_PASSWORD=password  # Change if needed
    DB_NAME=ptchampion   # Change if needed

    # JWT Configuration
    JWT_SECRET=your_strong_jwt_secret_here # Replace with a real secret!
    JWT_EXPIRES_IN=24h

    # Application Port Configuration (inside container)
    APP_PORT_CONTAINER=8080

    # Host Port Mappings (for accessing services from your machine)
    DB_PORT_HOST=5432
    APP_PORT_HOST=8080

    # Add any other environment variables your Go application needs
    # e.g., GIN_MODE=debug
    ```
    *Ensure this `.env` file is listed in your `.gitignore` to avoid committing secrets.*

**Running the Stack:**

1.  Open a terminal in the project root directory (`/Users/brendantoole/projects/ptchampion`).
2.  Run the following command:
    ```bash
    docker-compose up --build -d
    ```
    *   `--build`: Builds the backend image if it doesn't exist or if the `Dockerfile` or source code has changed.
    *   `-d`: Runs the containers in detached mode (in the background).

**Accessing Services:**

*   **Backend API:** The Go backend should be accessible on your host machine at `http://localhost:8080` (or the value of `APP_PORT_HOST` if you changed it in `.env`).
*   **Database:** The PostgreSQL database should be accessible on `localhost:5432` (or the value of `DB_PORT_HOST`) using the credentials defined in `.env` (`DB_USER`, `DB_PASSWORD`, `DB_NAME`). You can connect using tools like `psql` or a GUI client.

**Database Migrations:**

The system uses [golang-migrate](https://github.com/golang-migrate/migrate) to manage database schema changes. Migrations are stored in the `db/migrations` directory as pairs of `.up.sql` and `.down.sql` files.

When using Docker Compose, migrations are automatically applied during container startup via the entrypoint script. However, you may need to run migrations manually during development:

1. **Configure Database Connection**: 
   *  Set up your database connection details in your `.env` file:
   ```
   DB_HOST=localhost
   DB_PORT=5432
   DB_USER=user
   DB_PASSWORD=password
   DB_NAME=ptchampion
   ```

2. **Run Migrations Using Make**:
   The project Makefile provides convenient commands for managing migrations:
   ```bash
   # Apply all pending migrations
   make migrate-up

   # Roll back the most recent migration
   make migrate-down

   # Roll back all migrations and apply them again
   make migrate-reset

   # Create a new migration file
   make migrate-create name=add_users_table
   ```

3. **Run Migrations Directly**:
   If you have `migrate` installed locally, you can also run migrations directly:
   ```bash
   # Export variables from .env
   export $(cat .env | grep -v '#' | xargs)

   # Run migrations
   migrate -path db/migrations -database "postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=disable" up
   ```

For more details on working with migrations, see [db/migrations/README.md](db/migrations/README.md).

**Stopping the Stack:**

*   To stop the running containers, execute:
    ```bash
    docker-compose down
    ```
    This stops and removes the containers but preserves the database data volume (`postgres_data`). To remove the volume as well (deleting all database data), use `docker-compose down -v`.

### Deployment

For Docker deployment instructions, see [DOCKER_DEPLOYMENT.md](DOCKER_DEPLOYMENT.md).

## Usage

1. **Register/Login**: Create an account or login to access the application
2. **Select Exercise**: Choose from push-ups, pull-ups, sit-ups, or running
3. **Allow Camera Access**: Position yourself so the camera can track your form
4. **Perform Exercise**: Follow the on-screen guidance and receive real-time feedback
5. **Complete Session**: Finish your workout to save your score and form rating
6. **View Progress**: Check your history and leaderboard ranking

# PT CHAMPION STYLING GUIDE V2
Refined for Clean Brass-on-Cream Aesthetic

## 🎨 Color Palette

| Usage | Color Name | HEX | Notes |
|---------|-------|----------|----------|
| Light Background | Tactical Cream | #F4F1E6 | Page and card backgrounds |
| Primary Dark Background | Deep Ops Green | #1E241E | Nav bar, logos, header backgrounds |
| Accent / Highlight | Brass Gold | #BFA24D | Chart strokes, icons, highlights |
| Button/Text Highlight | Army Tan | #E0D4A6 | Optional light highlight |
| Chart Fill | Olive Mist | #C9CCA6 | Light, translucent area fills |
| Primary Text | Command Black | #1E1E1E | Headings, stat numbers |
| Secondary Text | Tactical Gray | #4E5A48 | Labels, descriptions |

## 🛡️ Logo Usage

Use just the emblem (without text) in top-center or top-left of authenticated pages.

Logo color: #BFA24D on dark backgrounds, #1E241E on light backgrounds.

Size should be small (32–48px height max) and not dominate the header.

```tsx
<LogoIcon className="h-8 w-auto text-brass-gold" />
```

## Typography

| Text Element | Font | Size | Weight | Color | Style |
|-------------|------|------|--------|-------|-------|
| Headings | Bebas Neue | 24–32px | Bold | #1E1E1E | UPPERCASE |
| Subheadings | Montserrat | 18–20px | Semi-Bold | #4E5A48 | Uppercase |
| Stats / Numbers | Roboto Mono | 20–28px | Medium | #1E1E1E or #BFA24D | Lined-up mono spacing |
| Labels | Montserrat | 12–14px | Regular | #4E5A48 | Sentence case |

## 📊 Charts & Data

**Chart Colors:**
- Line Stroke: #BFA24D
- Fill Under Line: rgba(201, 204, 166, 0.2)
- Gridlines: #E3E0D5
- Axis Label Font: Montserrat, #4E5A48

**Metric Cards:**
- Background: #F4F1E6 (or slightly darker with #EDE9DB)
- Border Radius: 12px
- Shadow: Soft subtle shadow (1px)

**Typography:**
- Label: Montserrat uppercase, small
- Number: Roboto Mono, bold
- Layout: Even 3-column layout on mobile

## 🧩 Components

### ✅ Buttons
- Background: #BFA24D
- Text: #1E241E
- Font: Montserrat Bold, 14px, UPPERCASE
- Border-radius: 8px
- Hover: Darken brass or underline text

### ✅ Bottom Navigation
| Element | Style |
|---------|-------|
| Background | #1E241E |
| Active Icon Color | #BFA24D |
| Inactive Icon Color | #A3A390 |
| Label Font | Montserrat UPPERCASE, 10px |

```tsx
<nav className="bg-deep-ops text-brass-gold">
  <Tab icon={<ProgressIcon />} label="PROGRESS" active />
</nav>
```

### Cards / Panels
| Style | Value |
|-------|-------|
| Background Color | #F4F1E6 |
| Border Radius | 12px |
| Shadow | Soft, muted |
| Padding | 16px |

## 🔧 Spacing & Layout
- Global padding: 20px
- Card gap: 12px
- Bottom nav height: 60px
- Logo margin-top: 16px
- Border radius for large panels: 16px

```js
theme: {
  extend: {
    colors: {
      'cream': '#F4F1E6',
      'deep-ops': '#1E241E',
      'brass-gold': '#BFA24D',
      'olive-mist': '#C9CCA6',
      'tactical-gray': '#4E5A48',
      'command-black': '#1E1E1E',
    },
    fontFamily: {
      heading: ['Bebas Neue', 'sans-serif'],
      body: ['Montserrat', 'sans-serif'],
      mono: ['Roboto Mono', 'monospace'],
    },
    borderRadius: {
      card: '12px',
      panel: '16px',
    }
  }
}
```


Logo Use
Full Logo (Emblem + Text): Only on splash screens and login page
Emblem Only: Top corner of all authenticated app pages (e.g., dashboard, leaderboard, progress)
Placement: Subtle but consistent, preferably:
<LogoIcon size="sm" style={{ position: "absolute", top: 16, left: 16 }} />