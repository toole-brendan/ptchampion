import { useState, useCallback, useEffect } from 'react';

// Type declarations for Web Bluetooth API
interface BluetoothRemoteGATTCharacteristic {
  service: any;
  uuid: string;
  properties: any;
  value?: DataView;
  startNotifications(): Promise<BluetoothRemoteGATTCharacteristic>;
  stopNotifications(): Promise<BluetoothRemoteGATTCharacteristic>;
  readValue(): Promise<DataView>;
  writeValue(value: BufferSource): Promise<void>;
  addEventListener(type: string, listener: EventListener): void;
  removeEventListener(type: string, listener: EventListener): void;
}

interface BluetoothRemoteGATTServer {
  device: any;
  connected: boolean;
  connect(): Promise<BluetoothRemoteGATTServer>;
  disconnect(): void;
  getPrimaryService(service: string): Promise<any>;
}

interface BluetoothDevice {
  id: string;
  name?: string;
  gatt?: BluetoothRemoteGATTServer;
  addEventListener(type: string, listener: EventListener): void;
  removeEventListener(type: string, listener: EventListener): void;
  dispatchEvent(event: Event): boolean;
}

export type CustomBluetoothDevice = {
  id: string;
  name: string;
  device: BluetoothDevice;
  connected: boolean;
  heartRate?: number;
  gatt?: BluetoothRemoteGATTServer;
};

export type BluetoothServiceData = {
  heartRate?: number;
  steps?: number;
  distance?: number;
  timeElapsed?: number;
  speed?: number;
};

// Web Bluetooth API service and characteristic UUIDs
const HEART_RATE_SERVICE = 'heart_rate';
const HEART_RATE_CHARACTERISTIC = 'heart_rate_measurement';
const RUNNING_SPEED_SERVICE = 'running_speed_and_cadence';
const RSC_MEASUREMENT_CHARACTERISTIC = 'rsc_measurement';

// For testing in environments without real Bluetooth devices
const USE_SIMULATED_DEVICES = true;
const SIMULATED_DEVICES = [
  { id: 'simulated-apple-watch', name: 'Apple Watch Series 8', connected: false },
  { id: 'simulated-garmin', name: 'Garmin Forerunner 955', connected: false },
  { id: 'simulated-fitbit', name: 'Fitbit Versa 4', connected: false }
];

