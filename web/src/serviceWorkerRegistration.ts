/**
 * PT Champion Service Worker Registration
 * 
 * This file handles the registration and lifecycle of the service worker
 * which enables offline capabilities for the app.
 */

import { updateSyncStatus } from './lib/syncManager';

// Check if service workers are supported by the browser
const isServiceWorkerSupported = 'serviceWorker' in navigator;

// URL of the service worker script
const SW_URL = '/serviceWorker.js';

// For localhost detection
const isLocalhost = Boolean(
  window.location.hostname === 'localhost' ||
    // [::1] is the IPv6 localhost address.
    window.location.hostname === '[::1]' ||
    // 127.0.0.0/8 are considered localhost for IPv4.
    window.location.hostname.match(/^127(?:\.(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$/)
);

// Configuration for registration callbacks
type Config = {
  onSuccess?: (registration: ServiceWorkerRegistration) => void;
  onUpdate?: (registration: ServiceWorkerRegistration) => void;
  onMessage?: (event: MessageEvent) => void;
};

// Define the SyncManager type
interface SyncManager {
  register(tag: string): Promise<void>;
}

// Declare this interface since TypeScript doesn't include it yet
declare global {
  interface ServiceWorkerRegistration {
    sync?: SyncManager;
  }
}

/**
 * Register the service worker for the application
 */
export const registerServiceWorker = async (config?: Config): Promise<void> => {
  if (!isServiceWorkerSupported) {
    console.log('Service Workers are not supported in this browser.');
    return;
  }

  try {
    // Wait until window is loaded
    if (document.readyState !== 'complete') {
      await new Promise<void>((resolve) => {
        window.addEventListener('load', () => resolve());
      });
    }

    // ADDED: First unregister any existing service workers to ensure users get the latest version
    console.log('Checking for existing service workers to unregister first...');
    const registrations = await navigator.serviceWorker.getRegistrations();
    for(let registration of registrations) {
      console.log('Unregistering existing service worker to force update');
      await registration.unregister();
    }
    console.log('Existing service workers cleared, registering new service worker');

    // Register the service worker
    const registration = await navigator.serviceWorker.register(SW_URL, {
      scope: '/',
    });

    // Setup message handling for sync status updates
    if (config && config.onMessage) {
      navigator.serviceWorker.addEventListener('message', config.onMessage);
    }
    
    // Default message handler for sync status updates
    navigator.serviceWorker.addEventListener('message', (event) => {
      if (event.data && event.data.type === 'SYNC_STATUS') {
        // Update sync status in the app
        updateSyncStatus(event.data.status);
      }
    });

    // Log the service worker registration status
    if (registration.active) {
      console.log('Service Worker is active!');
    } else if (registration.installing) {
      console.log('Service Worker is installing...');
    } else if (registration.waiting) {
      console.log('Service Worker is waiting...');
    }

    // Handle service worker updates
    registration.addEventListener('updatefound', () => {
      const newWorker = registration.installing;
      if (!newWorker) return;

      // Track the state of the installing service worker
      newWorker.addEventListener('statechange', () => {
        if (newWorker.state === 'installed') {
          if (navigator.serviceWorker.controller) {
            // There's a new service worker available - show refresh UI to user
            console.log('New content is available and will be used when all tabs for this page are closed.');
            showUpdateAvailableMessage();
            
            // Execute callback
            if (config && config.onUpdate) {
              config.onUpdate(registration);
            }
          } else {
            // At this point, everything has been precached
            console.log('Content is cached for offline use.');
            
            // Execute callback
            if (config && config.onSuccess) {
              config.onSuccess(registration);
            }
          }
        }
      });
    });
  } catch (error) {
    console.error('Service Worker registration failed:', error);
  }
};

/**
 * Legacy registration method for compatibility with existing code
 */
export function register(config?: Config) {
  if (process.env.NODE_ENV === 'production' && isServiceWorkerSupported) {
    // The URL constructor is available in all browsers that support SW.
    const publicUrl = new URL(import.meta.env.BASE_URL, window.location.href);
    if (publicUrl.origin !== window.location.origin) {
      // Our service worker won't work if PUBLIC_URL is on a different origin
      return;
    }

    window.addEventListener('load', () => {
      const swUrl = `${import.meta.env.BASE_URL}service-worker.js`;
      if (isLocalhost) {
        // Running on localhost
        checkValidServiceWorker(swUrl, config);
        
        // Log additional information for developers
        navigator.serviceWorker.ready.then(() => {
          console.log('This web app is being served cache-first by a service worker');
        });
      } else {
        // Not localhost - just register service worker
        registerValidSW(swUrl, config);
      }
    });
  }
}

/**
 * Legacy helper function for service worker registration
 */
function registerValidSW(swUrl: string, config?: Config) {
  navigator.serviceWorker.register(swUrl)
    .then(registration => {
      // Forward to our main registerServiceWorker implementation
      registerServiceWorker(config);
    })
    .catch(error => {
      console.error('Error during service worker registration:', error);
    });
}

/**
 * Legacy helper to check if a service worker exists
 */
function checkValidServiceWorker(swUrl: string, config?: Config) {
  fetch(swUrl, { headers: { 'Service-Worker': 'script' } })
    .then(response => {
      const contentType = response.headers.get('content-type');
      if (
        response.status === 404 ||
        (contentType != null && contentType.indexOf('javascript') === -1)
      ) {
        // No service worker found - reload the page
        navigator.serviceWorker.ready.then(registration => {
          registration.unregister().then(() => {
            window.location.reload();
          });
        });
      } else {
        // Service worker found
        registerValidSW(swUrl, config);
      }
    })
    .catch(() => {
      console.log('No internet connection. App is running in offline mode.');
    });
}

/**
 * Unregister the service worker
 */
export const unregisterServiceWorker = async (): Promise<void> => {
  if (!isServiceWorkerSupported) return;

  try {
    const registration = await navigator.serviceWorker.ready;
    const unregistered = await registration.unregister();
    
    if (unregistered) {
      console.log('Service Worker unregistered successfully');
    } else {
      console.warn('Service Worker could not be unregistered');
    }
  } catch (error) {
    console.error('Error unregistering Service Worker:', error);
  }
};

/**
 * Legacy unregister function for compatibility
 */
export function unregister() {
  if (isServiceWorkerSupported) {
    navigator.serviceWorker.ready
      .then(registration => {
        registration.unregister();
      })
      .catch(error => {
        console.error(error.message);
      });
  }
}

/**
 * Show a message to the user that an update is available
 */
const showUpdateAvailableMessage = (): void => {
  // Create the message container
  const messageContainer = document.createElement('div');
  messageContainer.className = 'sw-update-message';
  messageContainer.style.position = 'fixed';
  messageContainer.style.bottom = '0';
  messageContainer.style.left = '0';
  messageContainer.style.right = '0';
  messageContainer.style.backgroundColor = '#1E241E';
  messageContainer.style.color = '#F4F1E6';
  messageContainer.style.padding = '1rem';
  messageContainer.style.textAlign = 'center';
  messageContainer.style.zIndex = '9999';
  messageContainer.style.boxShadow = '0 -2px 8px rgba(0, 0, 0, 0.2)';
  messageContainer.style.display = 'flex';
  messageContainer.style.justifyContent = 'space-between';
  messageContainer.style.alignItems = 'center';

  // Create message text
  const message = document.createElement('span');
  message.textContent = 'A new version is available!';
  
  // Create refresh button
  const refreshButton = document.createElement('button');
  refreshButton.textContent = 'REFRESH';
  refreshButton.style.backgroundColor = '#BFA24D';
  refreshButton.style.color = '#1E241E';
  refreshButton.style.border = 'none';
  refreshButton.style.padding = '0.5rem 1rem';
  refreshButton.style.borderRadius = '4px';
  refreshButton.style.cursor = 'pointer';
  refreshButton.style.fontWeight = 'bold';
  refreshButton.style.textTransform = 'uppercase';
  refreshButton.style.fontSize = '14px';
  
  // Add click handler to reload the page
  refreshButton.addEventListener('click', () => {
    window.location.reload();
  });
  
  // Add elements to the document
  messageContainer.appendChild(message);
  messageContainer.appendChild(refreshButton);
  document.body.appendChild(messageContainer);
};

/**
 * Check if the user is online, used for online/offline indicators
 */
export const useOnlineStatus = (): boolean => {
  return navigator.onLine;
};

/**
 * Register background sync for workouts
 * This is used to sync workout data when the user goes back online
 */
export const registerBackgroundSync = async (tag: string = 'sync-workouts'): Promise<void> => {
  if (!isServiceWorkerSupported) return;
  
  try {
    const registration = await navigator.serviceWorker.ready;
    
    // Type assertion to avoid type errors
    const anyRegistration = registration as any;
    
    // Check if background sync is supported
    if ('sync' in anyRegistration) {
      await anyRegistration.sync.register(tag);
      console.log(`Background sync registered: ${tag}`);
    } else {
      console.log('Background Sync is not supported in this browser');
    }
  } catch (error) {
    console.error('Background Sync registration failed:', error);
  }
}; 