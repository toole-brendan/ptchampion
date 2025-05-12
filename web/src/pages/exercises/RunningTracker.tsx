/**
 * Running Tracker - Canonical Component
 * 
 * This is the canonical source for running tracking used by both:
 * - /exercises/running
 * - /trackers/running (legacy redirect)
 * 
 * Any modifications should be made to this file only.
 */

import React, { useRef, useEffect, useState } from 'react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Alert, AlertTitle, AlertDescription } from "@/components/ui/alert";
import { Play, Pause, RotateCcw, Timer, MapPin, Flag, Loader2 } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
// Import mapping components
import { MapContainer, TileLayer, Polyline, Marker, Popup } from 'react-leaflet';
import L from 'leaflet'; // Import Leaflet library itself for icon customization

// Import our ViewModel hook
import { useRunningTrackerViewModel } from '../../viewmodels/RunningTrackerViewModel';
import { SessionStatus, TrackerErrorType, ExerciseResult } from '../../viewmodels/TrackerViewModel';
import { ExerciseType } from '@/grading';

// Import HUD component
import HUD from '@/components/workout/HUD';

// Fix leaflet's default icon path issue with bundlers like Vite
// eslint-disable-next-line @typescript-eslint/no-explicit-any
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});

// Create custom colored markers for start and end points
const startIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-green.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41]
});

const endIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41]
});

// Placeholder type for coordinates
type LatLngTuple = [number, number];

