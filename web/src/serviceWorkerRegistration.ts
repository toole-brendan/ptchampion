/**
 * PT Champion Service Worker Registration
 * 
 * This file handles the registration and lifecycle of the service worker
 * which enables offline capabilities for the app.
 */

// Check if service workers are supported by the browser
const isServiceWorkerSupported = 'serviceWorker' in navigator;

// URL of the service worker script
const SW_URL = '/serviceWorker.js';

/**
 * Register the service worker for the application
 */
export const registerServiceWorker = async (): Promise<void> => {
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
        if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
          // There's a new service worker available - show refresh UI to user
          showUpdateAvailableMessage();
        }
      });
    });
  } catch (error) {
    console.error('Service Worker registration failed:', error);
  }
};

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
    
    // Check if background sync is supported
    if ('sync' in registration) {
      await registration.sync.register(tag);
      console.log(`Background sync registered: ${tag}`);
    } else {
      console.log('Background Sync is not supported in this browser');
    }
  } catch (error) {
    console.error('Background Sync registration failed:', error);
  }
}; 