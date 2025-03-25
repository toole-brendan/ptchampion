import { useEffect, useState } from 'react';
import { useAuth } from '@/hooks/use-auth';
import { useMutation } from '@tanstack/react-query';
import { useLocation } from 'wouter';
import { queryClient, apiRequest } from '@/lib/queryClient';
import { Button } from '@/components/ui/button';
import { Pause, Play, CheckCircle, Heart } from 'lucide-react';
import { BluetoothServiceData } from '@/hooks/use-bluetooth';
import { calculateRunGrade } from '@/lib/exercise-grading';

interface RunTrackerProps {
  isRunning: boolean;
  serviceData: BluetoothServiceData;
  deviceName: string;
  onComplete: () => { timeInSeconds: number, distanceInMiles: number };
  onCancel: () => void;
}

export default function RunTracker({ 
  isRunning,
  serviceData,
  deviceName,
  onComplete,
  onCancel
}: RunTrackerProps) {
  const [, setLocation] = useLocation();
  const { user } = useAuth();
  const [isPaused, setIsPaused] = useState(false);
  const [runComplete, setRunComplete] = useState(false);
  
  // Format time for display
  const formatTime = (timeInSeconds: number) => {
    const minutes = Math.floor(timeInSeconds / 60);
    const seconds = timeInSeconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  };

  // Format distance for display (convert meters to miles)
  const formatDistance = (distanceInMeters?: number) => {
    if (!distanceInMeters) return '0.00';
    // Convert meters to miles
    const miles = distanceInMeters / 1609.34;
    return miles.toFixed(2);
  };
  
  // Complete run mutation
  const completeMutation = useMutation({
    mutationFn: async (data: { timeInSeconds: number, distanceInMiles: number }) => {
      // Get run exercise ID (assuming it's 4 based on seed data)
      const exerciseId = 4;
      
      // Calculate grade for the run time (for 2-mile run)
      const grade = calculateRunGrade(data.timeInSeconds);
      
      const payload = {
        exerciseId,
        timeInSeconds: data.timeInSeconds,
        formScore: 100, // Not applicable for runs
        grade, // Include the calculated grade
        completed: true,
        metadata: JSON.stringify({
          distanceInMiles: data.distanceInMiles,
          avgHeartRate: serviceData.heartRate
        })
      };
      
      const res = await apiRequest("POST", "/api/user-exercises", payload);
      return await res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/user-exercises/latest/all"] });
      queryClient.invalidateQueries({ queryKey: ["/api/leaderboard/global"] });
      setLocation("/");
    }
  });
  
  // Handle completing the run
  const handleCompleteRun = () => {
    setRunComplete(true);
    const result = onComplete();
    completeMutation.mutate(result);
  };
  
  return (
    <div className="bg-white rounded-xl shadow-sm p-6 mb-6">
      <div className="flex flex-col items-center justify-center py-6">
        {!runComplete ? (
          <>
            <div className="w-48 h-48 rounded-full bg-slate-100 flex items-center justify-center mb-4 relative">
              {/* Circular progress indicator */}
              <svg className="absolute top-0 left-0 h-full w-full" viewBox="0 0 100 100">
                <circle 
                  cx="50" 
                  cy="50" 
                  r="45" 
                  fill="none" 
                  stroke="#e2e8f0" 
                  strokeWidth="8"
                />
                <circle 
                  cx="50" 
                  cy="50" 
                  r="45" 
                  fill="none" 
                  stroke="currentColor" 
                  strokeWidth="8"
                  strokeLinecap="round"
                  strokeDasharray="283"
                  strokeDashoffset={283 - (283 * (serviceData.timeElapsed || 0) / 1200)} // 20 mins = 1200 secs
                  className="text-accent transform -rotate-90 origin-center"
                />
              </svg>
              
              {/* Time display */}
              <div className="text-center z-10">
                <div className="text-4xl font-bold">
                  {formatTime(serviceData.timeElapsed || 0)}
                </div>
                <div className="text-sm text-slate-500">Time</div>
              </div>
            </div>
            
            <h3 className="text-xl font-bold mb-6">Running with {deviceName}</h3>
            
            <div className="w-full max-w-sm grid grid-cols-2 gap-4 mb-8">
              {/* Distance Card */}
              <div className="bg-slate-100 rounded-lg p-4 text-center">
                <div className="font-bold text-2xl">
                  {formatDistance(serviceData.distance)}
                </div>
                <div className="text-sm text-slate-500">Miles</div>
              </div>
              
              {/* Heart Rate Card */}
              <div className="bg-slate-100 rounded-lg p-4 text-center flex flex-col items-center">
                <div className="font-bold text-2xl flex items-center">
                  {serviceData.heartRate || '--'}
                  <Heart className="h-5 w-5 ml-1 text-red-500" />
                </div>
                <div className="text-sm text-slate-500">BPM</div>
              </div>
            </div>
            
            <div className="space-y-3 w-full max-w-sm">
              {isPaused ? (
                <button 
                  className="w-full bg-accent text-white py-3 px-4 rounded-lg font-medium flex items-center justify-center"
                  onClick={() => setIsPaused(false)}
                >
                  <Play className="h-5 w-5 mr-2" />
                  Resume Run
                </button>
              ) : (
                <button 
                  className="w-full bg-slate-200 text-slate-800 py-3 px-4 rounded-lg font-medium flex items-center justify-center"
                  onClick={() => setIsPaused(true)}
                >
                  <Pause className="h-5 w-5 mr-2" />
                  Pause Run
                </button>
              )}
              
              <button 
                className="w-full bg-green-600 text-white py-3 px-4 rounded-lg font-medium flex items-center justify-center"
                onClick={handleCompleteRun}
              >
                <CheckCircle className="h-5 w-5 mr-2" />
                Complete Run
              </button>
              
              <button 
                className="w-full bg-white border border-slate-200 py-3 px-4 rounded-lg font-medium"
                onClick={onCancel}
              >
                Cancel Run
              </button>
            </div>
          </>
        ) : (
          <div className="flex flex-col items-center">
            <div className="w-24 h-24 rounded-full bg-green-100 flex items-center justify-center mb-4">
              <CheckCircle className="h-12 w-12 text-green-600" />
            </div>
            <h3 className="text-xl font-bold mb-2">Run Completed!</h3>
            <p className="text-center text-slate-500 mb-6">Your run has been recorded.</p>
            {completeMutation.isPending && <p>Saving your run data...</p>}
          </div>
        )}
      </div>
    </div>
  );
}