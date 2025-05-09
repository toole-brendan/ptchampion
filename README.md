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


## Technology Stack

### Backend (Go)

- **Framework**: [Echo](https://echo.labstack.com/) (Web Framework)
- **Database**: PostgreSQL
- **Data Access**: [sqlc](https://sqlc.dev/) (Generate Go code from SQL)
- **Caching**: Redis (using [go-redis/redis](https://github.com/go-redis/redis)) for leaderboard caching
- **Migrations**: [golang-migrate](https://github.com/golang-migrate/migrate) (SQL-based migrations managed via `Makefile`)
- **API Specification**: OpenAPI 3.0 (`openapi.yaml`)
- **Code Generation**: [oapi-codegen](https://github.com/deepmap/oapi-codegen) (Generate Echo server code from OpenAPI spec)
- **Configuration**: Environment Variables, `.env` files, [Azure Key Vault](https://azure.microsoft.com/en-us/services/key-vault/) integration
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

## Documentation

For detailed information about the project, please refer to the following documents:

- [Production Readiness Implementation Plan](PRODUCTION_READINESS_PLAN.md) - Detailed plan for making the application production-ready
- [Architecture Documentation](docs/ARCHITECTURE.md) - C4 model diagrams and technical architecture details
- [Compliance, Backup & Disaster Recovery](docs/COMPLIANCE_BACKUP_DR.md) - Information about compliance frameworks, data backup strategies, and DR procedures
- [iOS App Store Submission Guide](ios/AppStoreMetadata.md) - Guide for iOS App Store submission
- [Android Play Store Submission Guide](android/PlayStoreMetadata.md) - Guide for Google Play Store submission
- [Azure Deployment Guide](docs/AZURE_DEPLOYMENT.md) - Guide for deploying the application to Azure

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

For Azure deployment instructions, see [AZURE_DEPLOYMENT.md](docs/AZURE_DEPLOYMENT.md).

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

# Design System Implementation (iOS)

The iOS application implements the styling guide above through a token-based design system in the `PTDesignSystem` package. This system provides a consistent way to apply styling across the app without relying on hardcoded values.

## Using the Design System

### Colors

Always use `AppTheme.GeneratedColors` to access color tokens rather than direct color values:

```swift
// ✅ Correct usage
Text("Hello world")
    .foregroundColor(AppTheme.GeneratedColors.textPrimary)
    .background(AppTheme.GeneratedColors.cardBackground)

// ❌ Incorrect usage - don't use direct RGB/hex values
Text("Hello world")
    .foregroundColor(Color(red: 0.12, green: 0.14, blue: 0.12))
```

### Typography

Use `AppTheme.GeneratedTypography` for consistent font styling:

```swift
// ✅ Correct usage
Text("Heading")
    .font(AppTheme.GeneratedTypography.heading())

Text("Body text")
    .font(AppTheme.GeneratedTypography.body())

// ❌ Incorrect usage - don't use Font.custom directly
Text("Heading")
    .font(Font.custom("BebasNeue-Bold", size: 24))
```

### Spacing

Use `AppTheme.GeneratedSpacing` for consistent layout:

```swift
// ✅ Correct usage
VStack(spacing: AppTheme.GeneratedSpacing.medium) {
    // Content
}
.padding(.horizontal, AppTheme.GeneratedSpacing.contentPadding)

// ❌ Incorrect usage - don't use hardcoded spacing values
VStack(spacing: 16) {
    // Content
}
.padding(.horizontal, 20)
```

### Border Radius

Use `AppTheme.GeneratedRadius` for consistent corner radius:

```swift
// ✅ Correct usage
RoundedRectangle(cornerRadius: AppTheme.GeneratedRadius.card)

// ❌ Incorrect usage - don't use hardcoded radius values
RoundedRectangle(cornerRadius: 12)
```

## Components

The design system provides several ready-to-use components that help maintain consistency:

- `PTButton` - Styled buttons with various states
- `PTLabel` - Text with predefined styles
- `PTTextField` - Standardized text input
- `PTCard` - Card container with appropriate styling
- `PTSeparator` - Consistent divider/separator

These components automatically apply the correct styling from the token system, ensuring consistency throughout the app.

For more details, see the [PTDesignSystem README](ios/PTDesignSystem/README.md).