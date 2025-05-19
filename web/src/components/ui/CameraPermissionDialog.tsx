/**
 * CameraPermissionDialog.tsx
 * 
 * A dialog that displays when camera permission is denied.
 * Provides options to retry or open browser settings.
 */

import React, { useEffect, useState } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from './dialog';
import { Button } from './button';
import { usePoseContext } from '../../lib/contexts/PoseContext';
import { InitError, PoseDetectorError } from '../../services/PoseDetectorError';

const CameraPermissionDialog: React.FC = () => {
  const { error, resetError, retryInitialization } = usePoseContext();
  const [isOpen, setIsOpen] = useState(false);
  
  // Check if error is related to camera permissions
  const isCameraPermissionError = error instanceof PoseDetectorError && 
    error.type === InitError.CAMERA_PERMISSION;
  
  useEffect(() => {
    setIsOpen(isCameraPermissionError);
  }, [isCameraPermissionError]);
  
  // Handle retry
  const handleRetry = async () => {
    await retryInitialization();
    // PoseContext will update the error state
  };
  
  // Open browser settings based on browser
  const openSettings = () => {
    let settingsUrl: string | null = null;
    
    // Different instructions based on browser
    if (navigator.userAgent.includes('Chrome')) {
      settingsUrl = 'chrome://settings/content/camera';
    } else if (navigator.userAgent.includes('Firefox')) {
      settingsUrl = 'about:preferences#privacy';
    } else if (navigator.userAgent.includes('Safari') && !navigator.userAgent.includes('Chrome')) {
      // Safari doesn't allow direct settings URLs
      settingsUrl = null;
    }
    
    if (settingsUrl) {
      window.open(settingsUrl, '_blank');
    } else {
      // For Safari and other browsers, show instructions in dialog
      alert('Please open your browser settings and enable camera permissions for this site.');
    }
  };
  
  if (!isOpen) return null;
  
  return (
    <Dialog open={isOpen} onOpenChange={(open) => {
      setIsOpen(open);
      if (!open) resetError();
    }}>
      <DialogContent className="sm:max-w-[425px]">
        <DialogHeader>
          <DialogTitle>Camera Permission Required</DialogTitle>
          <DialogDescription>
            This exercise requires access to your camera to track your form and count reps.
            Please allow camera access to continue.
          </DialogDescription>
        </DialogHeader>
        
        <div className="my-4">
          <p className="text-sm text-gray-500">
            If you've denied permission, you'll need to reset it in your browser settings.
          </p>
        </div>
        
        <DialogFooter>
          <Button variant="outline" onClick={openSettings}>
            Open Settings
          </Button>
          <Button onClick={handleRetry}>
            Retry
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};

export default CameraPermissionDialog; 