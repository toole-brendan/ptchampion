/**
 * SyncManager - Handles synchronization between online and offline states
 * This bridges the gap between IndexedDB, ServiceWorker and the UI
 */
import { useEffect, useState } from 'react';
import { 
  storeOfflineWorkout,
  getPendingExercises,
  deletePendingExercise,
  incrementSyncAttempt,
  PendingExerciseValue
} from './db/indexedDB';
import { logExerciseResult } from './apiClient';
import { ExerciseResult } from '../viewmodels/TrackerViewModel';
import { ExerciseId } from '../constants/exercises';

export type SyncStatus = 'idle' | 'syncing' | 'success' | 'error';
export type SyncEventType = 'queued' | 'flushed' | 'error';

export interface SyncEvent {
  type: SyncEventType;
  count?: number;
  message?: string;
}

// Event target for local event handling
const eventTarget = new EventTarget();

// Broadcast channel for communicating sync status across tabs
const syncChannel = typeof BroadcastChannel !== 'undefined' 
  ? new BroadcastChannel('pt-champion-sync-channel') 
  : null;

// Track last sync time to avoid spamming the server
let lastSyncTime = 0;
const SYNC_DEBOUNCE_MS = 60000; // 60 seconds

/**
 * Update the sync status both in localStorage and via broadcast channel
 */
export function updateSyncStatus(status: SyncStatus): void {
  // Store in localStorage for persistence
  localStorage.setItem('pt-champion-sync-status', status);
  
  // Notify any service worker
  if (navigator.serviceWorker && navigator.serviceWorker.controller) {
    navigator.serviceWorker.controller.postMessage({
      type: 'SYNC_STATUS_UPDATE',
      status
    });
  }
  
  // Broadcast to other tabs
  if (syncChannel) {
    syncChannel.postMessage({ type: 'SYNC_STATUS', status });
  }
  
  // Dispatch storage event for same-tab listeners
  window.dispatchEvent(new StorageEvent('storage', {
    key: 'pt-champion-sync-status',
    newValue: status
  }));
}

/**
 * Dispatch a sync event for the UI to respond to
 */
export function dispatchSyncEvent(event: SyncEvent): void {
  const customEvent = new CustomEvent('sync-event', { detail: event });
  eventTarget.dispatchEvent(customEvent);
}

/**
 * Hook to track sync status across the app
 */
export function useSyncStatus() {
  const [status, setStatus] = useState<SyncStatus>(() => {
    return (localStorage.getItem('pt-champion-sync-status') as SyncStatus) || 'idle';
  });
  
  useEffect(() => {
    // Listen for storage events (from other components using updateSyncStatus)
    const handleStorageChange = (event: StorageEvent) => {
      if (event.key === 'pt-champion-sync-status') {
        setStatus(event.newValue as SyncStatus || 'idle');
      }
    };
    
    // Listen for service worker messages
    const handleServiceWorkerMessage = (event: MessageEvent) => {
      if (event.data && event.data.type === 'SYNC_STATUS') {
        setStatus(event.data.status);
      }
    };
    
    // Listen for broadcast channel messages
    const handleBroadcastMessage = (event: MessageEvent) => {
      if (event.data && event.data.type === 'SYNC_STATUS') {
        setStatus(event.data.status);
      }
    };
    
    window.addEventListener('storage', handleStorageChange);
    
    if (navigator.serviceWorker) {
      navigator.serviceWorker.addEventListener('message', handleServiceWorkerMessage);
    }
    
    if (syncChannel) {
      syncChannel.addEventListener('message', handleBroadcastMessage);
    }
    
    return () => {
      window.removeEventListener('storage', handleStorageChange);
      
      if (navigator.serviceWorker) {
        navigator.serviceWorker.removeEventListener('message', handleServiceWorkerMessage);
      }
      
      if (syncChannel) {
        syncChannel.removeEventListener('message', handleBroadcastMessage);
      }
    };
  }, []);
  
  return status;
}

/**
 * Hook to listen for sync events
 */
export function useSyncEvents() {
  const [event, setEvent] = useState<SyncEvent | null>(null);
  
  useEffect(() => {
    const handleSyncEvent = (e: Event) => {
      const customEvent = e as CustomEvent<SyncEvent>;
      setEvent(customEvent.detail);
    };
    
    eventTarget.addEventListener('sync-event', handleSyncEvent);
    
    return () => {
      eventTarget.removeEventListener('sync-event', handleSyncEvent);
    };
  }, []);
  
  return event;
}

/**
 * Queue a workout for sync when offline
 * @param result Exercise result to queue
 * @param exerciseId Exercise ID from enum
 * @returns Promise with success flag
 */
