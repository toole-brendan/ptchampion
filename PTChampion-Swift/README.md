# PT Champion (iOS)

A native iOS application for fitness evaluation and tracking with computer vision for military exercises, featuring global and local leaderboards.

## Overview

PT Champion is a comprehensive fitness evaluation application designed specifically for military physical training standards. The app uses computer vision to count and evaluate exercise form, connects to Bluetooth heart rate monitors and fitness trackers, and provides performance tracking with competitive leaderboards.

## Features

- **Exercise Detection & Evaluation**: Camera-based detection for push-ups, sit-ups, and pull-ups using Apple's Vision framework
- **Run Tracking**: Track 2-mile run performance with time, distance, and pace metrics
- **Bluetooth Integration**: Connect to heart rate monitors and fitness trackers
- **Leaderboards**: Compare your performance globally or with users in your local area
- **Performance History**: View your exercise history and track improvements over time
- **Form Feedback**: Receive real-time feedback on exercise form and technique
- **Military Standards**: Grading based on military physical training test standards

## Technical Architecture

### Models
- `User`: User profile data including authentication and location
- `Exercise`: Exercise definitions, types, and requirements
- `UserExercise`: Recorded exercise performance and results

### Services
- `APIClient`: Communication with the backend server
- `BluetoothManager`: Connection to heart rate monitors and fitness trackers
- `PoseDetectionService`: Computer vision implementation for exercise counting

### Utils
- `ExerciseGrading`: Logic for scoring exercises based on military standards

### Views (SwiftUI)
- Dashboard with performance summary
- Exercise execution screens with camera view
- Running tracker with map and metrics
- Performance history and analytics
- Global and local leaderboards

## Getting Started

### Prerequisites
- Xcode 14.0+
- iOS 15.0+ device (for camera and Vision framework features)
- CocoaPods or Swift Package Manager

### Installation
1. Clone the repository
2. Open the project in Xcode
3. Install dependencies
4. Build and run on a physical device

## Development Guidelines

### Coding Conventions
- Follow Swift style guidelines
- Use SwiftUI for all UI components
- Implement MVVM architecture pattern
- Utilize Combine for reactive programming

### Backend Communication
- RESTful API communication with JSON encoding
- Server endpoint: `http://localhost:5000/api` (development)
- Authentication via JWT tokens

### Data Management
- CoreData for local persistence
- UserDefaults for preferences and settings
- Keychain for secure credential storage

## Testing

- Unit tests for service and utility functions
- UI tests for critical user flows
- TestFlight for beta testing

## Deployment

- App Store submission process documented in DEPLOYMENT.md
- CI/CD pipeline using GitHub Actions

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- Original web application built with React/TypeScript
- Exercise standards based on military fitness test requirements
- Vision framework implementation inspired by Apple's sample code