import React from 'react';
import { RotateCw, Check, AlertCircle } from 'lucide-react';
import { Badge } from './ui/badge';
import { useSyncStatus, type SyncStatus } from '@/lib/syncManager';

export default function SyncIndicator() {
  const syncStatus = useSyncStatus();
  
  if (syncStatus === 'idle') return null;
  
  const variants: Record<SyncStatus, { variant: "default" | "info" | "success" | "destructive", icon: React.ReactNode, text: string }> = {
    idle: { variant: 'default', icon: null, text: '' },
    syncing: { variant: 'info', icon: <RotateCw className="size-3 animate-spin" />, text: 'Syncing...' },
    success: { variant: 'success', icon: <Check className="size-3" />, text: 'Synced' },
    error: { variant: 'destructive', icon: <AlertCircle className="size-3" />, text: 'Sync failed' }
  };
  
  const { variant, icon, text } = variants[syncStatus];
  
  return (
    <Badge variant={variant} size="sm" className="ml-2">
      {icon && <span className="mr-1">{icon}</span>}
      <span>{text}</span>
    </Badge>
  );
} 