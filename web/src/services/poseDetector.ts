import {
  FilesetResolver,
  PoseLandmarker,
  DrawingUtils,
  NormalizedLandmark
} from "@mediapipe/tasks-vision";

export interface PoseDetectorResult {
  landmarks: NormalizedLandmark[];
  worldLandmarks?: NormalizedLandmark[];
  timestamp: number;
}

export class PoseDetector {
  private landmarker?: PoseLandmarker;
  private lastVideoTime = -1;

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
    if (video.currentTime === this.lastVideoTime) return null; // same frame
    this.lastVideoTime = video.currentTime;

    const now = performance.now();
    const result = this.landmarker.detectForVideo(video, now);

    if (!result.landmarks?.[0]) return null;

    return {
      landmarks: result.landmarks[0],
      worldLandmarks: result.worldLandmarks?.[0],
      timestamp: Date.now()
    };
  }

  /** Simple overlay helper (optional) */
  static draw(
    canvas: HTMLCanvasElement,
    video: HTMLVideoElement,
    landmarks: NormalizedLandmark[]
  ) {
    const ctx = canvas.getContext("2d")!;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    const utils = new DrawingUtils(ctx);
    utils.drawLandmarks(landmarks);
    utils.drawConnectors(
      landmarks,
      PoseLandmarker.POSE_CONNECTIONS /*  skeleton lines */
    );
  }
} 