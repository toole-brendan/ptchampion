declare module '@mediapipe/tasks-vision' {
  export class PoseLandmarker {
    static createFromOptions(vision: unknown, options: unknown): Promise<PoseLandmarker>;
    detectForVideo(video: HTMLVideoElement, timestamp: number, callback: (result: PoseLandmarkerResult) => void): void;
    close(): void;
    static readonly POSE_CONNECTIONS: Array<[number, number]>;
  }
  
  export interface PoseLandmarkerResult {
    landmarks: NormalizedLandmark[][];
    worldLandmarks?: Array<NormalizedLandmark[]>;
  }
  
  export interface NormalizedLandmark {
    x: number;
    y: number;
    z: number;
    visibility?: number;
  }
  
  export class FilesetResolver {
    static forVisionTasks(wasmFilePath: string): Promise<unknown>;
  }
  
  export class DrawingUtils {
    constructor(ctx: CanvasRenderingContext2D);
    drawLandmarks(landmarks: NormalizedLandmark[], options?: unknown): void;
    drawConnectors(landmarks: NormalizedLandmark[], connections: Array<[number, number]>, options?: unknown): void;
    static lerp(z: number, min: number, max: number, minValue: number, maxValue: number): number;
  }
} 