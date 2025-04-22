import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { unregisterServiceWorker } from './serviceWorkerRegistration'

// For now, we'll unregister any existing service workers to avoid caching issues
// This will help ensure users get the latest version of the app
unregisterServiceWorker().catch(error => 
  console.error('Service worker unregistration failed:', error)
);

// We'll re-enable service worker registration once we have it properly set up
// if (import.meta.env.PROD) {
//   // Only register in production to avoid development issues
//   registerServiceWorker().catch(error => 
//     console.error('Service worker registration failed:', error)
//   );
// }

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
