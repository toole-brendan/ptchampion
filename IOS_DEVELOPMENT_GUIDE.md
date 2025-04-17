# PT Champion iOS Development Guide: Achieving Android Parity

## 1. Introduction

**Goal:** This document outlines the steps and considerations required to develop the PT Champion iOS application (`ios/`) to match the features, functionality, and styling of the existing Android application (`android/`).

**Reference Points:**
*   **Android Module:** `android/` serves as the functional blueprint.
*   **Backend API:** `openapi.yaml` defines the data structures and endpoints.
*   **Core Logic:** Shared concepts in `internal/grading/` might be relevant.
*   **Styling Guide:** Refer to the `PT CHAMPION STYLING GUIDE V2` section in the main `README.md`.

## 2. Prerequisites

*   **macOS:** Latest version recommended.
*   **Xcode:** Latest version (supporting Swift 5.7+ and iOS 16+).
*   **CocoaPods / Swift Package Manager:** For dependency management.
*   **Apple Developer Account:** For testing on physical devices (especially for Bluetooth/Camera features).
*   **Familiarity:** Swift, SwiftUI, Combine/async/await, Core Data, Core Location, Core Bluetooth, AVFoundation, Vision framework.

## 3. Project Setup & Architecture

*   **Directory:** Ensure the project resides in the `ios/` directory.
*   **Target:** Target iOS 16.0 or later to leverage modern SwiftUI features.
*   **Architecture:** Implement the **MVVM (Model-View-ViewModel)** pattern, consistent with the Android app and the existing `README.md` plan.
    *   **Views (SwiftUI):** Define the UI screens and components. Keep them lightweight and focused on presentation.
    *   **ViewModels (ObservableObject):** Contain presentation logic, state management for views, and interact with Services/Repositories. Use `@StateObject`, `@ObservedObject`, or `@EnvironmentObject` appropriately.
    *   **Models (Codable):** Represent data structures, mirroring the backend API models (potentially generated or manually defined based on `openapi.yaml`).
    *   **Services/Repositories:** Handle data fetching (networking), data persistence (Core Data), Bluetooth interactions, location services, etc. Define protocols for these services to facilitate dependency injection and testing.
*   **Dependency Management:** Use **Swift Package Manager (SPM)** preferably, or CocoaPods if necessary.
*   **Dependency Injection:**
    *   Start with manual injection via initializers or use SwiftUI's `@EnvironmentObject` for widely used services (like an `AuthService`).
    *   Avoid singletons where possible; favor injecting dependencies through initializers or environment objects.

## 4. Core Functionality Implementation

Implement features mirroring the Android app, using appropriate iOS frameworks:

### 4.1. Authentication

*   **Screens:** Login, Registration views.
*   **Networking:** Create an `AuthService` using `URLSession` with `async/await` or `Combine` to call backend login/register endpoints defined in `openapi.yaml`. Use `Codable` for request/response parsing.
*   **Token Storage:** Use **Keychain Services** for secure storage of the JWT authentication token. `UserDefaults` is **not** suitable for sensitive data like auth tokens. Create a wrapper service (e.g., `KeychainService`) for easier interaction.
*   **State Management:** Maintain authentication state (e.g., `isAuthenticated`) in a shared object (e.g., `AuthViewModel` or `AppState` object) potentially injected via `@EnvironmentObject`.

### 4.2. Exercise Flow

