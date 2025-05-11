/**
 * Running Tracker - Canonical Component
 * 
 * This is the canonical source for running tracking used by both:
 * - /exercises/running
 * - /trackers/running
 * 
 * Any modifications should be made to this file only.
 */

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
import { LogExerciseRequest, ExerciseResponse } from '../../lib/types';

// Fix leaflet's default icon path issue with bundlers like Vite
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});

// Placeholder type for coordinates
type LatLngTuple = [number, number];

// Haversine formula to calculate distance between two points in miles
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 3959; // Radius of the Earth in miles
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
  const [distance, setDistance] = useState(0); // Distance in MILES
  const [timer, setTimer] = useState(0); // Timer in seconds
  const [isActive, setIsActive] = useState(false);
  const [isFinished, setIsFinished] = useState(false); // Indicates tracking is done, form might be pre-filled
  const [pathCoordinates, setPathCoordinates] = useState<LatLngTuple[]>([]);
  const [currentPosition, setCurrentPosition] = useState<LatLngTuple | null>(null);
  const [geoError, setGeoError] = useState<string | null>(null);
  const [permissionGranted, setPermissionGranted] = useState<boolean | null>(null);

  const timerIntervalRef = useRef<NodeJS.Timeout | null>(null);
  const watchIdRef = useRef<number | null>(null);
  const mapRef = useRef<L.Map>(null); // Ref for map instance

  // --- State for the Manual/Submission Form ---
  // These will be pre-filled by the tracker when finished, or manually entered otherwise
  const [formMinutes, setFormMinutes] = useState<number>(0);
  const [formSeconds, setFormSeconds] = useState<number>(0);
  const [formDistance, setFormDistance] = useState<number>(0); // Distance in MILES for the form
  const [notes, setNotes] = useState<string>('');
  
  // UI state
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const [loggedGrade, setLoggedGrade] = useState<number | null>(null); // State to hold the returned grade
  
  // Constants for this exercise (TODO: Should be passed dynamically)
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
              // Accumulate distance in miles
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

  // Timer logic
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
    if (isFinished) return; // Don't allow start/pause if already finished and pending submission
    setIsActive(!isActive);
    console.log(isActive ? "Pausing Run Tracking..." : "Starting Run Tracking...");
  };

  const handleFinish = () => {
    setIsActive(false);
    setIsFinished(true); // Mark as finished, ready to log

    // Stop geolocation watch if active
    if (watchIdRef.current !== null) {
      navigator.geolocation.clearWatch(watchIdRef.current);
      watchIdRef.current = null;
    }

    // Pre-fill form state with tracked values
    const trackedMinutes = Math.floor(timer / 60);
    const trackedSeconds = timer % 60;
    setFormMinutes(trackedMinutes);
    setFormSeconds(trackedSeconds);
    // Ensure distance is rounded reasonably for the form
    setFormDistance(parseFloat(distance.toFixed(2))); 

    console.log(`Run finished! Distance: ${distance.toFixed(2)} miles, Time: ${formatTime(timer)}`);
    // Removed alert, form is now pre-filled
  };

  const handleReset = () => {
    setIsActive(false);
    setIsFinished(false);
    setDistance(0); // Reset live tracker distance
    setTimer(0);    // Reset live tracker timer
    setPathCoordinates([]);
    setCurrentPosition(null);
    setGeoError(null);
    setPermissionGranted(null); // Re-check permission on next start attempt
    
    // Reset form fields
    setFormMinutes(0);
    setFormSeconds(0);
    setFormDistance(0);
    setNotes('');
    setError(null);
    setSuccess(false);
    setIsSubmitting(false);
    setLoggedGrade(null); // Reset logged grade

    if (watchIdRef.current !== null) {
        navigator.geolocation.clearWatch(watchIdRef.current);
        watchIdRef.current = null;
    }
    console.log("Resetting Run Tracker state and form...");
  };

  const formatTime = (timeInSeconds: number): string => {
    const minutes = Math.floor(timeInSeconds / 60).toString().padStart(2, '0');
    const seconds = (timeInSeconds % 60).toString().padStart(2, '0');
    return `${minutes}:${seconds}`;
  };

  // --- Form Input Handlers ---
  const handleMinutesChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = parseInt(e.target.value);
    if (!isNaN(value) && value >= 0) {
      setFormMinutes(value);
    }
  };
  
  const handleSecondsChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = parseInt(e.target.value);
    if (!isNaN(value) && value >= 0 && value < 60) {
      setFormSeconds(value);
    }
  };
  
  const handleDistanceChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = parseFloat(e.target.value);
    if (!isNaN(value) && value >= 0) {
      setFormDistance(value);
    }
  };
  
  const handleNotesChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setNotes(e.target.value);
  };
  
  // --- Form Submission Logic ---
  const getTotalSecondsFromForm = (): number => {
    return (formMinutes * 60) + formSeconds;
  };
  
  const formatTimeForDisplay = (): string => {
    const formattedMinutes = formMinutes.toString().padStart(2, '0');
    const formattedSeconds = formSeconds.toString().padStart(2, '0');
    return `${formattedMinutes}:${formattedSeconds}`;
  };
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    const totalSeconds = getTotalSecondsFromForm();
    if (totalSeconds <= 0) {
      setError('Please enter a valid time (or track a run)');
      return;
    }
    if (formDistance <= 0) {
      setError('Please enter a valid distance (or track a run)');
      return;
    }
    
    // Convert form distance (miles) to meters for the API
    const distanceMeters = Math.round(formDistance * 1609.34); 
    
    setIsSubmitting(true);
    setError(null);
    setSuccess(false);
    setLoggedGrade(null); // Clear previous grade on new submission attempt
    
    try {
      const exerciseData: LogExerciseRequest = {
        exercise_id: EXERCISE_ID,
        duration: totalSeconds, // Total seconds from form/tracked data
        distance: distanceMeters, // Distance in meters from form/tracked data
        notes: notes || undefined,
      };
      
      // Assume logExercise returns the LogExerciseResponse which includes the grade
      const response: ExerciseResponse = await logExercise(exerciseData); 
      
      setSuccess(true);
      setLoggedGrade(response.grade ?? null); // Store the returned grade, handle potential undefined

      // After 2 seconds, redirect to the history page
      setTimeout(() => {
        navigate('/history'); 
      }, 2000);
      
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to log exercise');
      setSuccess(false); // Ensure success is false on error
      setLoggedGrade(null); // Ensure grade is null on error
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

      <Card className="overflow-hidden rounded-lg bg-card shadow-sm">
        <CardHeader>
          <CardTitle className="text-lg font-medium">Track Your Run</CardTitle>
          <CardDescription>Start the timer to begin tracking distance and path.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Map Integration */}
          <div className="relative aspect-video overflow-hidden rounded-md bg-muted">
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
               <div className="absolute inset-0 z-10 flex flex-col items-center justify-center bg-black/70 p-4 text-center text-white">
                 <MapPin className="mb-2 size-12 text-destructive" />
                 <p className="mb-1 font-semibold">Location Access Issue</p>
                 <p className="text-sm">{geoError}</p>
               </div>
            )}
          </div>

          {/* Stats Display */}
          <div className="grid grid-cols-2 gap-4 text-center">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Distance</p>
              <p className="text-4xl font-bold text-foreground">
                 {distance.toFixed(2)} <span className="text-xl font-normal">miles</span>
              </p>
            </div>
            <div>
              <p className="text-sm font-medium text-muted-foreground">Time</p>
              <p className="flex items-center justify-center text-4xl font-bold text-foreground">
                <Timer className="mr-1 inline-block size-6" />
                {formatTime(timer)}
              </p>
            </div>
          </div>
        </CardContent>
        <CardFooter className="flex justify-center space-x-4 border-t bg-background/50 px-6 py-4">
            {!isFinished ? (
              <>
                <Button size="lg" onClick={handleStartPause} disabled={isFinished || (isActive && permissionGranted === false) }>
                  {isActive ? <Pause className="mr-2 size-5" /> : <Play className="mr-2 size-5" />}
                  {isActive ? 'Pause' : 'Start'}
                </Button>
                <Button size="lg" variant="secondary" onClick={handleReset} disabled={isActive || isFinished || timer > 0 || distance > 0}>
                  <RotateCcw className="mr-2 size-5" />
                  Reset
                </Button>
                <Button size="lg" variant="outline" onClick={handleFinish} disabled={(!isActive && timer === 0) || isFinished}>
                  Finish Session
                </Button>
              </>
            ) : (
              <Button size="lg" variant="secondary" onClick={handleReset}>
                <RotateCcw className="mr-2 size-5" />
                Start New Session
              </Button>
            )}
          </CardFooter>
      </Card>

      {/* --- Log Submission Section --- */}
      <div className="mx-auto max-w-3xl p-4">
        <div className="mb-8">
          <h1 className="mb-2 text-3xl font-bold">Log Your {EXERCISE_NAME}</h1>
          {isFinished && !success && (
             <p className="rounded-md border border-green-200 bg-green-50 p-3 text-green-600">
               Run tracked! Review the details below and click "Log Exercise" to save.
             </p>
          )}
          {!isFinished && !success && (
            <p className="text-gray-600">
              Complete the fields below to manually log your run, or use the tracker above.
            </p>
          )}
        </div>
        
        {success && (
          <div className="mb-6 rounded-md bg-green-50 p-4 text-green-800">
            Exercise logged successfully! 
            {loggedGrade !== null && ` Grade: ${loggedGrade}. `} 
            Redirecting to history...
          </div>
        )}
        
        {error && (
          <div className="mb-6 rounded-md bg-red-50 p-4 text-red-800">
            {error}
          </div>
        )}
        
        <div className="rounded-lg bg-white p-6 shadow-md">
          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label className="mb-1 block text-sm font-medium text-gray-700">
                Running Time (Minutes:Seconds)
              </label>
              <div className="flex space-x-2">
                <div className="w-1/2">
                  <input
                    type="number"
                    min="0"
                    value={formMinutes} // Use formMinutes state
                    onChange={handleMinutesChange}
                    className="block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 disabled:bg-gray-100"
                    placeholder="Minutes"
                    disabled={isSubmitting || (isFinished && !success)} // Disable if tracked data is shown and not yet submitted/succeeded
                    required
                  />
                </div>
                <div className="w-1/2">
                  <input
                    type="number"
                    min="0"
                    max="59"
                    value={formSeconds} // Use formSeconds state
                    onChange={handleSecondsChange}
                    className="block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 disabled:bg-gray-100"
                    placeholder="Seconds"
                    disabled={isSubmitting || (isFinished && !success)} // Disable if tracked data is shown
                    required
                  />
                </div>
              </div>
              <p className="mt-1 text-sm text-gray-500">
                {isFinished ? "Time from tracked run." : "Format: MM:SS (e.g., 13:30)"}
              </p>
            </div>
            
            <div>
              <label htmlFor="distance" className="mb-1 block text-sm font-medium text-gray-700">
                Distance (Miles)
              </label>
              <input
                id="distance"
                type="number"
                min="0"
                step="0.01"
                value={formDistance} // Use formDistance state
                onChange={handleDistanceChange}
                className="block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 disabled:bg-gray-100"
                placeholder="2.0"
                disabled={isSubmitting || (isFinished && !success)} // Disable if tracked data is shown
                required // Make distance required
              />
              <p className="mt-1 text-sm text-gray-500">
                {isFinished ? "Distance from tracked run." : "Enter distance in miles (e.g., 2.0)"}
              </p>
            </div>
            
            <div>
              <label htmlFor="notes" className="mb-1 block text-sm font-medium text-gray-700">
                Notes (Optional)
              </label>
              <textarea
                id="notes"
                value={notes}
                onChange={handleNotesChange}
                rows={3}
                className="block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500"
                disabled={isSubmitting}
                placeholder="Add any notes about this run..."
              />
            </div>
            
            <div className="flex items-center justify-between pt-4">
              <div>
                {getTotalSecondsFromForm() > 0 && (
                  <div className="text-sm text-gray-500">
                    {isFinished ? "Logged time from tracker:" : "Manually entered time:"} {formatTimeForDisplay()}
                  </div>
                )}
              </div>
              <button
                type="submit"
                disabled={isSubmitting || getTotalSecondsFromForm() <= 0 || formDistance <= 0 || success}
                className="inline-flex justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50"
              >
                {isSubmitting ? 'Logging...' : 'Log Exercise'}
              </button>
            </div>
          </form>
        </div>
        
        <div className="mt-8 rounded-md bg-gray-50 p-4">
          <h2 className="mb-2 text-lg font-medium">Running Tips</h2>
          <ul className="list-disc space-y-1 pl-5">
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