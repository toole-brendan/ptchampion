import React, { useState, useRef, useEffect, useCallback } from 'react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Camera, Play, Pause, RotateCcw, Timer, VideoOff, Loader2 } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { logExercise } from '../../lib/apiClient';
import { LogExerciseRequest } from '../../lib/types';
import { useAuth } from '../../lib/authContext';
// --- MediaPipe Imports ---
import {
  PoseLandmarker,
  FilesetResolver,
  DrawingUtils,
  NormalizedLandmark,
  PoseLandmarkerResult
} from "@mediapipe/tasks-vision";

// --- Push-up specific logic constants (can be tuned) ---
const PUSHUP_THRESHOLD_ANGLE_DOWN = 90; // Angle threshold for elbows down
const PUSHUP_THRESHOLD_ANGLE_UP = 160; // Angle threshold for elbows up (full extension)
const BACK_STRAIGHT_THRESHOLD_ANGLE = 165; // Min angle for shoulder-hip-knee (degrees)
const PUSHUP_THRESHOLD_VISIBILITY = 0.6; // Visibility threshold for landmarks

const PushupTracker: React.FC = () => {
  const navigate = useNavigate();
  
  // Fix: Properly handle the useAuth hook with proper typing
  const auth = useAuth();
  const user = auth?.user;
  
  const [repCount, setRepCount] = useState(0);
  const [timer, setTimer] = useState(0);
  const [isActive, setIsActive] = useState(false);
  const [isFinished, setIsFinished] = useState(false);
  const timerIntervalRef = useRef<NodeJS.Timeout | null>(null);

  // Camera state
  const videoRef = useRef<HTMLVideoElement>(null);
  const [stream, setStream] = useState<MediaStream | null>(null);
  const [permissionGranted, setPermissionGranted] = useState<boolean | null>(null);
  const [cameraError, setCameraError] = useState<string | null>(null);

  // --- MediaPipe State ---
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [poseLandmarker, setPoseLandmarker] = useState<PoseLandmarker | null>(null);
  const [isModelLoading, setIsModelLoading] = useState(true);
  const [modelError, setModelError] = useState<string | null>(null);
  const requestRef = useRef<number>(); // For requestAnimationFrame
  const lastVideoTimeRef = useRef<number>(-1);
  const isPredictingRef = useRef(false); // <-- Add Ref for loop control

  // --- Push-up Tracking State ---
  const [pushupState, setPushupState] = useState<'start' | 'down' | 'up'>('start'); // State machine for push-up

  // UI state for Live Tracking submission
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null); // Changed from manual form error
  const [success, setSuccess] = useState(false); // Changed from manual form success

  // Constants for this exercise
  const EXERCISE_ID = 1; // Assuming 1 is the ID for pushups in your database
  const EXERCISE_NAME = 'Push-ups';

  // --- MediaPipe Initialization Effect ---
  useEffect(() => {
    let landmarkInstance: PoseLandmarker | null = null;
    const initializeMediaPipe = async () => {
      setIsModelLoading(true);
      setModelError(null);
      try {
        const vision = await FilesetResolver.forVisionTasks(
          // Path to the WASM files, often copied during build or hosted
          "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.14/wasm"
        );
        landmarkInstance = await PoseLandmarker.createFromOptions(vision, {
          baseOptions: {
            modelAssetPath: `/models/pose_landmarker_lite.task`, // Path in public folder
            delegate: "GPU" // Use GPU if available, fallback to CPU
          },
          runningMode: "VIDEO", // Process video stream
          numPoses: 1 // Track only one person
        });
        setPoseLandmarker(landmarkInstance);
        console.log("Pose Landmarker model loaded successfully.");
      } catch (err) {
        console.error("Failed to initialize MediaPipe Pose Landmarker:", err);
        setModelError(`Failed to load model: ${err instanceof Error ? err.message : String(err)}`);
        setPoseLandmarker(null); // Ensure state is null on error
      } finally {
        setIsModelLoading(false);
      }
    };

    initializeMediaPipe();

    // Cleanup
    return () => {
        landmarkInstance?.close(); // Use the local variable for cleanup
        setPoseLandmarker(null); // Also clear state on unmount
        console.log("Pose Landmarker closed.");
    }
  }, []); // Run once on mount

  // --- Camera Request Effect (Existing) ---
  useEffect(() => {
    let currentStream: MediaStream | null = null;

    const getCameraStream = async () => {
      setPermissionGranted(null); // Set to pending
      setCameraError(null);
      try {
        // Prefer front camera for exercises often involving facing the screen
        const constraints: MediaStreamConstraints = {
          video: {
            facingMode: 'user', // 'user' for front camera, 'environment' for back
            width: { ideal: 640 }, // Request a reasonable resolution
            height: { ideal: 480 }
          },
          audio: false // No audio needed for pose estimation
        };
        currentStream = await navigator.mediaDevices.getUserMedia(constraints);
        setStream(currentStream);
        if (videoRef.current) {
          videoRef.current.srcObject = currentStream;
        }
        setPermissionGranted(true);
      } catch (err) {
        console.error("Error accessing camera:", err);
        if (err instanceof Error) {
            if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
                setCameraError("Camera permission denied. Please grant access in your browser settings.");
            } else if (err.name === 'NotFoundError' || err.name === 'DevicesNotFoundError') {
                setCameraError("No camera found. Please ensure a camera is connected and enabled.");
            } else {
                setCameraError(`Error accessing camera: ${err.message}`);
            }
        } else {
             setCameraError("An unknown error occurred while accessing the camera.");
        }
        setPermissionGranted(false);
        setStream(null);
      }
    };

    getCameraStream();

    // Cleanup function
    return () => {
      if (currentStream) {
        currentStream.getTracks().forEach(track => track.stop());
        console.log("Camera stream stopped.");
      }
      if (videoRef.current) {
          videoRef.current.srcObject = null; // Detach stream from video element
      }
      // --- Stop MediaPipe loop on camera cleanup ---
      if (requestRef.current) {
        cancelAnimationFrame(requestRef.current);
      }
    };
  }, []); // Empty dependency array means this runs once on mount

  // --- Timer Effect (Existing) ---
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

  // --- Prediction Loop ---
  const predictWebcam = useCallback(() => {
    // --- Check Ref first to control loop execution ---
    if (!isPredictingRef.current) {
      console.log("Prediction loop stopped via ref.");
      return; // Stop the loop if ref is false
    }

    // --- DETAILED LOGGING FOR DEBUGGING PREREQUISITES ---
    console.log(
        `Prerequisites check:
         isPredictingRef: ${isPredictingRef.current},
         videoRef.current: ${!!videoRef.current},
         poseLandmarker: ${!!poseLandmarker},
         canvasRef.current: ${!!canvasRef.current},
         stream: ${!!stream}`
    );
    // --- END DETAILED LOGGING ---

    // Original prerequisite check (excluding isActive, as ref handles loop control)
    if (!videoRef.current || !poseLandmarker || !canvasRef.current || !stream) {
        console.log("Prediction prerequisites not met (other than loop control).");
        // We need to keep requesting frames even if prerequisites fail momentarily
        if (!videoRef.current || !canvasRef.current || !poseLandmarker) {
            console.error("Critical prerequisite missing (video, canvas, or landmarker ref/instance). Stopping loop.");
            isPredictingRef.current = false; // Stop loop if critical parts missing
            return;
        }
        if (!stream) {
           // If stream is missing, just wait for the next frame without processing
           requestRef.current = requestAnimationFrame(predictWebcam);
           return;
        }
    }

    const video = videoRef.current;
    const canvas = canvasRef.current;
    const canvasCtx = canvas.getContext("2d");
    if (!canvasCtx) {
        console.error("Failed to get canvas context");
        return;
    }

    // Ensure canvas dimensions match video AFTER video metadata is loaded
    if (video.readyState >= 2) { // HAVE_CURRENT_DATA or higher
        if (canvas.width !== video.videoWidth || canvas.height !== video.videoHeight) {
            canvas.width = video.videoWidth;
            canvas.height = video.videoHeight;
            console.log(`Canvas resized to: ${video.videoWidth}x${video.videoHeight}`);
        }
    } else {
        // Video not ready yet, try again soon
        requestRef.current = requestAnimationFrame(predictWebcam);
        return;
    }

    if (video.currentTime !== lastVideoTimeRef.current) {
      lastVideoTimeRef.current = video.currentTime;
      const startTimeMs = performance.now();

      // Run landmark detection
      poseLandmarker.detectForVideo(video, startTimeMs, (result: PoseLandmarkerResult) => {
        canvasCtx.save();
        canvasCtx.clearRect(0, 0, canvas.width, canvas.height);

        if (result.landmarks && result.landmarks.length > 0) {
          const landmarks = result.landmarks[0]; // Assuming single pose detection

          // Draw landmarks
          const drawingUtils = new DrawingUtils(canvasCtx);
          drawingUtils.drawLandmarks(landmarks, {
            radius: (data: { index?: number; from?: NormalizedLandmark; to?: NormalizedLandmark; }) => DrawingUtils.lerp(data.from!.z, -0.15, 0.1, 5, 1)
          });
          drawingUtils.drawConnectors(landmarks, PoseLandmarker.POSE_CONNECTIONS);

          // --- Push-up counting logic ---
          processPushup(landmarks);

        } else {
          // console.log("No landmarks detected");
        }
        canvasCtx.restore();
      });
    }

    // Call the function again recursively ONLY if still predicting
    if (isPredictingRef.current) {
        requestRef.current = requestAnimationFrame(predictWebcam);
    }

  }, [poseLandmarker, stream]); // Dependencies: Removed isActive, kept poseLandmarker and stream


  // --- Function to process landmarks for push-up counting ---
  const processPushup = (landmarks: NormalizedLandmark[]) => {
    // Indices for relevant landmarks (refer to MediaPipe pose documentation)
    const leftShoulder = landmarks[11];
    const rightShoulder = landmarks[12];
    const leftElbow = landmarks[13];
    const rightElbow = landmarks[14];
    const leftWrist = landmarks[15];
    const rightWrist = landmarks[16];
    const leftHip = landmarks[23];
    const rightHip = landmarks[24];
    const leftKnee = landmarks[25]; // Added for back straightness
    const rightKnee = landmarks[26]; // Added for back straightness

    // Basic visibility check (ensure key joints are detected)
    // Updated to include knees
    const areLandmarksVisible = [
        leftShoulder, rightShoulder, leftElbow, rightElbow, leftWrist, rightWrist,
        leftHip, rightHip, leftKnee, rightKnee
    ].every(lm => lm && lm.visibility && lm.visibility > PUSHUP_THRESHOLD_VISIBILITY);

    if (!areLandmarksVisible) {
      // console.log("Key landmarks not visible enough for push-up detection.");
      // Optionally provide feedback to the user about visibility
      return; // Skip processing if visibility is low
    }

    // Calculate elbow angles
    const leftElbowAngle = calculateAngle(leftShoulder, leftElbow, leftWrist);
    const rightElbowAngle = calculateAngle(rightShoulder, rightElbow, rightWrist);
    const elbowAngle = (leftElbowAngle + rightElbowAngle) / 2; // Average elbow angle

    // Calculate back straightness angles (shoulder-hip-knee)
    const leftBodyAngle = calculateAngle(leftShoulder, leftHip, leftKnee);
    const rightBodyAngle = calculateAngle(rightShoulder, rightHip, rightKnee);
    const bodyAngle = (leftBodyAngle + rightBodyAngle) / 2; // Average body angle

    // Check form conditions
    const isBackStraight = bodyAngle >= BACK_STRAIGHT_THRESHOLD_ANGLE;
    const isArmsExtended = elbowAngle >= PUSHUP_THRESHOLD_ANGLE_UP;
    const isArmsBentDown = elbowAngle <= PUSHUP_THRESHOLD_ANGLE_DOWN;

    // More robust state machine logic
    // Current state: pushupState ('start', 'down', 'up')
    // 'start' = initial state or reset after bad form/incomplete rep. Expecting extension.
    // 'down' = successfully reached down position with good form. Expecting extension.
    // 'up' = successfully extended from down position with good form (rep counted). Expecting bend.

    if (!isBackStraight) {
      // If back is not straight at any point, reset state and wait for good form.
      // Optionally provide feedback about back form here.
      if (pushupState !== 'start') {
          console.log("Form Error: Back not straight. Resetting state. Body Angle:", bodyAngle.toFixed(0));
          setPushupState('start');
      }
      return; // Don't process rep logic if back isn't straight
    }

    // --- State Transitions (only if back is straight) ---
    switch (pushupState) {
        case 'start':
            // Need to be extended first before starting the downward movement
            if (isArmsExtended) {
                setPushupState('up'); // Ready to go down
                console.log("State -> UP (Ready) (Elbow:", elbowAngle.toFixed(0), "Body:", bodyAngle.toFixed(0), ")");
            }
            // Else: still waiting for user to get into starting position (arms extended, back straight)
            break;

        case 'up': // Arms are extended, waiting for downward motion
            if (isArmsBentDown) {
                // Successfully reached the 'down' position with good form
                setPushupState('down');
                console.log("State -> DOWN (Elbow:", elbowAngle.toFixed(0), "Body:", bodyAngle.toFixed(0), ")");
            }
            // Else: still in 'up' state or moving down but not bent enough yet
            break;

        case 'down': // Arms are bent, waiting for upward motion (extension)
            if (isArmsExtended) {
                // Successfully returned to 'up' position -> COUNT REP
                setPushupState('up');
                setRepCount(prev => prev + 1);
                console.log("State -> UP (Rep Counted:", repCount + 1, ", Elbow:", elbowAngle.toFixed(0), "Body:", bodyAngle.toFixed(0), ")");
            }
            // Else: still in 'down' state or moving up but not extended enough yet
            break;
    }
  };

  // --- Helper function to calculate angle between three points ---
  // This needs to be implemented correctly based on landmark coordinates (x, y, [z])
  const calculateAngle = (a: NormalizedLandmark, b: NormalizedLandmark, c: NormalizedLandmark): number => {
    // Placeholder - returns a dummy value.
    // **Actual implementation required here using vector math.**
    // Example structure:
    // const radians = Math.atan2(c.y - b.y, c.x - b.x) - Math.atan2(a.y - b.y, a.x - b.x);
    // let angle = Math.abs(radians * 180.0 / Math.PI);
    // if (angle > 180.0) {
    //   angle = 360 - angle;
    // }
    // return angle;

    // Temporary random angle for testing UI update
    // Remove this and implement the real calculation
    // return Math.random() * 180;
     try {
        const v1 = { x: a.x - b.x, y: a.y - b.y };
        const v2 = { x: c.x - b.x, y: c.y - b.y };

        const dot = v1.x * v2.x + v1.y * v2.y;
        const det = v1.x * v2.y - v1.y * v2.x; // For cross product in 2D

        const angleRad = Math.atan2(Math.abs(det), dot); // Gives angle in [0, PI]
        let angleDeg = angleRad * (180 / Math.PI);

        // Optional: refine angle based on Z if needed, but often 2D is sufficient

        // Ensure angle is between 0 and 180
        angleDeg = Math.max(0, Math.min(180, angleDeg));

        return angleDeg;
    } catch (error) {
        console.error("Error calculating angle:", error, {a, b, c});
        return 180; // Return neutral angle on error
    }
  };


  const handleStartPause = () => {
    if (isFinished || !permissionGranted || cameraError || isModelLoading || !poseLandmarker) return;

    const nextIsActive = !isActive;
    setIsActive(nextIsActive);

    if (nextIsActive) {
        // Starting
        console.log("Starting MediaPipe prediction loop (setting ref to true)...");
        isPredictingRef.current = true; // <-- Set ref to true
        setPushupState('start'); // Reset state on start
        lastVideoTimeRef.current = -1; // Reset timer ref
        // Clear previous animation frame just in case
        if (requestRef.current) cancelAnimationFrame(requestRef.current);
        requestRef.current = requestAnimationFrame(predictWebcam);
    } else {
        // Pausing
        console.log("Pausing MediaPipe prediction loop (setting ref to false)...");
        isPredictingRef.current = false; // <-- Set ref to false
        // Cancel animation frame is handled implicitly by the check inside predictWebcam now,
        // but we can still cancel it here for immediate effect if needed.
         if (requestRef.current) {
             cancelAnimationFrame(requestRef.current);
         }
    }
  };

  const handleFinish = async () => { // Make async for API call
    setIsActive(false);
    isPredictingRef.current = false; // <-- Ensure ref is false on finish
    setIsFinished(true);
    if (requestRef.current) {
      cancelAnimationFrame(requestRef.current);
    }

    console.log(`Workout finished! Reps: ${repCount}, Time: ${formatTime(timer)}`);

    // --- Save workout session data ---
    if (repCount > 0 && user) { // Only save if reps were counted and user is logged in
        setIsSubmitting(true);
        setError(null);
        try {
            // TODO: Define the backend endpoint and API client function properly
            // Assuming logExercise can handle this or needs modification
             const exerciseData: LogExerciseRequest = {
                exercise_id: EXERCISE_ID,
                reps: repCount, // Use the counted reps
                duration: timer, // Fixed: Use duration instead of duration_seconds
                // Add other metrics if available (form score, etc.)
                notes: `Tracked via webcam. State: ${pushupState}` // Example note
            };
            await logExercise(exerciseData); // Call the API
            console.log("Exercise logged successfully!");
            // Maybe show a success message before navigating
             setSuccess(true); // Show success state
             setTimeout(() => navigate('/history'), 2000); // Navigate after showing success

        } catch (err) {
            console.error("Failed to log exercise:", err);
            setError(err instanceof Error ? err.message : 'Failed to save workout session');
             setSuccess(false);
        } finally {
            setIsSubmitting(false);
        }
    } else if (repCount === 0) {
        // Optionally handle case where no reps were done
         console.log("No reps counted, session not saved.");
         // Maybe navigate back directly or show a message
         navigate('/exercises'); // Example: go back if nothing was done
    }

    // alert(`Workout finished! Reps: ${repCount}, Time: ${formatTime(timer)}`); // Replace alert with API call + feedback
  };

  const handleReset = () => {
    setIsActive(false);
    isPredictingRef.current = false; // <-- Ensure ref is false on reset
    setIsFinished(false);
    setRepCount(0);
    setTimer(0);
    setPushupState('start');
    setError(null); // Clear errors
    setSuccess(false); // Clear success state
    setIsSubmitting(false);

    if (requestRef.current) {
      cancelAnimationFrame(requestRef.current);
      console.log("Resetting MediaPipe state...");
    }
    // No need to re-initialize MediaPipe model here, just stop predictions
  };

  const formatTime = (timeInSeconds: number): string => {
    const minutes = Math.floor(timeInSeconds / 60).toString().padStart(2, '0');
    const seconds = (timeInSeconds % 60).toString().padStart(2, '0');
    return `${minutes}:${seconds}`;
  };

  return (
    <div className="space-y-6">
      <Button variant="outline" onClick={() => navigate('/exercises')} className="mb-4">
        &larr; Back to Exercises
      </Button>
      <h1 className="text-3xl font-semibold text-foreground">{EXERCISE_NAME} Tracker</h1>

      <Card className="bg-card rounded-lg shadow-sm overflow-hidden">
        <CardHeader>
          <CardTitle className="text-lg font-medium">Live Tracking</CardTitle>
          <CardDescription>Position yourself correctly for the camera and press Start.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Camera Feed Section */}
          <div className="aspect-video bg-muted rounded-md overflow-hidden relative">
            <video 
              ref={videoRef} 
              autoPlay 
              playsInline 
              className="w-full h-full object-cover" // Ensure video fills the container
              muted // Mute video to avoid feedback loops if audio was enabled
              onLoadedMetadata={() => {
                  console.log("Video metadata loaded.");
              }}
            />
            <canvas
              ref={canvasRef}
              className="absolute top-0 left-0 w-full h-full"
            />
            {/* Overlay messages based on camera/model state */}
            {/* Model Loading Indicator */}
            {isModelLoading && (
              <div className="absolute inset-0 flex flex-col items-center justify-center bg-black/60 text-white z-10">
                <Loader2 className="h-10 w-10 mb-3 animate-spin" />
                <span>Loading AI Model...</span>
              </div>
            )}
            {/* Model Error Message */}
            {!isModelLoading && modelError && (
               <div className="absolute inset-0 flex flex-col items-center justify-center bg-destructive/80 text-white p-4 text-center z-10">
                <VideoOff className="h-12 w-12 mb-2" />
                <p className="font-semibold mb-1">Model Loading Failed</p>
                <p className="text-sm">{modelError}</p>
              </div>
            )}
            {/* Camera Pending */}
            {permissionGranted === null && !isModelLoading && !modelError && (
              <div className="absolute inset-0 flex items-center justify-center bg-black/50 text-white">
                <Camera className="h-8 w-8 mr-2 animate-pulse" />
                <span>Requesting camera access...</span>
              </div>
            )}
            {/* Camera Denied/Error */}
            {permissionGranted === false && !isModelLoading && !modelError && (
              <div className="absolute inset-0 flex flex-col items-center justify-center bg-black/70 text-white p-4 text-center">
                <VideoOff className="h-12 w-12 mb-2 text-destructive" />
                <p className="font-semibold mb-1">Camera Access Issue</p>
                <p className="text-sm">{cameraError || "Could not access camera. Check permissions and connection."}</p>
              </div>
            )}
          </div>

          {/* Stats Display */}
          <div className="grid grid-cols-2 gap-4 text-center">
            <div>
              <p className="text-sm font-medium text-muted-foreground">Reps</p>
              <p className="text-4xl font-bold text-foreground">{repCount}</p>
            </div>
            <div>
              <p className="text-sm font-medium text-muted-foreground">Time</p>
              <p className="text-4xl font-bold text-foreground flex items-center justify-center">
                <Timer className="h-6 w-6 mr-1 inline-block" />
                {formatTime(timer)}
              </p>
            </div>
          </div>

          {/* New Instructions Section */}
          <div className="pt-4 border-t">
            <h3 className="text-md font-semibold mb-2 text-foreground">Form Requirements for Rep Count:</h3>
            <ul className="list-disc pl-5 space-y-1 text-sm text-muted-foreground">
              <li>
                <strong>Camera:</strong> Place side-on to capture your full body clearly.
              </li>
              <li>
                <strong>Body:</strong> Keep your body straight (head to heels) throughout.
                (Angle &gt;= {BACK_STRAIGHT_THRESHOLD_ANGLE}°)
              </li>
              <li>
                <strong>Movement:</strong> 
                Lower until elbows bend to at least {PUSHUP_THRESHOLD_ANGLE_DOWN}°, 
                then push up until arms are fully extended (elbow angle &gt;= {PUSHUP_THRESHOLD_ANGLE_UP}°).
              </li>
               <li>
                <strong>Rep Counts:</strong> Only reps with correct form through the full range of motion are counted.
              </li>
            </ul>
          </div>

        </CardContent>
        <CardFooter className="border-t bg-background/50 px-6 py-4 flex flex-wrap justify-center gap-4">
            {!isFinished ? (
              <>
                <Button size="lg" onClick={handleStartPause} disabled={isFinished || !permissionGranted || !!cameraError || isModelLoading || !!modelError}>
                  {isModelLoading ? <Loader2 className="mr-2 h-5 w-5 animate-spin" /> : (isActive ? <Pause className="mr-2 h-5 w-5" /> : <Play className="mr-2 h-5 w-5" />)}
                  {isModelLoading ? 'Loading...' : (isActive ? 'Pause' : 'Start')}
                </Button>
                <Button size="lg" variant="secondary" onClick={handleReset} disabled={isActive || isFinished || (!permissionGranted && !cameraError && !isModelLoading)}> {/* Allow reset even if model failed? */}
                  <RotateCcw className="mr-2 h-5 w-5" /> Reset
                </Button>
                <Button size="lg" variant="destructive" onClick={handleFinish} disabled={isActive || isFinished || repCount === 0} >
                   {isSubmitting ? <Loader2 className="mr-2 h-5 w-5 animate-spin" /> : null}
                   Finish & Save
                </Button>
              </>
            ) : (
                 <div className="text-center w-full">
                    {isSubmitting && <p className="flex items-center justify-center"><Loader2 className="mr-2 h-4 w-4 animate-spin" /> Saving...</p>}
                    {error && <p className="text-destructive text-sm mt-2">Error: {error}</p>}
                    {success && <p className="text-green-600 text-sm mt-2">Workout saved successfully! Redirecting...</p>}
                    {!isSubmitting && !error && !success && <p>Workout Complete!</p>}
                    <Button size="lg" variant="outline" onClick={handleReset} className="mt-4">
                        Track Another Session
                    </Button>
                 </div>
            )}
        </CardFooter>
      </Card>
    </div>
  );
};

export default PushupTracker; 