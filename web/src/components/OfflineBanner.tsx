import React, { useEffect, useState } from 'react';
import { WifiOff } from 'lucide-react';
import { Alert } from './ui/alert';

export default function OfflineBanner() {
  const [isOffline, setIsOffline] = useState(!navigator.onLine);
  
  useEffect(() => {
    const handleOnline = () => setIsOffline(false);
    const handleOffline = () => setIsOffline(true);
    
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    
    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);
  
  if (!isOffline) return null;
  
  return (
    <Alert 
      variant="warning"
      className="fixed inset-x-0 top-16 z-50 mx-auto max-w-md border border-warning/20 shadow-medium"
    >
      <WifiOff className="size-4" />
      <span className="ml-2 text-small">You're currently offline. Changes will sync when connection is restored.</span>
    </Alert>
  );
} 