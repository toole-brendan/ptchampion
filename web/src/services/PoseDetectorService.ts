/**
 * PoseDetectorService
 * 
 * A service that encapsulates MediaPipe pose detection functionality,
 * similar to PoseDetectorService in iOS which encapsulates Apple Vision.
 * 
 * This service handles:
 * - Model initialization
 * - Camera stream management
 * - Pose detection loop
 * - Resource cleanup
 */

import {
  PoseLandmarker,
  FilesetResolver,
  DrawingUtils,
  NormalizedLandmark,
  PoseLandmarkerResult
} from "@mediapipe/tasks-vision";
import { Subject } from 'rxjs';
import { InitError, PoseDetectorError, RuntimeError } from '@/services/PoseDetectorError';
import cameraManager, { CameraOptions } from '@/services/CameraManager';
import { logger } from '@/lib/logger';

// Re-export landmark types for convenience
export type { NormalizedLandmark, PoseLandmarkerResult };
export { DrawingUtils };

// Configuration options for the pose detector
export interface PoseDetectorOptions {
  modelPath?: string;
  delegate?: 'GPU' | 'CPU';
  runningMode?: 'IMAGE' | 'VIDEO';
  numPoses?: number;
  minPoseDetectionConfidence?: number;
  minPosePresenceConfidence?: number;
  minTrackingConfidence?: number;
}

// Re-export camera options
export type { CameraOptions };

// Result callback function type
export type PoseResultsCallback = (results: PoseLandmarkerResult) => void;

/**
 * Pose Detection Service for MediaPipe
 */
class PoseDetectorService {
  private poseLandmarker: PoseLandmarker | null = null;
  private isModelLoading: boolean = false;
  private modelError: string | null = null;
  private videoElement: HTMLVideoElement | null = null;
  private canvasElement: HTMLCanvasElement | null = null;
  private requestAnimationId: number | null = null;
  private lastVideoTime: number = -1;
  private isPredicting: boolean = false;
  private resultsCallback: PoseResultsCallback | null = null;
  private initialized: boolean = false;
  private activeConsumers: number = 0;
  
  // Default options
  private defaultModelPath = '/models/pose_landmarker_lite.task';
  private defaultWasmPath = 'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.14/wasm';
  
  // RxJS Subject for emitting pose frames
  public pose$: Subject<PoseLandmarkerResult> = new Subject<PoseLandmarkerResult>();
  
  // Track initialization with a Promise to handle concurrent initialization requests
  private initPromise: Promise<void> | null = null;
  
  /**
   * Check if the service is initialized
   */
  public isInitialized(): boolean {
    return this.initialized && this.poseLandmarker !== null;
  }
  
  /**
   * Check if detection is running
   */
  public isRunning(): boolean {
    return this.isPredicting;
  }
  
  /**
   * Check if camera requires a user gesture to play (iOS Safari)
   */
  public requiresUserGesture(): boolean {
    return cameraManager.requiresUserGesture();
  }
  
  /**
   * Register a consumer of the service
   * Used for reference counting to know when to release resources
   */
  public registerConsumer(): void {
    this.activeConsumers++;
  }
  
  /**
   * Unregister a consumer of the service
   * When no consumers remain, resources can be cleaned up
   */
  public releaseConsumer(): void {
    this.activeConsumers = Math.max(0, this.activeConsumers - 1);
    
    // Auto-cleanup when no more consumers
    if (this.activeConsumers === 0) {
      this.stop();
      // Don't destroy resources automatically to avoid reloading models
      // Full cleanup must be called explicitly
    }
  }
  
