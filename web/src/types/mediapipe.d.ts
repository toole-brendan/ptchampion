// Note: @mediapipe/holistic module declaration removed as we're using @mediapipe/tasks-vision now

declare module '@mediapipe/camera_utils' {
  export class Camera {
    constructor(
      videoElement: HTMLVideoElement,
      options: {
        onFrame: () => Promise<void>;
        width: number;
        height: number;
      }
    );
    start(): Promise<void>;
    stop(): void;
  }
}

declare module '@mediapipe/drawing_utils' {
  export function drawConnectors(
    canvasCtx: CanvasRenderingContext2D,
    landmarks: unknown[],
    connections: unknown,
    options?: { color?: string; lineWidth?: number }
  ): void;
  
  export function drawLandmarks(
    canvasCtx: CanvasRenderingContext2D,
    landmarks: unknown[],
    options?: { color?: string; lineWidth?: number }
  ): void;
} 