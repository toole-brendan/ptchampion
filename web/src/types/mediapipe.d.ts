declare module '@mediapipe/holistic' {
  export class Holistic {
    constructor(options?: any);
    setOptions(options: any): void;
    onResults(callback: (results: any) => void): void;
    initialize(): Promise<void>;
    send(options: { image: HTMLVideoElement }): Promise<void>;
    close(): void;
  }
  
  export const POSE_CONNECTIONS: any;
  export const HAND_CONNECTIONS: any;
  export const FACEMESH_TESSELATION: any;
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
    landmarks: any[],
    connections: any,
    options?: { color?: string; lineWidth?: number }
  ): void;
  
  export function drawLandmarks(
    canvasCtx: CanvasRenderingContext2D,
    landmarks: any[],
    options?: { color?: string; lineWidth?: number }
  ): void;
} 