import React, { useState, useRef, useEffect } from 'react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Play, Pause, RotateCcw, Timer, MapPin } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
// Import mapping components
import { MapContainer, TileLayer, Polyline, Marker, Popup } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet'; // Import Leaflet library itself for icon customization
import { logExercise } from '../../lib/apiClient';
import { LogExerciseRequest } from '../../lib/types';

// Fix leaflet's default icon path issue with bundlers like Vite
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});

// Placeholder type for coordinates
type LatLngTuple = [number, number];

// Haversine formula to calculate distance between two points in km
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371; // Radius of the Earth in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    0.5 - Math.cos(dLat) / 2 +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    (1 - Math.cos(dLon)) / 2;

  return R * 2 * Math.asin(Math.sqrt(a));
}

const RunningTracker: React.FC = () => {
  const navigate = useNavigate();
  const [distance, setDistance] = useState(0); // Distance in kilometers
  const [timer, setTimer] = useState(0);
  const [isActive, setIsActive] = useState(false);
  const [isFinished, setIsFinished] = useState(false);
  const [pathCoordinates, setPathCoordinates] = useState<LatLngTuple[]>([]);
  const [currentPosition, setCurrentPosition] = useState<LatLngTuple | null>(null);
  const [geoError, setGeoError] = useState<string | null>(null);
  const [permissionGranted, setPermissionGranted] = useState<boolean | null>(null);

  const timerIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const watchIdRef = useRef<number | null>(null);
  const mapRef = useRef<L.Map>(null); // Ref for map instance

  // Exercise state
  const [minutes, setMinutes] = useState<number>(0);
  const [seconds, setSeconds] = useState<number>(0);
  const [notes, setNotes] = useState<string>('');
  
  // UI state
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  
  // Constants for this exercise
  const EXERCISE_ID = 4; // Assuming 4 is the ID for running in your database
  const EXERCISE_NAME = '2-Mile Run';

  // Geolocation Tracking Logic
  useEffect(() => {
    if (isActive) {
      setGeoError(null);
      setPermissionGranted(null);
      console.log("Starting geolocation watch...");
      watchIdRef.current = navigator.geolocation.watchPosition(
        (position) => {
          setPermissionGranted(true);
          const { latitude, longitude } = position.coords;
          const newCoord: LatLngTuple = [latitude, longitude];
          setCurrentPosition(newCoord);
          setPathCoordinates((prevCoords) => {
            const updatedCoords = [...prevCoords, newCoord];
            // Calculate distance from the previous point to the new point
            if (updatedCoords.length > 1) {
              const prevCoord = updatedCoords[updatedCoords.length - 2];
              const addedDistance = calculateDistance(prevCoord[0], prevCoord[1], newCoord[0], newCoord[1]);
              setDistance((prevDistance) => prevDistance + addedDistance);
            }
            return updatedCoords;
          });
          // Center map on current position
          if (mapRef.current) {
             mapRef.current.setView(newCoord, 16); // Zoom level 16
          }
        },
        (error) => {
          console.error("Geolocation error:", error);
          setPermissionGranted(false);
          switch (error.code) {
            case error.PERMISSION_DENIED:
              setGeoError("Geolocation permission denied. Please enable location services.");
              break;
            case error.POSITION_UNAVAILABLE:
              setGeoError("Location information is unavailable.");
              break;
            case error.TIMEOUT:
              setGeoError("The request to get user location timed out.");
              break;
            default:
              setGeoError("An unknown error occurred while getting location.");
              break;
          }
          setIsActive(false); // Stop tracking if there's an error
        },
        {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 0, // Don't use cached positions
        }
      );
    } else {
      // Clear watch when not active
      if (watchIdRef.current !== null) {
        console.log("Stopping geolocation watch...");
        navigator.geolocation.clearWatch(watchIdRef.current);
        watchIdRef.current = null;
      }
    }

    // Cleanup function for component unmount
    return () => {
      if (watchIdRef.current !== null) {
        navigator.geolocation.clearWatch(watchIdRef.current);
      }
    };
  }, [isActive]); // Rerun effect when isActive changes

  // Timer logic (similar to other trackers)
  useEffect(() => {
    if (isActive) {
      timerIntervalRef.current = setInterval(() => {
        setTimer((prev) => prev + 1);
      }, 1000);
    } else if (timerIntervalRef.current) {
      clearInterval(timerIntervalRef.current);
      timerIntervalRef.current = null;
    }
    return () => {
      if (timerIntervalRef.current) {
        clearInterval(timerIntervalRef.current);
      }
    };
  }, [isActive]);

  // Control handlers
  const handleStartPause = () => {
    if (isFinished) return;
    // Check permission before starting (or let useEffect handle error)
    setIsActive(!isActive);
    console.log(isActive ? "Pausing Run Tracking..." : "Starting Run Tracking...");
  };

  const handleFinish = () => {
    setIsActive(false);
    setIsFinished(true);
    // Stop geolocation watch if active
    if (watchIdRef.current !== null) {
      navigator.geolocation.clearWatch(watchIdRef.current);
      watchIdRef.current = null;
    }
    alert(`Run finished! Distance: ${distance.toFixed(2)} km, Time: ${formatTime(timer)}`);
  };

  const handleReset = () => {
    setIsActive(false);
    setIsFinished(false);
    setDistance(0);
    setTimer(0);
    setPathCoordinates([]);
    setCurrentPosition(null);
    setGeoError(null);
    setPermissionGranted(null); // Re-check permission on next start attempt
    if (watchIdRef.current !== null) {
        navigator.geolocation.clearWatch(watchIdRef.current);
        watchIdRef.current = null;
    }
    console.log("Resetting Run Tracker state...");
  };

  const formatTime = (timeInSeconds: number): string => {
    const minutes = Math.floor(timeInSeconds / 60).toString().padStart(2, '0');
    const seconds = (timeInSeconds % 60).toString().padStart(2, '0');
    return `${minutes}:${seconds}`;
  };

  const handleMinutesChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = parseInt(e.target.value);
    if (!isNaN(value) && value >= 0) {
      setMinutes(value);
    }
  };
  
  const handleSecondsChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = parseInt(e.target.value);
    if (!isNaN(value) && value >= 0 && value < 60) {
      setSeconds(value);
    }
  };
  
  const handleDistanceChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = parseFloat(e.target.value);
    if (!isNaN(value) && value >= 0) {
      setDistance(value);
    }
  };
  
  const handleNotesChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setNotes(e.target.value);
  };
  
  const getTotalSeconds = (): number => {
    return (minutes * 60) + seconds;
  };
  
  const formatTimeForDisplay = (): string => {
    const formattedMinutes = minutes.toString().padStart(2, '0');
    const formattedSeconds = seconds.toString().padStart(2, '0');
    return `${formattedMinutes}:${formattedSeconds}`;
  };
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (getTotalSeconds() <= 0) {
      setError('Please enter a valid time');
      return;
    }
    
    // Convert distance from miles to meters if needed
    const distanceMeters = Math.round(distance * 1609.34); // Convert miles to meters
    
    setIsSubmitting(true);
    setError(null);
    setSuccess(false);
    
    try {
      const exerciseData: LogExerciseRequest = {
        exercise_id: EXERCISE_ID,
        duration: getTotalSeconds(),
        distance: distanceMeters,
        notes: notes || undefined,
      };
      
      await logExercise(exerciseData);
      
      setSuccess(true);
      setMinutes(0);
      setSeconds(0);
      setDistance(0);
      setNotes('');
      
      // After 2 seconds, redirect to the history page to see the logged exercise
      setTimeout(() => {
        navigate('/history');
      }, 2000);
      
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to log exercise');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="space-y-6">
      <Button variant="outline" onClick={() => navigate('/exercises')} className="mb-4">
        &larr; Back to Exercises
      </Button>
      <h1 className="text-3xl font-semibold text-foreground">Running Tracker</h1>

      <Card className="bg-card rounded-lg shadow-sm overflow-hidden">
        <CardHeader>
          <CardTitle className="text-lg font-medium">Track Your Run</CardTitle>
          <CardDescription>Start the timer to begin tracking distance and path.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Map Integration */}
          <div className="aspect-video bg-muted rounded-md overflow-hidden relative">
            <MapContainer 
              ref={mapRef}
              center={currentPosition || [51.505, -0.09]} // Default center if no position yet
              zoom={currentPosition ? 16 : 13} // Zoom in more if position known
              scrollWheelZoom={false} // Disable scroll wheel zoom for better UX on page
              style={{ height: "100%", width: "100%" }}
            >
              <TileLayer
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              />
              {pathCoordinates.length > 0 && (
                <Polyline pathOptions={{ color: 'blue' }} positions={pathCoordinates} />
              )}
              {currentPosition && (
                <Marker position={currentPosition}>
                  <Popup>Current Location</Popup>
                </Marker>
              )}
            </MapContainer>
            {/* Show overlay if permission denied */} 
            {permissionGranted === false && !isActive && (
               <div className="absolute inset-0 flex flex-col items-center justify-center bg-black/70 text-white p-4 text-center z-10">
                 <MapPin className="h-12 w-12 mb-2 text-destructive" />
                 <p className="font-semibold mb-1">Location Access Issue</p>
                 <p className="text-sm">{geoError}</p>
               </div>
            )}
          </div>

          {/* Stats Display */}
          <div className="grid grid-cols-2 gap-4 text-center">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Distance</p>
              <p className="text-4xl font-bold text-foreground">
                 {distance.toFixed(2)} <span className="text-xl font-normal">km</span>
              </p>
            </div>
            <div>
              <p className="text-sm font-medium text-muted-foreground">Time</p>
              <p className="text-4xl font-bold text-foreground flex items-center justify-center">
                <Timer className="h-6 w-6 mr-1 inline-block" />
                {formatTime(timer)}
              </p>
            </div>
          </div>
        </CardContent>
        <CardFooter className="border-t bg-background/50 px-6 py-4 flex justify-center space-x-4">
            {!isFinished ? (
              <>
                <Button size="lg" onClick={handleStartPause} disabled={isFinished || (isActive && permissionGranted === false) }>
                  {isActive ? <Pause className="mr-2 h-5 w-5" /> : <Play className="mr-2 h-5 w-5" />}
                  {isActive ? 'Pause' : 'Start'}
                </Button>
                <Button size="lg" variant="secondary" onClick={handleReset} disabled={isActive || isFinished}>
                  <RotateCcw className="mr-2 h-5 w-5" />
                  Reset
                </Button>
                <Button size="lg" variant="outline" onClick={handleFinish} disabled={!isActive && timer === 0}>
                  Finish Session
                </Button>
              </>
            ) : (
              <Button size="lg" variant="secondary" onClick={handleReset}>
                <RotateCcw className="mr-2 h-5 w-5" />
                Start New Session
              </Button>
            )}
          </CardFooter>
      </Card>

      <div className="max-w-3xl mx-auto p-4">
        <div className="mb-8">
          <h1 className="text-3xl font-bold mb-2">{EXERCISE_NAME}</h1>
          <p className="text-gray-600">
            Track your running time and distance to improve your cardiovascular fitness.
          </p>
        </div>
        
        {success && (
          <div className="mb-6 p-4 bg-green-50 text-green-800 rounded-md">
            Exercise logged successfully! Redirecting to history...
          </div>
        )}
        
        {error && (
          <div className="mb-6 p-4 bg-red-50 text-red-800 rounded-md">
            {error}
          </div>
        )}
        
        <div className="bg-white rounded-lg shadow-md p-6">
          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Running Time (Minutes:Seconds)
              </label>
              <div className="flex space-x-2">
                <div className="w-1/2">
                  <input
                    type="number"
                    min="0"
                    value={minutes}
                    onChange={handleMinutesChange}
                    className="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                    placeholder="Minutes"
                    disabled={isSubmitting}
                    required
                  />
                </div>
                <div className="w-1/2">
                  <input
                    type="number"
                    min="0"
                    max="59"
                    value={seconds}
                    onChange={handleSecondsChange}
                    className="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                    placeholder="Seconds"
                    disabled={isSubmitting}
                    required
                  />
                </div>
              </div>
              <p className="mt-1 text-sm text-gray-500">
                Format: MM:SS (e.g., 13:30 for 13 minutes and 30 seconds)
              </p>
            </div>
            
            <div>
              <label htmlFor="distance" className="block text-sm font-medium text-gray-700 mb-1">
                Distance (Miles)
              </label>
              <input
                id="distance"
                type="number"
                min="0"
                step="0.01"
                value={distance}
                onChange={handleDistanceChange}
                className="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                placeholder="2.0"
                disabled={isSubmitting}
              />
              <p className="mt-1 text-sm text-gray-500">
                Enter distance in miles (e.g., 2.0 for a 2-mile run)
              </p>
            </div>
            
            <div>
              <label htmlFor="notes" className="block text-sm font-medium text-gray-700 mb-1">
                Notes (Optional)
              </label>
              <textarea
                id="notes"
                value={notes}
                onChange={handleNotesChange}
                rows={3}
                className="block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                disabled={isSubmitting}
                placeholder="Add any notes about this run..."
              />
            </div>
            
            <div className="flex items-center justify-between pt-4">
              <div>
                {getTotalSeconds() > 0 && (
                  <div className="text-sm text-gray-500">
                    Logged time: {formatTimeForDisplay()}
                  </div>
                )}
              </div>
              <button
                type="submit"
                disabled={isSubmitting || getTotalSeconds() <= 0}
                className="inline-flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
              >
                {isSubmitting ? 'Logging...' : 'Log Exercise'}
              </button>
            </div>
          </form>
        </div>
        
        <div className="mt-8 p-4 bg-gray-50 rounded-md">
          <h2 className="text-lg font-medium mb-2">Running Tips</h2>
          <ul className="list-disc pl-5 space-y-1">
            <li>Warm up with dynamic stretching before your run</li>
            <li>Maintain good posture with shoulders relaxed and back straight</li>
            <li>Focus on a steady, consistent pace rather than starting too fast</li>
            <li>Land midfoot rather than on your heels or toes</li>
            <li>Cool down with a slower pace at the end of your run</li>
            <li>Stay hydrated before, during, and after your run</li>
          </ul>
        </div>
      </div>
    </div>
  );
};

export default RunningTracker; 