export function useBluetooth() {
  const [devices, setDevices] = useState<CustomBluetoothDevice[]>([]);
  const [isScanning, setIsScanning] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  const [serviceData, setServiceData] = useState<BluetoothServiceData>({});
  
  // Check if Web Bluetooth is supported
  const isSupported = typeof navigator !== 'undefined' && 
                     ('bluetooth' in navigator || USE_SIMULATED_DEVICES);

  // Scan for devices
  const scanForDevices = useCallback(async () => {
    if (!isSupported) {
      setError(new Error('Web Bluetooth is not supported in your browser'));
      return;
    }
    
    try {
      setIsScanning(true);
      setError(null);
      
      if (USE_SIMULATED_DEVICES) {
        // For testing when actual Bluetooth devices aren't available
        // Simulate finding devices after a brief delay
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        setDevices(SIMULATED_DEVICES.map(device => ({
          ...device,
          // Create a mock device object that mimics enough of the BluetoothDevice interface
          device: {
            id: device.id,
            name: device.name,
            addEventListener: () => {},
            removeEventListener: () => {},
            dispatchEvent: () => true,
            // Other methods can be added as needed for testing
          } as unknown as BluetoothDevice,
        })));
      } else {
        // Real Bluetooth device scanning
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
      }
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
      
      if (USE_SIMULATED_DEVICES) {
        // Simulate connection process for testing
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        // Create simulated GATT service
        const simulatedGatt = {
          connected: true,
          device: device.device,
          connect: () => Promise.resolve(simulatedGatt),
          disconnect: () => {},
          getPrimaryService: () => Promise.resolve({
            getCharacteristic: () => Promise.resolve({
              startNotifications: () => Promise.resolve({}),
              addEventListener: (event: string, listener: EventListener) => {
                // Begin simulating heart rate data after connection
                if (event === 'characteristicvaluechanged') {
                  simulateHeartRateData(deviceId, listener);
                }
              }
            })
          })
        } as unknown as BluetoothRemoteGATTServer;
        
        // Update device state with simulated GATT
        setDevices(prevDevices => 
          prevDevices.map(d => d.id === deviceId ? {
            ...d, 
            gatt: simulatedGatt, 
            connected: true
          } : d)
        );
      } else {
        // Real Bluetooth connection logic
        // Connect to GATT server
        if (!device.device.gatt) {
          throw new Error('GATT server not available');
        }
        
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
          
          heartRateChar.addEventListener('characteristicvaluechanged', (event: Event) => {
            // Safe type casting with explicit checks
            if (event.target && 'value' in (event.target as any)) {
              const value = (event.target as any).value as DataView;
              if (value) {
                const heartRate = parseHeartRate(value);
                
                setServiceData(prev => ({ ...prev, heartRate }));
                
                // Update heart rate in device state
                setDevices(prevDevices => 
                  prevDevices.map(d => d.id === deviceId ? {...d, heartRate} : d)
                );
              }
            }
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
          
          rscChar.addEventListener('characteristicvaluechanged', (event: Event) => {
            // Safe type casting with explicit checks
            if (event.target && 'value' in (event.target as any)) {
              const value = (event.target as any).value as DataView;
              if (value) {
                const { speed, distance } = parseRunningData(value);
                
                setServiceData(prev => ({ 
                  ...prev, 
                  speed,
                  distance 
                }));
              }
            }
          });
        } catch (err) {
          console.log('Running speed service not available on this device');
        }
      }
      
      return true;
    } catch (err: any) {
      setError(err);
      return false;
    }
  }, [devices]);
  
  // Function to simulate heart rate data for testing
  const simulateHeartRateData = (deviceId: string, listener: EventListener) => {
    let heartRate = 75; // starting heart rate
    const direction = 1; // increasing
    
    const intervalId = setInterval(() => {
      // Simulate a realistic heart rate during exercise (between 75-180)
      heartRate += direction * (Math.random() * 2);
      if (heartRate > 180) heartRate = 180;
      if (heartRate < 75) heartRate = 75;
      
      // Round to integer
      const roundedHeartRate = Math.round(heartRate);
      
      // Create a simulated DataView to mimic Bluetooth data
      const buffer = new ArrayBuffer(2);
      const dataView = new DataView(buffer);
      dataView.setUint8(0, 0); // flags
      dataView.setUint8(1, roundedHeartRate); // heart rate value
      
      // Create a simulated event
      const event = {
        target: {
          value: dataView
        }
      } as unknown as Event;
      
      // Pass the event to the listener
      listener(event);
      
      // Update service data with simulated values
      setServiceData(prev => ({ 
        ...prev, 
        heartRate: roundedHeartRate,
        // Also simulate distance for run tracking
        distance: (prev.distance || 0) + 2
      }));
      
      // Update heart rate in device state
      setDevices(prevDevices => 
        prevDevices.map(d => d.id === deviceId ? {...d, heartRate: roundedHeartRate} : d)
      );
    }, 2000);
    
    // Store the interval ID for cleanup
    return () => clearInterval(intervalId);
  };
  
  // Disconnect from device
  const disconnectDevice = useCallback(async (deviceId: string) => {
    const device = devices.find(d => d.id === deviceId);
    if (!device || !device.connected) {
      return;
    }
    
    try {
      if (!USE_SIMULATED_DEVICES) {
        // Disconnect from real GATT server
        if (device.gatt) {
          device.gatt.disconnect();
        }
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
      if (!USE_SIMULATED_DEVICES) {
        devices.forEach(device => {
          if (device.connected && device.gatt) {
            device.gatt.disconnect();
          }
        });
      }
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
        const seconds = Math.floor(elapsedMs / 1000);
        setTotalTimeElapsed(seconds);
        
        // Update service data
        setServiceData(prev => {
          // If it's simulated, also update distance
          if (USE_SIMULATED_DEVICES) {
            // Simulate realistic pace of ~9 min/mile (2.98 m/s)
            // Distance calculation: time (s) * speed (m/s)
            const distance = seconds * 2.98;
            return {
              ...prev,
              timeElapsed: seconds,
              distance: distance
            };
          }
          
          return {
            ...prev,
            timeElapsed: seconds
          };
        });
      }
    }, 1000);
    
    // Store the interval ID for cleanup
    return () => clearInterval(intervalId);
  }, [runStartTime]);
  
  // Complete run
  const completeRun = useCallback(() => {
    setIsRunning(false);
    
    // Calculate final distance in miles (convert from meters)
    // If no real data, use simulated data based on time
    const distanceInMeters = serviceData.distance || (totalTimeElapsed * 2.98);
    const distanceInMiles = distanceInMeters / 1609.34;
    
    // Return time in seconds and distance in miles
    return {
      timeInSeconds: totalTimeElapsed,
      distanceInMiles: parseFloat(distanceInMiles.toFixed(2))
    };
  }, [totalTimeElapsed, serviceData.distance]);
  
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