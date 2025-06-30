/// <reference lib="webworker" />

// PT Champion Service Worker
// This service worker handles caching strategies for the PWA

// Tell TypeScript this file is a service worker
declare const self: ServiceWorkerGlobalScope;

// Define SyncEvent interface that TypeScript is missing
interface SyncEvent extends ExtendableEvent {
  tag: string;
}

// Extend the ServiceWorkerGlobalScope interface to include sync events
declare global {
  interface ServiceWorkerGlobalScopeEventMap {
    sync: SyncEvent;
  }
}

// Cache names with versioning to allow for controlled updates
const STATIC_CACHE_NAME = 'pt-champion-static-v4';
const DYNAMIC_CACHE_NAME = 'pt-champion-dynamic-v4';
const API_CACHE_NAME = 'pt-champion-api-v4';

// Assets to cache on install (app shell)
const APP_SHELL_ASSETS = [
  '/',
  '/manifest.json',
  '/offline.html'
];

// Install event - cache app shell assets
self.addEventListener('install', (event) => {
  console.log('[Service Worker] Installing');
  
  // Skip waiting to ensure the new service worker activates immediately
  self.skipWaiting();
  
  event.waitUntil(
    caches.open(STATIC_CACHE_NAME)
      .then(cache => {
        console.log('[Service Worker] Caching app shell');
        return cache.addAll(APP_SHELL_ASSETS);
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[Service Worker] Activating');
  
  event.waitUntil(
    caches.keys()
      .then(keyList => {
        return Promise.all(
          keyList.map(key => {
            // Delete old versions of our caches
            if (
              key !== STATIC_CACHE_NAME && 
              key !== DYNAMIC_CACHE_NAME && 
              key !== API_CACHE_NAME
            ) {
              console.log('[Service Worker] Removing old cache', key);
              return caches.delete(key);
            }
            return Promise.resolve();
          })
        );
      })
      // Claim control immediately
      .then(() => self.clients.claim())
  );
});

// Fetch event - handle network requests with appropriate caching strategies
self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);
  
  // Skip non-GET requests and browser extension requests
  if (request.method !== 'GET' || url.origin.includes('chrome-extension')) {
    return;
  }
  
  // For API requests - use a Network First strategy with fallback to cache
  if (url.pathname.includes('/api/')) {
    event.respondWith(networkFirstStrategy(request));
    return;
  }
  
  // For static assets - use a Cache First strategy
  if (
    APP_SHELL_ASSETS.includes(url.pathname) || 
    url.pathname.includes('/assets/')
  ) {
    event.respondWith(cacheFirstStrategy(request));
    return;
  }
  
  // For HTML navigation requests - use a Network First strategy with offline fallback
  if (request.mode === 'navigate' || request.headers.get('accept')?.includes('text/html')) {
    event.respondWith(
      // FIX: Ensure we always return a Response by handling undefined case
      fetch(request).catch(() => {
        console.log('[Service Worker] Serving offline page for navigation');
        // Return offline.html from the cache or a fallback response if not found
        return caches.match('/offline.html').then(response => {
          return response || new Response('Offline page not found', {
            status: 503,
            headers: { 'Content-Type': 'text/plain' }
          });
        });
      })
    );
    return;
  }
  
  // Default strategy - Stale While Revalidate
  event.respondWith(staleWhileRevalidateStrategy(request));
});

// Network First strategy - try network, fallback to cache if available
async function networkFirstStrategy(request: Request) {
  try {
    const networkResponse = await fetch(request);
    
    // Cache a copy of the response for future
    const cache = await caches.open(API_CACHE_NAME);
    cache.put(request, networkResponse.clone());
    
    return networkResponse;
  } catch (
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    _error
  ) {
    console.log('[Service Worker] Network request failed, trying cache', request.url);
    
    // Try to get from cache
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    
    // If no cache match, return a generic error response
    return new Response(JSON.stringify({ 
      error: 'Network request failed and no cached version available' 
    }), {
      status: 503,
      headers: { 'Content-Type': 'application/json' }
    });
  }
}

