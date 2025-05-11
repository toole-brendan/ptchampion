# Legacy Code Cleanup Tracking

This document identifies sections of code that need to be cleaned up during the legacy code removal process.

## PushupTracker.tsx

The following sections in `src/pages/exercises/PushupTracker.tsx` should be marked with `// TODO(legacy-cleanup)` comments:

1. Manual constants definition (lines 32-35):
   ```tsx
   const PUSHUP_THRESHOLD_ANGLE_DOWN = 90; // Angle threshold for elbows down
   const PUSHUP_THRESHOLD_ANGLE_UP = 160; // Angle threshold for elbows up (full extension)
   const BACK_STRAIGHT_THRESHOLD_ANGLE = 165; // Min angle for shoulder-hip-knee (degrees)
   const PUSHUP_THRESHOLD_VISIBILITY = 0.6; // Visibility threshold for landmarks
   ```

2. Manual MediaPipe initialization (lines 75-110):
   ```tsx
   useEffect(() => {
     let landmarkInstance: PoseLandmarker | null = null;
     const initializeMediaPipe = async () => {
       setIsModelLoading(true);
       setModelError(null);
       try {
         const vision = await FilesetResolver.forVisionTasks(
           // Path to the WASM files, often copied during build or hosted
           "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.14/wasm"
         );
         // ...more initialization code
       }
       // ...error handling
     };
     // ...cleanup
   }, []);
   ```

3. Manual angle calculation function (lines 347-390):
   ```tsx
   const calculateAngle = (a: NormalizedLandmark, b: NormalizedLandmark, c: NormalizedLandmark): number => {
     // ...angle calculation logic
   };
   ```

4. Manual pushup processing logic (lines 262-330):
   ```tsx
   const processPushup = (landmarks: NormalizedLandmark[]) => {
     // ...landmark handling
     // ...position detection logic
     // ...rep counting logic
   };
   ```

## SitupTracker.tsx

The following sections in `src/pages/exercises/SitupTracker.tsx` should be marked with `// TODO(legacy-cleanup)` comments:

1. Manual constants definition (lines 32-33):
   ```tsx
   const SITUP_THRESHOLD_ANGLE_DOWN = 160; // Min hip angle (shoulder-hip-knee) when DOWN
   const SITUP_THRESHOLD_ANGLE_UP = 80;  // Max hip angle (shoulder-hip-knee) when UP
   ```

2. Manual angle calculation (similar to PushupTracker)

3. Manual situp processing logic

## PullupTracker.tsx

The following sections in `src/pages/exercises/PullupTracker.tsx` should be marked with `// TODO(legacy-cleanup)` comments:

1. Manual constants definition
2. Manual angle calculation
3. Manual pullup processing logic

## ViewModels to Implement

The following ViewModel classes need to be implemented to complete the migration:

- [x] PushupTrackerViewModel.ts - Implemented
- [ ] SitupTrackerViewModel.ts - Not implemented yet
- [ ] PullupTrackerViewModel.ts - Not implemented yet
- [ ] RunningTrackerViewModel.ts - Not implemented yet

## Integration Checklist

- [ ] Update index.ts to correctly reference Analyzer vs Grader
- [ ] Ensure consistent naming across all exercise types
- [ ] Remove all direct MediaPipe usage from tracker components
- [ ] Verify all exercise trackers use the appropriate ViewModel
- [ ] Ensure ViewModel properly handles data submission logic
- [ ] Remove the backup folder after all migrations are complete 