  /**
   * Initialize the MediaPipe pose detection model
   * @param options Configuration options
   * @returns Promise that resolves when the model is loaded
   */
  public async initialize(options: PoseDetectorOptions = {}): Promise<void> {
    // If already initialized, resolve immediately
    if (this.isInitialized()) {
      logger.info("PoseDetectorService: Model already initialized");
      return Promise.resolve();
    }
    
    // If initialization is in progress, return the existing promise
    if (this.initPromise) {
      return this.initPromise;
    }
    
    this.isModelLoading = true;
    this.modelError = null;
    
    const modelPath = options.modelPath || this.defaultModelPath;
    const delegate = options.delegate || 'GPU';
    const runningMode = options.runningMode || 'VIDEO';
    const numPoses = options.numPoses || 1;
    
    // Create a new initialization promise
    this.initPromise = (async () => {
      try {
        logger.info(`PoseDetectorService: Initializing model from ${modelPath}`);
        const vision = await FilesetResolver.forVisionTasks(this.defaultWasmPath);
        
        this.poseLandmarker = await PoseLandmarker.createFromOptions(vision, {
          baseOptions: {
            modelAssetPath: modelPath,
            delegate: delegate
          },
          runningMode: runningMode,
          numPoses: numPoses,
          minPoseDetectionConfidence: options.minPoseDetectionConfidence || 0.5,
          minPosePresenceConfidence: options.minPosePresenceConfidence || 0.5,
          minTrackingConfidence: options.minTrackingConfidence || 0.5
        });
        
        this.initialized = true;
        logger.info("PoseDetectorService: Model initialized successfully");
      } catch (err) {
        this.modelError = err instanceof Error ? err.message : String(err);
        logger.error("PoseDetectorService: Failed to initialize model:", this.modelError);
        const error = new PoseDetectorError(InitError.MODEL_LOAD, this.modelError);
        throw error;
      } finally {
        this.isModelLoading = false;
      }
    })();
    
    try {
      await this.initPromise;
      return Promise.resolve();
    } catch (error) {
      // Clear the promise on failure so future calls can retry
      this.initPromise = null;
      return Promise.reject(error);
    }
  }
  
  /**
   * Start the camera stream and connect it to a video element
   * Uses the shared CameraManager for better lifecycle management
   * 
   * @param videoElement HTML video element to attach the stream to
   * @param options Camera configuration options
   * @returns Promise that resolves with permission status when camera is started
   */
  public async startCamera(
    videoElement: HTMLVideoElement,
    options: CameraOptions = {}
  ): Promise<boolean> {
    this.videoElement = videoElement;
    
    try {
      const success = await cameraManager.startCamera(videoElement, options);
      
      if (!success) {
        this.modelError = cameraManager.getError()?.message || "Failed to start camera";
      }
      
      return success;
    } catch (err) {
      logger.error("PoseDetectorService: Error starting camera:", err);
      this.modelError = err instanceof Error ? err.message : String(err);
      return false;
    }
  }
  
  /**
   * Resume the camera if it was paused
   * Useful for iOS Safari which requires user gesture
   */
  public async resumeCamera(): Promise<boolean> {
    return cameraManager.resumeStream();
  }
  
  /**
   * Start pose detection on the video stream
   * @param videoElement HTML video element with camera stream
   * @param canvasElement HTML canvas element to draw landmarks on (optional)
   * @param callback Function to call with pose detection results
   * @returns boolean indicating whether detection started successfully
   */
  public start(
    videoElement: HTMLVideoElement,
    canvasElement: HTMLCanvasElement | null = null,
    callback?: PoseResultsCallback
  ): boolean {
    if (!this.isInitialized()) {
      logger.error("PoseDetectorService: Cannot start detection, model not initialized");
      return false;
    }
    
    if (!videoElement.srcObject) {
      logger.error("PoseDetectorService: Cannot start detection, no video stream");
      return false;
    }
    
    this.videoElement = videoElement;
    this.canvasElement = canvasElement;
    this.resultsCallback = callback || null;
    this.isPredicting = true;
    this.lastVideoTime = -1;
    
    this.predictFrame();
    this.registerConsumer();
    logger.info("PoseDetectorService: Pose detection started");
    return true;
  }
  
  /**
   * Stop pose detection
   */
  public stop(): void {
    this.isPredicting = false;
    if (this.requestAnimationId) {
      cancelAnimationFrame(this.requestAnimationId);
      this.requestAnimationId = null;
    }
    logger.info("PoseDetectorService: Pose detection stopped");
  }
  
