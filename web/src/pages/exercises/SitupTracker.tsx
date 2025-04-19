import React, { useState, useRef, useEffect, useCallback } from 'react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Camera, Play, Pause, RotateCcw, Timer, VideoOff, Loader2 } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { logExercise } from '../../lib/apiClient';
import { LogExerciseRequest, ExerciseResponse } from '../../lib/types';
import { useAuth } from '../../lib/authContext';
// --- MediaPipe Imports ---
import {
  PoseLandmarker,
  FilesetResolver,
  DrawingUtils,
  NormalizedLandmark,
  PoseLandmarkerResult
} from "@mediapipe/tasks-vision";

// --- Sit-up specific logic constants (tuned for stricter form) ---
const SITUP_THRESHOLD_ANGLE_DOWN = 160; // Min hip angle (shoulder-hip-knee) when DOWN (closer to 180)
const SITUP_THRESHOLD_ANGLE_UP = 80;  // Max hip angle (shoulder-hip-knee) when UP (more acute)
const HAND_POSITION_THRESHOLD_FACTOR = 0.6; // Max wrist-ear distance relative to shoulder width
const FOOT_LIFT_THRESHOLD = 0.08; // Max allowed relative vertical ankle movement (fraction of hip-knee distance)
const SITUP_THRESHOLD_VISIBILITY = 0.6; // Visibility threshold for landmarks

// Helper function to calculate distance between two landmarks
const calculateDistance = (lm1: NormalizedLandmark, lm2: NormalizedLandmark): number => {
    if (!lm1 || !lm2) return Infinity;
    return Math.sqrt(Math.pow(lm1.x - lm2.x, 2) + Math.pow(lm1.y - lm2.y, 2));
};

