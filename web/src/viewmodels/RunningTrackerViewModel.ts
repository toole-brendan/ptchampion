/**
 * RunningTrackerViewModel.ts
 * 
 * ViewModel for running tracking session. 
 * Unlike other trackers, this uses geolocation instead of pose detection.
 */

import { ExerciseType } from '../grading';
import { RunningGrader, RunningData } from '../grading/RunningGrader';
import { logExerciseResult } from '../lib/apiClient';
import { LogExerciseRequest, ExerciseResponse } from '../lib/types';
import { BaseTrackerViewModel, ExerciseResult, SessionStatus, TrackerErrorType } from './TrackerViewModel';
import { useState, useCallback, useRef, useEffect } from 'react';
// Import createGrader for consistency with other ViewModels
import { createGrader } from '../grading';
import { ExerciseId } from '../constants/exercises';
import { logger } from '@/lib/logger';

// Type for coordinates data
export interface Coordinates {
  lat: number;
  lng: number;
}

/**
 * Class implementation of RunningTrackerViewModel
 */
export class RunningTrackerViewModel extends BaseTrackerViewModel {
  private grader: RunningGrader;
  private submitting: boolean = false;
  private watchId: number | null = null;

  // Running-specific state
  private _distance: number = 0; // in meters
  private _coordinates: Coordinates[] = [];
  private _pace: string = "00:00";
  private _currentPosition: Coordinates | null = null;

  constructor() {
    super(ExerciseType.RUNNING);
    this.grader = createGrader(ExerciseType.RUNNING) as RunningGrader;
  }

  /**
   * Initialize the running tracker
   * No need for video or canvas ref for running
   */
  async initialize(): Promise<void> {
    if (this._status !== SessionStatus.INITIALIZING) {
      this.resetSession();
    }

    try {
      // Check if geolocation is available
      if (!navigator.geolocation) {
        throw new Error("Geolocation is not supported by this browser.");
      }
      
      // Test a single position get to check permissions
      await new Promise<void>((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(
          () => resolve(),
          (error) => reject(error),
          { enableHighAccuracy: true, timeout: 10000 }
        );
      });
      
      this._status = SessionStatus.READY;
      this._error = null;
    } catch (error) {
      logger.error("Failed to initialize geolocation:", error);
      
      if (error instanceof GeolocationPositionError) {
        if (error.code === 1) { // PERMISSION_DENIED
          this.setError(
            TrackerErrorType.LOCATION_PERMISSION,
            "Location permission denied. Please enable location services."
          );
        } else if (error.code === 2) { // POSITION_UNAVAILABLE
          this.setError(
            TrackerErrorType.LOCATION_PERMISSION,
            "Location information is unavailable."
          );
        } else if (error.code === 3) { // TIMEOUT
          this.setError(
            TrackerErrorType.LOCATION_PERMISSION,
            "The request to get user location timed out."
          );
        }
      } else {
        this.setError(
          TrackerErrorType.LOCATION_PERMISSION,
          error instanceof Error ? error.message : "Unknown error initializing geolocation"
        );
      }
    }
  }

  /**
   * Start or resume the tracking session
   */
  startSession(): void {
    if (this._status === SessionStatus.ACTIVE) {
      return; // Already active
    }

    // Start the grader's run tracking
    this.grader.startRun();

    // Start geolocation tracking
    this.startGeolocationTracking();

    // Start timer
    this.startTimer();

    this._status = SessionStatus.ACTIVE;
  }

