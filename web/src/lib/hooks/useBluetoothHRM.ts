import { useState, useEffect, useCallback } from 'react';

// Web Bluetooth API TypeScript definitions
// These are not standard in TypeScript yet as the API is still experimental
declare global {
  interface Navigator {
    bluetooth?: {
      requestDevice(options: {
        filters?: Array<{ services?: string[] }>;
        optionalServices?: string[];
      }): Promise<BluetoothDevice>;
    };
  }

  interface BluetoothDevice {
    name: string | null;
    gatt?: BluetoothRemoteGATTServer;
    addEventListener(type: string, listener: EventListener): void;
    removeEventListener(type: string, listener: EventListener): void;
  }

  interface BluetoothRemoteGATTServer {
    connected: boolean;
    connect(): Promise<BluetoothRemoteGATTServer>;
    disconnect(): void;
    getPrimaryService(service: string): Promise<BluetoothRemoteGATTService>;
  }

  interface BluetoothRemoteGATTService {
    getCharacteristic(characteristic: string): Promise<BluetoothRemoteGATTCharacteristic>;
  }

  interface BluetoothRemoteGATTCharacteristic {
    value: DataView | null;
    readValue(): Promise<DataView>;
    startNotifications(): Promise<BluetoothRemoteGATTCharacteristic>;
    addEventListener(type: string, listener: EventListener): void;
    removeEventListener(type: string, listener: EventListener): void;
  }
}

// Constants
const HEART_RATE_SERVICE = 'heart_rate';
const HEART_RATE_MEASUREMENT = 'heart_rate_measurement';
const BODY_SENSOR_LOCATION = 'body_sensor_location';

// Types
export type BluetoothHRMStatus = 'idle' | 'scanning' | 'connected' | 'disconnected' | 'error' | 'unsupported';
export type SensorLocation = 'Other' | 'Chest' | 'Wrist' | 'Finger' | 'Hand' | 'Ear Lobe' | 'Foot' | 'Unknown';

export interface BluetoothHRMState {
  status: BluetoothHRMStatus;
  heartRate: number | null;
  sensorLocation: SensorLocation | null;
  deviceName: string | null;
  error: Error | null;
}

export interface BluetoothHRMActions {
  connect: () => Promise<void>;
  disconnect: () => void;
  isSupported: boolean;
}

/**
 * Hook for connecting to Bluetooth Heart Rate Monitor devices
 * Note: This is Chrome-only functionality as Web Bluetooth API has limited browser support
 */
export function useBluetoothHRM(): [BluetoothHRMState, BluetoothHRMActions] {
  const [state, setState] = useState<BluetoothHRMState>({
    status: 'idle',
    heartRate: null,
    sensorLocation: null,
    deviceName: null,
    error: null,
  });

  const [device, setDevice] = useState<BluetoothDevice | null>(null);
  const [server, setServer] = useState<BluetoothRemoteGATTServer | null>(null);
  const [heartRateChar, setHeartRateChar] = useState<BluetoothRemoteGATTCharacteristic | null>(null);
  
  // Check if Web Bluetooth is supported
  const isSupported = typeof navigator !== 'undefined' && 
    navigator.bluetooth !== undefined;

  // Parse heart rate from DataView
  const parseHeartRate = (value: DataView): number => {
    const flags = value.getUint8(0);
    const rate16Bits = flags & 0x1;
    
    if (rate16Bits) {
      return value.getUint16(1, true);
    }
    return value.getUint8(1);
  };

  // Parse sensor location
  const parseSensorLocation = (value: DataView): SensorLocation => {
    const locationCode = value.getUint8(0);
    const locations: SensorLocation[] = [
      'Other', 'Chest', 'Wrist', 'Finger',
      'Hand', 'Ear Lobe', 'Foot', 'Unknown'
    ];
    return locations[locationCode] || 'Unknown';
  };

  // Handle incoming heart rate data
  const handleHeartRateChanged = useCallback((event: Event) => {
    // Cast event target to characteristic with type assertion
    const characteristic = event.target as unknown as BluetoothRemoteGATTCharacteristic;
    const value = characteristic.value;
    
    if (value) {
      const heartRate = parseHeartRate(value);
      setState(prev => ({ ...prev, heartRate }));
    }
  }, []);

  // Clean up function for disconnection
  const cleanUp = useCallback(() => {
    if (heartRateChar) {
      try {
        heartRateChar.removeEventListener('characteristicvaluechanged', handleHeartRateChanged);
      } catch (e) {
        console.warn('Error removing event listener:', e);
      }
    }
    
    if (device) {
      device.removeEventListener('gattserverdisconnected', onDisconnected);
    }
    
    setHeartRateChar(null);
    setServer(null);
    setState(prev => ({ 
      ...prev, 
      status: 'disconnected', 
      heartRate: null 
    }));
  }, [device, heartRateChar, handleHeartRateChanged]);

  // Handle device disconnection
  const onDisconnected = useCallback(() => {
    cleanUp();
  }, [cleanUp]);

  // Connect to HRM device
  const connect = useCallback(async () => {
    if (!isSupported || !navigator.bluetooth) {
      setState(prev => ({ 
        ...prev, 
        status: 'unsupported', 
        error: new Error('Web Bluetooth API is not supported in this browser')
      }));
      return;
    }

    try {
      setState(prev => ({ ...prev, status: 'scanning' }));
      
      // Request BLE device with heart rate service
      const bluetoothDevice = await navigator.bluetooth.requestDevice({
        filters: [{ services: ['heart_rate'] }],
        optionalServices: ['device_information']
      });
      
      setDevice(bluetoothDevice);
      setState(prev => ({ ...prev, deviceName: bluetoothDevice.name || 'Unknown Device' }));
      
      // Connect to GATT server
      bluetoothDevice.addEventListener('gattserverdisconnected', onDisconnected);
      const gattServer = await bluetoothDevice.gatt?.connect();
      
      if (!gattServer) {
        throw new Error('Failed to connect to GATT server');
      }
      setServer(gattServer);
      
      // Get heart rate service
      const service = await gattServer.getPrimaryService('heart_rate');
      
      // Get heart rate measurement characteristic
      const hrCharacteristic = await service.getCharacteristic('heart_rate_measurement');
      setHeartRateChar(hrCharacteristic);
      
      // Start notifications
      await hrCharacteristic.startNotifications();
      hrCharacteristic.addEventListener('characteristicvaluechanged', handleHeartRateChanged);
      
      // Get sensor location if available
      try {
        const locationChar = await service.getCharacteristic('body_sensor_location');
        const locationValue = await locationChar.readValue();
        const sensorLocation = parseSensorLocation(locationValue);
        setState(prev => ({ ...prev, sensorLocation }));
      } catch (e) {
        console.log('Sensor location not available', e);
      }
      
      setState(prev => ({ ...prev, status: 'connected', error: null }));
    } catch (error) {
      console.error('Bluetooth connection error:', error);
      setState(prev => ({ 
        ...prev, 
        status: 'error', 
        error: error instanceof Error ? error : new Error(String(error)) 
      }));
      cleanUp();
    }
  }, [isSupported, onDisconnected, handleHeartRateChanged, cleanUp]);

  // Disconnect from device
  const disconnect = useCallback(() => {
    if (server && server.connected) {
      server.disconnect();
    }
    cleanUp();
  }, [server, cleanUp]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      disconnect();
    };
  }, [disconnect]);

  return [
    state,
    { connect, disconnect, isSupported }
  ];
} 