/**
 * Pullup Tracker - Canonical Component
 * 
 * This is the canonical source for pull-up tracking used by both:
 * - /exercises/pullups
 * - /trackers/pullups (legacy redirect)
 * 
 * Any modifications should be made to this file only.
 */

import React, { useRef, useEffect } from 'react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Camera, Play, Pause, RotateCcw, Timer, VideoOff, Loader2 } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../lib/authContext';
import { calculatePullupScore, formatScoreDisplay } from '../../grading/APFTScoring';

// Import our ViewModel hook
import { usePullupTrackerViewModel } from '../../viewmodels/PullupTrackerViewModel';
import { SessionStatus, TrackerErrorType } from '../../viewmodels/TrackerViewModel';

// --- Pull-up specific logic constants (adjust as needed for UI display) ---
const PULLUP_THRESHOLD_ELBOW_ANGLE_DOWN = 160; // Angle for fully extended arms at bottom
const CHIN_OVER_BAR_VERTICAL_THRESHOLD = 0.05; // For UI display only
const KIPPING_VERTICAL_THRESHOLD = 0.15; // For UI display only

const PullupTracker: React.FC = () => {
  const navigate = useNavigate();
  const auth = useAuth();
  const user = auth?.user;

  // References for video and canvas elements
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);

  // Use our ViewModel hook to manage the tracking state
  const {
    repCount,
    timer,
    status,
    formScore,
    formFeedback,
    error,
    formattedTime,
    initialize,
    startSession,
    pauseSession,
    finishSession,
    resetSession,
    saveResults
  } = usePullupTrackerViewModel();

  // Mark unused variables with eslint disable comments
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const unusedTimer = timer;
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const unusedFormScore = formScore;

  // Derived state
  const isActive = status === SessionStatus.ACTIVE;
  const isFinished = status === SessionStatus.COMPLETED;
  const isModelLoading = status === SessionStatus.INITIALIZING;
  const modelError = error?.type === TrackerErrorType.MODEL_LOAD_FAILED ? error.message : null;
  const cameraError = error?.type === TrackerErrorType.CAMERA_NOT_FOUND ? error.message : null;
  const permissionGranted = !(error?.type === TrackerErrorType.CAMERA_NOT_FOUND || error?.type === TrackerErrorType.CAMERA_PERMISSION);

  // API state (could be moved to ViewModel)
  const [isSubmitting, setIsSubmitting] = React.useState(false);
  const [apiError, setApiError] = React.useState<string | null>(null);
  const [success, setSuccess] = React.useState(false);
  const [loggedGrade, setLoggedGrade] = React.useState<number | null>(null);
  const [pullupScore, setPullupScore] = React.useState(0);

  // Constants for this exercise
  const EXERCISE_NAME = 'Pull-ups';

  // Handle back navigation
  const handleBackNavigation = () => {
    // Use window.history to check if we can go back
    if (window.history.length > 1) {
      navigate(-1); // Go back to previous page if possible
    } else {
      navigate('/exercises'); // Otherwise go to exercises page
    }
  };

  // Initialize the tracker when component mounts
  useEffect(() => {
    const initTracker = async () => {
      await initialize(videoRef, canvasRef);
    };
    initTracker();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Update APFT score when rep count changes
  useEffect(() => {
    if (repCount > 0) {
      const score = calculatePullupScore(repCount);
      setPullupScore(score);
    } else {
      setPullupScore(0);
    }
  }, [repCount]);

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
    
    const result = await finishSession();
    
    // Calculate final APFT score
    const finalScore = calculatePullupScore(repCount);
    setPullupScore(finalScore);
    
    console.log(`Workout finished! Reps: ${repCount}, Time: ${formattedTime}, APFT Score: ${finalScore}`);

    // Save workout session data
    if (repCount > 0 && user) {
      setIsSubmitting(true);
      setApiError(null);
      setSuccess(false);
      setLoggedGrade(null);
      
      try {
        const saved = await saveResults();
        if (saved && result.grade !== undefined) {
          setSuccess(true);
          setLoggedGrade(typeof result.grade === 'number' ? result.grade : null);
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
    } else if (repCount === 0 && isFinished) {
      console.log("No reps counted, session not saved.");
      handleReset();
    } else if (!user) {
      setApiError("You must be logged in to save results.");
      console.warn("Attempted to save workout while not logged in.");
    }
  };

  const handleReset = () => {
    resetSession();
    setApiError(null);
    setSuccess(false);
    setIsSubmitting(false);
    setLoggedGrade(null);
    setPullupScore(0);
  };

  // --- JSX Structure ---
  return (
    <div className="space-y-6">
      <Button variant="outline" onClick={handleBackNavigation} className="mb-4">
        &larr; Back
      </Button>
      <h1 className="text-3xl font-semibold text-foreground">{EXERCISE_NAME} Exercise</h1>

      <Card className="overflow-hidden rounded-lg bg-card shadow-sm">
        <CardHeader>
          <CardTitle className="text-lg font-medium">Live Tracking</CardTitle>
          <CardDescription>Position yourself correctly for the camera and press Start.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Camera Feed Section */}
          <div className="relative aspect-video overflow-hidden rounded-md bg-muted">
            <video
              ref={videoRef}
              autoPlay
              playsInline
              className="size-full object-cover"
              muted
              onLoadedMetadata={() => console.log("Video metadata loaded.")}
            />
            <canvas
              ref={canvasRef}
              className="absolute left-0 top-0 size-full"
            />
            {/* Form Fault Message Overlay */} 
            {formFeedback && (
              <div className="absolute bottom-4 left-1/2 z-20 -translate-x-1/2 rounded-md bg-destructive/80 px-4 py-2 text-sm font-semibold text-white">
                {formFeedback}
              </div>
            )}
            {/* Overlay messages (Loading, Errors, Permissions) */}
            {isModelLoading && (
              <div className="absolute inset-0 z-10 flex flex-col items-center justify-center bg-black/60 text-white">
                <Loader2 className="mb-3 size-10 animate-spin" /><span>Loading AI Model...</span>
              </div>
            )}
            {!isModelLoading && modelError && (
               <div className="absolute inset-0 z-10 flex flex-col items-center justify-center bg-destructive/80 p-4 text-center text-white">
                <VideoOff className="mb-2 size-12" /><p className="mb-1 font-semibold">Model Failed</p><p className="text-sm">{modelError}</p>
              </div>
            )}
            {status === SessionStatus.INITIALIZING && !modelError && (
              <div className="absolute inset-0 flex items-center justify-center bg-black/50 text-white">
                <Camera className="mr-2 size-8 animate-pulse" /><span>Requesting camera...</span>
              </div>
            )}
            {!permissionGranted && !isModelLoading && !modelError && (
              <div className="absolute inset-0 flex flex-col items-center justify-center bg-black/70 p-4 text-center text-white">
                <VideoOff className="mb-2 size-12 text-destructive" /><p className="mb-1 font-semibold">Camera Issue</p><p className="text-sm">{cameraError || "Could not access camera."}</p>
              </div>
            )}
          </div>

          {/* Stats Display */}
          <div className="grid grid-cols-3 gap-4 text-center">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Reps</p>
              <p className="text-4xl font-bold text-foreground">{repCount}</p>
            </div>
            <div>
              <p className="text-sm font-medium text-muted-foreground">Time</p>
              <p className="flex items-center justify-center text-4xl font-bold text-foreground">
                <Timer className="mr-1 inline-block size-6" />{formattedTime}
              </p>
            </div>
            <div>
              <p className="text-sm font-medium text-muted-foreground">APFT Score</p>
              <p className="text-4xl font-bold text-foreground">{pullupScore}</p>
            </div>
          </div>

          {/* New Instructions Section for Pull-ups */}
          <div className="border-t pt-4">
            <h3 className="mb-2 text-base font-semibold text-foreground">Form Requirements for Rep Count:</h3>
            <ul className="list-disc space-y-1 pl-5 text-sm text-muted-foreground">
              <li>
                <strong>Camera:</strong> Place ideally side-on or front-on, ensuring your full body and the bar are visible.
              </li>
               <li>
                <strong>Grip:</strong> Use an overhand grip (palms facing away). <span className="italic">(Note: AI cannot reliably verify palm direction).</span>
              </li>
              <li>
                <strong>Start:</strong> Begin from a dead hang (arms fully extended, elbows ~{PULLUP_THRESHOLD_ELBOW_ANGLE_DOWN}°).
              </li>
              <li>
                <strong>Movement:</strong> Pull up until your chin is clearly above the bar level (relative vertical position &gt; {CHIN_OVER_BAR_VERTICAL_THRESHOLD}). Lower back down to full extension.
              </li>
               <li>
                <strong>Kipping:</strong> Minimize swinging or using leg momentum. Excessive vertical hip movement ( &gt; {KIPPING_VERTICAL_THRESHOLD} relative units) will invalidate the rep.
              </li>
              <li>
                <strong>Rep Counts:</strong> Only full-range reps with good form (chin over bar, full extension, minimal kipping) are counted.
              </li>
            </ul>
          </div>
        </CardContent>
        <CardFooter className="flex flex-wrap justify-center gap-4 border-t bg-background/50 px-6 py-4">
            {/* Controls */}
             {!isFinished ? (
              <>
                <Button size="lg" onClick={handleStartPause} disabled={isFinished || !permissionGranted || !!cameraError || isModelLoading || !!modelError}>
                  {isModelLoading ? <Loader2 className="mr-2 size-5 animate-spin" /> : (isActive ? <Pause className="mr-2 size-5" /> : <Play className="mr-2 size-5" />)}
                  {isModelLoading ? 'Loading...' : (isActive ? 'Pause' : 'Start')}
                </Button>
                <Button size="lg" variant="secondary" onClick={handleReset} disabled={isActive || isFinished || (!permissionGranted && !cameraError && !isModelLoading)}>
                  <RotateCcw className="mr-2 size-5" /> Reset
                </Button>
                <Button size="lg" variant="destructive" onClick={handleFinish} disabled={isActive || isFinished || repCount === 0} >
                   {isSubmitting ? <Loader2 className="mr-2 size-5 animate-spin" /> : null}
                   Finish & Save
                </Button>
              </>
            ) : (
                 <div className="w-full text-center">
                    {isSubmitting && <p className="flex items-center justify-center"><Loader2 className="mr-2 size-4 animate-spin" /> Saving...</p>}
                    {apiError && !isSubmitting && <p className="mt-2 text-sm text-destructive">Error Saving: {apiError}</p>}
                    {success && !isSubmitting && (
                      <p className="mt-2 text-sm text-green-600">
                        Workout saved successfully!
                        {loggedGrade !== null && ` Grade: ${loggedGrade}`}
                      </p>
                    )}
                    {!isSubmitting && !apiError && !success && <p>Workout Complete! Press Reset to start again.</p>}
                    <Button size="lg" variant="outline" onClick={handleReset} className="mt-4">
                        Reset Exercise
                    </Button>
                 </div>
            )}
        </CardFooter>
      </Card>

      {isFinished && (
        <div className="mt-4 w-full rounded-lg bg-muted p-4">
          <h3 className="mb-2 text-lg font-semibold">Workout Summary</h3>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-muted-foreground">Total Reps</p>
              <p className="text-2xl font-semibold">{repCount}</p>
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Total Time</p>
              <p className="text-2xl font-semibold">{formattedTime}</p>
            </div>
            <div>
              <p className="text-sm text-muted-foreground">APFT Score</p>
              <p className="text-2xl font-semibold">{pullupScore}</p>
            </div>
            <div>
              <p className="text-sm text-muted-foreground">Rep-to-Score</p>
              <p className="text-2xl font-semibold">{formatScoreDisplay(repCount, pullupScore)}</p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default PullupTracker; 