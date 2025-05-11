/**
 * SyncManager - Handles synchronization between online and offline states
 * This bridges the gap between IndexedDB, ServiceWorker and the UI
 */
import { useEffect, useState } from 'react';

export type SyncStatus = 'idle' | 'syncing' | 'success' | 'error';

// Broadcast channel for communicating sync status across tabs
const syncChannel = typeof BroadcastChannel !== 'undefined' 
  ? new BroadcastChannel('pt-champion-sync-channel') 
  : null;

/**
 * Update the sync status both in localStorage and via broadcast channel
 */
export function updateSyncStatus(status: SyncStatus): void {
  // Store in localStorage for persistence
  localStorage.setItem('pt-champion-sync-status', status);
  
  // Notify any service worker
  if (navigator.serviceWorker && navigator.serviceWorker.controller) {
    navigator.serviceWorker.controller.postMessage({
      type: 'SYNC_STATUS_UPDATE',
      status
    });
  }
  
  // Broadcast to other tabs
  if (syncChannel) {
    syncChannel.postMessage({ type: 'SYNC_STATUS', status });
  }
  
  // Dispatch storage event for same-tab listeners
  window.dispatchEvent(new StorageEvent('storage', {
    key: 'pt-champion-sync-status',
    newValue: status
  }));
}

/**
 * Hook to track sync status across the app
 */
export function useSyncStatus() {
  const [status, setStatus] = useState<SyncStatus>(() => {
    return (localStorage.getItem('pt-champion-sync-status') as SyncStatus) || 'idle';
  });
  
  useEffect(() => {
    // Listen for storage events (from other components using updateSyncStatus)
    const handleStorageChange = (event: StorageEvent) => {
      if (event.key === 'pt-champion-sync-status') {
        setStatus(event.newValue as SyncStatus || 'idle');
      }
    };
    
    // Listen for service worker messages
    const handleServiceWorkerMessage = (event: MessageEvent) => {
      if (event.data && event.data.type === 'SYNC_STATUS') {
        setStatus(event.data.status);
      }
    };
    
    // Listen for broadcast channel messages
    const handleBroadcastMessage = (event: MessageEvent) => {
      if (event.data && event.data.type === 'SYNC_STATUS') {
        setStatus(event.data.status);
      }
    };
    
    window.addEventListener('storage', handleStorageChange);
    
    if (navigator.serviceWorker) {
      navigator.serviceWorker.addEventListener('message', handleServiceWorkerMessage);
    }
    
    if (syncChannel) {
      syncChannel.addEventListener('message', handleBroadcastMessage);
    }
    
    return () => {
      window.removeEventListener('storage', handleStorageChange);
      
      if (navigator.serviceWorker) {
        navigator.serviceWorker.removeEventListener('message', handleServiceWorkerMessage);
      }
      
      if (syncChannel) {
        syncChannel.removeEventListener('message', handleBroadcastMessage);
      }
    };
  }, []);
  
  return status;
}

/**
 * Trigger a manual sync operation
 */
export async function triggerSync(): Promise<void> {
  updateSyncStatus('syncing');
  
  try {
    // Request a sync via the service worker if available
    if ('serviceWorker' in navigator && 'SyncManager' in window) {
      const registration = await navigator.serviceWorker.ready;
      await registration.sync.register('pt-champion-sync');
      // Actual status update will come from the service worker
    } else {
      // Fallback: trigger API sync directly
      // This would call your sync function that pushes offline data to server
      // For example: await syncOfflineData();
      
      // For now, we'll simulate a delay
      await new Promise(resolve => setTimeout(resolve, 1500));
      updateSyncStatus('success');
    }
  } catch (error) {
    console.error('Sync failed:', error);
    updateSyncStatus('error');
  }
} 