const SitupTracker: React.FC = () => {
  const navigate = useNavigate();
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
  const requestRef = useRef<number>();
  const lastVideoTimeRef = useRef<number>(-1);
  const isPredictingRef = useRef(false);

  // --- Sit-up Tracking State ---
  const [situpState, setSitupState] = useState<'start' | 'down' | 'up'>('start'); // State machine for sit-up
  const formFaultDuringRep = useRef(false); // Track if form failed during the current rep cycle
  const initialLeftAnkleY = useRef<number | null>(null); // Store initial ankle positions when down
  const initialRightAnkleY = useRef<number | null>(null);

  // UI state for Live Tracking submission
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null); // Error for API submission
  const [success, setSuccess] = useState(false); // Success for API submission
  const [loggedGrade, setLoggedGrade] = useState<number | null>(null); // Grade from API response
  const [formFaultMessage, setFormFaultMessage] = useState<string | null>(null);

  // Constants for this exercise
  const EXERCISE_ID = 2; // Correct ID for sit-ups
  const EXERCISE_NAME = 'Sit-ups'; // Correct name

  // --- MediaPipe Initialization Effect ---
  useEffect(() => {
    let landmarkInstance: PoseLandmarker | null = null;
    const initializeMediaPipe = async () => {
      setIsModelLoading(true);
      setModelError(null);
      try {
        const vision = await FilesetResolver.forVisionTasks(
          "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.14/wasm"
        );
        landmarkInstance = await PoseLandmarker.createFromOptions(vision, {
          baseOptions: {
            modelAssetPath: `/models/pose_landmarker_lite.task`,
            delegate: "GPU"
          },
          runningMode: "VIDEO",
          numPoses: 1
        });
        setPoseLandmarker(landmarkInstance);
        console.log("Pose Landmarker model loaded successfully.");
      } catch (err) {
        console.error("Failed to initialize MediaPipe Pose Landmarker:", err);
        setModelError(`Failed to load model: ${err instanceof Error ? err.message : String(err)}`);
        setPoseLandmarker(null);
      } finally {
        setIsModelLoading(false);
      }
    };
    initializeMediaPipe();
    return () => {
        landmarkInstance?.close();
        setPoseLandmarker(null);
        console.log("Pose Landmarker closed.");
    }
  }, []);

  // --- Camera Request Effect ---
   useEffect(() => {
    let currentStream: MediaStream | null = null;
    const getCameraStream = async () => {
      setPermissionGranted(null);
      setCameraError(null);
      try {
        const constraints: MediaStreamConstraints = {
          video: {
            facingMode: 'user',
            width: { ideal: 640 },
            height: { ideal: 480 }
          },
          audio: false
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
    return () => {
      if (currentStream) {
        currentStream.getTracks().forEach(track => track.stop());
        console.log("Camera stream stopped.");
      }
      if (videoRef.current) {
          videoRef.current.srcObject = null;
      }
      if (requestRef.current) {
        cancelAnimationFrame(requestRef.current);
      }
    };
  }, []);

  // --- Timer Effect ---
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
    if (!isPredictingRef.current) {
      // console.log("Prediction loop stopped via ref."); // Keep console clean
      return;
    }

    if (!videoRef.current || !poseLandmarker || !canvasRef.current || !stream) {
      // console.log("Prediction prerequisites not met (other than loop control)."); // Keep console clean
      if (!videoRef.current || !canvasRef.current || !poseLandmarker) {
        console.error("Critical prerequisite missing (video, canvas, or landmarker ref/instance). Stopping loop.");
        isPredictingRef.current = false;
        return;
      }
      if (!stream) {
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

    if (video.readyState >= 2) {
      if (canvas.width !== video.videoWidth || canvas.height !== video.videoHeight) {
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;
      }
    } else {
      requestRef.current = requestAnimationFrame(predictWebcam);
      return;
    }

    if (video.currentTime !== lastVideoTimeRef.current) {
      lastVideoTimeRef.current = video.currentTime;
      const startTimeMs = performance.now();

      poseLandmarker.detectForVideo(video, startTimeMs, (result: PoseLandmarkerResult) => {
        canvasCtx.save();
        canvasCtx.clearRect(0, 0, canvas.width, canvas.height);
        if (result.landmarks && result.landmarks.length > 0) {
          const landmarks = result.landmarks[0];
          const drawingUtils = new DrawingUtils(canvasCtx);
          drawingUtils.drawLandmarks(landmarks, { radius: (data: { from?: NormalizedLandmark, to?: NormalizedLandmark }) => DrawingUtils.lerp(data.from!.z, -0.15, 0.1, 5, 1) });
          drawingUtils.drawConnectors(landmarks, PoseLandmarker.POSE_CONNECTIONS);

          // --- Sit-up counting logic ---
          processSitup(landmarks); // Call the sit-up specific function
        }
        canvasCtx.restore();
      });
    }

    if (isPredictingRef.current) {
      requestRef.current = requestAnimationFrame(predictWebcam);
    }
  }, [poseLandmarker, stream]);

  // --- Function to process landmarks for sit-up counting ---
  const processSitup = (landmarks: NormalizedLandmark[]) => {

    // 1. Identify relevant landmarks
    const leftShoulder = landmarks[11];
    const rightShoulder = landmarks[12];
    const leftHip = landmarks[23];
    const rightHip = landmarks[24];
    const leftKnee = landmarks[25];
    const rightKnee = landmarks[26];
    const leftAnkle = landmarks[27];
    const rightAnkle = landmarks[28];
    const leftWrist = landmarks[15];
    const rightWrist = landmarks[16];
    const leftEar = landmarks[7];
    const rightEar = landmarks[8];

    // 2. Check visibility for ALL required landmarks
     const areLandmarksVisible = [
        leftShoulder, rightShoulder, leftHip, rightHip, leftKnee, rightKnee,
        leftAnkle, rightAnkle, leftWrist, rightWrist, leftEar, rightEar
    ].every(lm => lm && lm.visibility && lm.visibility > SITUP_THRESHOLD_VISIBILITY);

     if (!areLandmarksVisible) {
       // Optionally provide feedback: "Ensure full body, hands, feet, and head are visible."
       if (situpState !== 'start') {
            // Reset state if visibility lost mid-rep
            setSitupState('start');
            formFaultDuringRep.current = false;
            initialLeftAnkleY.current = null;
            initialRightAnkleY.current = null;
            console.warn("Visibility lost, resetting sit-up state.");
            setFormFaultMessage("Ensure full body is visible.");
            setTimeout(() => setFormFaultMessage(null), 2000);
       }
       return;
    }

    // 3. Calculate angles and distances
    const leftHipAngle = calculateAngle(leftShoulder, leftHip, leftKnee);
    const rightHipAngle = calculateAngle(rightShoulder, rightHip, rightKnee);
    const hipAngle = (leftHipAngle + rightHipAngle) / 2;

    const shoulderWidth = calculateDistance(leftShoulder, rightShoulder);
    const leftHandDist = calculateDistance(leftWrist, leftEar);
    const rightHandDist = calculateDistance(rightWrist, rightEar);

    const leftHipKneeDist = calculateDistance(leftHip, leftKnee);
    const rightHipKneeDist = calculateDistance(rightHip, rightKnee);
    const avgHipKneeDist = (leftHipKneeDist + rightHipKneeDist) / 2;

    // 4. Check Form Conditions
    const handsBehindHead = leftHandDist < HAND_POSITION_THRESHOLD_FACTOR * shoulderWidth &&
                           rightHandDist < HAND_POSITION_THRESHOLD_FACTOR * shoulderWidth;

    // Check foot lift relative to initial position when down
    let feetOnGround = true;
    if (initialLeftAnkleY.current !== null && initialRightAnkleY.current !== null && avgHipKneeDist > 0.01) {
        // Check only if we have initial positions and non-zero hip-knee distance
        const leftAnkleLift = initialLeftAnkleY.current - leftAnkle.y; // Y decreases upwards
        const rightAnkleLift = initialRightAnkleY.current - rightAnkle.y;
        const maxLiftThreshold = FOOT_LIFT_THRESHOLD * avgHipKneeDist;

        if (leftAnkleLift > maxLiftThreshold || rightAnkleLift > maxLiftThreshold) {
            feetOnGround = false;
        }
    }

    // Check position states based on hip angle
    const isDown = hipAngle >= SITUP_THRESHOLD_ANGLE_DOWN;
    const isUp = hipAngle <= SITUP_THRESHOLD_ANGLE_UP;

    // 5. Implement State Machine with Form Checks
    let currentFormFault = false;
    let faultMsg = "";
    if (!handsBehindHead) {
        faultMsg = "Keep hands behind head!";
        currentFormFault = true;
    }
    if (!feetOnGround && situpState !== 'start' && initialLeftAnkleY.current !== null) {
        faultMsg = "Keep feet on the ground!";
        currentFormFault = true;
    }

    // Display form fault message if there's a new fault
    if (currentFormFault && !formFaultDuringRep.current) {
        setFormFaultMessage(faultMsg);
        setTimeout(() => setFormFaultMessage(null), 1500);
    }

    // Update persistent form fault flag if a fault occurs during the rep cycle
    if (currentFormFault) {
        formFaultDuringRep.current = true;
    }

    switch (situpState) {
        case 'start':
            if (isDown) {
                // Initial down position reached
                setSitupState('down');
                formFaultDuringRep.current = currentFormFault; // Record initial form state
                initialLeftAnkleY.current = leftAnkle.y;
                initialRightAnkleY.current = rightAnkle.y;
                console.log("State -> DOWN (Ready, Initial Feet Y recorded)");
            }
            break;

        case 'down':
            if (isUp) {
                // Reached the UP position
                if (!formFaultDuringRep.current) {
                    // Only count if no form fault occurred during the upward movement
                    setSitupState('up');
                    setRepCount(prev => prev + 1); // Count rep!
                    console.log("State -> UP (Rep Counted:", repCount + 1, "Hip Angle:", hipAngle.toFixed(0), ")");
                } else {
                    // Reached UP but form was bad during the rep
                    setSitupState('up'); // Still transition state
                    setFormFaultMessage("Invalid Rep - Check Form");
                    setTimeout(() => setFormFaultMessage(null), 1500);
                    console.warn("State -> UP (Rep INVALID - Form Fault Detected, Hip Angle:", hipAngle.toFixed(0), ")");
                }
            }
            // Else: still moving up or staying down. Form faults are being tracked by formFaultDuringRep.
            break;

        case 'up':
            if (isDown) {
                // Returned to the DOWN position, reset for next rep
                setSitupState('down');
                formFaultDuringRep.current = currentFormFault; // Reset fault flag based on current form at bottom
                initialLeftAnkleY.current = leftAnkle.y; // Record new initial ankle positions
                initialRightAnkleY.current = rightAnkle.y;
                console.log("State -> DOWN (Completed Rep Cycle, Ready for Next)");
            }
            // Else: still moving down or staying up. Form faults are being tracked.
            break;
     }

  };

  // --- Helper function to calculate angle between three points ---
  const calculateAngle = (a: NormalizedLandmark, b: NormalizedLandmark, c: NormalizedLandmark): number => {
     try {
        const v1 = { x: a.x - b.x, y: a.y - b.y };
        const v2 = { x: c.x - b.x, y: c.y - b.y };
        const dot = v1.x * v2.x + v1.y * v2.y;
        const det = v1.x * v2.y - v1.y * v2.x;
        const angleRad = Math.atan2(Math.abs(det), dot);
        let angleDeg = angleRad * (180 / Math.PI);
        angleDeg = Math.max(0, Math.min(180, angleDeg));
        return angleDeg;
    } catch (error) {
        console.error("Error calculating angle:", error, {a, b, c});
        return 180;
    }
  };

  // --- Control Handlers ---
  const handleStartPause = () => {
    if (isFinished || !permissionGranted || cameraError || isModelLoading || !poseLandmarker) return;
    const nextIsActive = !isActive;
    setIsActive(nextIsActive);
    if (nextIsActive) {
      console.log("Starting MediaPipe prediction loop (setting ref to true)...");
      isPredictingRef.current = true;
      setSitupState('start'); // Reset state
      lastVideoTimeRef.current = -1;
      if (requestRef.current) cancelAnimationFrame(requestRef.current);
      requestRef.current = requestAnimationFrame(predictWebcam);
    } else {
      console.log("Pausing MediaPipe prediction loop (setting ref to false)...");
      isPredictingRef.current = false;
      if (requestRef.current) {
        cancelAnimationFrame(requestRef.current);
      }
    }
  };

  const handleFinish = async () => {
    setIsActive(false);
    isPredictingRef.current = false;
    setIsFinished(true);
    if (requestRef.current) {
      cancelAnimationFrame(requestRef.current);
    }
    console.log(`Workout finished! Reps: ${repCount}, Time: ${formatTime(timer)}`);

    // Save workout session data (Live Tracking)
    if (repCount > 0 && user) {
      setIsSubmitting(true);
      setError(null); 
      setSuccess(false);
      setLoggedGrade(null);
      try {
        const exerciseData: LogExerciseRequest = {
          exercise_id: EXERCISE_ID,
          reps: repCount,
          duration: timer,
          notes: `Tracked via webcam. State: ${situpState}`
        };
        // Capture response to get grade
        const response: ExerciseResponse = await logExercise(exerciseData); 
        console.log("Live Exercise logged successfully!");
        setSuccess(true); 
        setLoggedGrade(response.grade ?? null); // Store grade
        
        // Reset live tracker state, but keep finished state until reset
        // setRepCount(0); // Keep reps visible until reset
        // setTimer(0); // Keep time visible until reset
        // setSitupState('start'); // Keep state as is
        // setIsFinished(false); // Keep finished state
        
      } catch (err) {
        console.error("Failed to log live exercise:", err);
        setError(err instanceof Error ? err.message : 'Failed to save live workout session');
        setSuccess(false);
        setLoggedGrade(null);
      } finally {
        setIsSubmitting(false); 
      }
    } else if (repCount === 0 && isFinished) {
       console.log("No live reps counted, session not saved.");
       // Reset live tracker state if nothing to save
       handleReset(); // Use handleReset for consistency?
       // setIsFinished(false); // Or just allow reset
    } else if (!user) {
        setError("You must be logged in to save results.");
        console.warn("Attempted to save workout while not logged in.");
        setIsFinished(false); // Allow user to try again? Or just block?
    }
  };

  const handleReset = () => {
    setIsActive(false);
    isPredictingRef.current = false;
    setIsFinished(false);
    setRepCount(0);
    setTimer(0);
    setSitupState('start');
    setError(null); 
    setSuccess(false); 
    setIsSubmitting(false);
    setLoggedGrade(null); // Reset grade
    setFormFaultMessage(null); // Reset fault message
    formFaultDuringRep.current = false; // Reset fault ref
    initialLeftAnkleY.current = null;
    initialRightAnkleY.current = null;
    
    if (requestRef.current) {
      cancelAnimationFrame(requestRef.current);
      console.log("Resetting MediaPipe state...");
    }
  };

  const formatTime = (timeInSeconds: number): string => {
    const minutes = Math.floor(timeInSeconds / 60).toString().padStart(2, '0');
    const seconds = (timeInSeconds % 60).toString().padStart(2, '0');
    return `${minutes}:${seconds}`;
  };

  // --- JSX ---
  return (
    <div className="space-y-6">
      <Button variant="outline" onClick={() => navigate('/exercises')} className="mb-4">
        &larr; Back to Exercises
      </Button>
      <h1 className="text-3xl font-semibold text-foreground">{EXERCISE_NAME} Tracker</h1>

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
          <div className="relative aspect-video overflow-hidden rounded-md bg-muted">
            <video ref={videoRef} autoPlay playsInline className="size-full object-cover" muted onLoadedMetadata={() => console.log("Video metadata loaded.")} />
            <canvas ref={canvasRef} className="absolute left-0 top-0 size-full" />
            {/* Overlays */}
            {formFaultMessage && (
              <div className="absolute bottom-4 left-1/2 z-20 -translate-x-1/2 rounded-md bg-destructive/80 px-4 py-2 text-sm font-semibold text-white">
                {formFaultMessage}
              </div>
            )}
            {isModelLoading && ( <div className="absolute inset-0 z-10 flex flex-col items-center justify-center bg-black/60 text-white"><Loader2 className="mb-3 size-10 animate-spin" /><span>Loading AI Model...</span></div> )}
            {!isModelLoading && modelError && ( <div className="absolute inset-0 z-10 flex flex-col items-center justify-center bg-destructive/80 p-4 text-center text-white"><VideoOff className="mb-2 size-12" /><p className="mb-1 font-semibold">Model Loading Failed</p><p className="text-sm">{modelError}</p></div> )}
            {permissionGranted === null && !isModelLoading && !modelError && ( <div className="absolute inset-0 flex items-center justify-center bg-black/50 text-white"><Camera className="mr-2 size-8 animate-pulse" /><span>Requesting camera access...</span></div> )}
            {permissionGranted === false && !isModelLoading && !modelError && ( <div className="absolute inset-0 flex flex-col items-center justify-center bg-black/70 p-4 text-center text-white"><VideoOff className="mb-2 size-12 text-destructive" /><p className="mb-1 font-semibold">Camera Access Issue</p><p className="text-sm">{cameraError || "Could not access camera."}</p></div> )}
          </div>
          {/* Stats Display */}
          <div className="grid grid-cols-2 gap-4 text-center">
            <div><p className="text-sm font-medium text-muted-foreground">Reps</p><p className="text-4xl font-bold text-foreground">{repCount}</p></div>
            <div><p className="text-sm font-medium text-muted-foreground">Time</p><p className="flex items-center justify-center text-4xl font-bold text-foreground"><Timer className="mr-1 inline-block size-6" />{formatTime(timer)}</p></div>
          </div>

          {/* New Instructions Section */}
          <div className="border-t pt-4">
            <h3 className="text-md mb-2 font-semibold text-foreground">Form Requirements for Rep Count:</h3>
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
        <CardFooter className="flex flex-wrap justify-center gap-4 border-t bg-background/50 px-6 py-4">
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
                   Finish & Save Reps
                </Button>
              </>
            ) : (
                 <div className="w-full text-center">
                    {isSubmitting && <p className="flex items-center justify-center"><Loader2 className="mr-2 size-4 animate-spin" /> Saving Live Session...</p>}
                    {/* Display error/success related to live save attempt */}
                    {error && !isSubmitting && <p className="mt-2 text-sm text-destructive">Error Saving: {error}</p>}
                    {success && !isSubmitting && (
                      <p className="mt-2 text-sm text-green-600">
                        Live Workout saved successfully!
                        {loggedGrade !== null && ` Grade: ${loggedGrade}`}
                      </p>
                    )}
                    {!isSubmitting && !error && !success && <p>Live Workout Complete! Press Reset to start again.</p>}
                    <Button size="lg" variant="outline" onClick={handleReset} className="mt-4">
                        Reset Tracker
                    </Button>
                 </div>
            )}
        </CardFooter>
      </Card>
    </div>
  );
};

export default SitupTracker; 