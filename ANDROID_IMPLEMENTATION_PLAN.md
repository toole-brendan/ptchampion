# Android Exercise Tracking Implementation Plan

**Goal:** Implement real-time exercise repetition counting and session saving using MediaPipe pose detection in the PTChampion Android application.

**Current State:**
*   CameraX is integrated for accessing and previewing the camera feed (`CameraScreen`, `CameraPreview`).
*   MediaPipe Pose Landmarker (`PoseLandmarkerHelper`) is set up to process camera frames in a live stream, detect pose landmarks, and handle initialization/errors.
*   `CameraViewModel` manages the camera lifecycle, MediaPipe helper, permissions, and basic UI state (`CameraUiState`).
*   `PoseOverlay` visualizes the detected pose landmarks and connections on top of the camera preview.
*   Navigation is set up: `ExerciseListScreen` -> `CameraScreen` (passing `exerciseType`).
*   Exercise list is currently hardcoded (`ExerciseListViewModel`).

**Core Missing Components:**
1.  **Exercise Analysis Logic:** Interpreting pose landmarks to count reps and potentially assess form.
2.  **Camera Screen UI/UX Enhancements:** Controls for starting/stopping sessions and displaying results/feedback.
3.  **Workout Session Persistence:** Saving the completed workout data to the backend.

## Implementation Steps

### 1. Backend Infrastructure Setup (Azure Database) - ✅ COMPLETED

*   **Provision Azure Database:** ✅
    *   Created an Azure PostgreSQL Flexible Server instance (`ptchampion-db`) in the East US region using Azure CLI
    *   Configured storage (32GB) and compute (Standard_B1ms tier) resources
    *   Set up admin user `ptadmin` with secure password
*   **Obtain Connection String:** ✅
    *   Successfully obtained connection string in the format: `postgresql://ptadmin:PASSWORD@ptchampion-db.postgres.database.azure.com:5432/ptchampion?sslmode=require`
*   **Update Backend Configuration:** ✅
    *   Updated both `.env` and `.env.dev` files with the Azure PostgreSQL connection string
    *   Removed previous AWS-related configuration
*   **Verify Connection:** ✅
    *   Successfully tested Go backend connection to Azure PostgreSQL
    *   Resolved authentication format issues specific to Azure PostgreSQL
*   **Configure Firewall Rules:** ✅
    *   Added firewall rule to allow connections from development machine
    *   Added firewall rule to allow connections from Azure services
*   **Create Database:** ✅
    *   Created `ptchampion` database on the PostgreSQL server

### 2. Database Migration (`00X_create_workouts_table.sql`) - ✅ COMPLETED

*   Created migration files (`0003_create_workouts_table.up.sql` and `.down.sql`) for the `workouts` table.
*   **Resolved Migration Dependencies:**
    *   Created `exercises` table migration (`0001_...`) to define exercise types.
    *   Updated initial schema (`0000_...`) to use `user_exercises` and reference the new `exercises` table ID.
    *   Added a separate migration (`0001c_...`) to add the foreign key constraint after both tables exist.
    *   Renumbered migrations to ensure correct execution order.
*   Successfully applied all migrations (`0000` to `0003`) to the Azure database after cleaning the schema.

### 3. Backend Endpoint for Saving Workouts (`POST /api/v1/workouts`) - ✅ COMPLETED

*   Defined `CreateWorkout` SQL query in `sql/queries/workout.sql`.
*   Updated `sql/schema/schema.sql` to include the `workouts` table.
*   Generated Go database code using `sqlc generate`.
*   Defined `SaveWorkoutRequest` struct in `internal/api/handlers/workout_handler.go`.
*   Implemented `handleSaveWorkout` handler function:
    *   Handles request binding and validation.
    *   Retrieves user ID from JWT context.
    *   Fetches exercise details using `GetExercise` query.
    *   Includes placeholder logic for grade calculation.
    *   Prepares parameters using helper functions (refactored to `helpers.go`).
    *   Calls `CreateWorkout` database query.
    *   Returns the created workout data (HTTP 201).
