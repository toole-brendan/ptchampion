# PT Champion - Swift Edition

PT Champion is a comprehensive fitness tracking application designed specifically for military-style physical training exercises. This Swift version of the app brings the same functionality from the web-based version to a native iOS experience, with additional capabilities utilizing iOS-specific features.

## Features

### Exercise Tracking
- **Push-ups**: Track repetitions with real-time form feedback using Vision framework
- **Sit-ups**: Count and analyze sit-up form with posture feedback
- **Pull-ups**: Monitor pull-up technique and count repetitions
- **2-Mile Run**: Track time, pace, and distance with Apple Watch or Bluetooth device integration

### Performance Analysis
- **Form Scoring**: Get real-time feedback on exercise technique
- **Grading System**: Exercises are scored on a 0-100 scale
- **Performance History**: View trends and progress over time
- **Leaderboards**: Global and local rankings to compare with others

### Smart Features
- **Computer Vision**: Analyzes body position and movement using Apple's Vision framework
- **Bluetooth Connectivity**: Connects to heart rate monitors and running pods
- **Location Services**: Finds nearby users for local competition
- **Cloud Sync**: Syncs progress across devices

## Technical Architecture

### Core Components

#### Models
- `User`: Represents user account and profile data
- `Exercise`: Defines exercise types and requirements
- `UserExercise`: Tracks individual exercise performances

#### Services
- `APIClient`: Handles communication with backend servers
- `BluetoothManager`: Manages connections to fitness devices
- `PoseDetectionService`: Processes camera input for exercise form analysis

#### Views
- Authentication: Login and registration screens
- Dashboard: Overview of performance and available exercises
- Exercise Screens: Camera-based interfaces for performing exercises
- History: Record of past performances
- Profile: User account management

### Key Technologies
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for async operations
- **Vision**: Apple's computer vision framework for pose detection
- **CoreBluetooth**: Framework for connecting to fitness devices
- **CoreLocation**: Framework for geolocation features

## Getting Started

### Prerequisites
- Xcode 14.0+
- iOS 16.0+
- Swift 5.7+
- Active Apple Developer account for testing on physical devices

### Installation
1. Clone the repository
2. Open the project in Xcode
3. Install dependencies using Swift Package Manager
4. Configure the backend server URL in `APIClient.swift`
5. Build and run on simulator or physical device

## Using the App

### Account Setup
1. Create a new account or login with existing credentials
2. Grant necessary permissions for camera, Bluetooth, and location

### Performing Exercises
1. Select an exercise from the dashboard
2. For bodyweight exercises (push-ups, sit-ups, pull-ups):
   - Position your device so your full body is visible
   - Follow on-screen instructions for proper form
   - Begin exercise when countdown completes
   - Receive real-time feedback on form and count
3. For running:
   - Connect Bluetooth devices if available
   - Start the timer when ready to begin
   - Track your progress during the run
   - Complete when finished to save results

### Viewing Progress
1. Check your performance history in the History tab
2. View detailed breakdowns of each exercise
3. Track improvements over time with progress graphs
4. Compare your performance with others on the leaderboard

## Contributing

If you'd like to contribute to the PT Champion Swift app:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

Project Link: [https://github.com/yourusername/pt-champion-swift](https://github.com/yourusername/pt-champion-swift)

## Acknowledgments

- Original PT Champion web application team
- Apple Developer Documentation
- SwiftUI and Vision framework communities