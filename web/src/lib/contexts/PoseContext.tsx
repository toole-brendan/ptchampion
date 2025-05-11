/**
 * PoseContext.tsx
 * 
 * Provides global state for pose detection service,
 * allowing components to access service status, errors,
 * and handle camera permissions in a centralized way.
 */

import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import poseDetectorService from '@/services/PoseDetectorService';
import { PoseDetectorError } from '@/services/PoseDetectorError';
import type { PoseDetectorOptions } from '@/services/PoseDetectorService';

interface PoseContextType {
  // Service status
  isInitialized: boolean;
  isInitializing: boolean;
  isRunning: boolean;
  
  // Errors
  error: PoseDetectorError | Error | null;
  resetError: () => void;
  
  // Camera
  needsUserGesture: boolean;
  resumeCamera: () => Promise<boolean>;
  retryInitialization: (options?: PoseDetectorOptions) => Promise<void>;
}

const PoseContext = createContext<PoseContextType | undefined>(undefined);

export interface PoseProviderProps {
  children: ReactNode;
}

export const PoseProvider: React.FC<PoseProviderProps> = ({ children }) => {
  // State for tracking service status
  const [isInitialized, setIsInitialized] = useState<boolean>(poseDetectorService.isInitialized());
  const [isInitializing, setIsInitializing] = useState<boolean>(false);
  const [isRunning, setIsRunning] = useState<boolean>(poseDetectorService.isRunning());
  const [error, setError] = useState<Error | null>(null);
  const [needsUserGesture, setNeedsUserGesture] = useState<boolean>(poseDetectorService.requiresUserGesture());
  
  // Reset error helper
  const resetError = () => setError(null);
  
  // Function to retry initialization
  const retryInitialization = async (options?: PoseDetectorOptions) => {
    setIsInitializing(true);
    setError(null);
    
    try {
      await poseDetectorService.initialize(options);
      setIsInitialized(true);
    } catch (err) {
      console.error('PoseContext: Error initializing pose detector', err);
      if (err instanceof Error) {
        setError(err);
      } else {
        setError(new Error(String(err)));
      }
    } finally {
      setIsInitializing(false);
    }
  };
  
  // Resume camera (for iOS)
  const resumeCamera = async () => {
    const success = await poseDetectorService.resumeCamera();
    setNeedsUserGesture(!success);
    return success;
  };
  
  // Subscribe to service state changes
  useEffect(() => {
    // Update context when service state changes
    const statusInterval = setInterval(() => {
      setIsInitialized(poseDetectorService.isInitialized());
      setIsRunning(poseDetectorService.isRunning());
      setNeedsUserGesture(poseDetectorService.requiresUserGesture());
    }, 500);
    
    return () => {
      clearInterval(statusInterval);
    };
  }, []);
  
  // Provide the context
  const contextValue: PoseContextType = {
    isInitialized,
    isInitializing,
    isRunning,
    error,
    resetError,
    needsUserGesture,
    resumeCamera,
    retryInitialization
  };
  
  return (
    <PoseContext.Provider value={contextValue}>
      {children}
    </PoseContext.Provider>
  );
};

// Custom hook to use the pose context
export const usePoseContext = (): PoseContextType => {
  const context = useContext(PoseContext);
  
  if (context === undefined) {
    throw new Error('usePoseContext must be used within a PoseProvider');
  }
  
  return context;
};

export default PoseContext; 