*   Added `POST /api/v1/workouts` route to `internal/api/router.go` under JWT authentication middleware.

### 4. Design and Implement Exercise Analyzers - ✅ COMPLETED

*   **Define Base Analyzer Interface/Class:** ✅
    *   Created the `ExerciseAnalyzer` interface in `domain/exercise/ExerciseAnalyzer.kt`.
    *   Defined `analyze(result: PoseLandmarkerHelper.ResultBundle): AnalysisResult` method.
    *   Created `AnalysisResult` data class with `repCount`, `feedback`, `state`, `confidence`, and `formScore` properties.
    *   Implemented `ExerciseState` enum with `IDLE`, `STARTING`, `DOWN`, `UP`, `FINISHED`, `INVALID` states.
    *   Added utility methods like `start()`, `stop()`, and `reset()`.
*   **Implement Angle Calculation Utility:** ✅
    *   Created `AngleCalculator` utility in `domain/exercise/utils/AngleCalculator.kt` for 3D angle calculations.
    *   Implemented visibility checking to handle partially detected landmarks.
*   **Implement Concrete Analyzers:** ✅
    *   Created classes implementing `ExerciseAnalyzer` interface for each exercise type:
      *   **`PushupAnalyzer`:**
          *   Detects key landmarks (shoulders, elbows, wrists, hips).
          *   Calculates elbow angles and hip alignment.
          *   Implements state machine for rep counting (DOWN → UP transitions).
          *   Provides form feedback on insufficient depth and hip alignment.
          *   Calculates form score (0-100) based on depth and alignment.
      *   **`PullupAnalyzer`:**
          *   Detects key landmarks (shoulders, elbows, wrists, nose).
          *   Tracks elbow extension and chin-over-bar position.
          *   Implements custom state machine logic for pull-ups.
          *   Provides feedback on full extension and chin position.
      *   **`SitupAnalyzer`:**
          *   Detects key landmarks (shoulders, hips, knees).
          *   Calculates torso angle throughout the movement.
          *   Implements state machine based on torso angle.
          *   Provides feedback on proper range of motion.

### 5. Integrate Analyzers into CameraViewModel - ✅ COMPLETED

*   **Enhanced CameraViewModel:** ✅
    *   Added `exerciseAnalyzer` field to hold the appropriate analyzer instance.
    *   Implemented `SessionState` enum with `IDLE`, `RUNNING`, `PAUSED`, `STOPPED` states.
    *   Added session state tracking to manage workout progress.
    *   Injected `SavedStateHandle` to get `exerciseType` from navigation.
    *   Implemented analyzer initialization based on exercise type in `init` block.
*   **Updated CameraUiState:** ✅
    *   Added fields for rep count, feedback, form score, and current exercise state.
    *   Added session state tracking in the UI state.
*   **Enhanced Frame Processing:** ✅
    *   Modified `processFrame` to only analyze frames during `RUNNING` state.
    *   Updated frame handling to prevent buffer issues in non-running states.
*   **Added Session Control Methods:** ✅
    *   Implemented `startSession()` function to begin a workout.
    *   Added `pauseSession()` and `stopSession()` functions for workout control.
    *   Added placeholder for workout saving logic in `stopSession()`.
*   **Enhanced Results Handling:** ✅
    *   Updated `onResults` callback to process MediaPipe results through the analyzer.
    *   Implemented state updates from analysis results to UI state flow.

### 6. Enhance CameraScreen UI - ✅ COMPLETED

*   **Added Info Displays:** ✅
    *   Created top info bar with exercise type, rep count, and form score.
    *   Implemented color-coding for form score (green/yellow/red).
*   **Added Form Feedback:** ✅
    *   Added feedback display with contextual highlighting for issues.
    *   Added error message display for detection issues.
