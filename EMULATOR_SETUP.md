# PT Champion Emulator Setup Guide

This guide provides detailed instructions for setting up and running the PT Champion application in emulators for both the Android (Kotlin) and iOS (Swift) versions.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Backend Setup](#backend-setup)
3. [Android Emulator Setup (Kotlin Version)](#android-emulator-setup-kotlin-version)
4. [iOS Simulator Setup (Swift Version)](#ios-simulator-setup-swift-version)
5. [Troubleshooting](#troubleshooting)

## Prerequisites

Before proceeding with the emulator setup, ensure you have the following installed:

### For Backend:
- Node.js (v14+)
- PostgreSQL database

### For Android Development:
- Android Studio (latest version)
- Java Development Kit (JDK) 11 or newer
- Android SDK

### For iOS Development:
- macOS operating system
- Xcode (latest version)
- CocoaPods

## Backend Setup

The backend must be running before you launch the mobile applications in the emulators. The backend serves as the API for both the Android and iOS versions.

1. Start the backend server:

```bash
# From the project root
npm run dev
```

2. Verify the server is running:
   - The server should be available at `http://localhost:5000`
   - The console should display: "serving on port 5000"

3. Set environment variables:
   - Create a `.env` file in the project root if it doesn't exist
   - Ensure `DATABASE_URL` is properly configured with your PostgreSQL connection string

## Android Emulator Setup (Kotlin Version)

### Setting Up Android Studio

1. Open Android Studio
2. Select "Open an existing project"
3. Navigate to and select the `PTChampion-Kotlin` directory

### Configure the Emulator

1. Click on the AVD Manager (Android Virtual Device) in the toolbar or navigate to Tools > AVD Manager
2. Click on "Create Virtual Device"
3. Select a device (Pixel 4 or newer recommended for optimal testing)
4. Select a system image:
   - Choose Android API level 30 (Android 11) or newer
   - If not available, download it by clicking the "Download" link next to the system image
5. Configure the AVD with the following settings:
   - Name: "PT-Champion-Test"
   - Startup orientation: Portrait
   - Device frame: Enable
   - Memory and Storage: Default
   - Enable device frame and keyboard input
6. Click "Finish" to create the virtual device

### Configure the App for Emulator

1. Open the `PTChampion-Kotlin/app/src/main/kotlin/com/ptchampion/data/remote/ApiClient.kt` file
2. Update the base URL to point to your local backend:

```kotlin
// For Android emulator, 10.0.2.2 is used to access the host's localhost
private const val BASE_URL = "http://10.0.2.2:5000/api/"
```

### Run the Android App

1. In Android Studio, select the created emulator from the device dropdown
2. Click the "Run" button (green triangle) or press Shift+F10
3. Wait for the emulator to boot and the app to install
4. The app should launch automatically on the emulator

### Testing with Camera

The Android emulator has limited camera functionality for testing pose detection:

1. In the emulator, press the "..." or "More" button on the side panel
2. Select "Camera" and then "Virtual scene"
3. You can use the virtual scene to simulate basic camera input
4. Alternatively, use "Webcam" to use your computer's webcam as the emulator's camera

## iOS Simulator Setup (Swift Version)

### Setting Up Xcode

1. Open Xcode
2. Select "Open another project..."
3. Navigate to and select the `PTChampion-Swift` directory
4. Wait for Xcode to index the project

### Install Dependencies

1. Open Terminal and navigate to the `PTChampion-Swift` directory
2. Install CocoaPods dependencies:

```bash
pod install
```

3. If the above command created a workspace file, close Xcode and reopen the project using the `.xcworkspace` file

### Configure the App for Simulator

1. Open the `PTChampion-Swift/Services/API/APIClient.swift` file
2. Update the base URL to point to your local backend:

```swift
private let baseURL = "http://localhost:5000/api"
```

### Configure the Simulator

1. In Xcode, click on the scheme selector in the toolbar
2. Select an iPhone simulator (iPhone 12 or newer recommended)
3. Ensure the scheme is set to "PTChampion" and not "Test" or "Profile"

### Run the iOS App

1. Click the "Play" button in the Xcode toolbar or press Cmd+R
2. Wait for the simulator to launch and the app to install
3. The app should start automatically in the simulator

### Testing with Camera

The iOS simulator has limited camera capabilities:

1. For testing camera functionality, you can simulate camera input by going to Features > Camera in the simulator menu
2. Select "Simulator Photo Input" to choose an image or video
3. For live pose detection, it's recommended to test on a physical device

## Troubleshooting

### Android Emulator Issues

1. **App crashes on startup:**
   - Check logcat output in Android Studio
   - Verify the backend URL is correctly set to `10.0.2.2:5000` instead of `localhost`
   - Ensure API level compatibility

2. **Network connection issues:**
   - Verify that the emulator has internet access
   - Check that your backend server is running
   - Add `<uses-permission android:name="android.permission.INTERNET" />` to AndroidManifest.xml if not present

3. **Camera not working:**
   - Android emulator camera capabilities are limited
   - Use the "Extended controls" > "Camera" options to test basic functionality

### iOS Simulator Issues

1. **Build errors:**
   - Check that all dependencies are installed via CocoaPods
   - Update CocoaPods: `sudo gem install cocoapods`
   - Clean build folder (Shift+Cmd+K) and build again

2. **Network connection issues:**
   - Add necessary permissions in Info.plist:
     ```xml
     <key>NSAppTransportSecurity</key>
     <dict>
         <key>NSAllowsLocalNetworking</key>
         <true/>
     </dict>
     ```
   - Check network logs in Xcode console

3. **Camera limitations:**
   - iOS simulator has limited camera functionality
   - For full camera testing, use a physical device

## Additional Tips

### Using Physical Devices

1. **Android Device:**
   - Enable Developer Options on your device
   - Enable USB Debugging
   - Connect via USB and select your device in Android Studio

2. **iOS Device:**
   - Register your device in your Apple Developer account
   - Connect via USB and select your device in Xcode
   - Trust your computer on the device when prompted

### Performance Optimization

1. **Emulator/Simulator:**
   - Allocate more RAM to the emulator for better performance
   - Keep fewer apps running simultaneously on your development machine

2. **Application:**
   - Disable animations in the emulator settings for better performance
   - Use release builds for performance testing, debug builds for debugging

---

For any further assistance, refer to the respective platform documentation:
- [Android Developer Documentation](https://developer.android.com/)
- [iOS Developer Documentation](https://developer.apple.com/documentation/)