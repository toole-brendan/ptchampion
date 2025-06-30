import './index.css';
import './styles/design-tokens.css';
import './styles/ios-tokens.css';
import './styles/fonts.css';
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import { QueryClient } from '@tanstack/react-query';
import config from './lib/config';
import { syncManager } from './lib/syncManager';
// Register the service worker
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js')
      .then(registration => {
        console.log('Service Worker registered:', registration);
        
        // Check for updates every 60 seconds
        setInterval(() => {
          registration.update();
        }, 60 * 1000);
      })
      .catch(error => {
        console.error('Service Worker registration failed:', error);
      });
  });
}

// VERSION CHECK - THIS SHOULD CHANGE WITH EACH DEPLOY
console.log('🚨🚨🚨 PT CHAMPION VERSION: 2024-06-30-v7-DASHBOARD-FIX 🚨🚨🚨');
console.log('If you see an old version, the cache is STILL serving old files!');
console.log('Dashboard fixes: Exercise icons, date format DDMMMYYYY, run times, last activity');

// Clear stale tokens at startup
const clearStaleTokens = () => {
  console.log('Checking for stale tokens...');
  const TOKEN_STORAGE_KEY = config.auth.storageKeys.token;
  
  try {
    const hasToken = localStorage.getItem(TOKEN_STORAGE_KEY) !== null;
    // If we have a token in local storage, check if it's from a previous session
    if (hasToken) {
      const sessionKey = 'pt_champion_session';
      const lastSession = sessionStorage.getItem(sessionKey);
      const currentTime = Date.now();
      
      // If no session exists or it's older than 24 hours, clear the token
      if (!lastSession || (currentTime - parseInt(lastSession)) > 24 * 60 * 60 * 1000) {
        console.log('Clearing stale token from previous session');
        localStorage.removeItem(TOKEN_STORAGE_KEY);
      }
      
      // Update session timestamp
      sessionStorage.setItem(sessionKey, currentTime.toString());
    }
  } catch (error) {
    console.error('Error checking for stale tokens:', error);
  }
};

// Run token cleanup
clearStaleTokens();

/**
 * Bootstrap sync process for browsers without SyncManager support
 * This will flush any pending workouts when the app starts and we're online
 */
const appSyncBootstrap = async () => {
  // Check if browser has SyncManager support
  const hasSyncManager = 'serviceWorker' in navigator && 'SyncManager' in window;
  
  // If no sync manager but we're online, try to flush pending workouts
  if (!hasSyncManager && navigator.onLine) {
    console.log('No SyncManager support detected. Attempting to flush pending workouts.');
    try {
      // Wait a moment for auth to complete
      setTimeout(async () => {
        const syncedCount = await syncManager.flushPendingWorkouts(true);
        if (syncedCount > 0) {
          console.log(`Bootstrap sync completed: ${syncedCount} workouts synced.`);
        }
      }, 5000); // 5 second delay to allow auth to complete
    } catch (error) {
      console.error('Failed to flush pending workouts during bootstrap:', error);
    }
  }
  
  // Set up online listener for browsers without SyncManager
  if (!hasSyncManager) {
    window.addEventListener('online', async () => {
      console.log('Device came online. Attempting to sync pending workouts.');
      try {
        await syncManager.flushPendingWorkouts();
      } catch (error) {
        console.error('Failed to flush pending workouts on online event:', error);
      }
    });
  }
};

// Run sync bootstrap
appSyncBootstrap();

// Configure React Query default options
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1, // Limit retries to reduce long wait times on failures
      retryDelay: attemptIndex => Math.min(1000 * 2 ** attemptIndex, 30000), // Exponential backoff
      staleTime: 1000 * 60 * 5, // 5 minute stale time
      gcTime: 1000 * 60 * 10, // 10 minute gc time
      refetchOnWindowFocus: false, // Don't refetch on focus
    },
  },
})

// Ensure body has background color
document.body.classList.add('bg-cream', 'text-command-black');

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App queryClient={queryClient} />
  </StrictMode>,
)
