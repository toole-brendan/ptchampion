import { offlineQueue, QueuedWorkout } from './OfflineQueue';
import { api } from './api';
import { WorkoutRequest } from '../types/api';
import { logger } from '@/lib/logger';

interface SyncResult {
  successful: string[];
  failed: Array<{ id: string; error: string }>;
}

class WorkoutSyncService {
  private isOnline = navigator.onLine;
  private syncInProgress = false;
  private retryTimeouts: Map<string, NodeJS.Timeout> = new Map();
  private readonly MAX_RETRIES = 5;
  private readonly INITIAL_RETRY_DELAY = 1000; // 1 second

  constructor() {
    // Listen for online/offline events
    window.addEventListener('online', this.handleOnline);
    window.addEventListener('offline', this.handleOffline);

    // Initialize sync if online
    if (this.isOnline) {
      this.syncPendingWorkouts();
    }

    // Periodic sync every 5 minutes when online
    setInterval(() => {
      if (this.isOnline && !this.syncInProgress) {
        this.syncPendingWorkouts();
      }
    }, 5 * 60 * 1000);

    // Clean up old entries daily
    setInterval(() => {
      offlineQueue.clearOldEntries();
    }, 24 * 60 * 60 * 1000);
  }

  private handleOnline = () => {
    this.isOnline = true;
    logger.info('Connection restored, syncing pending workouts...');
    this.syncPendingWorkouts();
  };

  private handleOffline = () => {
    this.isOnline = false;
    logger.info('Connection lost, workouts will be queued');
  };

  async submitWorkout(workout: WorkoutRequest): Promise<void> {
    if (!this.isOnline) {
      // Queue for later submission
      await offlineQueue.enqueue(workout);
      logger.info('Workout queued for offline sync');
      return;
    }

    try {
      // Try to submit immediately
      await api.workouts.create(workout);
      logger.info('Workout submitted successfully');
      
      // Also try to sync any pending workouts
      this.syncPendingWorkouts();
    } catch (error) {
      // Queue on failure
      await offlineQueue.enqueue(workout);
      logger.error('Failed to submit workout, queued for retry:', error);
      
      // If it's a network error, mark as offline
      if (this.isNetworkError(error)) {
        this.isOnline = false;
      }
    }
  }

  private async syncPendingWorkouts(): Promise<SyncResult> {
    if (this.syncInProgress || !this.isOnline) {
      return { successful: [], failed: [] };
    }

    this.syncInProgress = true;
    offlineQueue.setSyncing(true);

    const result: SyncResult = {
      successful: [],
      failed: [],
    };

    try {
      const pendingWorkouts = await offlineQueue.getAllPending();
      logger.info(`Syncing ${pendingWorkouts.length} pending workouts`);

      for (const queuedWorkout of pendingWorkouts) {
        // Skip if max retries exceeded
        if (queuedWorkout.retryCount >= this.MAX_RETRIES) {
          logger.warn(`Workout ${queuedWorkout.id} exceeded max retries, skipping`);
          continue;
        }

        try {
          // Check for duplicates before submitting
          if (await this.isDuplicateSubmission(queuedWorkout.workout)) {
            logger.info(`Workout ${queuedWorkout.id} is a duplicate, removing from queue`);
            await offlineQueue.dequeue(queuedWorkout.id);
            result.successful.push(queuedWorkout.id);
            continue;
          }

          // Submit the workout
          await api.workouts.create(queuedWorkout.workout);
          
          // Remove from queue on success
          await offlineQueue.dequeue(queuedWorkout.id);
          result.successful.push(queuedWorkout.id);
          
          logger.info(`Successfully synced workout ${queuedWorkout.id}`);
        } catch (error) {
          const errorMessage = this.getErrorMessage(error);
          result.failed.push({ id: queuedWorkout.id, error: errorMessage });
          
          // Update retry info
          await offlineQueue.updateRetryInfo(queuedWorkout.id, errorMessage);
          
          // Schedule retry with exponential backoff
          this.scheduleRetry(queuedWorkout);
          
          logger.error(`Failed to sync workout ${queuedWorkout.id}:`, error);

          // If it's a network error, stop syncing
          if (this.isNetworkError(error)) {
            this.isOnline = false;
            break;
          }
        }
      }

      if (result.successful.length > 0) {
        offlineQueue.updateLastSyncTime();
      }

      if (result.failed.length > 0) {
        offlineQueue.updateLastSyncError(
          `Failed to sync ${result.failed.length} workout(s)`
        );
      }

    } catch (error) {
      logger.error('Error during sync process:', error);
      offlineQueue.updateLastSyncError(this.getErrorMessage(error));
    } finally {
      this.syncInProgress = false;
      offlineQueue.setSyncing(false);
    }

    return result;
  }

