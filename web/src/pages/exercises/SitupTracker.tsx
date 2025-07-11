/**
 * Situp Tracker - Canonical Component
 * 
 * This is the canonical source for sit-up tracking used by both:
 * - /exercises/situps
 * - /trackers/situps (legacy redirect)
 * 
 * Any modifications should be made to this file only.
 */

import React, { useRef, useEffect, useState } from 'react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft, Play, Pause, RotateCcw, Timer, VideoOff, Loader2, Camera } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../lib/authContext';
import { calculateSitupScore } from '../../grading/APFTScoring';
import { useDeviceCapabilities } from '@/lib/hooks/useDeviceCapabilities';

// Import our ViewModel hook
import { useSitupTrackerViewModel } from '../../viewmodels/SitupTrackerViewModel';
import { SessionStatus, TrackerErrorType } from '../../viewmodels/TrackerViewModel';

// Import new UI components
import HUD from '@/components/workout/HUD';
import SessionControls from '@/components/workout/SessionControls';

// Add a constant to enable the new BlazePose model
// Set to true to use the new BlazePose detector, false to use legacy
const USE_BLAZEPOSE_DETECTOR = true;

const SitupTracker: React.FC = () => {
  const navigate = useNavigate();
  const auth = useAuth();
  const user = auth?.user;

  // References for video and canvas elements
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  
  // Fullscreen state
  const [isFullscreen, setIsFullscreen] = useState(false);

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
    saveResults,
    flipCamera,
    setTimerExpiredCallback
  } = useSitupTrackerViewModel(USE_BLAZEPOSE_DETECTOR);

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
  const [situpScore, setSitupScore] = React.useState(0);

  // Constants for this exercise
  const EXERCISE_NAME = 'Sit-ups';
  const SITUP_THRESHOLD_ANGLE_DOWN = 160; // Get from analyzer in the future
  const SITUP_THRESHOLD_ANGLE_UP = 80;  // Get from analyzer in the future

  const capabilities = useDeviceCapabilities();
  const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);

  // Handle back navigation
  const handleBackNavigation = () => {
    // Use window.history to check if we can go back
    if (window.history.length > 1) {
      navigate(-1); // Go back to previous page if possible
    } else {
      navigate('/exercises'); // Otherwise go to exercises page
    }
  };
  
  // Toggle fullscreen mode
  const toggleFullscreen = () => {
    if (!document.fullscreenElement) {
      // Enter fullscreen
      const videoContainer = document.querySelector('.camera-container') as HTMLElement;
      if (videoContainer) {
        videoContainer.requestFullscreen().then(() => {
          setIsFullscreen(true);
        }).catch(err => {
          console.error(`Error attempting to enable fullscreen: ${err.message}`);
        });
      }
    } else {
      // Exit fullscreen
      document.exitFullscreen().then(() => {
        setIsFullscreen(false);
      }).catch(err => {
        console.error(`Error attempting to exit fullscreen: ${err.message}`);
      });
    }
  };

  // Listen for fullscreen change events
  useEffect(() => {
    const handleFullscreenChange = () => {
      setIsFullscreen(!!document.fullscreenElement);
    };
    
    document.addEventListener('fullscreenchange', handleFullscreenChange);
    return () => {
      document.removeEventListener('fullscreenchange', handleFullscreenChange);
    };
  }, []);

  // Initialize the tracker when component mounts
  useEffect(() => {
    const initTracker = async () => {
      await initialize(videoRef, canvasRef);
    };
    initTracker();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Set up timer expiration callback
  useEffect(() => {
    setTimerExpiredCallback(() => {
      // Auto-finish session when timer expires
      if (status === SessionStatus.ACTIVE) {
        finishSession();
      }
    });
  }, [setTimerExpiredCallback, status, finishSession]);

  // Update APFT score when rep count changes
  useEffect(() => {
    if (repCount > 0) {
      const score = calculateSitupScore(repCount);
      setSitupScore(score);
    } else {
      setSitupScore(0);
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
    const finalScore = calculateSitupScore(repCount);
    setSitupScore(finalScore);
    
    console.log(`Workout finished! Reps: ${repCount}, Time: ${formattedTime}, APFT Score: ${finalScore}`);

    // Create the workout summary object
    const workoutSummary = {
      exerciseType: 'SITUP',
      repCount,
      duration: timer,
      formScore: formScore,
      grade: finalScore,
      date: new Date(),
      saved: false
    };

    // Navigate to workout complete page with initial "not saved" state
    navigate('/complete', { state: workoutSummary });

    // Save workout session data in background
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
    setSitupScore(0);
  };

  // --- JSX ---
  return (
    <div className="space-y-6">
      <Button variant="outline" onClick={handleBackNavigation} className="mb-4">
        <ArrowLeft className="mr-2 size-4" /> Back
      </Button>
      <h1 className="font-semibold text-3xl text-foreground">{EXERCISE_NAME} Exercise</h1>

      {/* Live Tracking Card */}
      <Card className="overflow-hidden rounded-lg bg-card shadow-sm">
        <CardHeader>
          <CardTitle className="text-lg font-medium">Live Tracking</CardTitle>
          <CardDescription>
            Position yourself correctly for the camera and press Start.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Camera Feed Section */}
          <div ref={containerRef} className="relative aspect-video overflow-hidden rounded-md bg-muted camera-container">
            <video ref={videoRef} autoPlay playsInline className="size-full object-cover" muted onLoadedMetadata={() => console.log("Video metadata loaded.")} />
            <canvas ref={canvasRef} className="pointer-events-none absolute inset-0 size-full" />
            
            {/* HUD Component */}
            {isActive && permissionGranted && !modelError && !isModelLoading && (
              <HUD 
                repCount={repCount} 
                formattedTime={formattedTime} 
                formFeedback={formFeedback}
                exerciseColor="text-brass-gold" 
              />
            )}
            
            {/* Overlays */}
            {isModelLoading && ( <div className="absolute inset-0 z-10 flex flex-col items-center justify-center bg-black/60 text-white"><Loader2 className="mb-3 size-10 animate-spin" /><span>Loading AI Model...</span></div> )}
            {!isModelLoading && modelError && ( <div className="absolute inset-0 z-10 flex flex-col items-center justify-center bg-destructive/80 p-4 text-center text-white"><VideoOff className="mb-2 size-12" /><p className="mb-1 font-semibold">Model Loading Failed</p><p className="text-sm">{modelError}</p></div> )}
            {status === SessionStatus.INITIALIZING && !modelError && ( <div className="absolute inset-0 flex items-center justify-center bg-black/50 text-white"><Camera className="mr-2 size-8 animate-pulse" /><span>Requesting camera access...</span></div> )}
            {!permissionGranted && !isModelLoading && !modelError && ( <div className="absolute inset-0 flex flex-col items-center justify-center bg-black/70 p-4 text-center text-white"><VideoOff className="mb-2 size-12 text-destructive" /><p className="mb-1 font-semibold">Camera Access Issue</p><p className="text-sm">{cameraError || "Could not access camera."}</p></div> )}
          </div>
          {/* Stats Display */}
          <div className="grid grid-cols-3 gap-4 text-center">
            <div><p className="text-sm font-medium text-muted-foreground">Reps</p><p className="font-bold text-4xl text-foreground">{repCount}</p></div>
            <div><p className="text-sm font-medium text-muted-foreground">Time</p><p className="flex items-center justify-center font-bold text-4xl text-foreground"><Timer className="mr-1 inline-block size-6" />{formattedTime}</p></div>
            <div><p className="text-sm font-medium text-muted-foreground">Score</p><p className="font-bold text-4xl text-foreground">{situpScore}</p></div>
          </div>

          {/* Instructions Section */}
          <div className="border-t pt-4">
            <h3 className="mb-2 font-semibold text-base text-foreground">Form Requirements for Rep Count:</h3>
            <ul className="list-disc space-y-1 pl-5 text-sm text-muted-foreground">
              <li>
                <strong>Camera:</strong> Place side-on to capture your full body clearly.
              </li>
              <li>
                <strong>Start:</strong> Lie down, knees bent, feet flat on the floor, hands behind head.
              </li>
              <li>
                <strong>Movement:</strong> 
                Sit up until hip angle &lt;= {SITUP_THRESHOLD_ANGLE_UP}° (upper body near vertical), 
                then lie back down until hip angle &gt;= {SITUP_THRESHOLD_ANGLE_DOWN}° (nearly flat).
              </li>
               <li>
                <strong>Feet:</strong> Must remain on the ground throughout the repetition.
              </li>
               <li>
                <strong>Hands:</strong> Must remain behind your head throughout the repetition.
              </li>
            </ul>
          </div>
        </CardContent>
      </Card>
      
      {/* Completion status messages */}
      {isFinished && (
        <Card className="mt-4">
          <CardContent className="py-6 text-center">
            {isSubmitting && <p className="flex items-center justify-center"><Loader2 className="mr-2 size-4 animate-spin" /> Saving Live Session...</p>}
            {/* Display error/success related to live save attempt */}
            {apiError && !isSubmitting && <p className="mt-2 text-sm text-destructive">Error Saving: {apiError}</p>}
            {success && !isSubmitting && (
              <p className="mt-2 text-sm text-green-600">
                Live Workout saved successfully!
                {loggedGrade !== null && ` Grade: ${loggedGrade}`}
              </p>
            )}
            {!isSubmitting && !apiError && !success && <p>Live Workout Complete! Press Reset to start again.</p>}
            <Button size="lg" variant="outline" onClick={handleReset} className="mt-4">
              Reset Exercise
            </Button>
          </CardContent>
        </Card>
      )}
      
      {/* Session controls overlay - now without the camera controls, which have been moved */}
      {!isFinished && (
        <SessionControls
          status={status}
          isModelLoading={isModelLoading}
          disabled={!permissionGranted || !!cameraError || !!modelError}
          repCount={repCount}
          isSubmitting={isSubmitting}
          showFlip={isMobile}
          onFlipCamera={flipCamera}
          onStartPause={handleStartPause}
          onReset={handleReset}
          onFinish={handleFinish}
          cameraContainerRef={containerRef}
        />
      )}
    </div>
  );
};

export default SitupTracker; 