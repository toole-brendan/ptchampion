# PT Champion - Kotlin App Development Status

This document tracks the development progress and outlines the remaining tasks for the PT Champion Android (Kotlin) application.

## Current Status

The Kotlin application has been bootstrapped with a modern Android development stack. Key components and features implemented so far include:

1.  **Project Structure:**
    *   Standard Android project structure with separation of concerns (`data`, `di`, `domain`, `model`, `ui`, `util`).
    *   Package-by-feature structure within `ui/screens` (e.g., `login`, `signup`, `splash`).

2.  **Core Architecture:**
    *   **UI:** Jetpack Compose for declarative UI development.
    *   **Architecture Pattern:** MVVM-like approach using ViewModels (`LoginViewModel`, `SignUpViewModel`, `SplashViewModel`) managing state and events.
    *   **Dependency Injection:** Hilt for managing dependencies throughout the application (`NetworkModule`, `RepositoryModule`, `DataStoreModule`).
    *   **Navigation:** Jetpack Navigation Compose for navigating between screens (`MainActivity`, `Screen.kt`, `NavHost`).

3.  **Theming:**
    *   Material 3 theme implemented (`Theme.kt`, `Color.kt`, `Type.kt`, `Shape.kt`).
    *   Customized dark-only, minimalist, industrial style with grey tones and sharp corners.

4.  **Networking:**
    *   Retrofit and OkHttp for network communication with the backend API.
    *   Kotlinx Serialization for JSON parsing.
    *   Generated OpenAPI client (`generatedapi`) integrated via Retrofit.
    *   Basic network error handling within repositories (`Resource.kt`).

5.  **Authentication Flow:**
    *   **Login Screen:** UI for email/password input, loading/error state display, navigation to Sign Up/Home.
    *   **Sign Up Screen:** UI for email/password/confirm password input, basic validation, loading/error state display, navigation to Login.
    *   **Splash Screen:** Initial screen that checks for a saved auth token to determine navigation to Login or Home.
    *   **Authentication State Persistence:** Jetpack DataStore (Preferences) used via `UserPreferencesRepository` to save and retrieve the authentication token.
    *   `AuthRepository` defined (`domain`/`data` layers) to handle login/registration API calls.

6.  **Dependencies:**
    *   Essential dependencies for Compose, Hilt, Navigation, Retrofit, DataStore, Coroutines, MediaPipe, CameraX, etc., are configured in `app/build.gradle.kts`.

## To-Do / Next Steps

While the foundation is laid, significant work remains to make the app fully functional and feature-complete:

1.  **Core Feature Implementation:** **[PARTIALLY DONE]**
    *   `[PARTIALLY DONE]` **HomeScreen:** Implement the main screen UI after login (e.g., user dashboard, quick actions, navigation to other features). (Basic structure with ViewModel/State and placeholder sections added, uses UserRepository)
    *   `[DONE]` **ExerciseList Screen:** Display available exercises fetched from the API. (Implemented with hardcoded list, navigates to Camera)
    *   `[TODO]` **ExerciseDetail Screen:** Show details for a selected exercise.
    *   `[DONE]` **Leaderboard Screen:** Fetch and display global/local leaderboards from the API. (Implemented)
    *   `[PARTIALLY DONE]` **Profile Screen:** Display user information, allow editing. (Basic UI with ViewModel/State showing placeholder user data added, uses UserRepository, Logout implemented).

2.  **Logout Functionality:** **[PARTIALLY DONE]**
    *   `[DONE]` Add a mechanism (e.g., button in Profile/Home) to clear the saved auth token from DataStore (`UserPreferencesRepository.clearAuthToken`). (Added to basic ProfileScreen)
    *   `[DONE]` Navigate the user back to the `LoginScreen` after logout.
    *   `[TODO]` Add Logout option to a more prominent place (e.g., final Profile screen or AppBar).

