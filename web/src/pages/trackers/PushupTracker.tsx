import React, { useEffect, useRef, useState } from 'react';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { usePoseDetector, PoseLandmarkIndex, Landmark } from '@/lib/hooks/usePoseDetector';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { InfoIcon, PlayIcon, PauseIcon, RefreshCw, ShareIcon, CheckCircle, CloudOff } from 'lucide-react';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/lib/authContext';
import { apiRequest } from '@/lib/apiClient';
import { saveWorkout } from '@/lib/db/indexedDB';
import { registerBackgroundSync } from '@/serviceWorkerRegistration';
import { v4 as uuidv4 } from 'uuid';

export function PushupTracker() {
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
  const { user } = useAuth();

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

  // Track the Y position of shoulders and elbows to detect pushup motion
  const [shoulderY, setShoulderY] = useState(0);
  const [elbowY, setElbowY] = useState(0);
  
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
      exerciseType: 'PUSHUP',
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
        text: `I just completed ${repCount} push-ups with a form score of ${formScore}% using PT Champion!`,
        url: window.location.href,
      }).catch(error => {
        console.error('Error sharing:', error);
      });
    } else {
      // Fallback for browsers that don't support Web Share API
      const text = `I just completed ${repCount} push-ups with a form score of ${formScore}% using PT Champion!`;
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

  // Process landmark data to detect pushups
  useEffect(() => {
    if (!landmarks || landmarks.length === 0 || !isTracking) return;
    
    const poseLandmarks = landmarks[0];
    if (!poseLandmarks) return;
    
    // Get key body parts for a pushup
    const leftShoulder = poseLandmarks[PoseLandmarkIndex.LEFT_SHOULDER];
    const rightShoulder = poseLandmarks[PoseLandmarkIndex.RIGHT_SHOULDER];
    const leftElbow = poseLandmarks[PoseLandmarkIndex.LEFT_ELBOW];
    const rightElbow = poseLandmarks[PoseLandmarkIndex.RIGHT_ELBOW];
    const leftWrist = poseLandmarks[PoseLandmarkIndex.LEFT_WRIST];
    const rightWrist = poseLandmarks[PoseLandmarkIndex.RIGHT_WRIST];
    const leftHip = poseLandmarks[PoseLandmarkIndex.LEFT_HIP];
    const rightHip = poseLandmarks[PoseLandmarkIndex.RIGHT_HIP];
    
    // Calculate average shoulder and elbow heights (y-coordinate)
    const avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    const avgElbowY = (leftElbow.y + rightElbow.y) / 2;
    
    setShoulderY(avgShoulderY);
    setElbowY(avgElbowY);
    
    // Detect pushup phases based on shoulder position
    // Note: In normalized screen coordinates, smaller Y means higher up on screen
    const DOWN_THRESHOLD = 0.55; // Threshold for "down" position
    const UP_THRESHOLD = 0.4;    // Threshold for "up" position
    
    // Determine current phase
    let newPhase = currentPhase;
    if (avgShoulderY > DOWN_THRESHOLD) {
      newPhase = 'down';
    } else if (avgShoulderY < UP_THRESHOLD) {
      newPhase = 'up';
    }
    
    // Check for rep completion
    if (newPhase === 'up' && lastPhase === 'down') {
      setRepCount((count) => count + 1);
      
      // Basic form checking - check if back is straight
      const hipToShoulderAngle = calculateBodyLineAngle(
        leftHip, rightHip, leftShoulder, rightShoulder
      );
      
      // Deduct points for poor form
      if (hipToShoulderAngle > 15) {
        setFormScore((score) => Math.max(0, score - 5));
      }
    }
    
    // Update phase states
    if (newPhase !== currentPhase) {
      setLastPhase(currentPhase);
      setCurrentPhase(newPhase);
    }
    
  }, [landmarks, isTracking, currentPhase, lastPhase]);

  // Calculate angle between body segments for form checking
  const calculateBodyLineAngle = (
    leftHip: Landmark,
    rightHip: Landmark,
    leftShoulder: Landmark,
    rightShoulder: Landmark
  ) => {
    // Calculate hip and shoulder midpoints
    const hipMidpoint = {
      x: (leftHip.x + rightHip.x) / 2,
      y: (leftHip.y + rightHip.y) / 2
    };
    
    const shoulderMidpoint = {
      x: (leftShoulder.x + rightShoulder.x) / 2,
      y: (leftShoulder.y + rightShoulder.y) / 2
    };
    
    // Calculate angle in degrees between vertical line and back line
    const dx = shoulderMidpoint.x - hipMidpoint.x;
    const dy = shoulderMidpoint.y - hipMidpoint.y;
    const radians = Math.atan2(dx, dy);
    const degrees = Math.abs(radians * (180 / Math.PI));
    
    return degrees;
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
          <CardTitle className="font-heading text-2xl tracking-wide">Pushup Tracker</CardTitle>
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
                <span className="text-8xl font-bold text-brass-gold">{countdown}</span>
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
        </CardContent>
        
        <CardFooter className="flex justify-between border-t border-border p-4">
          {!isTracking ? (
            <Button 
              onClick={startCountdown} 
              className="bg-brass-gold text-deep-ops hover:bg-brass-gold/90"
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
              className="border-brass-gold text-brass-gold hover:bg-brass-gold/10"
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
                "Your push-up session is complete!"
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
                className="w-full bg-brass-gold text-deep-ops hover:bg-brass-gold/90 sm:w-auto"
                disabled={submitting}
              >
                {submitting ? 'Saving...' : `Save Results${!isOnline ? ' Offline' : ''}`}
              </Button>
            ) : (
              <Button
                onClick={() => navigate('/history')}
                className="w-full bg-brass-gold text-deep-ops hover:bg-brass-gold/90 sm:w-auto"
              >
                View History
              </Button>
            )}
            
            <Button 
              onClick={shareResults} 
              variant="outline" 
              className="w-full border-brass-gold text-brass-gold hover:bg-brass-gold/10 sm:w-auto"
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