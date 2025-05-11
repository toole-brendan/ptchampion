import React, { useEffect, useRef, useState } from 'react';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { usePoseDetector, PoseLandmarkIndex } from '@/lib/hooks/usePoseDetector';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { InfoIcon, PlayIcon, PauseIcon, RefreshCw, ShareIcon, CheckCircle, CloudOff } from 'lucide-react';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/lib/authContext';
import { apiRequest } from '@/lib/apiClient';
import { saveWorkout } from '@/lib/db/indexedDB';
import { registerBackgroundSync } from '@/serviceWorkerRegistration';
import { v4 as uuidv4 } from 'uuid';

export function SitupTracker() {
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [countdown, setCountdown] = useState(3);
  const [isCountingDown, setIsCountingDown] = useState(false);
  const [isTracking, setIsTracking] = useState(false);
  const [repCount, setRepCount] = useState(0);
  const [formScore, setFormScore] = useState(100);
  const [currentPhase, setCurrentPhase] = useState<'up' | 'down' | 'unknown'>('unknown');
  const [lastPhase, setLastPhase] = useState<'up' | 'down' | 'unknown'>('unknown');
  const [cameraPermission, setCameraPermission] = useState<boolean | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [showResultModal, setShowResultModal] = useState(false);
  const [sessionTime, setSessionTime] = useState(0);
  const [sessionStartTime, setSessionStartTime] = useState<number | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [submitSuccess, setSubmitSuccess] = useState(false);
  const [scoreGrade, setScoreGrade] = useState<'A' | 'B' | 'C' | 'D' | 'F'>('A');
  const [savedOffline, setSavedOffline] = useState(false);
  const [isOnline, setIsOnline] = useState(navigator.onLine);

  const navigate = useNavigate();
  const auth = useAuth();
  const user = auth?.user;

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

  // Track the positions of shoulders, hips to detect situp motion
  const [shoulderY, setShoulderY] = useState(0);
  const [hipY, setHipY] = useState(0);
  
  // Initialize the pose detector hook
  const { 
    landmarks, 
    isDetectorReady, 
    isRunning, 
    startDetection, 
    stopDetection 
  } = usePoseDetector(videoRef, canvasRef, {
    minPoseDetectionConfidence: 0.7,
    modelType: 'HEAVY', // Use highest quality model for exercise tracking
    smoothLandmarks: true,
  });

  // Initialize webcam
  useEffect(() => {
    async function initCamera() {
      try {
        if (!videoRef.current) return;
        
        const stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: 'user' },
          audio: false,
        });
        
        videoRef.current.srcObject = stream;
        setCameraPermission(true);
      } catch (error) {
        console.error('Error accessing camera:', error);
        setCameraPermission(false);
        setErrorMessage('Camera access denied. Please allow camera permissions to track exercises.');
      }
    }
    
    initCamera();
    
    // Cleanup function to stop camera stream
    return () => {
      if (videoRef.current?.srcObject) {
        const stream = videoRef.current.srcObject as MediaStream;
        stream.getTracks().forEach(track => track.stop());
      }
    };
  }, []);

  // Start countdown when user clicks begin
  const startCountdown = () => {
    setIsCountingDown(true);
    setCountdown(3);
  };

  // Handle countdown timer
  useEffect(() => {
    if (!isCountingDown) return;
    
    if (countdown <= 0) {
      setIsCountingDown(false);
      startTracking();
      return;
    }
    
    const timer = setTimeout(() => {
      setCountdown((count) => count - 1);
    }, 1000);
    
    return () => clearTimeout(timer);
  }, [isCountingDown, countdown]);

  // Start pose tracking
  const startTracking = () => {
    if (isDetectorReady) {
      setIsTracking(true);
      startDetection();
      setRepCount(0);
      setFormScore(100);
      setCurrentPhase('unknown');
      setLastPhase('unknown');
      setSessionStartTime(Date.now());
      setSubmitSuccess(false);
      setSavedOffline(false);
    }
  };

  // Stop pose tracking and show results
  const stopTracking = () => {
    if (!isTracking) return;
    
    setIsTracking(false);
    stopDetection();
    
    if (sessionStartTime) {
      const duration = Math.round((Date.now() - sessionStartTime) / 1000); // in seconds
      setSessionTime(duration);
    }
    
    // Only show results if at least 1 rep was completed
    if (repCount > 0) {
      // Calculate grade based on form score
      if (formScore >= 90) {
        setScoreGrade('A');
      } else if (formScore >= 80) {
        setScoreGrade('B');
      } else if (formScore >= 70) {
        setScoreGrade('C');
      } else if (formScore >= 60) {
        setScoreGrade('D');
      } else {
        setScoreGrade('F');
      }
      
      setShowResultModal(true);
    }
  };

  // Reset tracking session
  const resetTracking = () => {
    stopDetection();
    setIsTracking(false);
    setRepCount(0);
    setFormScore(100);
    setCurrentPhase('unknown');
    setLastPhase('unknown');
    setSessionStartTime(null);
    setSessionTime(0);
    setShowResultModal(false);
    setSavedOffline(false);
  };

  // Submit workout results to the API
  const submitWorkout = async () => {
    if (!user || repCount === 0) return;
    
    setSubmitting(true);
    
    // Generate a unique ID for the workout (useful for offline sync)
    const workoutId = uuidv4();
    
    const workoutData = {
      id: workoutId,
      exerciseType: 'SITUP',
      count: repCount,
      formScore: formScore,
      durationSeconds: sessionTime,
      deviceType: 'WEB',
      userId: String(user.id),
      date: new Date().toISOString()
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

  // Share results on social media
  const shareResults = () => {
    if (navigator.share) {
      navigator.share({
        title: 'PT Champion Workout',
        text: `I just completed ${repCount} sit-ups with a form score of ${formScore}% using PT Champion!`,
        url: window.location.href,
      }).catch(error => {
        console.error('Error sharing:', error);
      });
    } else {
      // Fallback for browsers that don't support Web Share API
      const text = `I just completed ${repCount} sit-ups with a form score of ${formScore}% using PT Champion!`;
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

  // Process landmark data to detect sit-ups
  useEffect(() => {
    if (!landmarks || landmarks.length === 0 || !isTracking) return;

    const poseLandmarks = landmarks[0];
    if (!poseLandmarks) return;

    // Get key body parts for a sit-up
    const leftShoulder = poseLandmarks[PoseLandmarkIndex.LEFT_SHOULDER];
    const rightShoulder = poseLandmarks[PoseLandmarkIndex.RIGHT_SHOULDER];
    const leftHip = poseLandmarks[PoseLandmarkIndex.LEFT_HIP];
    const rightHip = poseLandmarks[PoseLandmarkIndex.RIGHT_HIP];
    const leftKnee = poseLandmarks[PoseLandmarkIndex.LEFT_KNEE];
    const rightKnee = poseLandmarks[PoseLandmarkIndex.RIGHT_KNEE];

    // Calculate average shoulder and hip heights (y-coordinate)
    const avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    const avgHipY = (leftHip.y + rightHip.y) / 2;
    const avgKneeY = (leftKnee.y + rightKnee.y) / 2;

    setShoulderY(avgShoulderY);
    setHipY(avgHipY);

    // Determine current phase based on shoulder position relative to hip
    // In a sit-up, when shoulders rise, shoulderY decreases (moves up in the image)
    const UP_THRESHOLD = 0.1; // Threshold for "up" position - shoulders above a certain point
    const DOWN_THRESHOLD = 0.2; // Threshold for "down" position - shoulders below a certain point

    // Determine current phase
    let newPhase = currentPhase;
    if (avgShoulderY > avgHipY - DOWN_THRESHOLD) {
      newPhase = 'down'; // User is lying down
    } else if (avgShoulderY < avgHipY - UP_THRESHOLD) {
      newPhase = 'up'; // User has sat up
    }

    // Check for rep completion
    if (newPhase === 'down' && lastPhase === 'up') {
      setRepCount((count) => count + 1);
      
      // Basic form checking - check if knees are bent sufficiently
      const hipKneeAngle = calculateAngle(
        { x: avgHipY, y: 0 } as Point,
        { x: avgKneeY, y: 0 } as Point,
        { x: 1, y: 0 } as Point // Reference point for an angle
      );
      
      // Deduct points for poor form - if knees are too straight
      if (hipKneeAngle > 150) {
        setFormScore((score) => Math.max(0, score - 5));
      }
    }

    // Update phase states
    if (newPhase !== currentPhase) {
      setLastPhase(currentPhase);
      setCurrentPhase(newPhase);
    }
  }, [landmarks, isTracking, currentPhase, lastPhase]);

  // Define a Point type for angle calculations
  type Point = {
    x: number;
    y: number;
  };

  // Calculate angle between three points
  const calculateAngle = (
    a: Point,
    b: Point,
    c: Point
  ) => {
    const radians = Math.atan2(c.y - b.y, c.x - b.x) - Math.atan2(a.y - b.y, a.x - b.x);
    let angle = Math.abs(radians * 180.0 / Math.PI);
    
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    
    return angle;
  };

  // Format seconds to mm:ss
  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div className="container mx-auto px-4 py-8">
      {!isOnline && (
        <Alert className="mb-4 border-amber-200 bg-amber-50">
          <CloudOff className="size-4 text-amber-500" />
          <AlertTitle className="text-amber-800">Offline Mode</AlertTitle>
          <AlertDescription className="text-amber-700">
            You're currently offline. Your workout will be saved locally and synced when you reconnect.
          </AlertDescription>
        </Alert>
      )}
      
      <Card className="mx-auto w-full max-w-3xl bg-cream">
        <CardHeader className="rounded-t-lg bg-deep-ops text-cream">
          <CardTitle className="font-heading text-2xl tracking-wide">Sit-up Tracker</CardTitle>
          <CardDescription className="text-army-tan">
            Track your form and count repetitions
          </CardDescription>
        </CardHeader>
        
        <CardContent className="p-6">
          {errorMessage && (
            <Alert variant="destructive" className="mb-4">
              <InfoIcon className="size-4" />
              <AlertTitle>Error</AlertTitle>
              <AlertDescription>{errorMessage}</AlertDescription>
            </Alert>
          )}
          
          <div className="relative mb-6 aspect-video overflow-hidden rounded-lg bg-muted">
            {/* Base video element (hidden) */}
            <video 
              ref={videoRef}
              autoPlay 
              playsInline
              muted
              className="absolute inset-0 size-full object-cover opacity-30"
            />
            
            {/* Canvas overlay for pose landmarks */}
            <canvas 
              ref={canvasRef}
              className="absolute inset-0 size-full"
            />
            
            {/* Countdown overlay */}
            {isCountingDown && (
              <div className="absolute inset-0 flex items-center justify-center">
                <span className="font-bold text-8xl text-brass-gold">{countdown}</span>
              </div>
            )}
            
            {/* Stats overlay */}
            {isTracking && (
              <div className="absolute left-4 top-4 rounded-lg bg-black/50 p-3">
                <div className="font-mono text-lg text-brass-gold">Reps: {repCount}</div>
                <div className="font-mono text-sm text-cream">Form: {formScore}%</div>
                <div className="font-mono text-xs text-cream">
                  Phase: {currentPhase === 'up' ? 'UP' : currentPhase === 'down' ? 'DOWN' : 'READY'}
                </div>
              </div>
            )}
          </div>
          
          {/* Status and progress */}
          <div className="mb-4">
            <div className="mb-2 flex justify-between">
              <span className="text-sm font-medium">Form Quality</span>
              <span className="font-mono text-sm">{formScore}%</span>
            </div>
            <Progress value={formScore} className="h-2" />
          </div>
          
          <div className="mb-4 rounded-lg bg-muted p-4">
            <h3 className="mb-2 font-semibold">Exercise Stats</h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-muted-foreground">Repetitions</p>
                <p className="font-mono text-2xl text-brass-gold">{repCount}</p>
              </div>
              <div>
                <p className="text-sm text-muted-foreground">Current Phase</p>
                <p className="font-mono text-lg">
                  {currentPhase === 'up' ? 'UP' : currentPhase === 'down' ? 'DOWN' : 'READY'}
                </p>
              </div>
            </div>
          </div>
          
          <div className="mb-4 rounded-lg bg-muted p-4">
            <h3 className="mb-2 font-semibold">Instructions</h3>
            <ul className="list-disc space-y-1 pl-5 text-sm">
              <li>Position your body sideways to the camera</li>
              <li>Lie flat on your back with knees bent</li>
              <li>Place hands across chest or behind ears</li>
              <li>Sit up until your elbows touch your knees</li>
              <li>Return to the starting position</li>
              <li>Keep your feet flat on the ground</li>
            </ul>
          </div>
        </CardContent>
        
        <CardFooter className="border-border flex justify-between border-t p-4">
          {!isTracking ? (
            <Button 
              onClick={startCountdown} 
              className="hover:bg-brass-gold/90 bg-brass-gold text-deep-ops"
              disabled={!isDetectorReady || isCountingDown}
              size="lg"
            >
              <PlayIcon className="mr-2 size-5" />
              {isCountingDown ? `Starting in ${countdown}...` : 'Begin Tracking'}
            </Button>
          ) : (
            <Button 
              onClick={stopTracking} 
              variant="outline" 
              className="hover:bg-brass-gold/10 border-brass-gold text-brass-gold"
              size="lg"
            >
              <PauseIcon className="mr-2 size-5" />
              End Session
            </Button>
          )}
          
          <Button 
            onClick={resetTracking} 
            variant="ghost" 
            className="text-muted-foreground"
            disabled={repCount === 0}
          >
            <RefreshCw className="mr-2 size-4" />
            Reset
          </Button>
        </CardFooter>
      </Card>
      
      {/* Results Modal */}
      <Dialog open={showResultModal} onOpenChange={setShowResultModal}>
        <DialogContent className="bg-cream sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="text-center font-heading text-2xl">Session Results</DialogTitle>
            <DialogDescription className="text-center">
              {submitSuccess ? (
                <div className="mt-2 flex items-center justify-center text-green-600">
                  <CheckCircle className="mr-2 size-5" />
                  Workout saved successfully!
                </div>
              ) : savedOffline ? (
                <div className="mt-2 flex items-center justify-center text-amber-600">
                  <CloudOff className="mr-2 size-5" />
                  Workout saved offline. Will sync when online.
                </div>
              ) : (
                "Your sit-up session is complete!"
              )}
            </DialogDescription>
          </DialogHeader>
          
          <div className="grid grid-cols-2 gap-4 py-4">
            <div className="rounded-lg bg-white/50 p-4 text-center">
              <div className="mb-1 text-sm font-medium text-tactical-gray">Repetitions</div>
              <div className="font-mono text-3xl text-brass-gold">{repCount}</div>
            </div>
            
            <div className="rounded-lg bg-white/50 p-4 text-center">
              <div className="mb-1 text-sm font-medium text-tactical-gray">Form Score</div>
              <div className="font-mono text-3xl text-brass-gold">{formScore}%</div>
            </div>
            
            <div className="rounded-lg bg-white/50 p-4 text-center">
              <div className="mb-1 text-sm font-medium text-tactical-gray">Duration</div>
              <div className="font-mono text-2xl text-brass-gold">{formatTime(sessionTime)}</div>
            </div>
            
            <div className="rounded-lg bg-white/50 p-4 text-center">
              <div className="mb-1 text-sm font-medium text-tactical-gray">Grade</div>
              <div className="font-mono text-3xl text-brass-gold">{scoreGrade}</div>
            </div>
          </div>
          
          <DialogFooter className="flex flex-col gap-2 sm:flex-row sm:justify-between">
            {!submitSuccess && !savedOffline ? (
              <Button 
                onClick={submitWorkout} 
                className="hover:bg-brass-gold/90 w-full bg-brass-gold text-deep-ops sm:w-auto"
                disabled={submitting}
              >
                {submitting ? 'Saving...' : `Save Results${!isOnline ? ' Offline' : ''}`}
              </Button>
            ) : (
              <Button
                onClick={() => navigate('/history')}
                className="hover:bg-brass-gold/90 w-full bg-brass-gold text-deep-ops sm:w-auto"
              >
                View History
              </Button>
            )}
            
            <Button 
              onClick={shareResults} 
              variant="outline" 
              className="hover:bg-brass-gold/10 w-full border-brass-gold text-brass-gold sm:w-auto"
            >
              <ShareIcon className="mr-2 size-4" />
              Share Results
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
} 