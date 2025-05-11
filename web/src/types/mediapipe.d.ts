declare module '@mediapipe/holistic' {
  export class Holistic {
    constructor(options?: unknown);
    setOptions(options: unknown): void;
    onResults(callback: (results: unknown) => void): void;
    initialize(): Promise<void>;
    send(options: { image: HTMLVideoElement }): Promise<void>;
    close(): void;
  }
  
  export const POSE_CONNECTIONS: unknown;
  export const HAND_CONNECTIONS: unknown;
  export const FACEMESH_TESSELATION: unknown;
}

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