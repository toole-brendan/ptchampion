import { WorkoutRequest } from '../types/api';

export interface QueuedWorkout {
  id: string;
  workout: WorkoutRequest;
  timestamp: number;
  retryCount: number;
  lastError?: string;
}

export interface SyncStatus {
  isPending: boolean;
  pendingCount: number;
  lastSyncTime?: number;
  lastError?: string;
}

type SyncStatusListener = (status: SyncStatus) => void;

class OfflineQueueService {
  private db: IDBDatabase | null = null;
  private readonly DB_NAME = 'PTChampionOfflineDB';
  private readonly DB_VERSION = 1;
  private readonly STORE_NAME = 'workouts';
  private syncStatusListeners: Set<SyncStatusListener> = new Set();
  private isSyncing = false;

  async initialize(): Promise<void> {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.DB_NAME, this.DB_VERSION);

      request.onerror = () => {
        reject(new Error('Failed to open IndexedDB'));
      };

      request.onsuccess = () => {
        this.db = request.result;
        resolve();
      };

      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result;
        
        if (!db.objectStoreNames.contains(this.STORE_NAME)) {
          const store = db.createObjectStore(this.STORE_NAME, { keyPath: 'id' });
          store.createIndex('timestamp', 'timestamp', { unique: false });
        }
      };
    });
  }

  async enqueue(workout: WorkoutRequest): Promise<string> {
    if (!this.db) {
      await this.initialize();
    }

    const id = crypto.randomUUID();
    const queuedWorkout: QueuedWorkout = {
      id,
      workout,
      timestamp: Date.now(),
      retryCount: 0,
    };

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([this.STORE_NAME], 'readwrite');
      const store = transaction.objectStore(this.STORE_NAME);
      const request = store.add(queuedWorkout);

      request.onsuccess = () => {
        this.notifyStatusChange();
        resolve(id);
      };

      request.onerror = () => {
        reject(new Error('Failed to enqueue workout'));
      };
    });
  }

  async dequeue(id: string): Promise<void> {
    if (!this.db) {
      await this.initialize();
    }

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([this.STORE_NAME], 'readwrite');
      const store = transaction.objectStore(this.STORE_NAME);
      const request = store.delete(id);

      request.onsuccess = () => {
        this.notifyStatusChange();
        resolve();
      };

      request.onerror = () => {
        reject(new Error('Failed to dequeue workout'));
      };
    });
  }

  async updateRetryInfo(id: string, error: string): Promise<void> {
    if (!this.db) {
      await this.initialize();
    }

    const workout = await this.getWorkout(id);
    if (!workout) return;

    workout.retryCount++;
    workout.lastError = error;

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([this.STORE_NAME], 'readwrite');
      const store = transaction.objectStore(this.STORE_NAME);
      const request = store.put(workout);

      request.onsuccess = () => {
        this.notifyStatusChange();
        resolve();
      };

      request.onerror = () => {
        reject(new Error('Failed to update retry info'));
      };
    });
  }

  async getWorkout(id: string): Promise<QueuedWorkout | null> {
    if (!this.db) {
      await this.initialize();
    }

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([this.STORE_NAME], 'readonly');
      const store = transaction.objectStore(this.STORE_NAME);
      const request = store.get(id);

      request.onsuccess = () => {
        resolve(request.result || null);
      };

      request.onerror = () => {
        reject(new Error('Failed to get workout'));
      };
    });
  }

  async getAllPending(): Promise<QueuedWorkout[]> {
    if (!this.db) {
      await this.initialize();
    }

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([this.STORE_NAME], 'readonly');
      const store = transaction.objectStore(this.STORE_NAME);
      const request = store.getAll();

      request.onsuccess = () => {
        const workouts = request.result || [];
        // Sort by timestamp, oldest first
        workouts.sort((a, b) => a.timestamp - b.timestamp);
        resolve(workouts);
      };

      request.onerror = () => {
        reject(new Error('Failed to get pending workouts'));
      };
    });
  }

  async getPendingCount(): Promise<number> {
    if (!this.db) {
      await this.initialize();
    }

    return new Promise((resolve, reject) => {
      const transaction = this.db!.transaction([this.STORE_NAME], 'readonly');
      const store = transaction.objectStore(this.STORE_NAME);
      const request = store.count();

      request.onsuccess = () => {
        resolve(request.result);
      };

      request.onerror = () => {
        reject(new Error('Failed to get pending count'));
      };
    });
  }

  async clearOldEntries(maxAgeMs: number = 7 * 24 * 60 * 60 * 1000): Promise<void> {
    if (!this.db) {
      await this.initialize();
    }

    const cutoffTime = Date.now() - maxAgeMs;
    const workouts = await this.getAllPending();
    
    for (const workout of workouts) {
      if (workout.timestamp < cutoffTime) {
        await this.dequeue(workout.id);
      }
    }
  }

  // Sync status management
  subscribeToStatusChanges(listener: SyncStatusListener): () => void {
    this.syncStatusListeners.add(listener);
    
    // Send initial status
    this.getStatus().then(status => listener(status));
    
    // Return unsubscribe function
    return () => {
      this.syncStatusListeners.delete(listener);
    };
  }

  private async getStatus(): Promise<SyncStatus> {
    const pendingCount = await this.getPendingCount();
    const lastSyncTime = parseInt(localStorage.getItem('lastSyncTime') || '0');
    const lastError = localStorage.getItem('lastSyncError') || undefined;

    return {
      isPending: pendingCount > 0,
      pendingCount,
      lastSyncTime: lastSyncTime || undefined,
      lastError,
    };
  }

  private async notifyStatusChange(): Promise<void> {
    const status = await this.getStatus();
    this.syncStatusListeners.forEach(listener => listener(status));
  }

  setSyncing(isSyncing: boolean): void {
    this.isSyncing = isSyncing;
  }

  isSyncInProgress(): boolean {
    return this.isSyncing;
  }

  updateLastSyncTime(): void {
    localStorage.setItem('lastSyncTime', Date.now().toString());
    localStorage.removeItem('lastSyncError');
    this.notifyStatusChange();
  }

  updateLastSyncError(error: string): void {
    localStorage.setItem('lastSyncError', error);
    this.notifyStatusChange();
  }
}

// Export singleton instance
export const offlineQueue = new OfflineQueueService();