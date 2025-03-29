# MediaPipe Pose Detection Integration Guide for Android

This document outlines the implementation of MediaPipe pose detection in the PT Champion Android app, which enhances the exercise form detection for push-ups and other exercises.

## Overview

This integration brings several benefits over the existing ML Kit implementation:

- **More accurate pose detection** with 33 body landmarks (vs 17 in ML Kit)
- **Enhanced form analysis** for exercises with more detailed feedback
- **Better performance** in challenging lighting conditions
- **More precise hand position detection** for push-ups
- **Improved body alignment analysis** for all exercises

## Implementation Components

The MediaPipe integration consists of the following components:

1. `MediaPipePoseDetectionService.kt` - Main service for MediaPipe pose detection
2. `PoseDetectionManager.kt` - Coordinator between ML Kit and MediaPipe detection
3. `MediaPipeModelInstaller.kt` - Utility to download and install the model
4. `ExerciseViewModel.kt` - Updated ViewModel with detection toggling capability
5. `PushupExerciseScreen.kt` - Updated UI to toggle between detection systems

## Getting Started

### Gradle Dependencies

Make sure your `build.gradle.kts` includes the MediaPipe dependencies:

```kotlin
// MediaPipe pose detection
implementation("com.google.mediapipe:tasks-vision:0.10.0")
implementation("com.google.mediapipe:tasks-core:0.10.0")
```

### Model Installation

The MediaPipe model must be available on the device. There are two approaches:

1. **Bundle with the app**: Include `pose_landmarker_full.task` in the assets folder
2. **Download at runtime**: Use `MediaPipeModelInstaller` to fetch the model

For production apps, it's recommended to bundle the model in your app's assets to minimize first-run delays.

### Camera Permissions

Ensure your app has camera permissions in the manifest:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera" android:required="true"/>
```

## Usage

### Toggling Between Detection Systems

The app now includes UI controls to switch between ML Kit and MediaPipe:

```kotlin
IconButton(onClick = onTogglePoseDetection) {
    Icon(
        imageVector = if (uiState.useMediaPipeDetection) 
            Icons.Default.Star else Icons.Default.StarOutline,
        contentDescription = "Toggle detection system",
        tint = if (uiState.useMediaPipeDetection) 
            MaterialTheme.colorScheme.primary 
        else 
            MaterialTheme.colorScheme.onSurface
    )
}
```

The `PoseDetectionManager` handles the actual switching and preserves the user's choice.

### Enhancements to Pose Detection

The MediaPipe version includes several enhancements to pose detection:

#### Push-up Form Analysis

- **Hand position detection**: Checks for proper hand width and alignment with shoulders
- **Body alignment**: More precise detection of proper back alignment
- **Depth checking**: Better measurement of push-up depth and chest position
- **Arm symmetry**: Improved detection of uneven arm positioning

Similar enhancements were made for pull-ups and sit-ups.

## Architecture

The architecture follows these principles:

1. **Seamless fallback**: Falls back to ML Kit if MediaPipe fails
2. **User preference persistence**: Remembers detection system choice
3. **Performance optimization**: Runs on GPU where available
4. **Compatibility layer**: Maps between MediaPipe and existing app data structures

The data flow follows this pattern:

```
Camera → Image Analysis → PoseDetectionManager → Appropriate Detector → Update UI
```

## Troubleshooting

### Common Issues

1. **Model Not Found**: 
   - Verify the model file exists in the app's files directory
   - Check that `MediaPipeModelInstaller` has been called during app initialization

2. **Detection Not Working**:
   - Check if camera permission has been granted
   - Verify that the model was successfully loaded
   - Look for exceptions in `MediaPipePoseDetectionService`

3. **Performance Issues**:
   - Try reducing the camera resolution
   - Ensure GPU acceleration is enabled where possible
   - Consider using a lower-complexity model variant

### Logging

The implementation includes detailed logging to help diagnose issues:

- `PoseDetectionManager`: Logs detection system changes and fallbacks
- `MediaPipePoseDetectionService`: Logs detection errors
- `MediaPipeModelInstaller`: Logs model installation progress

## Future Improvements

Potential enhancements:

1. **Custom model training**: Train models specific to each exercise
2. **Offline mode enhancements**: Ensure model is available without network
3. **Multi-person detection**: Support for detecting multiple users exercising
4. **GPU optimizations**: Further performance tuning for different devices

## Credits

- [MediaPipe by Google](https://github.com/google/mediapipe)
- [TensorFlow Lite](https://www.tensorflow.org/lite)