*   **Implemented Control Interface:** ✅
    *   Added Start button (visible in IDLE and STOPPED states).
    *   Added Pause/Resume button (toggles in RUNNING/PAUSED states).
    *   Added Stop button to end workout session.
*   **Layout and Styling:** ✅
    *   Created semi-transparent overlays to ensure readability.
    *   Implemented responsive layouts that work with camera preview.
    *   Applied consistent styling and icon usage.
*   **Navigation Integration:** ✅
    *   Added `onWorkoutComplete` callback for navigation after workout.
    *   Connected Stop button to both save workout and trigger navigation.

### 7. Implement Workout Session Persistence - ✅ COMPLETED

*   **Define Data Model (Shared):** ✅
    *   Created Kotlin data classes `WorkoutSession`, `SaveWorkoutRequest`, `WorkoutResponse` in `domain/model/WorkoutSession.kt`.
    *   Backend `SaveWorkoutRequest` struct defined in Go.
*   **Create API Service Interface (Kotlin):** ✅
    *   Defined `WorkoutApiService` interface with `saveWorkout` and `getExercises` functions in `data/network/WorkoutApiService.kt`.
*   **Create Repository (Kotlin):** ✅
    *   Defined `WorkoutRepository` interface with `saveWorkout` and `getExercises` functions in `domain/repository/WorkoutRepository.kt`.
    *   Implemented `WorkoutRepositoryImpl` in `data/repository/WorkoutRepositoryImpl.kt`, calling the API service.
*   **Provide Dependencies (Hilt):** ✅
    *   Added provider for `WorkoutApiService` in `di/NetworkModule.kt`.
    *   Bound `WorkoutRepository` to `WorkoutRepositoryImpl` in `di/RepositoryModule.kt`.
*   **Integrate Repository (Kotlin):** ✅
    *   Injected `WorkoutRepository` into `CameraViewModel`.
    *   Implemented session start time tracking in `CameraViewModel`.
    *   Implemented `saveWorkoutSession` method in `CameraViewModel`:
        *   Calculates duration.
        *   Retrieves `exerciseId` from navigation arguments.
        *   Creates `SaveWorkoutRequest`.
        *   Calls `workoutRepository.saveWorkout`.
        *   Updates UI state (`isSaving`, `saveSuccess`, `saveError`).
        *   Sends navigation event (`CameraNavigationEvent.NavigateBack`) on success.
    *   **Note:** Backend JWT middleware handles User ID extraction.
*   **UI Feedback and Navigation:** ✅
    *   Added `isSaving`, `saveSuccess`, `saveError` to `CameraUiState`.
    *   Added `CameraNavigationEvent` for navigation.
    *   Updated `CameraScreen`:
        *   Collects navigation events and triggers `onWorkoutComplete`.
        *   Uses `SnackbarHost` to show save errors.
        *   Shows `LinearProgressIndicator` while `isSaving`.
        *   Shows success message.
        *   Disables buttons while saving.

### 8. (Optional) Refinements - 🔄 PARTIALLY COMPLETED

*   **Activate GPU Delegate:** ✅ COMPLETED
*   **Fix Front Camera Mirroring:** ✅ COMPLETED
*   **Improve Form Checking:** - 🔄 PENDING
*   **Dynamic Exercise List:** ✅ COMPLETED
*   **Workout History Endpoint:** ✅ COMPLETED
    *   **Backend:** ✅ COMPLETED (Added `GET /api/v1/workouts` with pagination)
    *   **Android:** ✅ COMPLETED (Added API service call, repository method, `HistoryScreen`, `HistoryViewModel`)

### 9. Implement Local Leaderboards (Proximity-Based) - 🔄 IN PROGRESS

**Goal:** Allow users to view leaderboards filtered by users within a specific radius (e.g., 5 miles) of their last known location.

**Prerequisites:** ✅ COMPLETED

**Implementation Steps:**

