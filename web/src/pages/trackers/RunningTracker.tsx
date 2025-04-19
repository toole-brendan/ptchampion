import React, { useEffect, useRef, useState } from 'react';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { InfoIcon, PlayIcon, PauseIcon, RefreshCw, ShareIcon, CheckCircle, CloudOff, MapPin, Watch } from 'lucide-react';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/lib/authContext';
import { apiRequest } from '@/lib/apiClient';
import { saveWorkout } from '@/lib/db/indexedDB';
import { registerBackgroundSync } from '@/serviceWorkerRegistration';
import { v4 as uuidv4 } from 'uuid';
import { HeartRateMonitor } from '../../components/ui/heart-rate-monitor';

export function RunningTracker() {
  // General workout states
  const [isTracking, setIsTracking] = useState(false);
  const [distance, setDistance] = useState(0);
  const [pace, setPace] = useState<string>('--:--');
  const [formScore, setFormScore] = useState(100);
  const [elapsedTime, setElapsedTime] = useState(0);
  const [startTime, setStartTime] = useState<number | null>(null);
  const [showResultModal, setShowResultModal] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [submitSuccess, setSubmitSuccess] = useState(false);
  const [scoreGrade, setScoreGrade] = useState<'A' | 'B' | 'C' | 'D' | 'F'>('A');
  const [savedOffline, setSavedOffline] = useState(false);
  const [isOnline, setIsOnline] = useState(navigator.onLine);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  
  // Location tracking states
  const [geolocationAvailable, setGeolocationAvailable] = useState<boolean>(!!navigator.geolocation);
  const [locationPermission, setLocationPermission] = useState<boolean | null>(null);
  const [lastPosition, setLastPosition] = useState<GeolocationPosition | null>(null);
  const [totalDistance, setTotalDistance] = useState<number>(0);
  const watchIdRef = useRef<number | null>(null);

  // Interval refs
  const timerIntervalRef = useRef<NodeJS.Timeout | null>(null);
  
  const navigate = useNavigate();
  const { user } = useAuth();

  // Inside the RunningTracker component, before the return statement
  const [heartRate, setHeartRate] = useState<number | null>(null);

  const handleHeartRateChange = (newHeartRate: number | null) => {
    setHeartRate(newHeartRate);
    // We'll use this heart rate data when submitting the workout
  };

  // Track online status
  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  // Ask for location permission when component mounts
  useEffect(() => {
    if (!geolocationAvailable) {
      setErrorMessage('Geolocation is not available in your browser. Running tracking requires location access.');
      return;
    }
    
    // Just check if geolocation is available, don't actually start tracking yet
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setLocationPermission(true);
      },
      (error) => {
        console.error('Error getting location permission:', error);
        setLocationPermission(false);
        setErrorMessage('Location access denied. Please allow location permissions to track running.');
      },
      { enableHighAccuracy: true }
    );
    
    return () => {
      if (watchIdRef.current !== null) {
        navigator.geolocation.clearWatch(watchIdRef.current);
        watchIdRef.current = null;
      }
    };
  }, [geolocationAvailable]);

  // Timer logic
  useEffect(() => {
    if (isTracking) {
      timerIntervalRef.current = setInterval(() => {
        if (startTime) {
          const now = Date.now();
          const elapsed = Math.floor((now - startTime) / 1000);
          setElapsedTime(elapsed);
          
          // Update pace (minutes per mile)
          if (totalDistance > 0) {
            // Convert meters to miles, and calculate minutes per mile
            const miles = totalDistance / 1609.34;
            const minutesPerMile = elapsed / 60 / miles;
            
            if (!isNaN(minutesPerMile) && isFinite(minutesPerMile)) {
              const paceMinutes = Math.floor(minutesPerMile);
              const paceSeconds = Math.floor((minutesPerMile - paceMinutes) * 60);
              setPace(`${paceMinutes}:${paceSeconds.toString().padStart(2, '0')}`);
            }
          }
        }
      }, 1000);
    } else if (timerIntervalRef.current) {
      clearInterval(timerIntervalRef.current);
      timerIntervalRef.current = null;
    }
    
    return () => {
      if (timerIntervalRef.current) {
        clearInterval(timerIntervalRef.current);
        timerIntervalRef.current = null;
      }
    };
  }, [isTracking, startTime, totalDistance]);

  // Start tracking run
  const startTracking = () => {
    if (!geolocationAvailable || !locationPermission) {
      setErrorMessage('Location services are required for run tracking.');
      return;
    }
    
    setIsTracking(true);
    setStartTime(Date.now());
    setElapsedTime(0);
    setTotalDistance(0);
    setDistance(0);
    setPace('--:--');
    setFormScore(100);
    setSubmitSuccess(false);
    setSavedOffline(false);
    
    // Start watching position
    watchIdRef.current = navigator.geolocation.watchPosition(
      (position) => {
        if (lastPosition) {
          const newDistance = calculateDistance(
            lastPosition.coords.latitude,
            lastPosition.coords.longitude,
            position.coords.latitude,
            position.coords.longitude
          );
          
          // Only count if the new position is at least 5 meters away (to filter out GPS jitter)
          if (newDistance > 5) {
            setTotalDistance(prev => prev + newDistance);
            setDistance(prev => prev + newDistance);
            
            // Basic form evaluation based on pace consistency
            if (lastPosition.timestamp) {
              const timeDiff = position.timestamp - lastPosition.timestamp;
              const speedMps = newDistance / (timeDiff / 1000); // meters per second
              
              // Check for sudden pace changes, which could indicate bad form
              // This is a simplified approach - real form analysis would be more complex
              if (speedMps > 4.5) { // Faster than ~10mph - likely GPS error or extreme acceleration
                setFormScore(prev => Math.max(0, prev - 2));
              }
            }
          }
        }
        
        setLastPosition(position);
      },
      (error) => {
        console.error('Error tracking location:', error);
        setErrorMessage('Error tracking location. Please ensure location services are enabled.');
      },
      { 
        enableHighAccuracy: true,
        maximumAge: 0,
        timeout: 5000 
      }
    );
  };

  // Stop tracking run
  const stopTracking = () => {
    if (!isTracking) return;
    
    setIsTracking(false);
    
    // Stop watching position
    if (watchIdRef.current !== null) {
      navigator.geolocation.clearWatch(watchIdRef.current);
      watchIdRef.current = null;
    }
    
    // Only show results if at least 100 meters were run
    if (totalDistance > 100) {
      // Calculate grade based on distance and form
      if (formScore >= 90 && totalDistance > 1000) {
        setScoreGrade('A');
      } else if (formScore >= 80 && totalDistance > 800) {
        setScoreGrade('B');
      } else if (formScore >= 70 && totalDistance > 500) {
        setScoreGrade('C');
      } else if (formScore >= 60 && totalDistance > 300) {
        setScoreGrade('D');
      } else {
        setScoreGrade('F');
      }
      
      setShowResultModal(true);
    }
  };

  // Reset tracking session
  const resetTracking = () => {
    setIsTracking(false);
    setStartTime(null);
    setElapsedTime(0);
    setTotalDistance(0);
    setDistance(0);
    setPace('--:--');
    setFormScore(100);
    setShowResultModal(false);
    setSavedOffline(false);
    setLastPosition(null);
    
    // Stop watching position
    if (watchIdRef.current !== null) {
      navigator.geolocation.clearWatch(watchIdRef.current);
      watchIdRef.current = null;
    }
  };

  // Submit workout results to the API
  const submitWorkout = async () => {
    if (!user || totalDistance < 100) return;
    
    setSubmitting(true);
    
    // Generate a unique ID for the workout (useful for offline sync)
    const workoutId = uuidv4();
    
    const workoutData = {
      id: workoutId,
      exerciseType: 'RUNNING',
      // For running exercises, store distance in the count field for API compatibility
      count: Math.round(totalDistance), // Convert distance to count for API
      formScore: formScore,
      durationSeconds: elapsedTime,
      deviceType: 'WEB',
      userId: String(user.id), // Ensure userId is a string
      date: new Date().toISOString(),
      // Include heart rate if available
      heartRate: heartRate || undefined
    };
    
    try {
      if (isOnline) {
        // Online - submit directly to API
        await apiRequest('/workouts', 'POST', workoutData, true);
        setSubmitSuccess(true);
      } else {
        // Offline - save to IndexedDB
        const saved = await saveWorkout(workoutData);
        
        if (saved) {
          setSavedOffline(true);
          // Register for background sync if available
          try {
            await registerBackgroundSync('sync-workouts');
          } catch (e) {
            console.log('Background sync registration failed, but data is saved offline');
          }
        } else {
          throw new Error('Failed to save workout offline');
        }
      }
    } catch (error) {
      console.error('Error submitting workout:', error);
      setErrorMessage('Failed to save workout. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  // Calculate distance between two geographic coordinates (in meters)
  const calculateDistance = (lat1: number, lon1: number, lat2: number, lon2: number): number => {
    // Implementation of the haversine formula
    const R = 6371e3; // Earth's radius in meters
    const φ1 = lat1 * Math.PI / 180;
    const φ2 = lat2 * Math.PI / 180;
    const Δφ = (lat2 - lat1) * Math.PI / 180;
    const Δλ = (lon2 - lon1) * Math.PI / 180;

    const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
              Math.cos(φ1) * Math.cos(φ2) *
              Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c;
    
    return distance;
  };

  // Format distance to km or meters
  const formatDistance = (meters: number): string => {
    if (meters >= 1000) {
      return `${(meters / 1000).toFixed(2)} km`;
    }
    return `${Math.round(meters)} m`;
  };

  // Format seconds to hh:mm:ss
  const formatTime = (seconds: number): string => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const remainingSeconds = seconds % 60;
    
    if (hours > 0) {
      return `${hours}:${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
    }
    
    return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
  };

  // Share results on social media
  const shareResults = () => {
    if (navigator.share) {
      navigator.share({
        title: 'PT Champion Workout',
        text: `I just ran ${formatDistance(totalDistance)} in ${formatTime(elapsedTime)} using PT Champion!`,
        url: window.location.href,
      }).catch(error => {
        console.error('Error sharing:', error);
      });
    } else {
      // Fallback for browsers that don't support Web Share API
      const text = `I just ran ${formatDistance(totalDistance)} in ${formatTime(elapsedTime)} using PT Champion!`;
      navigator.clipboard.writeText(text)
        .then(() => {
          // Set a temporary message to the user
          const originalError = errorMessage;
          setErrorMessage('Results copied to clipboard!');
          setTimeout(() => {
            setErrorMessage(originalError);
          }, 3000);
        })
        .catch(err => {
          console.error('Could not copy text: ', err);
        });
    }
  };

  return (
    <div className="container mx-auto px-4 py-8">
      {!isOnline && (
        <Alert className="mb-4 bg-amber-50 border-amber-200">
          <CloudOff className="h-4 w-4 text-amber-500" />
          <AlertTitle className="text-amber-800">Offline Mode</AlertTitle>
          <AlertDescription className="text-amber-700">
            You're currently offline. Your workout will be saved locally and synced when you reconnect.
          </AlertDescription>
        </Alert>
      )}
      
      <div className="mb-4">
        <HeartRateMonitor onHeartRateChange={handleHeartRateChange} />
      </div>
      
      <Card className="w-full max-w-3xl mx-auto bg-cream">
        <CardHeader className="bg-deep-ops text-cream rounded-t-lg">
          <CardTitle className="text-2xl font-heading tracking-wide">Running Tracker</CardTitle>
          <CardDescription className="text-army-tan">
            Track your distance, pace, and time
          </CardDescription>
        </CardHeader>
        
        <CardContent className="p-6">
          {errorMessage && (
            <Alert variant="destructive" className="mb-4">
              <InfoIcon className="h-4 w-4" />
              <AlertTitle>Error</AlertTitle>
              <AlertDescription>{errorMessage}</AlertDescription>
            </Alert>
          )}
          
          <div className="relative aspect-video bg-muted rounded-lg overflow-hidden mb-6 flex flex-col items-center justify-center">
            <div className="text-8xl font-mono text-brass-gold font-bold">
              {formatTime(elapsedTime)}
            </div>
            <div className="text-2xl font-mono text-deep-ops mt-4">
              {formatDistance(totalDistance)}
            </div>
            <div className="text-lg font-mono text-tactical-gray mt-2">
              Pace: {pace} min/mile
            </div>
            
            {!locationPermission && geolocationAvailable && (
              <div className="absolute inset-0 flex flex-col items-center justify-center bg-black/70 z-10">
                <MapPin className="h-12 w-12 mb-3 text-destructive" />
                <p className="text-white text-lg font-semibold">Location Access Required</p>
                <p className="text-white/80 text-center max-w-xs mt-2">Please allow location access to track your runs.</p>
              </div>
            )}
            
            {!geolocationAvailable && (
              <div className="absolute inset-0 flex flex-col items-center justify-center bg-black/70 z-10">
                <MapPin className="h-12 w-12 mb-3 text-destructive" />
                <p className="text-white text-lg font-semibold">Geolocation Not Available</p>
                <p className="text-white/80 text-center max-w-xs mt-2">Your browser doesn't support location tracking.</p>
              </div>
            )}
          </div>
          
          <div className="grid grid-cols-3 gap-4 mb-6">
            <div className="rounded-lg bg-white/50 p-4 text-center">
              <h3 className="text-sm font-medium text-tactical-gray mb-1">Time</h3>
              <p className="text-xl font-mono text-brass-gold">{formatTime(elapsedTime)}</p>
            </div>
            <div className="rounded-lg bg-white/50 p-4 text-center">
              <h3 className="text-sm font-medium text-tactical-gray mb-1">Distance</h3>
              <p className="text-xl font-mono text-brass-gold">{formatDistance(totalDistance)}</p>
            </div>
            <div className="rounded-lg bg-white/50 p-4 text-center">
              <h3 className="text-sm font-medium text-tactical-gray mb-1">Pace</h3>
              <p className="text-xl font-mono text-brass-gold">{pace}</p>
            </div>
          </div>
          
          <div className="mb-4">
            <div className="flex justify-between mb-2">
              <span className="text-sm font-medium">Pace Consistency</span>
              <span className="text-sm font-mono">{formScore}%</span>
            </div>
            <Progress value={formScore} className="h-2" />
          </div>
          
          <div className="rounded-lg bg-muted p-4 mb-4">
            <h3 className="font-semibold mb-2">Tips</h3>
            <ul className="text-sm list-disc pl-5 space-y-1">
              <li>Keep your phone with you while running</li>
              <li>Ensure location services are enabled</li>
              <li>Run in open areas for better GPS accuracy</li>
              <li>Maintain a consistent pace for better scores</li>
              <li>The tracker works best outdoors</li>
            </ul>
          </div>
        </CardContent>
        
        <CardFooter className="border-t border-border flex justify-between p-4">
          {!isTracking ? (
            <Button 
              onClick={startTracking} 
              className="bg-brass-gold hover:bg-brass-gold/90 text-deep-ops"
              disabled={!locationPermission || !geolocationAvailable}
              size="lg"
            >
              <PlayIcon className="mr-2 h-5 w-5" />
              Begin Tracking
            </Button>
          ) : (
            <Button 
              onClick={stopTracking} 
              variant="outline" 
              className="border-brass-gold text-brass-gold hover:bg-brass-gold/10"
              size="lg"
            >
              <PauseIcon className="mr-2 h-5 w-5" />
              End Run
            </Button>
          )}
          
          <Button 
            onClick={resetTracking} 
            variant="ghost" 
            className="text-muted-foreground"
            disabled={isTracking || (totalDistance === 0 && elapsedTime === 0)}
          >
            <RefreshCw className="mr-2 h-4 w-4" />
            Reset
          </Button>
        </CardFooter>
      </Card>
      
      {/* Results Modal */}
      <Dialog open={showResultModal} onOpenChange={setShowResultModal}>
        <DialogContent className="bg-cream sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="text-2xl font-heading text-center">Run Results</DialogTitle>
            <DialogDescription className="text-center">
              {submitSuccess ? (
                <div className="flex items-center justify-center text-green-600 mt-2">
                  <CheckCircle className="mr-2 h-5 w-5" />
                  Run saved successfully!
                </div>
              ) : savedOffline ? (
                <div className="flex items-center justify-center text-amber-600 mt-2">
                  <CloudOff className="mr-2 h-5 w-5" />
                  Run saved offline. Will sync when online.
                </div>
              ) : (
                "Your run is complete!"
              )}
            </DialogDescription>
          </DialogHeader>
          
          <div className="grid grid-cols-2 gap-4 py-4">
            <div className="bg-white/50 p-4 rounded-lg text-center">
              <div className="text-sm text-tactical-gray font-medium mb-1">Distance</div>
              <div className="text-3xl font-mono text-brass-gold">{formatDistance(totalDistance)}</div>
            </div>
            
            <div className="bg-white/50 p-4 rounded-lg text-center">
              <div className="text-sm text-tactical-gray font-medium mb-1">Time</div>
              <div className="text-2xl font-mono text-brass-gold">{formatTime(elapsedTime)}</div>
            </div>
            
            <div className="bg-white/50 p-4 rounded-lg text-center">
              <div className="text-sm text-tactical-gray font-medium mb-1">Avg. Pace</div>
              <div className="text-2xl font-mono text-brass-gold">{pace}</div>
            </div>
            
            <div className="bg-white/50 p-4 rounded-lg text-center">
              <div className="text-sm text-tactical-gray font-medium mb-1">Grade</div>
              <div className="text-3xl font-mono text-brass-gold">{scoreGrade}</div>
            </div>
          </div>
          
          <DialogFooter className="flex flex-col sm:flex-row gap-2 sm:justify-between">
            {!submitSuccess && !savedOffline ? (
              <Button 
                onClick={submitWorkout} 
                className="bg-brass-gold hover:bg-brass-gold/90 text-deep-ops w-full sm:w-auto"
                disabled={submitting}
              >
                {submitting ? 'Saving...' : `Save Results${!isOnline ? ' Offline' : ''}`}
              </Button>
            ) : (
              <Button
                onClick={() => navigate('/history')}
                className="bg-brass-gold hover:bg-brass-gold/90 text-deep-ops w-full sm:w-auto"
              >
                View History
              </Button>
            )}
            
            <Button 
              onClick={shareResults} 
              variant="outline" 
              className="border-brass-gold text-brass-gold hover:bg-brass-gold/10 w-full sm:w-auto"
            >
              <ShareIcon className="mr-2 h-4 w-4" />
              Share Results
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
} 