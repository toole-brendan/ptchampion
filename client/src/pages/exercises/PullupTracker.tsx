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

// --- Pull-up specific logic constants (adjust as needed) ---
const PULLUP_THRESHOLD_ELBOW_ANGLE_DOWN = 160; // Angle for fully extended arms at bottom
const PULLUP_THRESHOLD_VISIBILITY = 0.6;      // Visibility threshold for landmarks
// Threshold for chin (nose landmark) being above wrists (bar)
// Positive value means nose needs to be *higher* than wrists (smaller y-coordinate)
// This depends heavily on camera angle and user proportions - requires tuning!
const CHIN_OVER_BAR_VERTICAL_THRESHOLD = 0.05; // e.g., nose y < wrist y - 0.05
// Threshold to detect excessive kipping (vertical hip movement relative to shoulders)
const KIPPING_VERTICAL_THRESHOLD = 0.15; // Max allowed relative hip displacement (tune this)


const PullupTracker: React.FC = () => {
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
  const requestRef = useRef<number>(); // For requestAnimationFrame
  const lastVideoTimeRef = useRef<number>(-1);
  const isPredictingRef = useRef(false);

  // --- Pull-up Tracking State ---
  const [pullupState, setPullupState] = useState<'start' | 'down' | 'up'>('start'); // State machine
  const [formFault, setFormFault] = useState(false); // Track form issues during a rep
  // Ref to store initial hip position at the bottom of the rep to check kipping
  const initialHipYRef = useRef<number | null>(null);
  const initialShoulderYRef = useRef<number | null>(null); // Relative reference for hip

  // UI state for Live Tracking submission
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  // Constants for this exercise
  const EXERCISE_ID = 3; // Assuming 3 is the ID for pull-ups
  const EXERCISE_NAME = 'Pull-ups';

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
        console.log("Pose Landmarker model loaded successfully for Pull-ups.");
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
          video: { facingMode: 'user', width: { ideal: 640 }, height: { ideal: 480 } },
          audio: false
        };
        currentStream = await navigator.mediaDevices.getUserMedia(constraints);
        setStream(currentStream);
        if (videoRef.current) { videoRef.current.srcObject = currentStream; }
        setPermissionGranted(true);
      } catch (err) {
        console.error("Error accessing camera:", err);
        if (err instanceof Error) {
            if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') { setCameraError("Camera permission denied."); }
            else if (err.name === 'NotFoundError' || err.name === 'DevicesNotFoundError') { setCameraError("No camera found."); }
            else { setCameraError(`Error accessing camera: ${err.message}`); }
        } else { setCameraError("An unknown camera error occurred."); }
        setPermissionGranted(false);
        setStream(null);
      }
    };
    getCameraStream();
    return () => {
      if (currentStream) { currentStream.getTracks().forEach(track => track.stop()); }
      if (videoRef.current) { videoRef.current.srcObject = null; }
      if (requestRef.current) { cancelAnimationFrame(requestRef.current); }
    };
  }, []);

  // --- Timer Effect ---
  useEffect(() => {
    if (isActive) {
      timerIntervalRef.current = setInterval(() => { setTimer((prev) => prev + 1); }, 1000);
    } else if (timerIntervalRef.current) {
      clearInterval(timerIntervalRef.current);
      timerIntervalRef.current = null;
    }
    return () => { if (timerIntervalRef.current) { clearInterval(timerIntervalRef.current); } };
  }, [isActive]);

  // --- Prediction Loop ---
  const predictWebcam = useCallback(() => {
    if (!isPredictingRef.current || !videoRef.current || !poseLandmarker || !canvasRef.current || !stream) {
      if (!isPredictingRef.current) return; // Stop if intended
      // Keep requesting if momentarily missing prerequisites but loop is active
      requestRef.current = requestAnimationFrame(predictWebcam);
      return;
    }

    const video = videoRef.current;
    const canvas = canvasRef.current;
    const canvasCtx = canvas.getContext("2d");
    if (!canvasCtx) return;

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
          drawingUtils.drawLandmarks(landmarks, {
            radius: (data: { index?: number; from?: NormalizedLandmark; to?: NormalizedLandmark; }) => DrawingUtils.lerp(data.from!.z, -0.15, 0.1, 5, 1)
          });
          drawingUtils.drawConnectors(landmarks, PoseLandmarker.POSE_CONNECTIONS);

          // --- Pull-up counting logic ---
          if (isActive) { // Only process if timer is active
             processPullup(landmarks);
          }

        }
        canvasCtx.restore();
      });
    }

    if (isPredictingRef.current) {
      requestRef.current = requestAnimationFrame(predictWebcam);
    }
  }, [poseLandmarker, stream, isActive]); // Include isActive here

  // --- Function to process landmarks for pull-up counting ---
  const processPullup = (landmarks: NormalizedLandmark[]) => {
    // Indices for relevant landmarks
    const leftShoulder = landmarks[11];
    const rightShoulder = landmarks[12];
    const leftElbow = landmarks[13];
    const rightElbow = landmarks[14];
    const leftWrist = landmarks[15]; // Represents hand on bar
    const rightWrist = landmarks[16]; // Represents hand on bar
    const nose = landmarks[0];         // Represents chin position
    const leftHip = landmarks[23];
    const rightHip = landmarks[24];

    // Basic visibility check
    const areLandmarksVisible = [
        leftShoulder, rightShoulder, leftElbow, rightElbow, leftWrist, rightWrist,
        nose, leftHip, rightHip
    ].every(lm => lm && lm.visibility && lm.visibility > PULLUP_THRESHOLD_VISIBILITY);

    if (!areLandmarksVisible) {
      // console.warn("Key landmarks not visible for pull-up detection.");
      setFormFault(true); // Mark potential fault if landmarks disappear mid-rep
      return;
    }

    // Calculate elbow angles (average)
    const leftElbowAngle = calculateAngle(leftShoulder, leftElbow, leftWrist);
    const rightElbowAngle = calculateAngle(rightShoulder, rightElbow, rightWrist);
    const elbowAngle = (leftElbowAngle + rightElbowAngle) / 2;

    // Calculate vertical positions (y-coordinate, smaller is higher on screen)
    const noseY = nose.y;
    const avgWristY = (leftWrist.y + rightWrist.y) / 2;
    const avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    const avgHipY = (leftHip.y + rightHip.y) / 2;

    // Conditions for state transitions
    const isArmsExtended = elbowAngle >= PULLUP_THRESHOLD_ELBOW_ANGLE_DOWN;
    // Check if nose is significantly higher than wrists
    const isChinOverBar = noseY < avgWristY - CHIN_OVER_BAR_VERTICAL_THRESHOLD;

    // --- State Machine Logic ---
    switch (pullupState) {
        case 'start':
            // Waiting to reach the bottom hang position (arms extended)
            if (isArmsExtended) {
                setPullupState('down');
                setFormFault(false); // Reset fault flag for the new rep attempt
                // Record initial positions for kipping check
                initialHipYRef.current = avgHipY;
                initialShoulderYRef.current = avgShoulderY;
                console.log("State -> DOWN (Arms Extended)");
            }
            break;

        case 'down':
            // At the bottom, waiting for upward movement AND chin over bar
            if (isChinOverBar) {
                // Check for excessive kipping during the upward movement
                const currentRelativeHipY = avgHipY - avgShoulderY;
                const initialRelativeHipY = initialHipYRef.current !== null && initialShoulderYRef.current !== null
                    ? initialHipYRef.current - initialShoulderYRef.current
                    : currentRelativeHipY; // Use current if initial wasn't set (unlikely)

                // Kipping check: Did the hips move upwards significantly MORE than the shoulders?
                // We check if the initial relative position (hip below shoulder) decreased too much
                // (i.e., hip got much closer to shoulder vertically during the pull)
                const verticalHipDisplacement = initialRelativeHipY - currentRelativeHipY;

                if (verticalHipDisplacement > KIPPING_VERTICAL_THRESHOLD) {
                    console.warn(`Form Fault: Excessive Kipping Detected! Displacement: ${verticalHipDisplacement.toFixed(3)}`);
                    setFormFault(true); // Mark rep as faulty due to kipping
                }

                // Transition to 'up' regardless of kipping for state flow, fault flag handles counting
                setPullupState('up');
                console.log(`State -> UP (Chin Over Bar: ${isChinOverBar}, Kipping Fault: ${formFault})`);

            } else if (!isArmsExtended) {
                // If arms start bending but chin isn't over bar yet, still 'down'
                // Optional: Add checks here for partial reps or getting stuck
            }
            break;

        case 'up':
            // At the top, waiting for downward movement (arms extending)
            if (isArmsExtended) {
                // Successfully returned to bottom hang position
                if (!formFault) {
                    // Only count if no form fault was detected during the rep
                    setRepCount(prev => prev + 1);
                    console.log("State -> DOWN (Rep Counted:", repCount + 1, ")");
                } else {
                    console.log("State -> DOWN (Rep Not Counted due to Form Fault)");
                }
                setPullupState('down'); // Go back to down state, ready for next rep
                setFormFault(false); // Reset fault flag
                // Record new initial positions
                initialHipYRef.current = avgHipY;
                initialShoulderYRef.current = avgShoulderY;
            }
            // Else: Still in 'up' state or moving down but not fully extended yet.
            // If landmarks become invisible here, the fault flag should already be set.
            break;
    }
  };

  // --- Helper function to calculate angle ---
  const calculateAngle = (a: NormalizedLandmark, b: NormalizedLandmark, c: NormalizedLandmark): number => {
     try {
        // Check for valid landmarks
        if (!a || !b || !c) return 180; // Neutral angle if landmark missing

        const v1 = { x: a.x - b.x, y: a.y - b.y };
        const v2 = { x: c.x - b.x, y: c.y - b.y };
        const dot = v1.x * v2.x + v1.y * v2.y;
        const det = v1.x * v2.y - v1.y * v2.x;
        const angleRad = Math.atan2(Math.abs(det), dot);
        let angleDeg = angleRad * (180 / Math.PI);
        return Math.max(0, Math.min(180, angleDeg));
    } catch (error) {
        console.error("Error calculating angle:", error, {a, b, c});
        return 180; // Return neutral angle on error
    }
  };

  // --- Control Handlers ---
  const handleStartPause = () => {
    if (isFinished || !permissionGranted || cameraError || isModelLoading || !poseLandmarker) return;
    const nextIsActive = !isActive;
    setIsActive(nextIsActive);
    if (nextIsActive) {
        console.log("Starting MediaPipe prediction loop...");
        isPredictingRef.current = true;
        setPullupState('start'); // Reset state on start/resume
        setFormFault(false);
        initialHipYRef.current = null; // Clear initial positions
        initialShoulderYRef.current = null;
        lastVideoTimeRef.current = -1;
        if (requestRef.current) cancelAnimationFrame(requestRef.current);
        requestRef.current = requestAnimationFrame(predictWebcam);
    } else {
        console.log("Pausing MediaPipe prediction loop...");
        isPredictingRef.current = false;
         if (requestRef.current) cancelAnimationFrame(requestRef.current);
    }
  };

  const handleFinish = async () => {
    setIsActive(false);
    isPredictingRef.current = false;
    setIsFinished(true);
    if (requestRef.current) cancelAnimationFrame(requestRef.current);

    console.log(`Workout finished! Reps: ${repCount}, Time: ${formatTime(timer)}`);

    if (repCount > 0 && user) {
        setIsSubmitting(true);
        setError(null);
        setSuccess(false);
        try {
             const exerciseData: LogExerciseRequest = {
                exercise_id: EXERCISE_ID,
                reps: repCount,
                duration: timer,
                notes: `Tracked via webcam. Final State: ${pullupState}`
            };
            await logExercise(exerciseData);
            console.log("Pull-up exercise logged successfully!");
            setSuccess(true);
             setTimeout(() => navigate('/history'), 2000); // Redirect after success
        } catch (err) {
            console.error("Failed to log pull-up exercise:", err);
            setError(err instanceof Error ? err.message : 'Failed to save workout');
            setSuccess(false);
        } finally {
            setIsSubmitting(false);
        }
    } else if (repCount === 0) {
         console.log("No reps counted, session not saved.");
         navigate('/exercises');
    }
  };

  const handleReset = () => {
    setIsActive(false);
    isPredictingRef.current = false;
    setIsFinished(false);
    setRepCount(0);
    setTimer(0);
    setPullupState('start');
    setFormFault(false);
    initialHipYRef.current = null;
    initialShoulderYRef.current = null;
    setError(null);
    setSuccess(false);
    setIsSubmitting(false);
    if (requestRef.current) cancelAnimationFrame(requestRef.current);
    console.log("Resetting MediaPipe state...");
  };

  const formatTime = (timeInSeconds: number): string => {
    const minutes = Math.floor(timeInSeconds / 60).toString().padStart(2, '0');
    const seconds = (timeInSeconds % 60).toString().padStart(2, '0');
    return `${minutes}:${seconds}`;
  };

  // --- JSX Structure (based on PushupTracker) ---
  return (
    <div className="space-y-6">
      <Button variant="outline" onClick={() => navigate('/exercises')} className="mb-4">
        &larr; Back to Exercises
      </Button>
      <h1 className="text-3xl font-semibold text-foreground">{EXERCISE_NAME} Tracker</h1>

      <Card className="bg-card rounded-lg shadow-sm overflow-hidden">
        <CardHeader>
          <CardTitle className="text-lg font-medium">Live Tracking</CardTitle>
          {/* Simplified description */}
          <CardDescription>Position yourself correctly for the camera and press Start.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          {/* Camera Feed Section */}
          <div className="aspect-video bg-muted rounded-md overflow-hidden relative">
            <video
              ref={videoRef}
              autoPlay
              playsInline
              className="w-full h-full object-cover"
              muted
              onLoadedMetadata={() => console.log("Video metadata loaded.")}
            />
            <canvas
              ref={canvasRef}
              className="absolute top-0 left-0 w-full h-full"
            />
            {/* Overlay messages (Loading, Errors, Permissions) */}
             {isModelLoading && (
              <div className="absolute inset-0 flex flex-col items-center justify-center bg-black/60 text-white z-10">
                <Loader2 className="h-10 w-10 mb-3 animate-spin" /><span>Loading AI Model...</span>
              </div>
            )}
            {!isModelLoading && modelError && (
               <div className="absolute inset-0 flex flex-col items-center justify-center bg-destructive/80 text-white p-4 text-center z-10">
                <VideoOff className="h-12 w-12 mb-2" /><p className="font-semibold mb-1">Model Failed</p><p className="text-sm">{modelError}</p>
              </div>
            )}
            {permissionGranted === null && !isModelLoading && !modelError && (
              <div className="absolute inset-0 flex items-center justify-center bg-black/50 text-white">
                <Camera className="h-8 w-8 mr-2 animate-pulse" /><span>Requesting camera...</span>
              </div>
            )}
            {permissionGranted === false && !isModelLoading && !modelError && (
              <div className="absolute inset-0 flex flex-col items-center justify-center bg-black/70 text-white p-4 text-center">
                <VideoOff className="h-12 w-12 mb-2 text-destructive" /><p className="font-semibold mb-1">Camera Issue</p><p className="text-sm">{cameraError || "Could not access camera."}</p>
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
                <Timer className="h-6 w-6 mr-1 inline-block" />{formatTime(timer)}
              </p>
            </div>
          </div>

          {/* New Instructions Section for Pull-ups */}
          <div className="pt-4 border-t">
            <h3 className="text-md font-semibold mb-2 text-foreground">Form Requirements for Rep Count:</h3>
            <ul className="list-disc pl-5 space-y-1 text-sm text-muted-foreground">
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
        <CardFooter className="border-t bg-background/50 px-6 py-4 flex flex-wrap justify-center gap-4">
            {/* Controls (identical structure to PushupTracker) */}
             {!isFinished ? (
              <>
                <Button size="lg" onClick={handleStartPause} disabled={isFinished || !permissionGranted || !!cameraError || isModelLoading || !!modelError}>
                  {isModelLoading ? <Loader2 className="mr-2 h-5 w-5 animate-spin" /> : (isActive ? <Pause className="mr-2 h-5 w-5" /> : <Play className="mr-2 h-5 w-5" />)}
                  {isModelLoading ? 'Loading...' : (isActive ? 'Pause' : 'Start')}
                </Button>
                <Button size="lg" variant="secondary" onClick={handleReset} disabled={isActive || isFinished || (!permissionGranted && !cameraError && !isModelLoading)}>
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
                    {success && <p className="text-green-600 text-sm mt-2">Workout saved! Redirecting...</p>}
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

export default PullupTracker; 