import { useState, useEffect } from "react";
import { useLocation } from "wouter";
import { useMutation } from "@tanstack/react-query";
import { useAuth } from "@/hooks/use-auth";
import Navigation from "@/components/navigation";
import { useBluetooth, CustomBluetoothDevice } from "@/hooks/use-bluetooth";
import RunTracker from "@/components/run-tracker";
import { useToast } from "@/hooks/use-toast";
import { queryClient, apiRequest } from "@/lib/queryClient";
import { calculateRunGrade } from "@/lib/exercise-grading";
import { ArrowLeft, Clock, CheckCircle, Wifi, AlertCircle } from "lucide-react";

export default function RunPage() {
  const [, setLocation] = useLocation();
  const { user } = useAuth();
  const { toast } = useToast();
  
  // Bluetooth hook integration
  const {
    devices,
    isScanning,
    error,
    isSupported,
    serviceData,
    isRunning,
    scanForDevices,
    connectToDevice,
    disconnectDevice,
    startRun,
    completeRun
  } = useBluetooth();
  
  // State for manual entry
  const [showManualEntry, setShowManualEntry] = useState(false);
  const [minutes, setMinutes] = useState("14");
  const [seconds, setSeconds] = useState("32");
  
  // State for tracking run in progress
  const [runInProgress, setRunInProgress] = useState(false);
  const [selectedDevice, setSelectedDevice] = useState<CustomBluetoothDevice | null>(null);
  
  // Show error if Bluetooth isn't supported
  useEffect(() => {
    if (!isSupported) {
      toast({
        title: "Bluetooth Not Supported",
        description: "Your browser doesn't support Web Bluetooth. Try using Chrome or Edge on desktop, or Android with Chrome.",
        variant: "destructive"
      });
    }
  }, [isSupported, toast]);
  
  // Handle errors
  useEffect(() => {
    if (error) {
      toast({
        title: "Bluetooth Error",
        description: error.message,
        variant: "destructive"
      });
    }
  }, [error, toast]);
  
  // Handle device scanning
  const handleScanForDevices = async () => {
    try {
      await scanForDevices();
    } catch (err: any) {
      toast({
        title: "Scanning Failed",
        description: err.message,
        variant: "destructive"
      });
    }
  };
  
  // Handle device connection toggle
  const handleToggleConnection = async (deviceId: string) => {
    const device = devices.find(d => d.id === deviceId);
    
    if (!device) {
      return;
    }
    
    if (device.connected) {
      await disconnectDevice(deviceId);
      setSelectedDevice(null);
    } else {
      const success = await connectToDevice(deviceId);
      
      if (success) {
        // Set as selected device
        setSelectedDevice(device);
        
        toast({
          title: "Device Connected",
          description: `Connected to ${device.name} successfully.`,
          variant: "default"
        });
      }
    }
  };
  
  // Handle start run with connected device
  const handleStartRun = () => {
    if (!selectedDevice) {
      toast({
        title: "No Device Selected",
        description: "Please connect to a device first.",
        variant: "destructive"
      });
      return;
    }
    
    // Start run tracking
    startRun();
    setRunInProgress(true);
  };
  
  // Handle completing run
  const handleCompleteRun = () => {
    // Get final data
    const result = completeRun();
    setRunInProgress(false);
    return result;
  };
  
  // Handle canceling run
  const handleCancelRun = () => {
    setRunInProgress(false);
  };
  
  // Complete run mutation for manual entry
  const completeMutation = useMutation({
    mutationFn: async (timeInSeconds: number) => {
      // Get run exercise ID (assuming it's 4 based on seed data)
      const exerciseId = 4;
      
      // Calculate grade for the run time
      const grade = calculateRunGrade(timeInSeconds);
      
      const data = {
        exerciseId,
        timeInSeconds,
        formScore: 100, // Not really applicable for runs
        grade,
        completed: true
      };
      
      const res = await apiRequest("POST", "/api/user-exercises", data);
      return await res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/user-exercises/latest/all"] });
      queryClient.invalidateQueries({ queryKey: ["/api/leaderboard/global"] });
      setLocation("/");
    }
  });
  
  // Handle manual entry submission
  const handleManualEntry = () => {
    const mins = parseInt(minutes || "0");
    const secs = parseInt(seconds || "0");
    
    if (isNaN(mins) || isNaN(secs) || mins < 0 || secs < 0 || secs > 59) {
      toast({
        title: "Invalid Time",
        description: "Please enter a valid time.",
        variant: "destructive"
      });
      return;
    }
    
    const timeInSeconds = mins * 60 + secs;
    completeMutation.mutate(timeInSeconds);
  };

  return (
    <div className="min-h-screen flex flex-col bg-slate-50">
      {/* Header */}
      <header className="bg-white border-b border-slate-200">
        <div className="container px-4 py-3 mx-auto flex items-center justify-between">
          <div>
            <button 
              className="flex items-center text-accent" 
              onClick={() => runInProgress ? setRunInProgress(false) : setLocation("/")}
            >
              <ArrowLeft className="h-5 w-5 mr-1" />
              Back
            </button>
          </div>
          <h2 className="text-2xl font-bold">2-mile Run</h2>
          <div></div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1">
        <section className="py-6 px-4 lg:px-8">
          <div className="container mx-auto max-w-5xl">
            {runInProgress && selectedDevice ? (
              <RunTracker 
                isRunning={isRunning}
                serviceData={serviceData}
                deviceName={selectedDevice.name || "Device"}
                onComplete={handleCompleteRun}
                onCancel={handleCancelRun}
              />
            ) : !showManualEntry ? (
              <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
                <div className="flex flex-col items-center justify-center py-6">
                  <div className="w-24 h-24 rounded-full bg-slate-100 flex items-center justify-center mb-4">
                    <Clock className="h-12 w-12 text-slate-400" />
                  </div>
                  <h3 className="text-xl font-bold mb-2">Connect Smartwatch</h3>
                  <p className="text-slate-500 text-center max-w-md mb-6">Connect your smartwatch to track your 2-mile run. Ensure GPS is enabled on your device.</p>
                  
                  {!isSupported && (
                    <div className="w-full max-w-sm mb-4 bg-red-50 border border-red-200 rounded-lg p-4 flex items-start">
                      <AlertCircle className="h-5 w-5 text-red-500 mr-2 flex-shrink-0 mt-0.5" />
                      <div>
                        <h4 className="font-medium text-red-700">Bluetooth Not Supported</h4>
                        <p className="text-sm text-red-600">Your browser doesn't support Web Bluetooth. Try using Chrome, Edge, or Opera on desktop or Android.</p>
                      </div>
                    </div>
                  )}
                  
                  <div className="w-full max-w-sm mb-8">
                    {isScanning ? (
                      <div className="flex justify-center items-center py-8">
                        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-accent"></div>
                        <span className="ml-3">Scanning for devices...</span>
                      </div>
                    ) : devices.length > 0 ? (
                      devices.map(device => (
                        <div key={device.id} className="bg-slate-100 rounded-lg p-4 mb-4 flex items-center justify-between">
                          <div className="flex items-center">
                            <div className="w-10 h-10 bg-white rounded-full flex items-center justify-center mr-3">
                              <Clock className={`h-6 w-6 ${device.connected ? 'text-accent' : 'text-slate-400'}`} />
                            </div>
                            <div>
                              <div className="font-medium">{device.name}</div>
                              <div className="text-xs text-slate-500">
                                {device.connected ? 'Connected' : 'Not connected'}
                                {device.heartRate && ` • ${device.heartRate} BPM`}
                              </div>
                            </div>
                          </div>
                          {device.connected ? (
                            <div className="w-5 h-5 bg-green-500 rounded-full"></div>
                          ) : (
                            <button 
                              className="text-xs font-medium text-accent"
                              onClick={() => handleToggleConnection(device.id)}
                            >
                              Connect
                            </button>
                          )}
                        </div>
                      ))
                    ) : (
                      <div className="text-center py-6">
                        <Wifi className="h-12 w-12 mx-auto text-slate-300 mb-2" />
                        <p className="text-slate-500">No devices found. Tap "Scan for Devices" to search for nearby Bluetooth devices.</p>
                      </div>
                    )}
                    
                    {isSupported && (
                      <button 
                        className="w-full bg-slate-200 text-slate-800 py-2 px-4 rounded-lg font-medium mt-4"
                        onClick={handleScanForDevices}
                        disabled={isScanning}
                      >
                        {isScanning ? 'Scanning...' : 'Scan for Devices'}
                      </button>
                    )}
                  </div>
                  
                  <div className="space-y-3 w-full max-w-sm">
                    <button 
                      className="w-full bg-accent text-white py-3 px-4 rounded-lg font-medium"
                      onClick={handleStartRun}
                      disabled={!devices.some(d => d.connected)}
                    >
                      Start 2-mile Run
                    </button>
                    <button 
                      className="w-full bg-white border border-slate-200 py-3 px-4 rounded-lg font-medium"
                      onClick={() => setShowManualEntry(true)}
                    >
                      Manual Entry
                    </button>
                  </div>
                </div>
              </div>
            ) : (
              <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
                <div className="flex flex-col items-center justify-center py-6">
                  <div className="w-24 h-24 rounded-full bg-slate-100 flex items-center justify-center mb-4">
                    <Clock className="h-12 w-12 text-slate-400" />
                  </div>
                  <h3 className="text-xl font-bold mb-2">Manual Time Entry</h3>
                  <p className="text-slate-500 text-center max-w-md mb-6">Enter your 2-mile run time manually.</p>
                  
                  <div className="w-full max-w-sm mb-8">
                    <div className="flex items-center justify-center space-x-2 mb-6">
                      <div className="w-20">
                        <label className="block text-sm font-medium text-gray-700 mb-1 text-center">Minutes</label>
                        <input
                          type="number"
                          min="0"
                          max="59"
                          value={minutes}
                          onChange={(e) => setMinutes(e.target.value)}
                          className="w-full text-center border border-gray-300 rounded-md py-2 px-3 focus:outline-none focus:ring-2 focus:ring-accent"
                        />
                      </div>
                      <span className="text-2xl font-bold">:</span>
                      <div className="w-20">
                        <label className="block text-sm font-medium text-gray-700 mb-1 text-center">Seconds</label>
                        <input
                          type="number"
                          min="0"
                          max="59"
                          value={seconds}
                          onChange={(e) => setSeconds(e.target.value)}
                          className="w-full text-center border border-gray-300 rounded-md py-2 px-3 focus:outline-none focus:ring-2 focus:ring-accent"
                        />
                      </div>
                    </div>
                  </div>
                  
                  <div className="space-y-3 w-full max-w-sm">
                    <button 
                      className="w-full bg-accent text-white py-3 px-4 rounded-lg font-medium"
                      onClick={handleManualEntry}
                    >
                      Save Run Time
                    </button>
                    <button 
                      className="w-full bg-white border border-slate-200 py-3 px-4 rounded-lg font-medium"
                      onClick={() => setShowManualEntry(false)}
                    >
                      Back to Watch Connection
                    </button>
                  </div>
                </div>
              </div>
            )}
            
            {!runInProgress && (
              <div className="bg-white rounded-xl shadow-sm p-4">
                <h3 className="text-lg font-semibold mb-3">Before You Start</h3>
                <ul className="space-y-2">
                  <li className="flex">
                    <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                    <span>Ensure your device has GPS enabled for accurate tracking</span>
                  </li>
                  <li className="flex">
                    <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                    <span>Find a flat, measured 2-mile course for best results</span>
                  </li>
                  <li className="flex">
                    <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                    <span>Warm up properly before beginning your run</span>
                  </li>
                  <li className="flex">
                    <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                    <span>Keep your smartwatch visible and accessible during the run</span>
                  </li>
                </ul>
              </div>
            )}
          </div>
        </section>
      </main>

      {/* Bottom Navigation */}
      <Navigation active="home" />
    </div>
  );
}