  /**
   * Stop and release the camera stream
   * Uses the shared CameraManager
   */
  public stopCamera(): void {
    cameraManager.removeConsumer();
    this.videoElement = null;
    
    logger.info("PoseDetectorService: Camera stopped");
  }
  
  /**
   * Clean up all resources
   */
  public destroy(): void {
    this.stop();
    this.stopCamera();
    
    if (this.poseLandmarker) {
      this.poseLandmarker.close();
      this.poseLandmarker = null;
    }
    
    this.videoElement = null;
    this.canvasElement = null;
    this.resultsCallback = null;
    this.initialized = false;
    this.activeConsumers = 0;
    logger.info("PoseDetectorService: Resources destroyed");
  }
  
  /**
   * Get model loading status
   */
  public isLoading(): boolean {
    return this.isModelLoading;
  }
  
  /**
   * Get model error if any
   */
  public getModelError(): string | null {
    return this.modelError;
  }
  
  /**
   * Create a DrawingUtils instance for the given canvas
   * @param canvas Canvas element to draw on
   * @returns DrawingUtils instance
   */
  public createDrawingUtils(canvas: HTMLCanvasElement): DrawingUtils {
    const ctx = canvas.getContext('2d');
    if (!ctx) {
      throw new PoseDetectorError(
        RuntimeError.UNKNOWN,
        "PoseDetectorService: Failed to get 2D context for canvas"
      );
    }
    return new DrawingUtils(ctx);
  }
  
  /**
   * Internal method to predict pose on each frame
   */
  private predictFrame(): void {
    if (!this.isPredicting || !this.videoElement || !this.poseLandmarker) {
      return;
    }
    
    const video = this.videoElement;
    
    // Ensure video is ready
    if (video.readyState < 2) {
      this.requestAnimationId = requestAnimationFrame(() => this.predictFrame());
      return;
    }
    
    // Handle canvas if provided
    if (this.canvasElement) {
      const canvas = this.canvasElement;
      const ctx = canvas.getContext('2d');
      
      if (ctx) {
        // Ensure canvas dimensions match video
        if (canvas.width !== video.videoWidth || canvas.height !== video.videoHeight) {
          canvas.width = video.videoWidth;
          canvas.height = video.videoHeight;
        }
      }
    }
    
    // Only run detection when new frame is available
    if (video.currentTime !== this.lastVideoTime) {
      this.lastVideoTime = video.currentTime;
      const startTimeMs = performance.now();
      
      // Run landmark detection
      this.poseLandmarker.detectForVideo(video, startTimeMs, (result: PoseLandmarkerResult) => {
        // Draw landmarks on canvas if available
        if (this.canvasElement) {
          const canvas = this.canvasElement;
          const ctx = canvas.getContext('2d');
          
          if (ctx && result.landmarks && result.landmarks.length > 0) {
            ctx.save();
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            
            const drawingUtils = new DrawingUtils(ctx);
            
            result.landmarks.forEach((landmarks) => {
              drawingUtils.drawLandmarks(landmarks, {
                radius: (data: { from?: NormalizedLandmark }) => 
                  DrawingUtils.lerp(data.from!.z, -0.15, 0.1, 5, 1)
              });
              drawingUtils.drawConnectors(landmarks, PoseLandmarker.POSE_CONNECTIONS);
            });
            
            ctx.restore();
          }
        }
        
        // Emit results to the subject
        this.pose$.next(result);
        
        // Invoke callback with results
        if (this.resultsCallback) {
          this.resultsCallback(result);
        }
      });
    }
    
    // Continue the detection loop
    if (this.isPredicting) {
      this.requestAnimationId = requestAnimationFrame(() => this.predictFrame());
    }
  }
}

// Create and export a singleton instance
export const poseDetectorService = new PoseDetectorService();

// Export the singleton as default for convenience
export default poseDetectorService; 