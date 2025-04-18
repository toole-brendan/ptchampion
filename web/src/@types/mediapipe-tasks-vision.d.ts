declare module '@mediapipe/tasks-vision' {
  export class PoseLandmarker {
    static createFromOptions(vision: any, options: any): Promise<PoseLandmarker>;
    detectForVideo(video: HTMLVideoElement, timestamp: number, callback: (result: PoseLandmarkerResult) => void): void;
    close(): void;
    static readonly POSE_CONNECTIONS: any[];
  }
  
  export interface PoseLandmarkerResult {
    landmarks: NormalizedLandmark[][];
    worldLandmarks?: any[][];
  }
  
  export interface NormalizedLandmark {
    x: number;
    y: number;
    z: number;
    visibility?: number;
  }
  
  export class FilesetResolver {
    static forVisionTasks(wasmFilePath: string): Promise<any>;
  }
  
  export class DrawingUtils {
    constructor(ctx: CanvasRenderingContext2D);
    drawLandmarks(landmarks: NormalizedLandmark[], options?: any): void;
    drawConnectors(landmarks: NormalizedLandmark[], connections: any[], options?: any): void;
    static lerp(z: number, min: number, max: number, minValue: number, maxValue: number): number;
  }
} 