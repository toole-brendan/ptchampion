/**
 * IndexedDB wrapper for PT Champion
 * 
 * This module provides a simple interface to interact with IndexedDB
 * for offline data storage and synchronization.
 */

import { openDB, DBSchema, IDBPDatabase } from 'idb';
import { ExerciseResult } from '../../viewmodels/TrackerViewModel';
import { ExerciseId } from '../../constants/exercises';
import { LogExerciseRequest } from '../types';

// Database name and version
const DB_NAME = 'pt-champion-db';
const DB_VERSION = 2; // Incrementing version for schema changes

// Define structure for the value within the userData store
// Used in the PTChampionDB interface below
// eslint-disable-next-line @typescript-eslint/no-unused-vars
interface UserDataValue {
  id: string;
  displayName: string;
  email: string;
  profileImageUrl?: string;
  preferences: {
    theme: 'light' | 'dark' | 'system';
    notifications: boolean;
  };
  lastSynced: number;
}

// Define structure for the value within the workouts store
// Used in the PTChampionDB interface below
// eslint-disable-next-line @typescript-eslint/no-unused-vars
interface WorkoutValue {
   id: string;
   exerciseType: string;
   count: number;
   formScore: number;
   durationSeconds: number;
   deviceType: string;
   userId: string;
   date: string;
   synced: boolean;
   createdAt: number;
}

// Define structure for the pendingExercises store
export interface PendingExerciseValue {
  id: string; // UUID
  exerciseId: number; // From ExerciseId enum
  reps?: number;
  duration?: number;
  distance?: number;
  formScore?: number;
  notes?: string;
  createdAt: number;
  syncAttempts: number;
}

// eslint-disable-next-line @typescript-eslint/no-empty-interface
// Define the database schema with TypeScript
interface PTChampionDB extends DBSchema {
  workouts: {
    key: string; // Use a UUID
    value: {
      id: string;
      exerciseType: string;
      count: number;
      formScore: number;
      durationSeconds: number;
      deviceType: string;
      userId: string;
      date: string;
      synced: boolean;
      createdAt: number;
    };
    indexes: {
      'by-date': string;
      'by-sync-status': boolean;
    };
  };
  userData: {
    key: string; // userId
    value: {
      id: string;
      displayName: string;
      email: string;
      profileImageUrl?: string;
      preferences: {
        theme: 'light' | 'dark' | 'system';
        notifications: boolean;
      };
      lastSynced: number;
    };
  };
  pendingExercises: {
    key: string; // UUID
    value: PendingExerciseValue;
    indexes: {
      'by-created': number;
      'by-sync-attempts': number;
    };
  };
}

// Workout type alias for easier reference
export type Workout = PTChampionDB['workouts']['value'];
export type UserData = PTChampionDB['userData']['value'];

// Create a singleton database instance
let dbPromise: Promise<IDBPDatabase<PTChampionDB>> | null = null;

/**
 * Initialize the database connection
 */
const initDB = async (): Promise<IDBPDatabase<PTChampionDB>> => {
  if (!dbPromise) {
    dbPromise = openDB<PTChampionDB>(DB_NAME, DB_VERSION, {
      upgrade(db: IDBPDatabase<PTChampionDB>, oldVersion) {
        // Create workouts store
        if (!db.objectStoreNames.contains('workouts')) {
          const workoutStore = db.createObjectStore('workouts', { keyPath: 'id' });
          // Create indexes for querying
          workoutStore.createIndex('by-date', 'date');
          workoutStore.createIndex('by-sync-status', 'synced');
        }

        // Create userData store
        if (!db.objectStoreNames.contains('userData')) {
          db.createObjectStore('userData', { keyPath: 'id' });
        }
        
        // Add pendingExercises store in version 2
        if (oldVersion < 2 && !db.objectStoreNames.contains('pendingExercises')) {
          const pendingStore = db.createObjectStore('pendingExercises', { keyPath: 'id' });
          pendingStore.createIndex('by-created', 'createdAt');
          pendingStore.createIndex('by-sync-attempts', 'syncAttempts');
        }
      },
    });
  }
  return dbPromise;
};

/**
 * Save a workout to IndexedDB
 */
export const saveWorkout = async (workout: Omit<Workout, 'synced' | 'createdAt'>) => {
  try {
    const db = await initDB();
    const tx = db.transaction('workouts', 'readwrite');
    const store = tx.objectStore('workouts');
    
    // Add synced and createdAt properties
    const workoutToSave: Workout = {
      ...workout,
      synced: false,
      createdAt: Date.now(),
    };
    
    await store.add(workoutToSave);
    await tx.done;
    return true;
  } catch (error) {
    console.error('Error saving workout to IndexedDB:', error);
    return false;
  }
};

/**
 * Get all workouts from IndexedDB
 */
export const getAllWorkouts = async (): Promise<Workout[]> => {
  try {
    const db = await initDB();
    return db.getAll('workouts');
  } catch (error) {
    console.error('Error getting workouts from IndexedDB:', error);
    return [];
  }
};

/**
 * Get workouts by user ID
 */
export const getWorkoutsByUserId = async (userId: string): Promise<Workout[]> => {
  try {
    const db = await initDB();
    const tx = db.transaction('workouts', 'readonly');
    const store = tx.objectStore('workouts');
    const workouts = await store.getAll();
    await tx.done;
    
    return workouts.filter(workout => workout.userId === userId);
  } catch (error) {
    console.error('Error getting workouts by user ID:', error);
    return [];
  }
};

/**
 * Get pending (unsynced) workouts
 */
