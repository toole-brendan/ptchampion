import React, { useEffect, useState } from 'react';
import { Cloud, CloudOff, RefreshCw, Check, AlertCircle } from 'lucide-react';
import { offlineQueue, SyncStatus } from '../services/OfflineQueue';
import { workoutSyncService } from '../services/WorkoutSyncService';
import { Button } from './ui/button';
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from './ui/tooltip';

export const SyncStatusIndicator: React.FC = () => {
  const [syncStatus, setSyncStatus] = useState<SyncStatus>({
    isPending: false,
    pendingCount: 0,
  });
  const [isOnline, setIsOnline] = useState(navigator.onLine);
  const [isSyncing, setIsSyncing] = useState(false);
  const [lastSyncResult, setLastSyncResult] = useState<string | null>(null);

  useEffect(() => {
    // Subscribe to sync status changes
    const unsubscribe = offlineQueue.subscribeToStatusChanges(setSyncStatus);

    // Listen for online/offline events
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);
    
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    // Check sync status periodically
    const interval = setInterval(async () => {
      const status = await workoutSyncService.getQueueStatus();
      setIsSyncing(status.isSyncing);
    }, 1000);

    return () => {
      unsubscribe();
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
      clearInterval(interval);
    };
  }, []);

  const handleForceSync = async () => {
    if (!isOnline) return;
    
    setIsSyncing(true);
    setLastSyncResult(null);
    
    try {
      const result = await workoutSyncService.forceSyncNow();
      if (result.successful.length > 0) {
        setLastSyncResult(`Synced ${result.successful.length} workout(s)`);
      } else if (result.failed.length > 0) {
        setLastSyncResult(`Failed to sync ${result.failed.length} workout(s)`);
      } else {
        setLastSyncResult('No workouts to sync');
      }
    } catch (error) {
      setLastSyncResult('Sync failed');
    }
    
    // Clear result after 3 seconds
    setTimeout(() => setLastSyncResult(null), 3000);
  };

  const getStatusIcon = () => {
    if (!isOnline) {
      return <CloudOff className="h-5 w-5 text-muted-foreground" />;
    }
    
    if (isSyncing) {
      return <RefreshCw className="h-5 w-5 text-primary animate-spin" />;
    }
    
    if (syncStatus.lastError) {
      return <AlertCircle className="h-5 w-5 text-destructive" />;
    }
    
    if (syncStatus.pendingCount > 0) {
      return <Cloud className="h-5 w-5 text-warning" />;
    }
    
    return <Check className="h-5 w-5 text-success" />;
  };

  const getStatusText = () => {
    if (!isOnline) {
      return 'Offline';
    }
    
    if (isSyncing) {
      return 'Syncing...';
    }
    
    if (lastSyncResult) {
      return lastSyncResult;
    }
    
    if (syncStatus.pendingCount > 0) {
      return `${syncStatus.pendingCount} pending`;
    }
    
    if (syncStatus.lastSyncTime) {
      const timeDiff = Date.now() - syncStatus.lastSyncTime;
      if (timeDiff < 60000) {
        return 'Synced just now';
      } else if (timeDiff < 3600000) {
        const minutes = Math.floor(timeDiff / 60000);
        return `Synced ${minutes}m ago`;
      } else {
        const hours = Math.floor(timeDiff / 3600000);
        return `Synced ${hours}h ago`;
      }
    }
    
    return 'All synced';
  };

  const getTooltipContent = () => {
    if (!isOnline) {
      return 'You are offline. Workouts will be saved locally and synced when you reconnect.';
    }
    
    if (syncStatus.lastError) {
      return `Last sync error: ${syncStatus.lastError}`;
    }
    
    if (syncStatus.pendingCount > 0) {
      return `${syncStatus.pendingCount} workout(s) waiting to sync. Click to sync now.`;
    }
    
    return 'All workouts are synced to the server.';
  };

  const showBadge = !isOnline || syncStatus.pendingCount > 0 || syncStatus.lastError;

  return (
    <TooltipProvider>
      <Tooltip>
        <TooltipTrigger asChild>
          <Button
            variant="ghost"
            size="sm"
            className="gap-2 px-3"
            onClick={handleForceSync}
            disabled={!isOnline || isSyncing || syncStatus.pendingCount === 0}
          >
            {getStatusIcon()}
            <span className="text-sm hidden sm:inline">{getStatusText()}</span>
            {showBadge && syncStatus.pendingCount > 0 && (
              <span className="inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-white bg-warning rounded-full">
                {syncStatus.pendingCount}
              </span>
            )}
          </Button>
        </TooltipTrigger>
        <TooltipContent>
          <p>{getTooltipContent()}</p>
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
};