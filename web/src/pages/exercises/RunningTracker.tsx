/**
 * Running Tracker - Canonical Component
 * 
 * This is the canonical source for running tracking used by both:
 * - /exercises/running
 * - /trackers/running (legacy redirect)
 * 
 * Any modifications should be made to this file only.
 */

import React, { useEffect, useState } from 'react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Alert, AlertTitle, AlertDescription } from "@/components/ui/alert";
import { Play, Pause, RotateCcw, Timer, MapPin, Flag } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import L from 'leaflet';

// Import our ViewModel hook
import { useRunningTrackerViewModel } from '../../viewmodels/RunningTrackerViewModel';
import { SessionStatus, TrackerErrorType, ExerciseResult } from '../../viewmodels/TrackerViewModel';
import { ExerciseType } from '@/grading';

// Import split components
import { RunningMap } from '@/components/running/RunningMap';
import { RunningStats } from '@/components/running/RunningStats';
import { RunningForm } from '@/components/running/RunningForm';

// Fix leaflet's default icon path issue with bundlers like Vite
// eslint-disable-next-line @typescript-eslint/no-explicit-any
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});

const EXERCISE_NAME = "Two-Mile Run";

const RunningTracker: React.FC = () => {
  const navigate = useNavigate();

  // Use our ViewModel hook to manage the tracking state
  const {
    distance,
    distanceMiles,
    timer,
    status,
    coordinates,
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
  
  // Initialize the tracker once
  useEffect(() => {
    initialize();
  }, [initialize]);

  // Update form fields when a run is completed
  useEffect(() => {
    if (isFinished && timer > 0) {
      const totalMinutes = Math.floor(timer / 60);
      const totalSeconds = timer % 60;
      setFormMinutes(totalMinutes);
      setFormSeconds(totalSeconds);
      setFormDistance(distanceMiles);
    }
  }, [isFinished, timer, distanceMiles]);

  // --- Event Handlers ---
  const handleBackNavigation = () => {
    navigate('/exercises');
  };

  const handleStartPause = () => {
    if (isActive) {
      pauseSession();
    } else {
      startSession();
    }
  };

  const handleFinish = async () => {
    const result = await finishSession();
    
    if (result && distanceMiles > 0) {
      // Create workout summary for immediate navigation
      const workoutSummary = {
        exerciseType: result.exerciseType,
        distance: result.distance,
        duration: result.duration,
        pace: result.pace,
        notes: notes,
        date: result.date,
        saved: false
      };
      
      // Navigate immediately to complete page
      navigate('/complete', { state: workoutSummary });
      
      // Then save results in background
      setIsSubmitting(true);
      setApiError(null);
      setSuccess(false);
      setLoggedGrade(null); // Clear previous grade on new submission attempt
      
      try {
        const savedResult = await saveResults();
        if (savedResult) {
          setSuccess(true);
          
          // Exercise result might have a grade property
          const resultObject = savedResult as unknown as { grade?: number, id?: string };
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
          <RunningMap
            coordinates={coordinates}
            currentPosition={currentPosition}
            isActive={isActive}
            isFinished={isFinished}
            permissionGranted={permissionGranted}
            geoError={geoError}
            formattedTime={formattedTime}
            pace={pace}
            distanceMiles={distanceMiles}
          />

          {/* Stats Display */}
          <RunningStats
            distanceMiles={distanceMiles}
            formattedTime={formattedTime}
            pace={pace}
          />
        </CardContent>
        <CardFooter className="flex justify-center space-x-4 border-t bg-background/50 px-6 py-4">
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
      <RunningForm
        formMinutes={formMinutes}
        formSeconds={formSeconds}
        formDistance={formDistance}
        notes={notes}
        isSubmitting={isSubmitting}
        isFinished={isFinished}
        success={success}
        apiError={apiError}
        loggedGrade={loggedGrade}
        onMinutesChange={handleMinutesChange}
        onSecondsChange={handleSecondsChange}
        onDistanceChange={handleDistanceChange}
        onNotesChange={handleNotesChange}
        onSubmit={handleSubmit}
        getTotalSecondsFromForm={getTotalSecondsFromForm}
        formatTimeForDisplay={formatTimeForDisplay}
      />
    </div>
  );
};

export default RunningTracker;