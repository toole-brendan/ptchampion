import { useState } from 'react';
import { useBluetoothHRM } from '../../lib/hooks/useBluetoothHRM';
import { Button } from './button';
import { Card } from './card';
import { Progress } from './progress';

interface HeartRateMonitorProps {
  onHeartRateChange?: (heartRate: number | null) => void;
  className?: string;
}

export function HeartRateMonitor({ onHeartRateChange, className = '' }: HeartRateMonitorProps) {
  const [expanded, setExpanded] = useState(false);
  const [state, actions] = useBluetoothHRM();
  
  // Call the callback whenever heart rate changes
  if (onHeartRateChange && state.heartRate !== null) {
    onHeartRateChange(state.heartRate);
  }
  
  // If Web Bluetooth is not supported, show message
  if (!actions.isSupported) {
    return (
      <Card className={`p-4 ${className}`}>
        <div className="text-sm text-tactical-gray">
          <svg xmlns="http://www.w3.org/2000/svg" className="mr-1 inline size-5" viewBox="0 0 20 20" fill="currentColor">
            <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
          </svg>
          Heart rate monitoring requires Chrome or Edge on desktop/Android
        </div>
      </Card>
    );
  }
  
  // If not expanded, show minimized version
  if (!expanded) {
    return (
      <Button
        onClick={() => setExpanded(true)}
        className={`flex items-center text-sm ${className}`}
        variant="outline"
      >
        <svg 
          xmlns="http://www.w3.org/2000/svg" 
          viewBox="0 0 24 24" 
          fill="none" 
          stroke="currentColor" 
          strokeWidth="2" 
          strokeLinecap="round" 
          strokeLinejoin="round" 
          className="mr-2 size-5 text-brass-gold"
        >
          <path d="M20.42 4.58a5.4 5.4 0 0 0-7.65 0l-.77.78-.77-.78a5.4 5.4 0 0 0-7.65 0C1.46 6.7 1.33 10.28 4 13l8 8 8-8c2.67-2.72 2.54-6.3.42-8.42z"></path>
        </svg>
        {state.heartRate ? `${state.heartRate} BPM` : 'Connect HR Monitor'}
      </Button>
    );
  }
  
  // Render different content based on connection status
  let content;
  let zoneColor = 'bg-green-500';
  let zoneName = 'Resting';
  
  switch (state.status) {
    case 'idle':
      content = (
        <div className="p-4 text-center">
          <p className="mb-4 text-tactical-gray">Connect a heart rate monitor to track your workout intensity.</p>
          <Button onClick={() => actions.connect()}>
            Connect Device
          </Button>
        </div>
      );
      break;
      
    case 'scanning':
      content = (
        <div className="p-4 text-center">
          <div className="mb-4 animate-pulse text-brass-gold">
            <svg 
              xmlns="http://www.w3.org/2000/svg" 
              viewBox="0 0 24 24" 
              fill="none" 
              stroke="currentColor" 
              strokeWidth="2" 
              strokeLinecap="round" 
              strokeLinejoin="round" 
              className="mx-auto size-12"
            >
              <path d="M20.42 4.58a5.4 5.4 0 0 0-7.65 0l-.77.78-.77-.78a5.4 5.4 0 0 0-7.65 0C1.46 6.7 1.33 10.28 4 13l8 8 8-8c2.67-2.72 2.54-6.3.42-8.42z"></path>
            </svg>
          </div>
          <p className="mb-2 text-tactical-gray">Scanning for Bluetooth devices...</p>
          <p className="text-xs text-tactical-gray">Please select your heart rate monitor when prompted</p>
        </div>
      );
      break;
      
    case 'connected':
      // Calculate a color based on heart rate zones
      // 50-60% (very light): 94-113 bpm
      // 60-70% (light): 114-132 bpm
      // 70-80% (moderate): 133-151 bpm
      // 80-90% (hard): 152-170 bpm
      // 90-100% (maximum): 171-190 bpm
      // Based on average max HR of 190 for illustration
      if (state.heartRate) {
        if (state.heartRate < 94) {
          zoneColor = 'bg-blue-500';
          zoneName = 'Resting';
        } else if (state.heartRate < 114) {
          zoneColor = 'bg-green-500';
          zoneName = 'Very Light';
        } else if (state.heartRate < 133) {
          zoneColor = 'bg-yellow-500';
          zoneName = 'Light';
        } else if (state.heartRate < 152) {
          zoneColor = 'bg-orange-500';
          zoneName = 'Moderate';
        } else if (state.heartRate < 171) {
          zoneColor = 'bg-red-500';
          zoneName = 'Hard';
        } else {
          zoneColor = 'bg-purple-500';
          zoneName = 'Maximum';
        }
      }
      
      content = (
        <div className="p-4">
          <div className="flex flex-col items-center">
            <div className="mb-2 font-mono text-4xl text-brass-gold">
              {state.heartRate || '--'}
              <span className="ml-1 text-sm text-tactical-gray">BPM</span>
            </div>
            
            <div className="mb-4 text-sm text-tactical-gray">
              {state.deviceName}
              {state.sensorLocation && ` (${state.sensorLocation})`}
            </div>
            
            <div className="mb-2 w-full">
              <Progress value={state.heartRate || 0} max={190} className={zoneColor} />
            </div>
            
            <div className="mb-4 text-sm text-tactical-gray">
              Zone: <span className="font-semibold">{zoneName}</span>
            </div>
            
            <Button variant="outline" size="sm" onClick={() => actions.disconnect()}>
              Disconnect
            </Button>
          </div>
        </div>
      );
      break;
      
    case 'error':
      content = (
        <div className="p-4 text-center">
          <div className="mb-4 text-red-500">
            <svg xmlns="http://www.w3.org/2000/svg" className="mx-auto size-12" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <p className="mb-4 text-tactical-gray">
            {state.error?.message || 'Failed to connect to heart rate monitor'}
          </p>
          <div className="flex justify-center space-x-2">
            <Button onClick={() => actions.connect()}>Try Again</Button>
            <Button variant="outline" onClick={() => setExpanded(false)}>Close</Button>
          </div>
        </div>
      );
      break;
      
    default:
      content = (
        <div className="p-4 text-center">
          <p className="mb-4 text-tactical-gray">Heart rate monitor disconnected.</p>
          <div className="flex justify-center space-x-2">
            <Button onClick={() => actions.connect()}>Reconnect</Button>
            <Button variant="outline" onClick={() => setExpanded(false)}>Close</Button>
          </div>
        </div>
      );
  }
  
  return (
    <Card className={`overflow-hidden shadow-md ${className}`}>
      <div className="flex items-center justify-between bg-deep-ops px-4 py-2 text-cream">
        <h3 className="font-semibold text-sm uppercase">Heart Rate Monitor</h3>
        <button 
          onClick={() => setExpanded(false)}
          className="text-cream/70 hover:text-cream"
        >
          <svg xmlns="http://www.w3.org/2000/svg" className="size-5" viewBox="0 0 20 20" fill="currentColor">
            <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
          </svg>
        </button>
      </div>
      {content}
    </Card>
  );
} 