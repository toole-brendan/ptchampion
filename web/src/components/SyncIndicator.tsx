import React from 'react';
import { CloudSync, Check, AlertCircle } from 'lucide-react';
import { Badge } from './ui/badge';
import { useSyncStatus, type SyncStatus } from '@/lib/syncManager';

export default function SyncIndicator() {
  const syncStatus = useSyncStatus();
  
  if (syncStatus === 'idle') return null;
  
  const variants: Record<SyncStatus, { variant: any, icon: React.ReactNode, text: string }> = {
    idle: { variant: 'default', icon: null, text: '' },
    syncing: { variant: 'info', icon: <CloudSync className="animate-spin h-3 w-3" />, text: 'Syncing...' },
    success: { variant: 'success', icon: <Check className="h-3 w-3" />, text: 'Synced' },
    error: { variant: 'destructive', icon: <AlertCircle className="h-3 w-3" />, text: 'Sync failed' }
  };
  
  const { variant, icon, text } = variants[syncStatus];
  
  return (
    <Badge variant={variant} size="sm" className="ml-2">
      {icon && <span className="mr-1">{icon}</span>}
      <span>{text}</span>
    </Badge>
  );
} 