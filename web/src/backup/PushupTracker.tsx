import React, { useEffect, useRef, useState } from 'react';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { usePoseDetector, PoseLandmarkIndex, Landmark } from '@/lib/hooks/usePoseDetector';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { InfoIcon, PlayIcon, PauseIcon, RefreshCw, ShareIcon, CheckCircle, CloudOff, Timer, ChevronLeft } from 'lucide-react';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '@/lib/authContext';
import { apiRequest } from '@/lib/apiClient';
import { saveWorkout } from '@/lib/db/indexedDB';
import { registerBackgroundSync } from '@/serviceWorkerRegistration';
import { v4 as uuidv4 } from 'uuid';

// Military-style corner component
const MilitaryCorners: React.FC = () => (
  <>
    {/* Military corner cutouts - top left and right */}
    <div className="absolute left-0 top-0 size-[15px] bg-background"></div>
    <div className="absolute right-0 top-0 size-[15px] bg-background"></div>
    
    {/* Military corner cutouts - bottom left and right */}
    <div className="absolute bottom-0 left-0 size-[15px] bg-background"></div>
    <div className="absolute bottom-0 right-0 size-[15px] bg-background"></div>
    
    {/* Diagonal lines for corners */}
    <div className="bg-tactical-gray/50 absolute left-0 top-0 h-px w-[15px] origin-top-left rotate-45"></div>
    <div className="bg-tactical-gray/50 absolute right-0 top-0 h-px w-[15px] origin-top-right -rotate-45"></div>
    <div className="bg-tactical-gray/50 absolute bottom-0 left-0 h-px w-[15px] origin-bottom-left -rotate-45"></div>
    <div className="bg-tactical-gray/50 absolute bottom-0 right-0 h-px w-[15px] origin-bottom-right rotate-45"></div>
  </>
);

// Header divider component
const HeaderDivider: React.FC = () => (
  <div className="mx-auto my-2 h-px w-16 bg-brass-gold"></div>
);