**A. Database Enhancements (PostgreSQL with PostGIS):** ✅ COMPLETED
*   **Enable PostGIS Extension:** ✅ COMPLETED (Migration `0005`)
*   **Add Location Column to Users Table:** ✅ COMPLETED (Migration `0006`, added `last_location GEOGRAPHY` and index)
*   **Update User Model (Go):** ✅ COMPLETED (`sqlc` generated code updated)

**B. Backend API Enhancements (Go):** ✅ COMPLETED
*   **Update User Profile Endpoint:** ✅ COMPLETED (Implemented `PUT /api/v1/profile/location` and handler `handleUpdateUserLocation`)
*   **Create Local Leaderboard Endpoint:** ✅ COMPLETED (Implemented `GET /api/v1/leaderboards/local` and handler `handleGetLocalLeaderboard`)
*   **New Database Query (`GetLocalLeaderboard`):** ✅ COMPLETED (Added to `leaderboard.sql`)
*   **OpenAPI Spec Update:** ✅ COMPLETED (Added paths and schemas to `openapi.yaml`)
*   **Code Generation:** ✅ COMPLETED (`oapi-codegen` run)

**C. Client-Side Implementation (Android/iOS/Web):** ✅ COMPLETED (Android Core)
*   **Location Permissions:** ✅ COMPLETED (Added to `AndroidManifest.xml`, handled in `LocalLeaderboardScreen`)
*   **Get User Location:** ✅ COMPLETED (Implemented `LocationService`, integrated into `LocalLeaderboardViewModel`)
*   **Update User Location:** ✅ COMPLETED (API called in `LocalLeaderboardViewModel` after location retrieval)
*   **Local Leaderboard Screen:** ✅ COMPLETED (Created `LocalLeaderboardScreen` and `ViewModel`, list display, permission handling)
*   **API Client Updates:** ✅ COMPLETED (Added API service calls, repository methods, data classes)
*   **Exercise Selector:** ✅ COMPLETED (Added `ExposedDropdownMenuBox` to screen)
*   **Rationale UI:** ✅ COMPLETED (Added `AlertDialog` for rationale)
*   **Location Error Handling:** ✅ COMPLETED (Added basic error display and retry button)

**Considerations:**

*   **Privacy:** Be transparent about *why* location is needed and *how* it's used. Allow users to opt-out or not share location (they won't appear on local leaderboards). Only store the *last known* location, not a history.
*   **Accuracy:** Location accuracy can vary. Decide if coarse location is sufficient.
*   **Performance:** Spatial queries can be intensive. Ensure proper indexing (`GIST` index on the location column) and consider caching strategies if needed.
*   **Radius:** Make the radius configurable (e.g., via backend config or user setting) rather than hardcoding 5 miles everywhere.
*   **Data Freshness:** Decide how often user locations need to be updated for the leaderboards to feel current.

## Success Criteria

*   ✅ User can select an exercise from the list.
*   ✅ User can start a tracking session on the `CameraScreen`.
*   ✅ The application accurately counts repetitions in real-time for the selected exercise.
*   ✅ Basic form feedback is displayed.
*   ✅ User can stop the session.
*   ✅ The completed workout (exercise type, repetition count, duration) is successfully saved to the backend database associated with the correct user.
*   ✅ The saved workout is potentially viewable in a "History" screen (requires separate implementation for history viewing).
*   ✅ User can view their past workout history on a dedicated screen.
*   ✅ Backend successfully connects to and interacts with the Azure Database for PostgreSQL instance.
*   ✅ User can view their paginated workout history on the History screen.
*   ✅ User is prompted for location permission when viewing the Local Leaderboard screen.
*   ✅ If permission granted, the user's location is updated on the backend.
*   ✅ Local leaderboard entries for the selected exercise, filtered by proximity, are displayed.
*   ✅ Appropriate loading and error states (including permission denied/rationale) are shown on the Local Leaderboard screen.