// Cache First strategy - try cache, fallback to network
async function cacheFirstStrategy(request: Request) {
  const cachedResponse = await caches.match(request);
  if (cachedResponse) {
    return cachedResponse;
  }
  
  // If not in cache, get from network and add to dynamic cache
  try {
    const networkResponse = await fetch(request);
    const cache = await caches.open(DYNAMIC_CACHE_NAME);
    cache.put(request, networkResponse.clone());
    return networkResponse;
  } catch (
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    _error
  ) {
    console.log('[Service Worker] Both cache and network failed', request.url);
    
    // If both cache and network fail, return a basic offline response
    if (request.url.includes('.png') || request.url.includes('.jpg') || request.url.includes('.svg')) {
      // Return a placeholder image for image requests
      return new Response('', { status: 404 });
    }
    
    return new Response('Resource not available offline', { status: 404 });
  }
}

// Stale While Revalidate strategy - return from cache while updating in the background
async function staleWhileRevalidateStrategy(request: Request) {
  const cachedResponse = await caches.match(request);
  
  // Return cached response immediately if available
  if (cachedResponse) {
    // Update cache in the background
    fetch(request)
      .then(networkResponse => {
        caches.open(DYNAMIC_CACHE_NAME)
          .then(cache => {
            cache.put(request, networkResponse);
          })
          .catch(
            // eslint-disable-next-line @typescript-eslint/no-unused-vars
            _error => console.log('[Service Worker] Failed to update cache')
          );
      })
      .catch(() => console.log('[Service Worker] Background refresh failed'));
    
    return cachedResponse;
  }
  
  // If not in cache, get from network and add to cache
  try {
    const networkResponse = await fetch(request);
    const cache = await caches.open(DYNAMIC_CACHE_NAME);
    cache.put(request, networkResponse.clone());
    return networkResponse;
  } catch (
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    _error
  ) {
    console.log('[Service Worker] Network request failed with no cache entry', request.url);
    return new Response('Not available offline', { status: 404 });
  }
}

// Background sync for offline form submissions
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-workouts' || event.tag === 'pt-champion-sync') {
    notifyClients({ type: 'SYNC_STATUS', status: 'syncing' });
    event.waitUntil(
      syncWorkouts()
        .then((syncedCount) => {
          notifyClients({ 
            type: 'SYNC_STATUS', 
            status: 'success',
            data: { count: syncedCount }
          });
        })
        .catch(error => {
          console.error('[Service Worker] Sync failed:', error);
          notifyClients({ type: 'SYNC_STATUS', status: 'error' });
        })
    );
  }
});

// Function to notify all clients about sync status
function notifyClients(message: unknown) {
  self.clients.matchAll()
    .then(clients => {
      clients.forEach(client => {
        client.postMessage(message);
      });
    });
}

