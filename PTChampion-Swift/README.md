# PT Champion iOS App

This is the Swift version of the PT Champion fitness evaluation app, designed to work on iOS devices. This app offers the same functionality as the web version but is optimized for iOS using native Swift and SwiftUI.

## Features

- User authentication (login, registration)
- Exercise tracking with computer vision for:
  - Push-ups
  - Pull-ups
  - Sit-ups
  - 2-mile Run
- Performance scoring and grading
- Global and local leaderboards
- Bluetooth device integration for heart rate monitoring and run tracking
- Data persistence via PostgreSQL database

## Technical Components

- **Swift & SwiftUI**: For building the iOS UI
- **Vision framework**: For pose detection and exercise counting (replacing TensorFlow.js)
- **Core Bluetooth**: For connecting to heart rate monitors and fitness devices
- **Core Location**: For location services and local leaderboard functionality
- **URLSession**: For API communication with the server
- **Combine**: For reactive programming patterns

## Project Structure

```
PTChampion-Swift/
├── Models/             # Swift data models matching server schema
├── Views/              # SwiftUI views
│   ├── Authentication/ # Login and registration views
│   ├── Exercises/      # Exercise-specific views
│   ├── Dashboard/      # Home and performance views
│   └── Components/     # Reusable UI components
├── ViewModels/         # Business logic and state management
├── Services/           # Network, Bluetooth, and persistence services
│   ├── API/            # API communication with backend
│   ├── Bluetooth/      # Heart rate and fitness device connectivity
│   ├── PoseDetection/  # Computer vision for exercise detection
│   └── LocationService/# Location services for local leaderboard
└── Utils/              # Helper functions and extensions
```

## Getting Started

1. Clone this repository
2. Open `PTChampion.xcodeproj` in Xcode
3. Set up the backend server according to the main project documentation
4. Build and run the app on your iOS device or simulator

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+
- Camera access for exercise detection
- Bluetooth access for fitness device integration
- Location services for local leaderboard functionality

## Technical Implementation Notes

- The app uses Swift's Vision framework to replace the TensorFlow.js pose detection
- Core Bluetooth replaces the Web Bluetooth API for device connectivity
- The API routes match the existing Express backend for compatibility
- Authentication flow uses the same approach as the web version but adapted for iOS