3.  **Token Handling & Security:** **[PARTIALLY DONE]**
    *   `[DONE]` **Token Validation:** Implement token validation logic (potentially in `SplashViewModel` or an OkHttp Interceptor) to check if the saved token is still valid before navigating to `Home`. (Implemented in SplashViewModel)
    *   `[TODO]` **Token Refresh:** Implement token refresh logic if the backend API supports it.
    *   `[TODO]` **Secure Token Storage:** Consider using EncryptedSharedPreferences or equivalent via DataStore if higher security for the token is required (though DataStore Preferences is often sufficient for auth tokens).
    *   `[DONE]` **Auth Interceptor:** Create an OkHttp Interceptor to automatically add the auth token to relevant API requests.

4.  **Camera & Pose Detection:** **[PARTIALLY DONE]**
    *   `[DONE]` **CameraScreen:** Implement the camera preview using CameraX, handle permissions (`CameraScreen.kt`, `CameraViewModel.kt`).
    *   `[PARTIALLY DONE]` **MediaPipe Integration:** Integrate MediaPipe `PoseLandmarker` for real-time pose detection (`PoseLandmarkerHelper.kt`, integrated into `CameraViewModel`, `PoseOverlay.kt` created for drawing).
    *   `[TODO]` **Exercise Grading Logic:** Implement the logic in `posedetection` or `domain` layers to analyze poses and count repetitions/evaluate form based on the specific `exerciseType` passed to the `CameraScreen`.
    *   `[DONE]` **Permissions Handling:** Ensure robust handling of Camera permissions using Accompanist Permissions (`CameraScreen.kt`).

5.  **Bluetooth Integration:** **[TODO]**
    *   Implement `BluetoothManager` (likely in `data` or `services`) using the Nordic BLE Library.
    *   Scan for and connect to supported fitness devices.
    *   Collect and display/process heart rate and running metrics.
    *   Handle Bluetooth permissions correctly (including Location on older Android versions).

6.  **Data Layer Enhancements:** **[PARTIALLY DONE]**
    *   `[DONE]` Implement remaining repositories (e.g., `LeaderboardRepository`).
    *   `[PARTIALLY DONE]` Implement `ExerciseRepository` (for history/logging), `UserRepository` (for profile data). (UserRepository interface, basic impl with placeholder data, and Hilt binding added)
    *   `[TODO]` Implement `ExerciseRepository` (for history/logging).
    *   `[TODO]` Find/implement way to get list of available exercises (API endpoint or keep hardcoded).
    *   `[TODO]` Consider local caching strategies (e.g., using Room database) if offline support or improved performance is needed.
    *   `[PARTIALLY DONE]` Integrate actual API call for fetching user profile in `UserRepositoryImpl`. (API injected, basic call structure and error handling added; requires verification of endpoint/DTO and mapping implementation).

7.  **UI/UX Refinements:** **[PARTIALLY DONE]**
    *   `[DONE]` Replace placeholder screens with actual implementations (Leaderboard, ExerciseList).
    *   `[PARTIALLY DONE]` Replace placeholder screens with actual implementations (Basic Home/Profile UI structure added).
    *   `[DONE]` Add UI elements like `AppBar` or `BottomNavigationBar` as needed (using `Scaffold`). (BottomNav implemented)
    *   `[TODO]` Implement proper loading indicators and empty states for lists/data fetching. (Basic implemented in Leaderboard, Home, Profile).
    *   `[TODO]` Improve error handling feedback (e.g., using Snackbars).
    *   `[TODO]` Refine the industrial theme and potentially add custom fonts.
    *   `[TODO]` Implement actual Home screen UI (beyond basic structure).
    *   `[TODO]` Implement actual Profile screen UI (beyond basic structure).

8.  **Testing:** **[TODO]**
    *   Add Unit tests for ViewModels and Repositories.
    *   Add Integration tests for UI flows and navigation.

9.  **Build & Configuration:** **[TODO]**
    *   Configure Proguard/R8 for release builds.
    *   Manage API base URLs and potentially other secrets using `build.gradle` configurations or secrets management tools.
