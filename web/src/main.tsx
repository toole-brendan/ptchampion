import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { registerServiceWorker } from './serviceWorkerRegistration'

// Register the service worker for offline capabilities
if (import.meta.env.PROD) {
  // Only register in production to avoid development issues
  registerServiceWorker().catch(error => 
    console.error('Service worker registration failed:', error)
  );
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
