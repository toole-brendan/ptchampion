/**
 * IndexedDB wrapper for PT Champion
 * 
 * This module provides a simple interface to interact with IndexedDB
 * for offline data storage and synchronization.
 */

import { openDB, DBSchema, IDBPDatabase } from 'idb';

// Database name and version
const DB_NAME = 'pt-champion-db';
const DB_VERSION = 1;

// Define structure for the value within the userData store
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
      upgrade(db: IDBPDatabase<PTChampionDB>) {
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
    
    await tx1.objectStore('workouts').clear();
    await tx2.objectStore('userData').clear();
    
    await tx1.done;
    await tx2.done;
    return true;
  } catch (error) {
    console.error('Error clearing all data from IndexedDB:', error);
    return false;
  }
}; 