export const getPendingWorkouts = async (): Promise<Workout[]> => {
  try {
    const db = await initDB();
    const tx = db.transaction('workouts', 'readonly');
    const index = tx.objectStore('workouts').index('by-sync-status');
    const pendingWorkouts = await index.getAll(false);
    await tx.done;
    
    return pendingWorkouts;
  } catch (error) {
    console.error('Error getting pending workouts:', error);
    return [];
  }
};

/**
 * Mark a workout as synced
 */
export const markWorkoutAsSynced = async (id: string): Promise<boolean> => {
  try {
    const db = await initDB();
    const tx = db.transaction('workouts', 'readwrite');
    const store = tx.objectStore('workouts');
    
    const workout = await store.get(id);
    if (workout) {
      workout.synced = true;
      await store.put(workout);
    }
    
    await tx.done;
    return true;
  } catch (error) {
    console.error('Error marking workout as synced:', error);
    return false;
  }
};

/**
 * Delete a workout
 */
export const deleteWorkout = async (id: string): Promise<boolean> => {
  try {
    const db = await initDB();
    const tx = db.transaction('workouts', 'readwrite');
    const store = tx.objectStore('workouts');
    await store.delete(id);
    await tx.done;
    return true;
  } catch (error) {
    console.error('Error deleting workout:', error);
    return false;
  }
};

/**
 * Save user data
 */
export const saveUserData = async (userData: UserData): Promise<boolean> => {
  try {
    const db = await initDB();
    const tx = db.transaction('userData', 'readwrite');
    const store = tx.objectStore('userData');
    
    await store.put(userData);
    await tx.done;
    return true;
  } catch (error) {
    console.error('Error saving user data to IndexedDB:', error);
    return false;
  }
};

/**
 * Get user data from IndexedDB
 */
export const getUserData = async (userId: string): Promise<UserData | null> => {
  try {
    const db = await initDB();
    const data = await db.get('userData', userId);
    return data ?? null; // Return data or explicitly null if undefined
  } catch (error) {
    console.error('Error getting user data:', error);
    return null;
  }
};

/**
 * Clear all data (for logout or reset)
 */
export const clearAllData = async (): Promise<boolean> => {
  try {
    const db = await initDB();
    const tx1 = db.transaction('workouts', 'readwrite');
    const tx2 = db.transaction('userData', 'readwrite');
    const tx3 = db.transaction('pendingExercises', 'readwrite');
    
    await tx1.objectStore('workouts').clear();
    await tx2.objectStore('userData').clear();
    await tx3.objectStore('pendingExercises').clear();
    
    await tx1.done;
    await tx2.done;
    await tx3.done;
    return true;
  } catch (error) {
    console.error('Error clearing all data from IndexedDB:', error);
    return false;
  }
};

/**
 * Generate a unique ID (UUID v4-like)
 */
const generateUUID = (): string => {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
};

/**
 * Convert ExerciseResult to LogExerciseRequest format
 */
export const resultToRequestData = (result: ExerciseResult, exerciseId: ExerciseId): LogExerciseRequest => {
  return {
    exercise_id: exerciseId,
    reps: result.repCount,
    duration: result.duration,
    distance: result.distance,
    notes: result.formScore ? `Form Score: ${result.formScore.toFixed(0)}` : undefined
  };
};

/**
 * Store an offline exercise result
 * @param result Exercise result to store
 * @param exerciseId The ID of the exercise
 * @returns Promise with boolean success indicator and the ID of the stored entry
 */
export const storeOfflineWorkout = async (
  result: ExerciseResult,
  exerciseId: ExerciseId
): Promise<{ success: boolean; id: string }> => {
  try {
    const db = await initDB();
    const tx = db.transaction('pendingExercises', 'readwrite');
    const store = tx.objectStore('pendingExercises');
    
    const id = generateUUID();
    const pendingExercise: PendingExerciseValue = {
      id,
      exerciseId,
      reps: result.repCount,
      duration: result.duration,
      distance: result.distance,
      formScore: result.formScore,
      notes: result.formScore ? `Form Score: ${result.formScore.toFixed(0)}` : undefined,
      createdAt: Date.now(),
      syncAttempts: 0
    };
    
    await store.add(pendingExercise);
    await tx.done;
    
    return { success: true, id };
  } catch (error) {
    console.error('Error storing offline workout:', error);
    return { success: false, id: '' };
  }
};

/**
 * Get all pending exercises that need to be synced
 */
export const getPendingExercises = async (): Promise<PendingExerciseValue[]> => {
  try {
    const db = await initDB();
    return db.getAll('pendingExercises');
  } catch (error) {
    console.error('Error getting pending exercises:', error);
    return [];
  }
};

/**
 * Update sync attempt count for a pending exercise
 */
export const incrementSyncAttempt = async (id: string): Promise<boolean> => {
  try {
    const db = await initDB();
    const tx = db.transaction('pendingExercises', 'readwrite');
    const store = tx.objectStore('pendingExercises');
    
    const exercise = await store.get(id);
    if (exercise) {
      exercise.syncAttempts += 1;
      await store.put(exercise);
    }
    
    await tx.done;
    return true;
  } catch (error) {
    console.error('Error incrementing sync attempt count:', error);
    return false;
  }
};

/**
 * Delete a pending exercise after successful sync
 */
export const deletePendingExercise = async (id: string): Promise<boolean> => {
  try {
    const db = await initDB();
    const tx = db.transaction('pendingExercises', 'readwrite');
    const store = tx.objectStore('pendingExercises');
    
    await store.delete(id);
    await tx.done;
    return true;
  } catch (error) {
    console.error('Error deleting pending exercise:', error);
    return false;
  }
}; 