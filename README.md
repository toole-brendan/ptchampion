# PT Champion

PT Champion is a cross-platform fitness evaluation system that uses computer vision to track and evaluate military exercises. The ecosystem includes a web application and native mobile apps for iOS and Android, all sharing a common backend. The platform features global and local leaderboards, exercise tracking, and form analysis powered by TensorFlow's PoseNet model.

## Features

- **Exercise Tracking**: Monitor push-ups, pull-ups, sit-ups, and running performance
- **Computer Vision Analysis**: Real-time form analysis and feedback using TensorFlow and PoseNet
- **Leaderboards**: Compare your performance with others globally or locally
- **Personalized Feedback**: Get real-time form correction and improvement tips
- **Progress Tracking**: Monitor your performance over time with detailed history
- **Cross-Platform Synchronization**: Seamlessly sync your data between web and mobile apps
- **Offline Support**: Continue using the mobile apps without an internet connection
- **Bluetooth Integration**: Connect to fitness devices for heart rate and running metrics

## Project Structure

```
PT Champion/
├── / (Root - Web Application)
│   ├── server/                  # Backend Express.js server
│   │   ├── auth.ts              # Authentication logic with Passport.js
│   │   ├── db.ts                # Database connection setup
│   │   ├── index.ts             # Main server entry point
│   │   ├── migrate.ts           # Database migration utilities
│   │   ├── routes.ts            # API route definitions
│   │   ├── storage.ts           # Data access layer for PostgreSQL
│   │   └── vite.ts              # Vite server integration
│   │
│   ├── shared/                  # Shared code between frontend and backend
│   │   └── schema.ts            # Database schema with Drizzle ORM
│   │
│   ├── client/                  # Web frontend (React)
│   │   ├── src/
│   │   │   ├── components/      # Reusable UI components
│   │   │   ├── hooks/           # Custom React hooks
│   │   │   ├── lib/             # Utility functions and services
│   │   │   │   ├── exercise-grading.ts  # Exercise scoring algorithms
│   │   │   │   ├── protected-route.tsx  # Auth protection wrapper
│   │   │   │   ├── queryClient.ts       # API request utilities
│   │   │   │   ├── tensorflow.ts        # PoseNet integration
│   │   │   │   └── utils.ts             # General utilities
│   │   │   │
│   │   │   ├── pages/          # Application pages
│   │   │   │   ├── exercises/  # Exercise-specific pages
│   │   │   │   └── [...]       # Other page components
│   │   │   │
│   │   │   ├── App.tsx         # Main app component
│   │   │   └── main.tsx        # Application entry point
│   │   │
│   │   └── tailwind.config.ts  # Tailwind CSS configuration
│   │
│   ├── drizzle.config.ts       # Drizzle ORM configuration
│   └── [...]                   # Other configuration files
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

- **Frontend**: React with Tailwind CSS and shadcn UI components
- **Backend**: Node.js/Express API
- **Database**: PostgreSQL with Drizzle ORM
- **Authentication**: Passport.js with JWT and session-based auth
- **Computer Vision**: TensorFlow.js and PoseNet model

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

### Web Application Setup

1. Clone the repository:
   ```
   git clone <repository-url>
   cd pt-champion
   ```

2. Install dependencies:
   ```
   npm install
   ```

3. Set up environment variables by creating a `.env` file:
   ```
   DATABASE_URL=postgres://user:password@localhost:5432/pt_champion
   SESSION_SECRET=your-secret-key
   JWT_SECRET=your-jwt-secret
   ```

4. Initialize the database:
   ```
   npm run db:push
   ```

5. Start the development server:
   ```
   npm run dev
   ```

6. Open your browser and navigate to `http://localhost:5000`

### iOS Application Setup

1. Navigate to the iOS project directory:
   ```
   cd PTChampion-Swift
   ```

2. Install CocoaPods dependencies (if applicable):
   ```
   pod install
   ```

3. Open the Xcode project:
   ```
   open PTChampion.xcworkspace
   ```
   (or `PTChampion.xcodeproj` if not using CocoaPods)

4. Configure the `APIClient.swift` file with your backend URL:
   ```swift
   private let baseURL = "http://localhost:5000"
   ```

5. Build and run the application on your device or simulator.

### Android Application Setup

1. Navigate to the Android project directory:
   ```
   cd PTChampion-Kotlin
   ```

2. Open the project in Android Studio:
   - Launch Android Studio
   - Select "Open an Existing Project"
   - Navigate to the project directory

3. Configure the API base URL in the `build.gradle` file:
   ```gradle
   buildTypes {
       debug {
           buildConfigField "String", "API_BASE_URL", "\"http://localhost:5000\""
       }
   }
   ```

4. Build and run the application on your device or emulator.

## Usage

1. **Register/Login**: Create an account or login to access the application
2. **Select Exercise**: Choose from push-ups, pull-ups, sit-ups, or running
3. **Allow Camera Access**: Position yourself so the camera can track your form
4. **Perform Exercise**: Follow the on-screen guidance and receive real-time feedback
5. **Complete Session**: Finish your workout to save your score and form rating
6. **View Progress**: Check your history and leaderboard ranking

## Deployment

See the [DEPLOYMENT.md](./DEPLOYMENT.md) file for detailed instructions on deploying the application to AWS.

## License

This project is licensed under the MIT License - see the LICENSE file for details.