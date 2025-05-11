/**
 * PoseDetectorError.ts
 * 
 * Centralized error types for the PoseDetectorService
 */

/**
 * Enum for initialization error types
 */
export enum InitError {
  CAMERA_PERMISSION = 'CAMERA_PERMISSION',
  MODEL_LOAD = 'MODEL_LOAD',
  CAMERA_NOT_FOUND = 'CAMERA_NOT_FOUND',
  ALREADY_INITIALIZED = 'ALREADY_INITIALIZED',
  UNKNOWN = 'UNKNOWN'
}

/**
 * Enum for runtime error types
 */
export enum RuntimeError {
  DETECTION_FAILED = 'DETECTION_FAILED',
  CAMERA_DISCONNECTED = 'CAMERA_DISCONNECTED',
  NOT_INITIALIZED = 'NOT_INITIALIZED',
  INVALID_STATE = 'INVALID_STATE',
  UNKNOWN = 'UNKNOWN'
}

/**
 * Custom error class for PoseDetector errors
 */
export class PoseDetectorError extends Error {
  type: InitError | RuntimeError;
  
  constructor(type: InitError | RuntimeError, message: string) {
    super(message);
    this.name = 'PoseDetectorError';
    this.type = type;
  }
}

/**
 * Helper function to convert MediaDevices errors to our error types
 */
export function getErrorFromMediaDevicesError(err: unknown): PoseDetectorError {
  if (err instanceof Error) {
    switch (err.name) {
      case 'NotAllowedError':
      case 'PermissionDeniedError':
        return new PoseDetectorError(
          InitError.CAMERA_PERMISSION,
          "Camera permission denied. Please grant access in your browser settings."
        );
      case 'NotFoundError':
      case 'DevicesNotFoundError':
        return new PoseDetectorError(
          InitError.CAMERA_NOT_FOUND,
          "No camera found. Please ensure a camera is connected and enabled."
        );
      default:
        return new PoseDetectorError(
          InitError.UNKNOWN,
          `Error accessing camera: ${err.message}`
        );
    }
  }
  return new PoseDetectorError(
    InitError.UNKNOWN,
    "An unknown error occurred while accessing the camera."
  );
} 