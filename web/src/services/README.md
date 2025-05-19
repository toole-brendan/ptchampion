# Services Directory

This directory contains service modules that abstract and encapsulate specific functionality, implementing a service layer similar to the iOS app architecture.

## Available Services

### PoseDetectorService

`PoseDetectorService` abstracts the MediaPipe pose detection functionality, similar to how `PoseDetectorService.swift` encapsulates Apple Vision in the iOS app. This service handles:

- Model initialization and loading
- Camera stream management and permissions
- Pose detection loop using requestAnimationFrame
- Drawing landmarks on a canvas (optional)
- Providing results via callbacks
- Resource cleanup

#### Usage Example

```typescript
import { poseDetectorService } from '@/services/PoseDetectorService';

// In a React component:
useEffect(() => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  
  const initializePoseDetection = async () => {
    // Initialize the model
    await poseDetectorService.initialize();
    
    // Start the camera
    if (videoRef.current) {
      const cameraStarted = await poseDetectorService.startCamera(videoRef.current);
      
      if (cameraStarted && canvasRef.current) {
        // Start pose detection with a callback to process results
        poseDetectorService.startDetection(
          videoRef.current,
          canvasRef.current,
          (results) => {
            // Process pose landmarks here
            if (results.landmarks && results.landmarks.length > 0) {
              const landmarks = results.landmarks[0];
              // Use landmarks for exercise counting, form analysis, etc.
            }
          }
        );
      }
    }
  };
  
  initializePoseDetection();
  
  // Cleanup on component unmount
  return () => {
    poseDetectorService.destroy();
  };
}, []);
```

## Design Philosophy

The services directory follows these principles:

1. **Encapsulation**: Each service fully encapsulates a specific functionality, hiding implementation details.
2. **Abstraction**: Services provide a clean API that abstracts away complex operations.
3. **Reusability**: Services can be used by multiple components without duplicating code.
4. **Testability**: By separating concerns, services are easier to mock and test independently.
5. **Maintainability**: Changes to underlying libraries only require updates to the service, not every component.

This approach mirrors the iOS app architecture, where services like `NetworkService`, `AuthService`, and `PoseDetectorService` hide the details of API requests, authentication, and vision processing. 