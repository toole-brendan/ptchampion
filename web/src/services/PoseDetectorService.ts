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

// Re-export landmark types for convenience
export { NormalizedLandmark, PoseLandmarkerResult };
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

// Camera configuration options
export interface CameraOptions {
  facingMode?: 'user' | 'environment';
  width?: number;
  height?: number;
}

// Result callback function type
export type PoseResultsCallback = (results: PoseLandmarkerResult) => void;

/**
 * Pose Detection Service for MediaPipe
 */
export class PoseDetectorService {
  private poseLandmarker: PoseLandmarker | null = null;
  private isModelLoading: boolean = false;
  private modelError: string | null = null;
  private stream: MediaStream | null = null;
  private videoElement: HTMLVideoElement | null = null;
  private canvasElement: HTMLCanvasElement | null = null;
  private requestAnimationId: number | null = null;
  private lastVideoTime: number = -1;
  private isPredicting: boolean = false;
  private resultsCallback: PoseResultsCallback | null = null;
  
  // Default options
  private defaultModelPath = '/models/pose_landmarker_lite.task';
  private defaultWasmPath = 'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.14/wasm';
  
  /**
   * Initialize the MediaPipe pose detection model
   * @param options Configuration options
   * @returns Promise that resolves when the model is loaded
   */
  public async initialize(options: PoseDetectorOptions = {}): Promise<void> {
    if (this.poseLandmarker) {
      console.log("PoseDetectorService: Model already initialized");
      return;
    }
    
    this.isModelLoading = true;
    this.modelError = null;
    
    const modelPath = options.modelPath || this.defaultModelPath;
    const delegate = options.delegate || 'GPU';
    const runningMode = options.runningMode || 'VIDEO';
    const numPoses = options.numPoses || 1;
    
    try {
      console.log(`PoseDetectorService: Initializing model from ${modelPath}`);
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
      
      console.log("PoseDetectorService: Model initialized successfully");
      return Promise.resolve();
    } catch (err) {
      this.modelError = err instanceof Error ? err.message : String(err);
      console.error("PoseDetectorService: Failed to initialize model:", this.modelError);
      return Promise.reject(this.modelError);
    } finally {
      this.isModelLoading = false;
    }
  }
  
  /**
   * Start the camera stream and connect it to a video element
   * @param videoElement HTML video element to attach the stream to
   * @param options Camera configuration options
   * @returns Promise that resolves with permission status when camera is started
   */
  public async startCamera(
    videoElement: HTMLVideoElement,
    options: CameraOptions = {}
  ): Promise<boolean> {
    this.videoElement = videoElement;
    
    // Stop any existing camera stream first
    if (this.stream) {
      this.stopCamera();
    }
    
    try {
      const constraints: MediaStreamConstraints = {
        video: {
          facingMode: options.facingMode || 'user',
          width: options.width ? { ideal: options.width } : { ideal: 640 },
          height: options.height ? { ideal: options.height } : { ideal: 480 }
        },
        audio: false
      };
      
      console.log("PoseDetectorService: Requesting camera access");
      const stream = await navigator.mediaDevices.getUserMedia(constraints);
      this.stream = stream;
      
      if (this.videoElement) {
        this.videoElement.srcObject = stream;
        console.log("PoseDetectorService: Camera started successfully");
      }
      
      return true;
    } catch (err) {
      console.error("PoseDetectorService: Error accessing camera:", err);
      const errorMessage = this.getErrorMessageFromMediaDevicesError(err);
      this.modelError = errorMessage;
      return false;
    }
  }
  
  /**
   * Start pose detection on the video stream
   * @param videoElement HTML video element with camera stream
   * @param canvasElement HTML canvas element to draw landmarks on (optional)
   * @param callback Function to call with pose detection results
   * @returns boolean indicating whether detection started successfully
   */
  public startDetection(
    videoElement: HTMLVideoElement,
    canvasElement: HTMLCanvasElement | null = null,
    callback: PoseResultsCallback
  ): boolean {
    if (!this.poseLandmarker) {
      console.error("PoseDetectorService: Cannot start detection, model not initialized");
      return false;
    }
    
    if (!videoElement.srcObject) {
      console.error("PoseDetectorService: Cannot start detection, no video stream");
      return false;
    }
    
    this.videoElement = videoElement;
    this.canvasElement = canvasElement;
    this.resultsCallback = callback;
    this.isPredicting = true;
    this.lastVideoTime = -1;
    
    this.predictFrame();
    console.log("PoseDetectorService: Pose detection started");
    return true;
  }
  
  /**
   * Stop pose detection
   */
  public stopDetection(): void {
    this.isPredicting = false;
    if (this.requestAnimationId) {
      cancelAnimationFrame(this.requestAnimationId);
      this.requestAnimationId = null;
    }
    console.log("PoseDetectorService: Pose detection stopped");
  }
  
  /**
   * Stop and release the camera stream
   */
  public stopCamera(): void {
    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop());
      this.stream = null;
    }
    
    if (this.videoElement) {
      this.videoElement.srcObject = null;
    }
    
    console.log("PoseDetectorService: Camera stopped");
  }
  
  /**
   * Clean up all resources
   */
  public destroy(): void {
    this.stopDetection();
    this.stopCamera();
    
    if (this.poseLandmarker) {
      this.poseLandmarker.close();
      this.poseLandmarker = null;
    }
    
    this.videoElement = null;
    this.canvasElement = null;
    this.resultsCallback = null;
    console.log("PoseDetectorService: Resources destroyed");
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
   * Get current prediction status
   */
  public isPredicting(): boolean {
    return this.isPredicting;
  }
  
  /**
   * Create a DrawingUtils instance for the given canvas
   * @param canvas Canvas element to draw on
   * @returns DrawingUtils instance
   */
  public createDrawingUtils(canvas: HTMLCanvasElement): DrawingUtils {
    const ctx = canvas.getContext('2d');
    if (!ctx) {
      throw new Error("PoseDetectorService: Failed to get 2D context for canvas");
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
  
  /**
   * Get a user-friendly error message from a MediaDevices error
   */
  private getErrorMessageFromMediaDevicesError(err: unknown): string {
    if (err instanceof Error) {
      switch (err.name) {
        case 'NotAllowedError':
        case 'PermissionDeniedError':
          return "Camera permission denied. Please grant access in your browser settings.";
        case 'NotFoundError':
        case 'DevicesNotFoundError':
          return "No camera found. Please ensure a camera is connected and enabled.";
        default:
          return `Error accessing camera: ${err.message}`;
      }
    }
    return "An unknown error occurred while accessing the camera.";
  }
}

// Create and export a singleton instance for convenient use
export const poseDetectorService = new PoseDetectorService();

// Default export for cases where singleton is not desired
export default PoseDetectorService; 