// Listen for messages from the client
self.addEventListener('message', 
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  event => {
  if (event.data && event.data.type === 'SYNC_STATUS_UPDATE') {
    // Broadcast the sync status to all other clients
    notifyClients({ 
      type: 'SYNC_STATUS', 
      status: event.data.status 
    });
  }
  
  // Handle skip waiting message for updates
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

// Define types for pending exercises
interface PendingExercise {
  id: string;
  exerciseId: string;
  reps: number;
  duration: number;
  distance?: number;
  notes?: string;
  syncAttempts: number;
  createdAt: number;
}

// Function to sync pending workout data when back online
async function syncWorkouts() {
  try {
    console.log('[Service Worker] Syncing pending workouts');
    
    // Open the database
    const db = await openDatabase();
    if (!db) {
      console.error('[Service Worker] Failed to open database');
      return 0;
    }
    
    // Get all pending exercises
    const pendingExercises = await getAllPendingExercises(db);
    
    if (pendingExercises.length === 0) {
      console.log('[Service Worker] No pending workouts to sync');
      return 0;
    }
    
    let syncedCount = 0;
    
    // Process each pending exercise
    for (const exercise of pendingExercises) {
      try {
        // Increment sync attempt counter
        await incrementSyncAttempt(db, exercise.id);
        
        // Skip if too many attempts
        if (exercise.syncAttempts > 5) {
          console.warn(`[Service Worker] Skipping exercise ${exercise.id} after ${exercise.syncAttempts} failed attempts`);
          continue;
        }
        
        // Prepare request data
        const requestData = {
          exercise_id: exercise.exerciseId,
          reps: exercise.reps,
          duration: exercise.duration,
          distance: exercise.distance,
          notes: exercise.notes
        };
        
        // Send to server
        const response = await fetch('/api/v1/exercises', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${await getAuthToken()}`
          },
          body: JSON.stringify(requestData)
        });
        
        if (!response.ok) {
          throw new Error(`Server returned ${response.status}: ${response.statusText}`);
        }
        
        // If successful, remove from queue
        await deletePendingExercise(db, exercise.id);
        syncedCount++;
      } catch (error) {
        console.error(`[Service Worker] Failed to sync exercise ${exercise.id}:`, error);
        // We don't throw here to allow other exercises to sync
      }
    }
    
    console.log(`[Service Worker] Successfully synced ${syncedCount} workouts`);
    return syncedCount;
  } catch (error) {
    console.error('[Service Worker] Workout sync failed:', error);
    throw error;
  }
}

// Helper function to get auth token
async function getAuthToken() {
  try {
    // Try to get token from localStorage
    // Note: Service worker can't directly access localStorage, so we check IndexedDB or cache
    const tokenCache = await caches.open('auth-token-cache');
    const tokenResponse = await tokenCache.match('/auth-token');
    
    if (tokenResponse) {
      const tokenData = await tokenResponse.json();
      return tokenData.token;
    }
    
    return null;
  } catch (error) {
    console.error('[Service Worker] Failed to get auth token:', error);
    return null;
  }
}

// IndexedDB helper functions
async function openDatabase(): Promise<IDBDatabase | null> {
  return new Promise<IDBDatabase | null>((resolve, reject) => {
    const request = indexedDB.open('pt-champion-db', 2);
    
    request.onerror = () => {
      console.error('[Service Worker] IndexedDB error');
      reject(request.error);
    };
    
    request.onsuccess = () => {
      resolve(request.result);
    };
    
    request.onupgradeneeded = (
      // eslint-disable-next-line @typescript-eslint/no-unused-vars
      event
    ) => {
      const db = request.result;
      
      // Create stores if they don't exist
      if (!db.objectStoreNames.contains('pendingExercises')) {
        const pendingStore = db.createObjectStore('pendingExercises', { keyPath: 'id' });
        pendingStore.createIndex('by-created', 'createdAt');
        pendingStore.createIndex('by-sync-attempts', 'syncAttempts');
      }
    };
  });
}

async function getAllPendingExercises(db: IDBDatabase): Promise<PendingExercise[]> {
  return new Promise<PendingExercise[]>((resolve, reject) => {
    const transaction = db.transaction('pendingExercises', 'readonly');
    const store = transaction.objectStore('pendingExercises');
    const request = store.getAll();
    
    request.onerror = () => {
      reject(request.error);
    };
    
    request.onsuccess = () => {
      resolve(request.result as PendingExercise[]);
    };
  });
}

async function incrementSyncAttempt(db: IDBDatabase, id: string): Promise<void> {
  return new Promise<void>((resolve, reject) => {
    const transaction = db.transaction('pendingExercises', 'readwrite');
    const store = transaction.objectStore('pendingExercises');
    const getRequest = store.get(id);
    
    getRequest.onerror = () => {
      reject(getRequest.error);
    };
    
    getRequest.onsuccess = () => {
      const exercise = getRequest.result as PendingExercise | undefined;
      if (exercise) {
        exercise.syncAttempts += 1;
        const updateRequest = store.put(exercise);
        
        updateRequest.onerror = () => {
          reject(updateRequest.error);
        };
        
        updateRequest.onsuccess = () => {
          resolve();
        };
      } else {
        resolve();
      }
    };
  });
}

async function deletePendingExercise(db: IDBDatabase, id: string): Promise<void> {
  return new Promise<void>((resolve, reject) => {
    const transaction = db.transaction('pendingExercises', 'readwrite');
    const store = transaction.objectStore('pendingExercises');
    const request = store.delete(id);
    
    request.onerror = () => {
      reject(request.error);
    };
    
    request.onsuccess = () => {
      resolve();
    };
  });
}

// Empty export to make TypeScript treat this as a module
export {}; 