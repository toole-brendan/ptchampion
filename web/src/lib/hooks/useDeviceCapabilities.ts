import { useState, useEffect } from 'react';

interface DeviceCapabilities {
  camera: boolean;
  bluetooth: boolean;
  geolocation: boolean;
  offlineStorage: boolean;
  mediaRecording: boolean;
  deviceMotion: boolean;
  pushNotifications: boolean;
  shareApi: boolean;
}

export function useDeviceCapabilities() {
  const [capabilities, setCapabilities] = useState<DeviceCapabilities>({
    camera: false,
    bluetooth: false,
    geolocation: false,
    offlineStorage: false,
    mediaRecording: false,
    deviceMotion: false,
    pushNotifications: false,
    shareApi: false
  });

  useEffect(() => {
    // Detect available APIs
    const detect = {
      camera: !!navigator.mediaDevices?.getUserMedia,
      bluetooth: 'bluetooth' in navigator,
      geolocation: 'geolocation' in navigator,
      offlineStorage: 'indexedDB' in window,
      mediaRecording: 'MediaRecorder' in window,
      deviceMotion: 'DeviceMotionEvent' in window,
      pushNotifications: 'Notification' in window && 'serviceWorker' in navigator,
      shareApi: 'share' in navigator
    };

    setCapabilities(detect);
  }, []);

  return capabilities;
}

// Helper function to detect if a feature should be enabled based on capabilities
export function canUseFeature(
  feature: keyof DeviceCapabilities | 'mobile' | 'poseDetection', 
  capabilities?: DeviceCapabilities
): boolean {
  if (!capabilities) return false;
  
  // Special composite features
  if (feature === 'mobile') {
    // Check if we're on a mobile device based on common indicators
    return /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);
  }
  
  if (feature === 'poseDetection') {
    // For pose detection we need camera and sufficient processing power
    return capabilities.camera;
  }
  
  // Direct capability mapping
  return capabilities[feature];
} 