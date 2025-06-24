import {
  FilesetResolver,
  PoseLandmarker,
  DrawingUtils,
  NormalizedLandmark,
  PoseLandmarkerResult
} from "@mediapipe/tasks-vision";

export interface PoseDetectorResult {
  landmarks: NormalizedLandmark[];
  worldLandmarks?: NormalizedLandmark[];
  timestamp: number;
}

export class PoseDetector {
  private landmarker?: PoseLandmarker;
  private lastVideoTime = -1;
  private lastErrorLogged = 0; // Timestamp of last error logged

  async init(modelPath = "/models/pose_landmarker_full.task") {
    const vision = await FilesetResolver.forVisionTasks(
      "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.14/wasm"
    );
    this.landmarker = await PoseLandmarker.createFromOptions(vision, {
      baseOptions: { modelAssetPath: modelPath, delegate: "GPU" },
      runningMode: "VIDEO",
      numPoses: 1,
      minPoseDetectionConfidence: 0.5,
      minPosePresenceConfidence: 0.5,
      minTrackingConfidence: 0.5
    });
  }

  /** Caller pumps frames in a `requestAnimationFrame` loop */
  detect(video: HTMLVideoElement): PoseDetectorResult | null {
    if (!this.landmarker) return null;
    
    // Guard against empty or invalid video frames
    if (video.readyState < 2 || video.videoWidth === 0 || video.videoHeight === 0) {
      return null; // Skip detection on invalid/uninitialized frames
    }
    
    if (video.currentTime === this.lastVideoTime) return null; // same frame
    this.lastVideoTime = video.currentTime;

    const now = performance.now();
    
    // Create a temporary result variable
    let resultValue: PoseLandmarkerResult | undefined;
    
    try {
      // Call detectForVideo synchronously with a callback
      this.landmarker.detectForVideo(video, now, (detectionResult) => {
        resultValue = detectionResult;
      });
    } catch (error) {
      // Rate-limit error logging to avoid flooding the console
      const currentTime = Date.now();
      if (currentTime - this.lastErrorLogged > 5000) { // Log at most once per 5 seconds
        console.error('MediaPipe detection error:', error);
        this.lastErrorLogged = currentTime;
      }
      return null; // Return null on error
    }
    
    // If no results or no landmarks detected, return null
    if (!resultValue || !resultValue.landmarks || resultValue.landmarks.length === 0) {
      return null;
    }
    
    // Return the first pose's landmarks
    return {
      landmarks: resultValue.landmarks[0],
      worldLandmarks: resultValue.worldLandmarks?.[0],
      timestamp: Date.now()
    };
  }

  /** Simple overlay helper (optional) */
  static draw(
    canvas: HTMLCanvasElement,
    video: HTMLVideoElement,
    landmarks: NormalizedLandmark[],
    problemJoints?: number[]
  ) {
    const ctx = canvas.getContext("2d")!;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    const utils = new DrawingUtils(ctx);
    
    // Draw connections first
    utils.drawConnectors(
      landmarks,
      PoseLandmarker.POSE_CONNECTIONS /*  skeleton lines */
    );
    
    // Draw landmarks with custom styling for problem joints
    if (problemJoints && problemJoints.length > 0) {
      landmarks.forEach((landmark, index) => {
        if (!landmark || (landmark.visibility && landmark.visibility < 0.5)) {
          return;
        }
        
        const isProblem = problemJoints.includes(index);
        const x = landmark.x * canvas.width;
        const y = landmark.y * canvas.height;
        const radius = isProblem ? 8 : 5;
        
        ctx.beginPath();
        ctx.arc(x, y, radius, 0, 2 * Math.PI);
        ctx.fillStyle = isProblem ? 'rgba(255, 50, 50, 0.9)' : 'rgba(0, 255, 0, 0.8)';
        ctx.fill();
        ctx.strokeStyle = 'rgba(255, 255, 255, 0.8)';
        ctx.lineWidth = 1;
        ctx.stroke();
      });
    } else {
      // Default landmark drawing
      utils.drawLandmarks(landmarks);
    }
  }
} 