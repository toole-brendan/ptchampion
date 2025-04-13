# MediaPipe Pose Detection Integration Guide

This document provides instructions for completing the integration of MediaPipe pose detection into the PT Champion iOS app.

## Overview

The integration brings several benefits:

- More accurate pose detection with 33 body landmarks (vs. 18 in Vision)
- Better detection in challenging lighting conditions
- Enhanced form feedback for exercises
- Improved tracking of hand positions for push-ups
- Better body alignment detection

## Implementation Status

We've implemented:

1. `MediaPipePoseDetectionService.swift` - A complete MediaPipe-based pose detection service
2. `ExerciseViewModel+MediaPipe.swift` - An extension to support switching between Vision and MediaPipe
3. Updated `PushupView.swift` with a UI toggle to switch detection systems

## Required Actions to Complete Integration

### 1. Add MediaPipe Dependency

#### Option A: CocoaPods

Add to your Podfile:

```ruby
pod 'MediaPipeTasksVision', '~> 0.10.0'
```

Then run:

```bash
pod install
```

#### Option B: Swift Package Manager

Add the MediaPipe package in Xcode:
1. File → Swift Packages → Add Package Dependency
2. Enter `https://github.com/google/mediapipe-tasks-swift.git`
3. Select version `0.10.0` or newer

### 2. Download MediaPipe Model

1. Download the MediaPipe pose landmarker model:
   ```bash
   curl -O https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_full/float16/latest/pose_landmarker_full.task
   ```

2. Add the model to your Xcode project:
   - Drag the downloaded `.task` file into your Xcode project
   - Ensure "Copy items if needed" is checked
   - Add to your app target

### 3. Add Privacy Description

In `Info.plist`, ensure you have:

```xml
<key>NSCameraUsageDescription</key>
<string>PT Champion needs camera access to track your exercise form.</string>
```

### 4. Test the Implementation

1. Build and run the app
2. Navigate to Push-ups exercise
3. Tap the "wand and stars" icon in the top-right
4. Select "Toggle MediaPipe Detection" to switch detection systems
5. Verify the pose detection works with improved skeleton overlay

## Customizing the Detection

The integration uses dual detection systems that can be toggled:

- Vision framework (original) - Better compatibility with iOS but fewer landmarks
- MediaPipe (new) - Better accuracy and more landmarks

The toggle option allows users to switch between systems if one performs better on their device.

### Implementation Notes

- MediaPipe requires a downloaded model file (see step 2)
- The integration handles both detection systems transparently
- Default uses the original Vision-based detection
- The toggle persists user preference via UserDefaults

## Troubleshooting

### Common Issues

1. **Model File Not Found**
   - Verify the model file is included in the app bundle
   - Check the path: `pose_landmarker_full.task`

2. **Camera Permission Denied**
   - Ensure privacy description is properly set in Info.plist
   - User must grant camera permission

3. **Performance Issues**
   - MediaPipe is optimized but demanding on older devices
   - Consider reducing the camera resolution or frame rate
   - The throttling in `CameraView.swift` helps maintain performance

### Debug Logging

Debug statements have been added to:
- Show whether MediaPipe or Vision is being used
- Log when detection is switched

## Future Enhancements

Potential improvements:

1. Add user-facing toggle in settings
2. Implement device capability check to auto-select best detection system
3. Add profile-specific pose detection preferences
4. Implement A/B testing to compare accuracy between systems

## Credits

- [MediaPipe by Google](https://github.com/google/mediapipe)
- [MediaPipe Tasks Swift](https://github.com/google/mediapipe-tasks-swift)