export function PushupTracker() {
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [countdown, setCountdown] = useState(3);
  const [isCountingDown, setIsCountingDown] = useState(false);
  const [isTracking, setIsTracking] = useState(false);
  const [repCount, setRepCount] = useState(0);
  const [formScore, setFormScore] = useState(100);
  const [formFeedback, setFormFeedback] = useState<string | null>(null);
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
  const [elapsedTime, setElapsedTime] = useState(0);
  const timerIntervalRef = useRef<NodeJS.Timeout | null>(null);

  const navigate = useNavigate();
  const location = useLocation();
  const { user } = useAuth();

  // Timer for tracking session duration
  useEffect(() => {
    if (isTracking) {
      timerIntervalRef.current = setInterval(() => {
        setElapsedTime(prev => prev + 1);
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
  }, [isTracking]);

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
      setElapsedTime(0);
      setSessionStartTime(Date.now());
      setSubmitSuccess(false);
      setSavedOffline(false);
      setFormFeedback(null);
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
    } else {
      setSessionTime(elapsedTime);
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
    setElapsedTime(0);
    setShowResultModal(false);
    setSavedOffline(false);
    setFormFeedback(null);
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
      durationSeconds: sessionTime || elapsedTime,
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

    // Check for proper form - back should be straight
    const backAngle = calculateBodyLineAngle(
      leftHip, rightHip, leftShoulder, rightShoulder
    );

    // Check if back is straight (less than 15 degrees from vertical)
    const isBackStraight = backAngle <= 15;

    if (!isBackStraight && formFeedback !== "Keep your back straight!") {
      setFormFeedback("Keep your back straight!");
      // Clear feedback after 2 seconds
      setTimeout(() => {
        setFormFeedback(null);
      }, 2000);
    }

    // Determine current phase
    let newPhase = currentPhase;
    if (avgShoulderY > DOWN_THRESHOLD) {
      newPhase = 'down';
    } else if (avgShoulderY < UP_THRESHOLD) {
      newPhase = 'up';
    }

    // Only count reps with good form
    if (newPhase === 'up' && lastPhase === 'down') {
      if (isBackStraight) {
        setRepCount((count) => count + 1);
      } else {
        // Bad form - deduct points
        setFormScore((score) => Math.max(0, score - 5));
      }
    }

    // Update phase states
    if (newPhase !== currentPhase) {
      setLastPhase(currentPhase);
      setCurrentPhase(newPhase);
    }
  }, [landmarks, isTracking, currentPhase, lastPhase, formFeedback]);

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
    <div className="space-y-6">
      {/* Back button with military styling */}
      <Button 
        variant="outline" 
        onClick={() => {
          // Determine where to navigate back to based on the current URL
          if (location.pathname.includes('/trackers')) {
            navigate('/trackers');
          } else {
            navigate('/exercises');
          }
        }}
        className="hover:bg-tactical-gray/10 mb-4 border-tactical-gray text-tactical-gray"
      >
        <ChevronLeft className="mr-2 size-4" /> 
        {location.pathname.includes('/trackers') ? 'Back to Trackers' : 'Back to Exercises'}
      </Button>
      
      {/* Page title with military styling */}
      <div className="bg-card-background relative overflow-hidden rounded-card p-content shadow-medium">
        <MilitaryCorners />
        <div className="mb-4 text-center">
          <h2 className="font-heading text-heading3 uppercase tracking-wider text-command-black">
            Push-up Tracker
          </h2>
          <HeaderDivider />
          <p className="mt-2 text-sm uppercase tracking-wide text-tactical-gray">Track and count your push-ups with form analysis</p>
        </div>
      </div>

      {!isOnline && (
        <Alert className="mb-4 rounded-card border-amber-200 bg-amber-50">
          <CloudOff className="size-4 text-amber-500" />
          <AlertTitle className="text-amber-800">Offline Mode</AlertTitle>
          <AlertDescription className="text-amber-700">
            You're currently offline. Your workout will be saved locally and synced when you reconnect.
          </AlertDescription>
        </Alert>
      )}
      
      <Card className="bg-card-background relative overflow-hidden rounded-card shadow-medium">
        <MilitaryCorners />
        <CardHeader className="rounded-t-card bg-deep-ops">
          <CardTitle className="font-heading text-xl uppercase tracking-wider text-cream">Live Tracking</CardTitle>
          <CardDescription className="text-army-tan">
            Position yourself correctly and press Begin to start tracking
          </CardDescription>
        </CardHeader>
        
        <CardContent className="space-y-4 p-content">
          {errorMessage && (
            <Alert variant="destructive" className="mb-4 rounded-card">
              <InfoIcon className="size-4" />
              <AlertTitle>Error</AlertTitle>
              <AlertDescription>{errorMessage}</AlertDescription>
            </Alert>
          )}
          
          {/* Camera Feed Section */}
          <div className="relative aspect-video overflow-hidden rounded-card bg-muted">
            {/* Base video element */}
            <video 
              ref={videoRef}
              autoPlay 
              playsInline
              muted
              className="size-full object-cover"
            />
            
            {/* Canvas overlay for pose landmarks */}
            <canvas 
              ref={canvasRef}
              className="absolute inset-0 size-full"
            />
            
            {/* Countdown overlay */}
            {isCountingDown && (
              <div className="absolute inset-0 z-20 flex items-center justify-center bg-black/40">
                <span className="font-bold text-8xl text-brass-gold">{countdown}</span>
              </div>
            )}
            
            {/* Form feedback message */}
            {formFeedback && (
              <div className="bg-destructive/80 absolute bottom-4 left-1/2 z-20 -translate-x-1/2 rounded-md px-4 py-2 font-semibold text-sm text-white">
                {formFeedback}
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
          
          {/* Stats Display */}
          <div className="grid grid-cols-2 gap-4 text-center">
            <div>
              <p className="text-sm font-medium uppercase tracking-wider text-tactical-gray">Repetitions</p>
              <p className="font-heading text-heading2 text-command-black">{repCount}</p>
            </div>
            <div>
              <p className="text-sm font-medium uppercase tracking-wider text-tactical-gray">Time</p>
              <p className="flex items-center justify-center font-heading text-heading2 text-command-black">
                <Timer className="mr-1 inline-block size-5 text-brass-gold" />
                {formatTime(elapsedTime)}
              </p>
            </div>
          </div>
          
          {/* Form Quality Indicator */}
          <div className="space-y-2">
            <div className="flex justify-between">
              <span className="font-semibold text-sm uppercase tracking-wider text-tactical-gray">Form Quality</span>
              <span className="font-mono text-sm text-brass-gold">{formScore}%</span>
            </div>
            <Progress value={formScore} className="h-2" 
              style={{
                "--progress-background": "var(--color-olive-mist)",
                "--progress-foreground": "var(--color-brass-gold)"
              } as React.CSSProperties} 
            />
          </div>
          
          {/* Instructions */}
          <div className="border-olive-mist/20 rounded-card border p-content">
            <h3 className="text-md mb-2 font-heading uppercase tracking-wider text-command-black">Form Requirements:</h3>
            <ul className="list-disc space-y-1 pl-5 text-sm text-tactical-gray">
              <li>
                <strong>Camera:</strong> Position side-on to capture your full body.
              </li>
              <li>
                <strong>Body:</strong> Keep your back straight throughout the exercise.
              </li>
              <li>
                <strong>Movement:</strong> Lower your body until elbows are at 90°, then push up until arms are fully extended.
              </li>
              <li>
                <strong>Rep Counts:</strong> Only reps with correct form through the full range of motion are counted.
              </li>
            </ul>
          </div>
        </CardContent>
        
        <CardFooter className="border-olive-mist/20 bg-background/50 flex flex-wrap justify-center gap-4 border-t p-content">
          {!isTracking ? (
            <>
              <Button 
                onClick={startCountdown}
                size="lg"
                className="hover:bg-brass-gold/90 bg-brass-gold text-deep-ops shadow-medium transition-all hover:shadow-large"
                disabled={!isDetectorReady || isCountingDown || !cameraPermission}
              >
                <PlayIcon className="mr-2 size-5" />
                {isCountingDown ? `Starting in ${countdown}...` : 'Begin Tracking'}
              </Button>
              
              <Button 
                onClick={resetTracking}
                size="lg"
                variant="outline"
                className="hover:bg-tactical-gray/10 border-tactical-gray text-tactical-gray"
                disabled={repCount === 0 && !isTracking}
              >
                <RefreshCw className="mr-2 size-5" />
                Reset
              </Button>
            </>
          ) : (
            <>
              <Button 
                onClick={stopTracking}
                size="lg"
                variant="destructive"
                className="bg-tactical-red hover:bg-tactical-red/90"
              >
                <PauseIcon className="mr-2 size-5" />
                Finish & Save
              </Button>
              
              <Button 
                onClick={resetTracking}
                size="lg"
                variant="outline"
                className="hover:bg-tactical-gray/10 border-tactical-gray text-tactical-gray"
              >
                <RefreshCw className="mr-2 size-5" />
                Reset
              </Button>
            </>
          )}
        </CardFooter>
      </Card>
      
      {/* Results Dialog with military styling */}
      <Dialog open={showResultModal} onOpenChange={setShowResultModal}>
        <DialogContent className="bg-card-background relative overflow-hidden rounded-card shadow-large">
          <MilitaryCorners />
          <DialogHeader>
            <DialogTitle className="text-center font-heading text-heading3 uppercase tracking-wider text-command-black">
              Workout Results
            </DialogTitle>
            <DialogDescription className="text-center text-tactical-gray">
              {submitSuccess ? (
                <div className="mt-2 flex items-center justify-center text-success">
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
            <HeaderDivider />
          </DialogHeader>
          
          <div className="grid grid-cols-2 gap-4 py-4">
            <div className="bg-cream/30 rounded-card p-4 text-center">
              <div className="mb-1 font-semibold text-sm uppercase tracking-wider text-tactical-gray">Repetitions</div>
              <div className="font-heading text-heading2 text-brass-gold">{repCount}</div>
            </div>
            
            <div className="bg-cream/30 rounded-card p-4 text-center">
              <div className="mb-1 font-semibold text-sm uppercase tracking-wider text-tactical-gray">Form Score</div>
              <div className="font-heading text-heading2 text-brass-gold">{formScore}%</div>
            </div>
            
            <div className="bg-cream/30 rounded-card p-4 text-center">
              <div className="mb-1 font-semibold text-sm uppercase tracking-wider text-tactical-gray">Duration</div>
              <div className="font-heading text-heading3 text-brass-gold">{formatTime(sessionTime)}</div>
            </div>
            
            <div className="bg-cream/30 rounded-card p-4 text-center">
              <div className="mb-1 font-semibold text-sm uppercase tracking-wider text-tactical-gray">Grade</div>
              <div className="font-heading text-heading2 text-brass-gold">{scoreGrade}</div>
            </div>
          </div>
          
          <DialogFooter className="flex flex-col gap-2 pt-2 sm:flex-row sm:justify-between">
            {!submitSuccess && !savedOffline ? (
              <Button 
                onClick={submitWorkout} 
                className="hover:bg-brass-gold/90 bg-brass-gold text-deep-ops shadow-medium transition-all hover:shadow-large"
                disabled={submitting}
              >
                {submitting ? 'Saving...' : `Save Results${!isOnline ? ' Offline' : ''}`}
              </Button>
            ) : (
              <Button
                onClick={() => navigate('/history')}
                className="hover:bg-brass-gold/90 bg-brass-gold text-deep-ops shadow-medium transition-all hover:shadow-large"
              >
                View History
              </Button>
            )}
            
            <Button 
              onClick={shareResults} 
              variant="outline" 
              className="hover:bg-brass-gold/10 border-brass-gold text-brass-gold"
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