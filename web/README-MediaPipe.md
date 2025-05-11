# MediaPipe Holistic Integration for PT Champion

This document describes the integration of MediaPipe Holistic for exercise tracking and form analysis in the PT Champion web application.

## Overview

MediaPipe Holistic is a machine learning solution that provides comprehensive body pose, face, and hand tracking. For the PT Champion application, we primarily use the pose landmarks to:

1. Track exercise form during push-ups, pull-ups, sit-ups, and running
2. Count repetitions
3. Analyze form and provide feedback
4. Calculate metrics like exercise efficiency and proper form percentage

## Implementation Details

### Components

- `MediaPipeHolisticSetup.tsx`: Core component for initializing and running the MediaPipe Holistic model
- `HolisticCalibration.tsx`: Component for calibrating the system before exercise tracking
- `ExerciseCalibrationExample.tsx`: Example component showing how to use the calibration system

### Type Definitions

The type definitions for MediaPipe Holistic are defined in `src/lib/types.ts` and include:

- `NormalizedLandmark`: Basic structure for a 3D landmark with visibility
- `HolisticResults`: Structure for the results returned by MediaPipe Holistic
- `CalibrationData`: Structure for storing calibration data
- `HolisticConfig`: Configuration options for the Holistic model

### Offline Support

The implementation includes support for offline usage by:

1. Checking for locally stored models in `/public/models/holistic/` first
2. Falling back to CDN-hosted models if local models aren't available

To enable full offline support, download the model files from the MediaPipe CDN and place them in the appropriate directory.

## Usage Example

```tsx
import React, { useState } from 'react';
import { HolisticCalibration } from '@/components/HolisticCalibration';
import { CalibrationData } from '@/lib/types';

const ExerciseTracker: React.FC = () => {
  const [calibrationData, setCalibrationData] = useState<CalibrationData | null>(null);
  
  const handleCalibrationComplete = (data: CalibrationData) => {
    setCalibrationData(data);
    // Start exercise tracking with calibration data
  };
  
  return (
    <div>
      {!calibrationData ? (
        <HolisticCalibration 
          exerciseType="pushup" 
          onCalibrationComplete={handleCalibrationComplete} 
        />
      ) : (
        // Exercise tracking UI
        <div>Exercise tracking in progress...</div>
      )}
    </div>
  );
};
```

## Model Performance Considerations

- **Model Complexity**: The implementation allows for setting model complexity (0, 1, or 2)
  - 0: Fastest but least accurate
  - 1: Balanced (default)
  - 2: Most accurate but slowest
  
- **Device Compatibility**: Performance varies significantly across devices
  - Modern devices should handle complexity 1 at 30+ fps
  - Older devices may require complexity 0 or reduced resolution

## Future Improvements

- Download and cache model files for true offline support
- Implement WebGL acceleration for improved performance
- Create exercise-specific landmark tracking optimization
- Add form analysis algorithms based on military PT standards
- Implement rep counting state machines for each exercise type

## References

- [MediaPipe Holistic Documentation](https://developers.google.com/mediapipe/solutions/vision/holistic)
- [MediaPipe Models GitHub](https://github.com/google/mediapipe/tree/master/mediapipe/modules/holistic_landmark)
- [Web Camera API Reference](https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia) 