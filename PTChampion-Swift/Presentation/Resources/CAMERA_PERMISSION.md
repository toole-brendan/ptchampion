# Camera Permission Setup

The MediaPipe pose detection requires camera access. Make sure you have the following entry in your Info.plist file:

```xml
<!-- Required for camera access -->
<key>NSCameraUsageDescription</key>
<string>PT Champion needs camera access to analyze your exercise form.</string>
```

## Steps to Add Camera Permission

1. Open your project in Xcode
2. Find Info.plist in the Project Navigator
3. Add a new entry with key `NSCameraUsageDescription`
4. Set its value to the message explaining camera usage
5. Save the file

This permission is essential for the app to access the camera and perform pose detection for exercise tracking.
