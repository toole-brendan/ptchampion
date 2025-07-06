/**
 * Utility to preload the pose detector service during idle time
 * This helps improve performance by loading the model when the browser is idle
 * rather than when the user navigates to an exercise page
 */

let preloadPromise: Promise<void> | null = null;
let isPreloaded = false;

/**
 * Preload the pose detector service and model during idle time
 * Uses requestIdleCallback for better performance
 * @returns Promise that resolves when preloading is complete
 */
export function preloadPoseDetector(): Promise<void> {
  // If already preloaded, resolve immediately
  if (isPreloaded) {
    return Promise.resolve();
  }

  // If preload is in progress, return existing promise
  if (preloadPromise) {
    return preloadPromise;
  }

  // Create new preload promise
  preloadPromise = new Promise<void>((resolve) => {
    // Check if requestIdleCallback is supported
    if ('requestIdleCallback' in window) {
      // Use requestIdleCallback to load during idle time
      requestIdleCallback(
        async () => {
          try {
            // Dynamically import the pose detector service
            const { default: poseDetectorService } = await import('@/services/PoseDetectorService');
            
            // Initialize the service with default options
            await poseDetectorService.initialize({
              minPoseDetectionConfidence: 0.7,
              minPosePresenceConfidence: 0.7
            });
            
            isPreloaded = true;
            resolve();
          } catch (error) {
            console.error('Failed to preload pose detector:', error);
            // Resolve anyway to not block the app
            resolve();
          }
        },
        {
          // Give it up to 5 seconds of idle time
          timeout: 5000
        }
      );
    } else {
      // Fallback for browsers that don't support requestIdleCallback
      // Use setTimeout to delay loading slightly
      setTimeout(async () => {
        try {
          const { default: poseDetectorService } = await import('@/services/PoseDetectorService');
          await poseDetectorService.initialize({
            minPoseDetectionConfidence: 0.7,
            minPosePresenceConfidence: 0.7
          });
          isPreloaded = true;
          resolve();
        } catch (error) {
          console.error('Failed to preload pose detector:', error);
          resolve();
        }
      }, 2000); // Wait 2 seconds before preloading
    }
  });

  return preloadPromise;
}

/**
 * Check if pose detector has been preloaded
 */
export function isPoseDetectorPreloaded(): boolean {
  return isPreloaded;
}

/**
 * Reset preload state (mainly for testing)
 */
export function resetPreloadState(): void {
  preloadPromise = null;
  isPreloaded = false;
}