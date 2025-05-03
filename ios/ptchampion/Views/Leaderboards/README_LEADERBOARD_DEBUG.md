# Leaderboard View Debugging Guide

## The Freezing Issue

The LeaderboardView was freezing and crashing when users navigated to the leaderboard tab. This was caused by several issues:

1. Resource-intensive operations on the main thread
2. Lifecycle conflicts during rapid tab switching 
3. Memory management issues
4. Lack of proper task cancellation when navigating away

## Debug Mode Implementation

### LeaderboardViewDebug

A special debugging version of the LeaderboardView has been implemented at `ios/ptchampion/Views/Leaderboards/LeaderboardViewDebug.swift`. This view:

- Initializes with a "Load Leaderboard" button that lets you explicitly choose when to load the view
- Shows memory usage statistics
- Provides detailed logging
- Allows toggling between mock and real data
- Displays detailed logs that can be inspected while the app is running

### How to Use Debug Mode

1. In DEBUG builds, the TabView automatically uses `LeaderboardViewDebug` instead of the standard view
2. When you navigate to the Leaderboards tab, you'll see the debug interface
3. Press "Load Leaderboard" to initialize the view
4. If any issues occur, they'll be displayed in the logs
5. Toggle between mock and real data using the button in the header

### Logging and Diagnostics

The debug view and updated components include extensive logging:

- View lifecycle events (appear, disappear)
- Memory usage tracking
- Task execution and cancellation
- Network requests and responses
- Timing information

### Key Fixes Implemented

1. **MainActor Execution Control**: Ensuring all UI updates happen on the main thread
2. **Task Cancellation**: Proper cancellation of background tasks when navigating away
3. **Memory Management**: Weak references and proper cleanup
4. **Tab Switching Protection**: Delay mechanism to prevent rapid tab switches
5. **MockData First**: Using mock data by default to isolate network issues
6. **Lazy Loading**: Only loading the view when explicitly requested in debug mode
7. **Geometry Fixes**: Proper frame sizing to prevent layout issues

## Future Improvements

If issues persist, additional diagnostics to consider:

1. Enable thread sanitizer in Xcode to detect thread issues
2. Add memory leak detection using Instruments
3. Implement more granular component-level debugging
4. Add network request timeout monitoring

## Usage in Production

In production builds:

- The standard `LeaderboardView` is used (with fixes applied)
- Debug logging is disabled
- Mock data can still be used as a fallback if real API calls fail
- Tab switching protection remains active to prevent crashes

## Switching Between Debug and Production

The app automatically determines which view to use based on the build configuration. No manual switching is required.

To force using the debug view even in production builds, modify the `#if DEBUG` condition in `PTChampionApp.swift`. 