  private scheduleRetry(queuedWorkout: QueuedWorkout): void {
    // Clear any existing retry timeout
    const existingTimeout = this.retryTimeouts.get(queuedWorkout.id);
    if (existingTimeout) {
      clearTimeout(existingTimeout);
    }

    // Calculate delay with exponential backoff
    const delay = this.INITIAL_RETRY_DELAY * Math.pow(2, queuedWorkout.retryCount);
    
    logger.info(`Scheduling retry for workout ${queuedWorkout.id} in ${delay}ms`);

    const timeout = setTimeout(async () => {
      this.retryTimeouts.delete(queuedWorkout.id);
      
      if (this.isOnline && !this.syncInProgress) {
        try {
          await api.workouts.create(queuedWorkout.workout);
          await offlineQueue.dequeue(queuedWorkout.id);
          logger.info(`Retry successful for workout ${queuedWorkout.id}`);
        } catch (error) {
          logger.error(`Retry failed for workout ${queuedWorkout.id}:`, error);
          await offlineQueue.updateRetryInfo(
            queuedWorkout.id,
            this.getErrorMessage(error)
          );
        }
      }
    }, delay);

    this.retryTimeouts.set(queuedWorkout.id, timeout);
  }

  private async isDuplicateSubmission(workout: WorkoutRequest): Promise<boolean> {
    try {
      // Get recent workouts from the server
      const recentWorkouts = await api.workouts.getRecent();
      
      // Check if a workout with the same details exists within the last hour
      const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
      
      return recentWorkouts.some(existing => 
        existing.exercise_type === workout.exercise_type &&
        existing.repetitions === workout.repetitions &&
        existing.duration_seconds === workout.duration_seconds &&
        existing.grade === workout.grade &&
        new Date(existing.completed_at) > oneHourAgo
      );
    } catch (error) {
      // If we can't check for duplicates, assume it's not a duplicate
      logger.warn('Failed to check for duplicate submissions:', error);
      return false;
    }
  }

  private isNetworkError(error: any): boolean {
    if (!error) return false;
    
    // Check for common network error indicators
    if (error.code === 'NETWORK_ERROR' || error.code === 'ECONNREFUSED') {
      return true;
    }
    
    if (error.message && (
      error.message.includes('network') ||
      error.message.includes('fetch') ||
      error.message.includes('Failed to fetch')
    )) {
      return true;
    }
    
    // Check for status 0 (often indicates network failure)
    if (error.status === 0) {
      return true;
    }
    
    return false;
  }

  private getErrorMessage(error: any): string {
    if (error?.response?.data?.error) {
      return error.response.data.error;
    }
    
    if (error?.message) {
      return error.message;
    }
    
    return 'Unknown error occurred';
  }

  // Public methods for UI
  async getQueueStatus() {
    return {
      isOnline: this.isOnline,
      isSyncing: this.syncInProgress,
      pendingCount: await offlineQueue.getPendingCount(),
    };
  }

  async forceSyncNow(): Promise<SyncResult> {
    if (!this.isOnline) {
      throw new Error('Cannot sync while offline');
    }
    
    return this.syncPendingWorkouts();
  }

  destroy(): void {
    // Clean up event listeners and timeouts
    window.removeEventListener('online', this.handleOnline);
    window.removeEventListener('offline', this.handleOffline);
    
    // Clear all retry timeouts
    for (const timeout of this.retryTimeouts.values()) {
      clearTimeout(timeout);
    }
    this.retryTimeouts.clear();
  }
}

// Export singleton instance
export const workoutSyncService = new WorkoutSyncService();