  /**
   * Start tracking geolocation
   */
  private startGeolocationTracking(): void {
    if (this.watchId !== null) {
      navigator.geolocation.clearWatch(this.watchId);
    }

    this.watchId = navigator.geolocation.watchPosition(
      this.handlePositionUpdate,
      this.handlePositionError,
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 0
      }
    );
  }

  /**
   * Handle position updates from geolocation
   */
  private handlePositionUpdate = (position: GeolocationPosition): void => {
    const { latitude, longitude } = position.coords;
    const newCoord: Coordinates = { lat: latitude, lng: longitude };
    
    // Update current position
    this._currentPosition = newCoord;
    
    // Add to path
    this._coordinates.push(newCoord);
    
    // Update the grader with GPS position
    this.grader.updateGPSPosition({
      latitude: position.coords.latitude,
      longitude: position.coords.longitude,
      timestamp: position.timestamp,
      accuracy: position.coords.accuracy
    });
    
    // Get updated metrics from grader
    this._distance = this.grader.getDistance();
    this._pace = this.grader.getPacePerMile();
    
    // Use processPose to get the grading result (though running doesn't really use pose)
    const gradingResult = this.grader.processPose([]);
    
    // Update any form scores or feedback from the grading result
    if (gradingResult.formScore !== undefined) {
      this._formScore = gradingResult.formScore;
    }
    
    if (gradingResult.formFault) {
      this._formFeedback = gradingResult.formFault;
    }
  };

  /**
   * Handle geolocation errors
   */
  private handlePositionError = (error: GeolocationPositionError): void => {
    logger.error("Geolocation error:", error);
    
    let errorMessage = "An unknown error occurred while tracking location.";
    if (error.code === 1) {
      errorMessage = "Location permission denied. Please enable location services.";
    } else if (error.code === 2) {
      errorMessage = "Location information is unavailable.";
    } else if (error.code === 3) {
      errorMessage = "The request to get user location timed out.";
    }
    
    this.setError(TrackerErrorType.LOCATION_PERMISSION, errorMessage);
    this.pauseSession();
  };

  /**
   * Calculate distance between two points using the Haversine formula
   * @returns Distance in meters
   */
  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // Radius of the Earth in km
    const dLat = this.deg2rad(lat2 - lat1);
    const dLon = this.deg2rad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.deg2rad(lat1)) * Math.cos(this.deg2rad(lat2)) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distanceKm = R * c; // Distance in km
    return distanceKm * 1000; // Convert to meters
  }

  private deg2rad(deg: number): number {
    return deg * (Math.PI / 180);
  }

  /**
   * Clean up resources when component unmounts
   */
  cleanup(): void {
    if (this.watchId !== null) {
      navigator.geolocation.clearWatch(this.watchId);
      this.watchId = null;
    }
    
    this.stopTimer();
  }

  /**
   * Pause the tracking session
   */
  pauseSession(): void {
    if (this._status !== SessionStatus.ACTIVE) {
      return; // Not active
    }

    // Stop geolocation tracking
    if (this.watchId !== null) {
      navigator.geolocation.clearWatch(this.watchId);
      this.watchId = null;
    }

    // Pause timer
    this.stopTimer();

    this._status = SessionStatus.PAUSED;
  }

  /**
   * Finish the tracking session and prepare results
   */
  async finishSession(): Promise<ExerciseResult> {
    if (this._status === SessionStatus.COMPLETED) {
      return this._result!;
    }

    // Stop tracking if active
    if (this._status === SessionStatus.ACTIVE) {
      if (this.watchId !== null) {
        navigator.geolocation.clearWatch(this.watchId);
        this.watchId = null;
      }
      this.stopTimer();
    }

    // Stop the run in the grader
    this.grader.stopRun();
    
    // Get the final form score
    this._formScore = this.grader.getFormScore();

    // Create the result object
    const result: ExerciseResult = {
      exerciseType: this._exerciseType,
      distance: this.grader.getDistance(),
      duration: this.grader.getDuration(),
      pace: this.grader.getPacePerMile(),
      formScore: this.grader.getFormScore(),
      date: new Date(),
      saved: false
    };

    this._result = result;
    this._status = SessionStatus.COMPLETED;

    return result;
  }

  /**
   * Save results to backend
   */
  async saveResults(): Promise<boolean> {
    if (!this._result || this.submitting) {
      return false;
    }

    if (this._result.saved) {
      return true; // Already saved
    }

    this.submitting = true;

    try {
      // Prepare API request data
      const exerciseData: LogExerciseRequest = {
        exercise_id: ExerciseId.RUNNING,
        duration: this._result.duration,
        distance: this._result.distance,
        notes: this._result.distance ? `Distance: ${(this._result.distance / 1000).toFixed(2)}km, Pace: ${this._pace}/km` : undefined
      };

      // Check if we're online
      const isOnline = navigator.onLine;
      
      if (isOnline) {
        try {
          // Call the API with retry capability
          const response: ExerciseResponse = await logExerciseResult(exerciseData);
          
          // Update result with grade and saved status
          this._result.grade = response.grade;
          this._result.saved = true;
          
          return true;
        } catch (error) {
          // If API call fails, fall back to offline queue
          logger.info("API call failed, falling back to offline queue", error);
          return await this.saveOffline();
        }
      } else {
        // We're offline, save to queue immediately
        return await this.saveOffline();
      }
    } catch (error) {
      logger.error("Failed to save running results:", error);
      
      // Show toast notification to user 
      if (typeof window !== 'undefined' && window.showToast) {
        window.showToast({ 
          title: 'Save Failed', 
          description: 'Could not save exercise results. Will retry when online.', 
          variant: 'destructive' 
        });
      }
      
      // Log to error monitoring service if available
      if (typeof window !== 'undefined' && window.captureException) {
        window.captureException(error);
      }
      
      return false;
    } finally {
      this.submitting = false;
    }
  }
  
  /**
   * Save results to offline queue for later sync
   */
  private async saveOffline(): Promise<boolean> {
    try {
      // Import syncManager dynamically to avoid circular dependencies
      const { syncManager } = await import('../lib/syncManager');
      
      // Queue the workout for background sync
      const queued = await syncManager.queueWorkout(this._result!, ExerciseId.RUNNING);
      
      if (queued) {
        // Update local state to reflect that it's "saved" (but not yet synced to server)
        this._result!.saved = true;
        
        // Show toast notification to user
        if (typeof window !== 'undefined' && window.showToast) {
          window.showToast({
            title: 'Workout Saved Offline',
            description: 'Your workout has been saved and will sync when you\'re back online.',
            variant: 'success'
          });
        }
        
        return true;
      }
      
      return false;
    } catch (error) {
      logger.error("Failed to save running results offline:", error);
      
      // Log to error monitoring service if available
      if (typeof window !== 'undefined' && window.captureException) {
        window.captureException(error);
      }
      
      return false;
    }
  }

  /**
   * Get the current distance in meters
   */
  get distance(): number {
    return this._distance;
  }

  /**
   * Get the current pace (min/km)
   */
  get pace(): string {
    return this._pace;
  }

  /**
   * Get the current coordinates
   */
  get coordinates(): Coordinates[] {
    return [...this._coordinates];
  }

  /**
   * Get the current position
   */
  get currentPosition(): Coordinates | null {
    return this._currentPosition;
  }

  /**
   * Public method to format time in seconds to mm:ss format
   */
  formatTime(seconds: number): string {
    return super.formatTime(seconds);
  }

  /**
   * Convert distance to miles for display
   */
  getDistanceInMiles(): number {
    return this._distance / 1609.34;
  }

  /**
   * Reset the session to its initial state
   */
  resetSession(): void {
    super.resetSession();
    this.grader.reset();
    
    this._distance = 0;
    this._coordinates = [];
    this._pace = "00:00";
    this._currentPosition = null;
    
    if (this.watchId !== null) {
      navigator.geolocation.clearWatch(this.watchId);
      this.watchId = null;
    }
  }
}