export async function queueWorkout(
  result: ExerciseResult, 
  exerciseId: ExerciseId
): Promise<boolean> {
  try {
    // Store the workout in IndexedDB
    const { success, id } = await storeOfflineWorkout(result, exerciseId);
    
    if (success && id) {
      // Dispatch event for UI notification
      dispatchSyncEvent({
        type: 'queued',
        count: 1,
        message: 'Workout saved for offline sync'
      });
      
      // Try to register a sync task with the service worker
      if ('serviceWorker' in navigator && 'SyncManager' in window) {
        const registration = await navigator.serviceWorker.ready;
        await registration.sync.register('sync-workouts');
      }
      
      return true;
    }
    
    return false;
  } catch (error) {
    console.error('Failed to queue workout:', error);
    
    dispatchSyncEvent({
      type: 'error',
      message: 'Failed to save workout for offline sync'
    });
    
    return false;
  }
}

/**
 * Convert pending exercise to API request format
 */
function pendingToRequest(pending: PendingExerciseValue) {
  return {
    exercise_id: pending.exerciseId,
    reps: pending.reps,
    duration: pending.duration,
    distance: pending.distance,
    notes: pending.notes
  };
}

/**
 * Flush all pending workouts to the server
 * @param force If true, ignores the debounce time check
 * @returns Number of successfully synced items
 */
export async function flushPendingWorkouts(force = false): Promise<number> {
  // Respect debounce period unless forced
  const now = Date.now();
  if (!force && now - lastSyncTime < SYNC_DEBOUNCE_MS) {
    console.log('Sync skipped due to debounce period');
    return 0;
  }
  
  // Update status and last sync time
  updateSyncStatus('syncing');
  lastSyncTime = now;
  
  try {
    // Get all pending exercises
    const pendingExercises = await getPendingExercises();
    
    if (pendingExercises.length === 0) {
      updateSyncStatus('success');
      return 0;
    }
    
    let syncedCount = 0;
    
    // Process each pending exercise
    for (const exercise of pendingExercises) {
      try {
        // Increment sync attempt counter
        await incrementSyncAttempt(exercise.id);
        
        // Skip if too many attempts
        if (exercise.syncAttempts > 5) {
          console.warn(`Skipping exercise ${exercise.id} after ${exercise.syncAttempts} failed attempts`);
          continue;
        }
        
        // Attempt to send to server
        const data = pendingToRequest(exercise);
        await logExerciseResult(data);
        
        // If successful, remove from queue
        await deletePendingExercise(exercise.id);
        syncedCount++;
      } catch (error) {
        console.error(`Failed to sync exercise ${exercise.id}:`, error);
        // We don't throw here to allow other exercises to sync
      }
    }
    
    // Update sync status based on outcome
    updateSyncStatus(syncedCount > 0 ? 'success' : 'error');
    
    // Dispatch event for UI notification
    if (syncedCount > 0) {
      dispatchSyncEvent({
        type: 'flushed',
        count: syncedCount,
        message: `${syncedCount} workouts synced to server`
      });
      
      // Global toast for user notification
      if (typeof window !== 'undefined' && window.showToast) {
        window.showToast({
          title: 'Workouts Synced',
          description: `${syncedCount} workout${syncedCount === 1 ? '' : 's'} synced to server`,
          variant: 'success'
        });
      }
    }
    
    return syncedCount;
  } catch (error) {
    console.error('Error flushing pending workouts:', error);
    updateSyncStatus('error');
    
    dispatchSyncEvent({
      type: 'error',
      message: 'Failed to sync workouts to server'
    });
    
    return 0;
  }
}

/**
 * Trigger a manual sync operation
 */
export async function triggerSync(): Promise<void> {
  updateSyncStatus('syncing');
  
  try {
    // Request a sync via the service worker if available
    if ('serviceWorker' in navigator && 'SyncManager' in window) {
      const registration = await navigator.serviceWorker.ready;
      await registration.sync.register('sync-workouts');
      // Actual status update will come from the service worker
    } else {
      // Fallback: trigger API sync directly
      await flushPendingWorkouts(true);
    }
  } catch (error) {
    console.error('Sync failed:', error);
    updateSyncStatus('error');
  }
}

// Export a single interface for other components
export const syncManager = {
  queueWorkout,
  flushPendingWorkouts,
  triggerSync,
  updateSyncStatus,
  events: {
    addEventListener: (type: string, listener: EventListener) => {
      eventTarget.addEventListener(type, listener);
    },
    removeEventListener: (type: string, listener: EventListener) => {
      eventTarget.removeEventListener(type, listener);
    }
  }
}; 