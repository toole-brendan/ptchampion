# MediaPipe BlazePose Integration for PT Champion

This document describes the integration of MediaPipe BlazePose (Full model) for exercise tracking and form analysis in the PT Champion web application.

## Overview

MediaPipe BlazePose is a machine learning solution that provides comprehensive body pose tracking. For the PT Champion application, we use the pose landmarks to:

1. Track exercise form during push-ups, pull-ups, sit-ups, and running
2. Count repetitions
3. Analyze form and provide feedback
4. Calculate metrics like exercise efficiency and proper form percentage

## Implementation Details

### Components

- `poseDetector.ts`: Core service for initializing and running the MediaPipe BlazePose model
- `usePoseDetector.ts`: React hook for using the PoseDetector service in components

### Type Definitions

The type definitions for MediaPipe BlazePose are defined in the service and include:

- `NormalizedLandmark`: Basic structure for a 3D landmark with visibility
- `PoseDetectorResult`: Structure for the results returned by the PoseDetector

### Offline Support

The implementation includes support for offline usage by:

1. Using locally stored models in `/public/models/` directory
2. Supporting multiple model variants: lite, full, and heavy

## Usage Example

```tsx
import React, { useEffect, useRef } from 'react';
import { usePoseDetector } from '@/services/usePoseDetector';
import { PushupAnalyzer } from '@/grading/PushupAnalyzer';

const PushupTracker: React.FC = () => {
  const { videoRef, pose } = usePoseDetector('full');
  const analyzerRef = useRef(new PushupAnalyzer());

  useEffect(() => {
    if (!pose) return;
    analyzerRef.current.analyzePushupForm(
      pose.landmarks,
      pose.timestamp
    );
  }, [pose]);

  return (
    <div className="relative">
      <video ref={videoRef} className="w-full" muted playsInline />
      {/* Optional drawing overlay */}
      {/* <canvas ref={canvasRef} className="absolute inset-0" /> */}
    </div>
  );
};
```

## Model Performance Considerations

- **Model Variants**: Three model variants are available
  - `lite`: Fastest but least accurate (~4MB)
  - `full`: Good balance of accuracy and performance (~9MB, default)
  - `heavy`: Most accurate but slowest (~30MB)
  
- **Device Compatibility**: Performance varies across devices
  - Modern devices support WASM-SIMD and WebGL2 for best performance
  - Chrome ≥ 113, Edge ≥ 113, Safari ≥ 17 are recommended

## References

- [MediaPipe Pose Documentation](https://developers.google.com/mediapipe/solutions/vision/pose_landmarker)
- [MediaPipe Tasks Vision Library](https://developers.google.com/mediapipe/solutions/vision/pose_landmarker/web_js)
- [Web Camera API Reference](https://developer.mozilla.org/en-US/docs/Web/API/MediaDevices/getUserMedia) 