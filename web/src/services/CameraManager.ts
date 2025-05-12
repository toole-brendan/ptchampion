/**
 * CameraManager.ts
 * 
 * Handles camera lifecycle including permissions, stream management, 
 * and reference counting for shared camera usage across components.
 */

import { InitError, PoseDetectorError } from './PoseDetectorError';

export interface CameraOptions {
  facingMode?: 'user' | 'environment';
  width?: number;
  height?: number;
  frameRate?: number;
}

export class CameraManager {
  private stream: MediaStream | null = null;
  private videoElement: HTMLVideoElement | null = null;
  private activeConsumers: number = 0;
  private lastError: Error | null = null;
  private paused: boolean = false;
  private needsUserGestureForResume: boolean = false;
  private currentFacing: 'user' | 'environment' = 'user';
  
  /**
   * Start the camera and attach it to a video element
   * @param videoEl The video element to attach the camera stream to
   * @param options Camera configuration options
   * @returns Promise resolving to true if camera started successfully
   */
  public async startCamera(
    videoEl: HTMLVideoElement, 
    options: CameraOptions = {}
  ): Promise<boolean> {
    this.videoElement = videoEl;
    
    // If stream exists, check if we need to just reattach or restart
    if (this.stream) {
      if (this.paused) {
        return this.resumeStream();
      }
      
      // Already running, just increment consumer count
      if (this.activeConsumers > 0) {
        this.activeConsumers++;
        this.attachStreamToVideo();
        return true;
      }
    }
    
    try {
      // Configure camera constraints
      const facingMode = options.facingMode || 'user';
      this.currentFacing = facingMode;
      const constraints: MediaStreamConstraints = {
        video: {
          facingMode: { ideal: facingMode },
          width: options.width ? { ideal: options.width } : { ideal: 640 },
          height: options.height ? { ideal: options.height } : { ideal: 480 },
          frameRate: options.frameRate ? { ideal: options.frameRate } : { ideal: 30 }
        },
        audio: false
      };
      
      console.log('CameraManager: Requesting camera access');
      const stream = await navigator.mediaDevices.getUserMedia(constraints);
      this.stream = stream;
      this.lastError = null;
      this.paused = false;
      this.activeConsumers = 1;
      
      // Check for autoplay restrictions (especially on iOS Safari)
      try {
        await this.attachStreamToVideo();
        this.needsUserGestureForResume = false;
      } catch (playError) {
        console.warn('CameraManager: Autoplay prevented, may need user gesture', playError);
        this.needsUserGestureForResume = true;
      }
      
      return true;
    } catch (err) {
      console.error('CameraManager: Error accessing camera', err);
      this.lastError = err instanceof Error 
        ? err 
        : new PoseDetectorError(InitError.CAMERA_PERMISSION, String(err));
      return false;
    }
  }
  
  /**
   * Check if the camera requires a user gesture to play (iOS Safari)
   */
  public requiresUserGesture(): boolean {
    return this.needsUserGestureForResume;
  }
  
  /**
   * Resume the camera stream after a pause
   * Usually triggered by a user gesture
   */
  public async resumeStream(): Promise<boolean> {
    if (!this.stream || !this.videoElement) {
      return false;
    }
    
    try {
      // Ensure tracks are enabled
      this.stream.getVideoTracks().forEach(track => track.enabled = true);
      this.paused = false;
      
      // Try to play the video
      await this.videoElement.play();
      this.needsUserGestureForResume = false;
      return true;
    } catch (err) {
      console.error('CameraManager: Error resuming camera', err);
      this.needsUserGestureForResume = true;
      return false;
    }
  }
  
  /**
   * Pause the camera stream without releasing it
   * Useful for temporarily stopping camera when app goes to background
   */
  public pauseStream(): void {
    if (!this.stream) return;
    
    // Disable video tracks instead of stopping them completely
    this.stream.getVideoTracks().forEach(track => track.enabled = false);
    
    if (this.videoElement) {
      this.videoElement.pause();
    }
    
    this.paused = true;
  }
  
  /**
   * Register a new consumer of the camera
   * Used for reference counting
   */
  public addConsumer(): void {
    this.activeConsumers++;
  }
  
  /**
   * Unregister a consumer of the camera
   * When no consumers remain, the camera is stopped
   */
  public removeConsumer(): void {
    this.activeConsumers = Math.max(0, this.activeConsumers - 1);
    
    if (this.activeConsumers === 0) {
      this.stopCamera();
    }
  }
  
  /**
   * Get the current camera error if any
   */
  public getError(): Error | null {
    return this.lastError;
  }
  
  /**
   * Get the current media stream
   */
  public getStream(): MediaStream | null {
    return this.stream;
  }
  
  /**
   * Check if camera is currently active
   */
  public isActive(): boolean {
    return this.stream !== null && !this.paused;
  }
  
  /**
   * Check if camera is paused
   */
  public isPaused(): boolean {
    return this.paused;
  }
  
  /**
   * Get number of active consumers
   */
  public getConsumerCount(): number {
    return this.activeConsumers;
  }
  
  /**
   * Stop and release the camera
   */
  public stopCamera(): void {
    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop());
      this.stream = null;
    }
    
    if (this.videoElement) {
      this.videoElement.srcObject = null;
      this.videoElement = null;
    }
    
    this.activeConsumers = 0;
    this.paused = false;
    console.log('CameraManager: Camera stopped');
  }
  
  /**
   * Attach the current stream to the video element
   */
  private async attachStreamToVideo(): Promise<void> {
    if (!this.stream || !this.videoElement) return;
    
    this.videoElement.srcObject = this.stream;
    this.videoElement.muted = true;
    this.videoElement.playsInline = true; // Important for iOS
    
    // Try to play - this may throw on iOS if no user gesture occurred
    await this.videoElement.play();
  }

  /**
   * Switch between front (user) and rear (environment) cameras.
   * Works by stopping current tracks and requesting a new stream with the opposite facingMode.
   */
  public async switchFacing(): Promise<boolean> {
    if (!this.videoElement) {
      console.warn('CameraManager: No video element to switch camera');
      return false;
    }

    const newMode: 'user' | 'environment' = this.currentFacing === 'user' ? 'environment' : 'user';

    // Preserve reference before stopping
    const targetVideo = this.videoElement;

    // Stop existing stream but keep video element reference
    if (this.stream) {
      this.stream.getTracks().forEach(track => track.stop());
      targetVideo.srcObject = null;
      this.stream = null;
    }

    // Start camera again with new mode
    const success = await this.startCamera(targetVideo, {
      facingMode: newMode
    });

    return success;
  }

  /**
   * Get current facing mode.
   */
  public getFacingMode(): 'user' | 'environment' {
    return this.currentFacing;
  }
}

// Export a singleton instance
export const cameraManager = new CameraManager();

export default cameraManager; 