const RunningTracker: React.FC = () => {
  const navigate = useNavigate();
  const mapRef = useRef<L.Map>(null); // Ref for map instance

  // Use our ViewModel hook to manage the tracking state
  const {
    distance,
    distanceMiles,
    timer,
    status,
    coordinates, // Fixed: use coordinates from the ViewModel
    currentPosition,
    pace,
    error,
    formattedTime,
    initialize,
    startSession,
    pauseSession,
    finishSession,
    resetSession,
    saveResults
  } = useRunningTrackerViewModel();

  // Local state for form handling
  const [formMinutes, setFormMinutes] = useState<number>(0);
  const [formSeconds, setFormSeconds] = useState<number>(0);
  const [formDistance, setFormDistance] = useState<number>(0);
  const [notes, setNotes] = useState<string>('');

  // Derived state
  const isActive = status === SessionStatus.ACTIVE;
  const isFinished = status === SessionStatus.COMPLETED;
  const geoError = error && error.type === TrackerErrorType.LOCATION_PERMISSION ? error.message : null;
  const permissionGranted = !(error && error.type === TrackerErrorType.LOCATION_PERMISSION);
  
  // API state (could be moved to ViewModel)
  const [isSubmitting, setIsSubmitting] = React.useState(false);
  const [apiError, setApiError] = React.useState<string | null>(null);
  const [success, setSuccess] = React.useState(false);
  const [loggedGrade, setLoggedGrade] = React.useState<number | null>(null);
  
  // Constants for this exercise
  const EXERCISE_NAME = '2-Mile Run';

  // Initialize the geolocation on component mount
  useEffect(() => {
    initialize();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Handle back navigation
  const handleBackNavigation = () => {
    // Use window.history to check if we can go back
    if (window.history.length > 1) {
      navigate(-1); // Go back to previous page if possible
    } else {
      navigate('/exercises'); // Otherwise go to exercises page
    }
  };

  // Center map on current position when it changes
  useEffect(() => {
    if (currentPosition && mapRef.current) {
      mapRef.current.setView(currentPosition, 16); // Zoom level 16
    }
  }, [currentPosition]);

  // Update form fields when session is finished
  useEffect(() => {
    if (isFinished) {
      setFormMinutes(Math.floor(timer / 60));
      setFormSeconds(timer % 60);
      setFormDistance(parseFloat(distanceMiles.toFixed(2)));
    }
  }, [isFinished, timer, distanceMiles]);

  // Control handlers delegating to ViewModel
  const handleStartPause = () => {
    if (isFinished) return;
    
    if (isActive) {
      pauseSession();
    } else {
      startSession();
    }
  };

  const handleFinish = async () => {
    if (isActive) {
      pauseSession();
    }
    
    const result = await finishSession() as ExerciseResult;
    
    console.log(`Run finished! Distance: ${distanceMiles.toFixed(2)} miles, Time: ${formattedTime}`);
    
    // Create workout summary object
    const workoutSummary = {
      exerciseType: 'RUNNING',
      distance: distanceMiles,
      duration: timer,
      pace: pace,
      date: new Date(),
      saved: false
    };

    // Navigate to workout complete page with initial "not saved" state
    navigate('/complete', { state: workoutSummary });
    
    // Save workout session data in background
    if (distanceMiles > 0) {
      setIsSubmitting(true);
      setApiError(null);
      setSuccess(false);
      setLoggedGrade(null);
      
      try {
        const saved = await saveResults();
        if (saved) {
          setSuccess(true);
          
          // Use type assertion to handle the potential string or number grade
          setLoggedGrade(typeof result.grade === 'number' ? result.grade : null);
          
          // Update the page with saved status
          navigate('/complete', { 
            state: { 
              ...workoutSummary, 
              grade: result.grade,
              saved: saved,
              id: result.id
            },
            replace: true
          });
        } else {
          throw new Error("Failed to save results");
        }
      } catch (err) {
        console.error("Failed to log exercise:", err);
        setApiError(err instanceof Error ? err.message : 'Failed to save workout session');
        setSuccess(false);
        setLoggedGrade(null);
      } finally {
        setIsSubmitting(false);
      }
    } else if (distanceMiles === 0 && isFinished) {
      console.log("No distance tracked, session not saved.");
      handleReset();
    }
  };

  const handleReset = () => {
    resetSession();
    setApiError(null);
    setSuccess(false);
    setIsSubmitting(false);
    setLoggedGrade(null);
    setFormMinutes(0);
    setFormSeconds(0);
    setFormDistance(0);
    setNotes('');
  };
  
  // Form Handlers
  const handleMinutesChange = (value: number) => {
    if (!isNaN(value) && value >= 0) {
      setFormMinutes(value);
    }
  };
  
  const handleSecondsChange = (value: number) => {
    if (!isNaN(value) && value >= 0 && value < 60) {
      setFormSeconds(value);
    }
  };
  
  const handleDistanceChange = (value: number) => {
    if (!isNaN(value) && value >= 0) {
      setFormDistance(value);
    }
  };
  
  const handleNotesChange = (value: string) => {
    setNotes(value);
  };
  
  // Form Submission Logic
  const getTotalSecondsFromForm = (): number => {
    return (formMinutes * 60) + formSeconds;
  };
  
  const formatTimeForDisplay = (): string => {
    const displayMinutes = formMinutes.toString().padStart(2, '0');
    const displaySeconds = formSeconds.toString().padStart(2, '0');
    return `${displayMinutes}:${displaySeconds}`;
  };
  
  // Helper to calculate pace from time and distance
  const calculatePace = (seconds: number, miles: number): string => {
    if (miles <= 0) return "--:--";
    
    const paceSeconds = Math.round(seconds / miles);
    const paceMinutes = Math.floor(paceSeconds / 60);
    const paceRemainder = paceSeconds % 60;
    
    return `${paceMinutes}:${paceRemainder.toString().padStart(2, '0')}`;
  };

  // For the form submission in RunningTracker
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    const totalSeconds = getTotalSecondsFromForm();
    if (totalSeconds <= 0) {
      setApiError('Please enter a valid time (or track a run)');
      return;
    }
    if (formDistance <= 0) {
      setApiError('Please enter a valid distance (or track a run)');
      return;
    }
    
    // Create workout summary object for manual entry
    const workoutSummary = {
      exerciseType: 'RUNNING' as ExerciseType,
      distance: formDistance,
      duration: totalSeconds,
      // Calculate pace based on time and distance
      pace: calculatePace(totalSeconds, formDistance),
      notes: notes,
      date: new Date(),
      saved: false
    };
    
    // Navigate immediately to complete page
    navigate('/complete', { state: workoutSummary });
    
    setIsSubmitting(true);
    setApiError(null);
    setSuccess(false);
    setLoggedGrade(null); // Clear previous grade on new submission attempt
    
    try {
      const result = await saveResults();
      if (result) {
        setSuccess(true);
        
        // Exercise result might have a grade property
        const resultObject = result as unknown as { grade?: number, id?: string };
        const grade = typeof resultObject.grade === 'number' ? resultObject.grade : null;
        setLoggedGrade(grade);
        
        // Update the completion page with saved status
        navigate('/complete', { 
          state: { 
            ...workoutSummary,
            grade: grade,
            saved: true,
            id: resultObject.id
          },
          replace: true
        });
      } else {
        throw new Error("Failed to save results");
      }
    } catch (err) {
      setApiError(err instanceof Error ? err.message : 'Failed to log exercise');
      setSuccess(false);
      setLoggedGrade(null);
    } finally {
      setIsSubmitting(false);
    }
  };

  // Get start and end points for markers
  const startPoint = coordinates.length > 0 ? coordinates[0] : null;
  const endPoint = isFinished && coordinates.length > 1 ? coordinates[coordinates.length - 1] : null;

  return (
    <div className="space-y-6">
      <Button variant="outline" onClick={handleBackNavigation} className="mb-4">
        &larr; Back
      </Button>
      <h1 className="font-semibold text-3xl text-foreground">Running Exercise</h1>

      {/* Display error alert if geolocation permission denied */}
      {geoError && !isActive && (
        <Alert variant="destructive" className="mb-4">
          <AlertTitle>Location Access Denied</AlertTitle>
          <AlertDescription>
            {geoError || "Cannot track your run without location access. Please enable location services and reload the page."}
          </AlertDescription>
        </Alert>
      )}

      <Card className="overflow-hidden rounded-lg bg-card shadow-sm">
        <CardHeader>
          <CardTitle className="text-lg font-medium">Track Your Run</CardTitle>
          <CardDescription>Start the timer to begin tracking distance and path.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Map Integration */}
          <div className="relative h-64 md:h-80 w-full overflow-hidden rounded-md bg-muted">
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
              {coordinates.length > 0 && (
                <Polyline pathOptions={{ color: 'blue', weight: 4 }} positions={coordinates as unknown as LatLngTuple[]} />
              )}
              {currentPosition && !isFinished && (
                <Marker position={currentPosition as unknown as LatLngTuple}>
                  <Popup>Current Location</Popup>
                </Marker>
              )}
              {/* Start marker */}
              {startPoint && (
                <Marker 
                  position={[startPoint.lat, startPoint.lng] as unknown as LatLngTuple} 
                  icon={startIcon}
                >
                  <Popup>Start Point</Popup>
                </Marker>
              )}
              {/* End marker */}
              {endPoint && (
                <Marker 
                  position={[endPoint.lat, endPoint.lng] as unknown as LatLngTuple}
                  icon={endIcon}
                >
                  <Popup>End Point</Popup>
                </Marker>
              )}
            </MapContainer>

            {/* Use the HUD component for running */}
            {isActive && permissionGranted && (
              <HUD 
                repCount={0}
                formattedTime={formattedTime}
                formFeedback={null}
                pace={pace}
                distance={distanceMiles}
                isRunning={true}
              />
            )}
            
            {/* Show overlay if permission denied */} 
            {!permissionGranted && !isActive && (
               <div className="absolute inset-0 z-10 flex flex-col items-center justify-center bg-black/70 p-4 text-center text-white">
                 <MapPin className="mb-2 size-12 text-destructive" />
                 <p className="mb-1 font-semibold">Location Access Issue</p>
                 <p className="text-sm">{geoError}</p>
               </div>
            )}
          </div>

          {/* Stats Display */}
          <div className="grid grid-cols-3 gap-4 text-center">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Distance</p>
              <p className="font-bold text-4xl text-foreground">
                 {distanceMiles.toFixed(2)} <span className="text-xl font-normal">miles</span>
              </p>
            </div>
            <div>
              <p className="text-sm font-medium text-muted-foreground">Time</p>
              <p className="flex items-center justify-center font-bold text-4xl text-foreground">
                <Timer className="mr-1 inline-block size-6" />
                {formattedTime}
              </p>
            </div>
            <div>
              <p className="text-sm font-medium text-muted-foreground">Pace</p>
              <p className="font-bold text-4xl text-foreground">
                {pace}
              </p>
            </div>
          </div>
        </CardContent>
        <CardFooter className="bg-background/50 flex justify-center space-x-4 border-t px-6 py-4">
            {!isFinished ? (
              <>
                <Button 
                  size="lg" 
                  onClick={handleStartPause} 
                  disabled={isFinished || (isActive && !permissionGranted) || !permissionGranted}
                >
                  {isActive ? <Pause className="mr-2 size-5" /> : <Play className="mr-2 size-5" />}
                  {isActive ? 'Pause' : 'Start'}
                </Button>
                <Button 
                  size="lg" 
                  variant="secondary" 
                  onClick={handleReset} 
                  disabled={isActive || isFinished || (timer === 0 && distance === 0)}
                >
                  <RotateCcw className="mr-2 size-5" />
                  Reset
                </Button>
                <Button 
                  size="lg" 
                  variant="outline"
                  onClick={handleFinish} 
                  disabled={(!isActive && timer === 0) || isFinished || distance === 0}
                >
                  <Flag className="mr-2 size-5" />
                  Finish Run
                </Button>
              </>
            ) : (
              <Button size="lg" variant="secondary" onClick={handleReset}>
                <RotateCcw className="mr-2 size-5" />
                Start New Run
              </Button>
            )}
          </CardFooter>
      </Card>

      {/* --- Log Submission Section --- */}
      <div className="mx-auto max-w-3xl p-4">
        <div className="mb-8">
          <h1 className="mb-2 font-bold text-3xl">Log Your {EXERCISE_NAME}</h1>
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
            Redirecting to summary...
          </div>
        )}
        
        {apiError && (
          <div className="mb-6 rounded-md bg-red-50 p-4 text-red-800">
            {apiError}
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
                    value={formMinutes}
                    onChange={(e) => handleMinutesChange(parseInt(e.target.value))}
                    className="block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 disabled:bg-gray-100"
                    placeholder="Minutes"
                    disabled={isSubmitting || (isFinished && !success)}
                    required
                  />
                </div>
                <div className="w-1/2">
                  <input
                    type="number"
                    min="0"
                    max="59"
                    value={formSeconds}
                    onChange={(e) => handleSecondsChange(parseInt(e.target.value))}
                    className="block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 disabled:bg-gray-100"
                    placeholder="Seconds"
                    disabled={isSubmitting || (isFinished && !success)}
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
                value={formDistance}
                onChange={(e) => handleDistanceChange(parseFloat(e.target.value))}
                className="block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 disabled:bg-gray-100"
                placeholder="2.0"
                disabled={isSubmitting || (isFinished && !success)}
                required
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
                onChange={(e) => handleNotesChange(e.target.value)}
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
                {isSubmitting ? <Loader2 className="mr-2 size-4 animate-spin" /> : null}
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