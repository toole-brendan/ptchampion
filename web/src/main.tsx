// Import the token cleaner first - this will execute its code immediately
import './lib/tokenCleaner';

import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { unregisterServiceWorker } from './serviceWorkerRegistration'
import { QueryClient } from '@tanstack/react-query'
import config from './lib/config'

// For now, we'll unregister any existing service workers to avoid caching issues
// This will help ensure users get the latest version of the app
unregisterServiceWorker().catch(error => 
  console.error('Service worker unregistration failed:', error)
);

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

// We'll re-enable service worker registration once we have it properly set up
// if (import.meta.env.PROD) {
//   // Only register in production to avoid development issues
//   registerServiceWorker().catch(error => 
//     console.error('Service worker registration failed:', error)
//   );
// }

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App queryClient={queryClient} />
  </StrictMode>,
)
