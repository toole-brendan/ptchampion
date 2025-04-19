/**
 * WebAssembly Grading Module
 * 
 * This module provides a TypeScript wrapper for the PT Champion grading WebAssembly module,
 * which handles exercise grading logic like score calculation and pose analysis.
 */

// Types for the grading module
export interface GradingResult {
  isValid: boolean;
  repCounted: boolean;
  formScore: number;
  feedback: string[];
  state: Record<string, any>;
}

export interface WasmResponse<T> {
  success: boolean;
  error?: string;
  score?: number;
  result?: GradingResult;
  repCount?: number;
  state?: string;
}

export interface Joint {
  name: string;
  x: number;
  y: number;
  confidence: number;
}

export interface Pose {
  keypoints: Joint[];
}

// The main grading wrapper class
export class GradingWasm {
  private wasmInstance: WebAssembly.Instance | null = null;
  private isLoading: boolean = false;
  private loadPromise: Promise<void> | null = null;

  /**
   * Load the WebAssembly module
   */
  async load(): Promise<void> {
    if (this.wasmInstance) return;
    if (this.isLoading && this.loadPromise) {
      return this.loadPromise;
    }

    this.isLoading = true;
    this.loadPromise = new Promise<void>(async (resolve, reject) => {
      try {
        // Fetch and instantiate the WebAssembly module
        const response = await fetch('/wasm/grading.wasm');
        const buffer = await response.arrayBuffer();
        const result = await WebAssembly.instantiate(buffer, {
          env: {
            // Add any environment functions needed by the WASM module
          }
        });
        this.wasmInstance = result.instance;
        console.log('Grading WASM module loaded successfully');
        this.isLoading = false;
        resolve();
      } catch (error) {
        this.isLoading = false;
        console.error('Failed to load Grading WASM module:', error);
        reject(error);
      }
    });

    return this.loadPromise;
  }

  /**
   * Calculate the score for an exercise performance
   */
  async calculateScore(exerciseType: string, performanceValue: number): Promise<number> {
    await this.ensureLoaded();
    
    const result = (window as any).calculateExerciseScore(exerciseType, performanceValue) as WasmResponse<{ score: number }>;
    
    if (!result.success) {
      throw new Error(result.error || 'Unknown error calculating score');
    }
    
    return result.score as number;
  }

  /**
   * Grade a push-up pose for form and rep counting
   */
  async gradePushupPose(pose: Pose, stateJson?: string): Promise<{
    result: GradingResult;
    repCount: number;
    state: string;
  }> {
    await this.ensureLoaded();
    
    const poseJson = JSON.stringify(pose);
    const result = (window as any).gradePushupPose(poseJson, stateJson) as WasmResponse<GradingResult>;
    
    if (!result.success) {
      throw new Error(result.error || 'Unknown error grading push-up');
    }
    
    return {
      result: result.result as GradingResult,
      repCount: result.repCount as number,
      state: result.state as string
    };
  }

  /**
   * Ensure the WASM module is loaded before use
   */
  private async ensureLoaded(): Promise<void> {
    if (!this.wasmInstance) {
      await this.load();
    }
  }
}

// Create a singleton instance
const gradingWasm = new GradingWasm();
export default gradingWasm; 