/**
 * React hook that provides the RunningTrackerViewModel
 */
export function useRunningTrackerViewModel() {
  // State to hold the ViewModel and trigger re-renders on changes
  const [viewModel] = useState<RunningTrackerViewModel>(() => new RunningTrackerViewModel());
  
  // Refs to hold latest values for use in callbacks
  const timerRef = useRef(viewModel.timer);
  const statusRef = useRef(viewModel.status);
  const distanceRef = useRef(viewModel.distance);
  const paceRef = useRef(viewModel.pace);
  const currentPositionRef = useRef(viewModel.currentPosition);
  const coordinatesRef = useRef(viewModel.coordinates);
  const errorRef = useRef(viewModel.error);
  const resultRef = useRef(viewModel.result);
  
  // State for UI updates
  const [timer, setTimer] = useState(viewModel.timer);
  const [status, setStatus] = useState(viewModel.status);
  const [distance, setDistance] = useState(viewModel.distance);
  const [distanceMiles, setDistanceMiles] = useState(viewModel.getDistanceInMiles());
  const [pace, setPace] = useState(viewModel.pace);
  const [currentPosition, setCurrentPosition] = useState(viewModel.currentPosition);
  const [coordinates, setCoordinates] = useState(viewModel.coordinates);
  const [error, setError] = useState(viewModel.error);
  const [result, setResult] = useState(viewModel.result);
  
  // Update state on interval
  useEffect(() => {
    const updateInterval = setInterval(() => {
      // Check if any values have changed and update state if needed
      if (timerRef.current !== viewModel.timer) {
        timerRef.current = viewModel.timer;
        setTimer(viewModel.timer);
      }
      
      if (statusRef.current !== viewModel.status) {
        statusRef.current = viewModel.status;
        setStatus(viewModel.status);
      }
      
      if (distanceRef.current !== viewModel.distance) {
        distanceRef.current = viewModel.distance;
        setDistance(viewModel.distance);
        setDistanceMiles(viewModel.getDistanceInMiles());
      }
      
      if (paceRef.current !== viewModel.pace) {
        paceRef.current = viewModel.pace;
        setPace(viewModel.pace);
      }
      
      if (currentPositionRef.current !== viewModel.currentPosition) {
        currentPositionRef.current = viewModel.currentPosition;
        setCurrentPosition(viewModel.currentPosition);
      }
      
      if (coordinatesRef.current !== viewModel.coordinates) {
        coordinatesRef.current = viewModel.coordinates;
        setCoordinates(viewModel.coordinates);
      }
      
      if (errorRef.current !== viewModel.error) {
        errorRef.current = viewModel.error;
        setError(viewModel.error);
      }
      
      if (resultRef.current !== viewModel.result) {
        resultRef.current = viewModel.result;
        setResult(viewModel.result);
      }
    }, 250); // Update 4 times per second
    
    return () => {
      clearInterval(updateInterval);
      viewModel.cleanup();
    };
  }, [viewModel]);
  
  // Initialize method
  const initialize = useCallback(async () => {
    return await viewModel.initialize();
  }, [viewModel]);
  
  const startSession = useCallback(() => {
    viewModel.startSession();
  }, [viewModel]);
  
  const pauseSession = useCallback(() => {
    viewModel.pauseSession();
  }, [viewModel]);
  
  const finishSession = useCallback(async () => {
    return await viewModel.finishSession();
  }, [viewModel]);
  
  const resetSession = useCallback(() => {
    viewModel.resetSession();
  }, [viewModel]);
  
  const saveResults = useCallback(async () => {
    return await viewModel.saveResults();
  }, [viewModel]);
  
  // Return the state and methods
  return {
    // State
    timer,
    status,
    distance,
    distanceMiles,
    pace,
    currentPosition,
    coordinates,
    error,
    result,
    
    // Formatted time
    formattedTime: viewModel.formatTime(timer),
    
    // Methods
    initialize,
    startSession,
    pauseSession,
    finishSession,
    resetSession,
    saveResults
  };
}

export default useRunningTrackerViewModel; 