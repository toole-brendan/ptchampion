// PT Champion Service Worker
// This service worker handles caching strategies for the PWA

// Cache names with versioning to allow for controlled updates
const STATIC_CACHE_NAME = 'pt-champion-static-v1';
const DYNAMIC_CACHE_NAME = 'pt-champion-dynamic-v1';
const API_CACHE_NAME = 'pt-champion-api-v1';

// Assets to cache on install (app shell)
const APP_SHELL_ASSETS = [
  '/',
  '/index.html',
  '/manifest.json',
  '/assets/index.css',
  '/assets/index.js',
  '/assets/fonts/BebasNeue-Regular.woff2',
  '/assets/fonts/Montserrat-Regular.woff2',
  '/assets/fonts/Montserrat-Medium.woff2',
  '/assets/fonts/Montserrat-Bold.woff2',
  '/assets/fonts/RobotoMono-Regular.woff2',
  '/assets/icons/logo.svg',
  '/assets/icons/icon-192x192.png',
  '/assets/icons/icon-512x512.png',
  '/assets/images/empty-state.json', // Lottie animation
  '/offline.html'
];

// Install event - cache app shell assets
self.addEventListener('install', (event: ExtendableEvent) => {
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
self.addEventListener('activate', (event: ExtendableEvent) => {
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
          })
        );
      })
      // Claim control immediately
      .then(() => self.clients.claim())
  );
});

// Fetch event - handle network requests with appropriate caching strategies
self.addEventListener('fetch', (event: FetchEvent) => {
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
      fetch(request)
        .catch(() => {
          console.log('[Service Worker] Serving offline page for navigation');
          return caches.match('/offline.html');
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
  } catch (error) {
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
  } catch (error) {
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
          });
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
  } catch (error) {
    console.log('[Service Worker] Network request failed with no cache entry', request.url);
    return new Response('Not available offline', { status: 404 });
  }
}

// Background sync for offline form submissions
self.addEventListener('sync', (event: SyncEvent) => {
  if (event.tag === 'sync-workouts') {
    event.waitUntil(syncWorkouts());
  }
});

// Function to sync pending workout data when back online
async function syncWorkouts() {
  try {
    // This would normally use IndexedDB to store and retrieve pending workouts
    // For now, this is a placeholder for the actual implementation
    console.log('[Service Worker] Syncing pending workouts');
    
    // Implementation will be completed in the IndexedDB integration phase
    return Promise.resolve();
  } catch (error) {
    console.error('[Service Worker] Workout sync failed:', error);
    return Promise.reject(error);
  }
}

// TypeScript interface declarations for the service worker
interface ExtendableEvent extends Event {
  waitUntil(fn: Promise<any>): void;
}

interface FetchEvent extends ExtendableEvent {
  request: Request;
  respondWith(response: Promise<Response> | Response): void;
}

interface SyncEvent extends ExtendableEvent {
  tag: string;
}

// Make TypeScript aware of the service worker scope
declare const self: ServiceWorkerGlobalScope; 