*   **Exercise Selection:** A `View` displaying available exercises (Push-ups, Pull-ups, Sit-ups, Running). Fetch details if needed from the backend.
*   **Camera View & Pose Tracking:**
    *   Use **`AVFoundation`** to set up the camera capture session.
    *   Use Apple's **`Vision`** framework, specifically `VNDetectHumanBodyPoseRequest`, to detect body landmarks in real-time from the camera feed. This mirrors Android's use of MediaPipe `PoseLandmarker`.
    *   Create a dedicated `PoseAnalyzer` or `ExerciseTracker` class (similar to Android's `domain/analyzer`) to process the detected poses.
*   **Real-time Form Analysis & Grading:**
    *   Translate the grading logic (potentially from `internal/grading/` or by analyzing the Android app's logic) into Swift.
    *   Implement logic within the `PoseAnalyzer` to calculate joint angles, detect repetitions, and evaluate form based on the `Vision` framework's output.
    *   Provide real-time feedback on the SwiftUI `View` (e.g., rep count, form correction prompts).
*   **Exercise Result Screen:** Display the summary (reps, time, score, form rating). Post results to the backend via a `WorkoutService`.

### 4.3. Progress Tracking & History

*   **Screen:** A `View` showing past workout sessions.
*   **Data Fetching:** Fetch workout history from the backend API using `URLSession`.
*   **Data Persistence (Optional Caching):** Consider using **`Core Data`** to cache workout history for faster loading and basic offline viewing, though the primary source should be the backend.
*   **Visualization:** Use a Swift charting library (e.g., `Swift Charts` available in iOS 16+) or a third-party library via SPM to display progress graphs, mirroring the Android implementation style. Apply colors from the style guide.

### 4.4. Leaderboards

*   **Screens:** Views for Global and Local leaderboards.
*   **Global Leaderboard:** Fetch data directly from the backend API.
*   **Local Leaderboard:**
    *   Use **`Core Location`** to get the user's current location (requesting appropriate permissions).
    *   Send the location coordinates along with the leaderboard request to the backend API (assuming the backend endpoint supports location-based filtering as described in `README.md`).
*   **UI:** Display rankings using SwiftUI `List` or `LazyVStack`.

### 4.5. Bluetooth Integration

*   **Framework:** Use **`Core Bluetooth`** framework.
*   **Heart Rate Monitoring:** Scan for and connect to Bluetooth LE devices advertising the standard Heart Rate Service UUID. Subscribe to the heart rate measurement characteristic.
*   **GPS Watch Integration (Garmin, Polar, Suunto, etc.):** This requires understanding the specific Bluetooth services and characteristics these devices expose for running metrics (pace, cadence, distance). It might involve reverse-engineering or finding documentation for their GATT specifications. Implement specific `BluetoothService` handlers for recognized device types. This is complex and device-specific.
*   **Permissions:** Ensure proper `Info.plist` keys and user prompts for Bluetooth access (`NSBluetoothAlwaysUsageDescription`, `NSBluetoothPeripheralUsageDescription`).
*   **Service Class:** Encapsulate Bluetooth logic within a dedicated `BluetoothManager` or similar service.

### 4.6. Offline Support

*   **Data Caching:** Use `Core Data` to store essential data needed offline (e.g., user profile basics, cached history).
*   **Workout Recording:** Allow users to perform and record exercises offline. Store results locally (e.g., in `Core Data` with a "needs sync" flag).
*   **Synchronization:** Implement logic to sync locally stored offline data (e.g., completed workouts) to the backend when connectivity is restored.

## 5. UI & Styling (SwiftUI)

*   **Reference:** Adhere strictly to the `PT CHAMPION STYLING GUIDE V2` in `README.md`.
*   **Colors:** Define the specified HEX colors (Tactical Cream, Deep Ops Green, Brass Gold, etc.) as static properties in a `Color` extension or a dedicated `Theme` struct. Use them throughout the UI.
    ```swift
    // Example Color Extension
    import SwiftUI

    extension Color {
        static let tacticalCream = Color(hex: "#F4F1E6")
        static let deepOpsGreen = Color(hex: "#1E241E")
        static let brassGold = Color(hex: "#BFA24D")
        // ... add other colors
    }
    ```
*   **Fonts:**
    *   Include the specified fonts (Bebas Neue, Montserrat, Roboto Mono) in the project and register them in `Info.plist`.
    *   Create custom `Font` extensions or `ViewModifiers` for easy application of the defined text styles (Heading, Subheading, Stats, Labels).
    ```swift
    // Example Font Modifier
    struct HeadingStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .font(.custom("BebasNeue-Bold", size: 28)) // Adjust size as needed
                .foregroundColor(.commandBlack)
                .textCase(.uppercase)
        }
    }

    extension View {
        func headingStyle() -> some View {
            self.modifier(HeadingStyle())
        }
    }
    ```
*   **Components:** Recreate UI components (Buttons, Cards, Bottom Navigation) using standard SwiftUI views (`Button`, `ZStack`, `RoundedRectangle`, `TabView`) and style them using modifiers (`.background`, `.foregroundColor`, `.cornerRadius`, `.shadow`, `.padding`, `.font`).
    *   **Bottom Navigation:** Use SwiftUI's `TabView` with custom styling on the tab items (`.tabItem`) to match the design (icon color, label font/case).
    *   **Cards:** Use `ZStack` or `.background` with `RoundedRectangle` for card shapes, applying padding, background color, and shadows.
    *   **Charts:** Use `Swift Charts` or a library, configuring colors and fonts according to the guide.
*   **Layout:** Use `VStack`, `HStack`, `ZStack`, `LazyVGrid`, `Spacer`, `.padding()`, `.frame()` etc., to achieve the desired layouts and spacing defined in the guide.
*   **Logo:** Use an `Image` view for the emblem, applying appropriate `.resizable()`, `.scaledToFit()`, `.frame()` and `.foregroundColor()` modifiers based on the background. Position as specified using `.safeAreaInset` or overlays.

## 6. Networking Layer

*   **Base Client:** Create a reusable API client class using `URLSession`.
*   **Endpoints:** Define functions for each API endpoint specified in `openapi.yaml`.
*   **Request/Response:** Use `Codable` models for JSON encoding/decoding.
*   **Error Handling:** Implement robust error handling for network issues and API error responses.
*   **Authentication Header:** Ensure the JWT token (from Keychain) is added to the `Authorization` header for authenticated requests.

## 7. Data Persistence

*   **`Core Data`:** Suitable for structured data like workout history caching. Set up the Core Data stack (`NSPersistentContainer`), define entities in the `.xcdatamodeld` file, and create repository classes to interact with the store.
*   **`Keychain`:** For secure storage of the auth token and potentially other sensitive credentials.
*   **`UserDefaults`:** Only for non-sensitive user preferences (e.g., theme choice if added later, settings).

## 8. Testing

*   **Unit Tests (XCTest):** Write unit tests for ViewModels, Services, grading logic, and utility functions. Use mock objects/protocols for dependencies.
*   **UI Tests (XCUITest):** Implement UI tests for critical user flows (login, starting/completing an exercise, navigating tabs).

## 9. Dependencies (Potential SPM Packages)

*   **Charting:** `Swift Charts` (built-in iOS 16+) or consider `Charts` (DGCharts wrapper) if more complex charts needed or targeting older iOS.
*   **Networking (Optional):** While `URLSession` is powerful, `Alamofire` can sometimes simplify requests, but adds an external dependency.
*   **Async Helpers (Optional):** Libraries like `CombineExt` can add useful operators if using Combine heavily.

This guide provides a comprehensive roadmap. Refer back to the Android implementation (`android/`), the `openapi.yaml` spec, and the `README.md` styling guide frequently during development. 