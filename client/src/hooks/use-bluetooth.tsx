import { useState, useCallback, useEffect } from 'react';

export type BluetoothDevice = {
  id: string;
  name: string;
  device: any; // Web Bluetooth API device object
  connected: boolean;
  heartRate?: number;
  gatt?: any;
};

export type BluetoothServiceData = {
  heartRate?: number;
  steps?: number;
  distance?: number;
  timeElapsed?: number;
};

// Web Bluetooth API service and characteristic UUIDs
const HEART_RATE_SERVICE = 'heart_rate';
const HEART_RATE_CHARACTERISTIC = 'heart_rate_measurement';
const RUNNING_SPEED_SERVICE = 'running_speed_and_cadence';
const RSC_MEASUREMENT_CHARACTERISTIC = 'rsc_measurement';

export function useBluetooth() {
  const [devices, setDevices] = useState<BluetoothDevice[]>([]);
  const [isScanning, setIsScanning] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [serviceData, setServiceData] = useState<BluetoothServiceData>({});
  
  // Check if Web Bluetooth is supported
  const isSupported = typeof navigator !== 'undefined' && 
                     'bluetooth' in navigator;

  // Scan for devices
  const scanForDevices = useCallback(async () => {
    if (!isSupported) {
      setError(new Error('Web Bluetooth is not supported in your browser'));
      return;
    }
    
    try {
      setIsScanning(true);
      setError(null);
      
      // Request device with heart rate service
      const device = await navigator.bluetooth.requestDevice({
        filters: [
          { services: ['heart_rate'] },
          { services: ['running_speed_and_cadence'] },
          { namePrefix: 'Apple Watch' },
          { namePrefix: 'Garmin' },
          { namePrefix: 'Fitbit' }
        ],
        optionalServices: ['heart_rate', 'running_speed_and_cadence']
      });
      
      if (!device.id) {
        throw new Error('No device selected');
      }
      
      // Add device to state if it's not already there
      setDevices(prevDevices => {
        if (prevDevices.some(d => d.id === device.id)) {
          return prevDevices;
        }
        
        return [...prevDevices, {
          id: device.id,
          name: device.name || 'Unknown Device',
          device,
          connected: false
        }];
      });

      // Setup disconnection listener
      device.addEventListener('gattserverdisconnected', () => {
        setDevices(prevDevices => 
          prevDevices.map(d => d.id === device.id ? {...d, connected: false} : d)
        );
      });
      
    } catch (err: any) {
      setError(err);
    } finally {
      setIsScanning(false);
    }
  }, [isSupported]);
  
  // Connect to device
  const connectToDevice = useCallback(async (deviceId: string) => {
    const device = devices.find(d => d.id === deviceId);
    if (!device) {
      setError(new Error('Device not found'));
      return false;
    }
    
    try {
      setError(null);
      
      // Connect to GATT server
      const server = await device.device.gatt.connect();
      
      // Save GATT server reference
      setDevices(prevDevices => 
        prevDevices.map(d => d.id === deviceId ? {...d, gatt: server, connected: true} : d)
      );
      
      // Try to connect to heart rate service
      try {
        const heartRateService = await server.getPrimaryService('heart_rate');
        const heartRateChar = await heartRateService.getCharacteristic('heart_rate_measurement');
        
        // Start notifications for heart rate
        await heartRateChar.startNotifications();
        
        heartRateChar.addEventListener('characteristicvaluechanged', (event: any) => {
          const value = event.target.value;
          const heartRate = parseHeartRate(value);
          
          setServiceData(prev => ({ ...prev, heartRate }));
          
          // Update heart rate in device state
          setDevices(prevDevices => 
            prevDevices.map(d => d.id === deviceId ? {...d, heartRate} : d)
          );
        });
      } catch (err) {
        console.log('Heart rate service not available on this device');
      }
      
      // Try to connect to running speed service
      try {
        const rscService = await server.getPrimaryService('running_speed_and_cadence');
        const rscChar = await rscService.getCharacteristic('rsc_measurement');
        
        // Start notifications for running speed
        await rscChar.startNotifications();
        
        rscChar.addEventListener('characteristicvaluechanged', (event: any) => {
          const value = event.target.value;
          const { speed, distance } = parseRunningData(value);
          
          setServiceData(prev => ({ 
            ...prev, 
            speed,
            distance 
          }));
        });
      } catch (err) {
        console.log('Running speed service not available on this device');
      }
      
      return true;
    } catch (err: any) {
      setError(err);
      return false;
    }
  }, [devices]);
  
  // Disconnect from device
  const disconnectDevice = useCallback(async (deviceId: string) => {
    const device = devices.find(d => d.id === deviceId);
    if (!device || !device.connected) {
      return;
    }
    
    try {
      // Disconnect from GATT server
      if (device.gatt) {
        device.device.gatt.disconnect();
      }
      
      // Update device state
      setDevices(prevDevices => 
        prevDevices.map(d => d.id === deviceId ? {...d, connected: false} : d)
      );
    } catch (err: any) {
      setError(err);
    }
  }, [devices]);
  
  // Clean up function for disconnecting all devices
  useEffect(() => {
    return () => {
      devices.forEach(device => {
        if (device.connected && device.device.gatt) {
          device.device.gatt.disconnect();
        }
      });
    };
  }, [devices]);
  
  // Parse heart rate data
  function parseHeartRate(value: DataView): number {
    const flags = value.getUint8(0);
    const rate16Bits = flags & 0x1;
    let heartRate: number;
    
    if (rate16Bits) {
      heartRate = value.getUint16(1, true);
    } else {
      heartRate = value.getUint8(1);
    }
    
    return heartRate;
  }
  
  // Parse running speed data
  function parseRunningData(value: DataView): { speed: number, distance?: number } {
    const flags = value.getUint8(0);
    const instantaneousSpeedPresent = flags & 0x1;
    const instantaneousCadencePresent = flags & 0x2;
    const strideAndDistancePresent = flags & 0x4;
    
    let offset = 1;
    let speed = 0;
    let distance = undefined;
    
    if (instantaneousSpeedPresent) {
      // Speed is in units of 1/256 m/s
      speed = value.getUint16(offset, true) / 256;
      offset += 2;
    }
    
    if (instantaneousCadencePresent) {
      // Skip cadence
      offset += 1;
    }
    
    if (strideAndDistancePresent) {
      // Distance is in meters
      distance = value.getUint32(offset, true);
    }
    
    return { speed, distance };
  }
  
  // Start run session
  const [runStartTime, setRunStartTime] = useState<Date | null>(null);
  const [totalDistance, setTotalDistance] = useState<number>(0);
  const [totalTimeElapsed, setTotalTimeElapsed] = useState<number>(0);
  const [isRunning, setIsRunning] = useState(false);
  
  // Start run tracking
  const startRun = useCallback(() => {
    setRunStartTime(new Date());
    setTotalDistance(0);
    setTotalTimeElapsed(0);
    setIsRunning(true);
    
    // Start a timer to update elapsed time
    const intervalId = setInterval(() => {
      if (runStartTime) {
        const elapsedMs = new Date().getTime() - runStartTime.getTime();
        setTotalTimeElapsed(Math.floor(elapsedMs / 1000));
        
        // Update service data
        setServiceData(prev => ({
          ...prev,
          timeElapsed: Math.floor(elapsedMs / 1000)
        }));
      }
    }, 1000);
    
    // Clean up interval on unmount
    return () => clearInterval(intervalId);
  }, [runStartTime]);
  
  // Complete run
  const completeRun = useCallback(() => {
    setIsRunning(false);
    // Calculate final distance in miles (convert from meters)
    const distanceInMiles = totalDistance / 1609.34;
    // Return time in seconds and distance in miles
    return {
      timeInSeconds: totalTimeElapsed,
      distanceInMiles
    };
  }, [totalDistance, totalTimeElapsed]);
  
  return {
    devices,
    isScanning,
    error,
    isSupported,
    serviceData,
    isRunning,
    totalTimeElapsed,
    scanForDevices,
    connectToDevice,
    disconnectDevice,
    startRun,
    completeRun
  };
}