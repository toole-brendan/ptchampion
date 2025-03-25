import { useEffect, useRef, useState } from "react";
import { useParams, useLocation } from "wouter";
import { useQuery, useMutation } from "@tanstack/react-query";
import { useAuth } from "@/hooks/use-auth";
import Navigation from "@/components/navigation";
import CameraView from "@/components/camera-view";
import { Button } from "@/components/ui/button";
import { queryClient, apiRequest } from "@/lib/queryClient";
import { detectPose, detectPushup, detectPullup, detectSitup, PushupState, PullupState, SitupState } from "@/lib/tensorflow";
import { calculatePushupGrade, calculatePullupGrade, calculateSitupGrade, getScoreRating } from "@/lib/exercise-grading";
import { AlertCircle, ArrowLeft, CheckCircle, AlertTriangle, XCircle, Play, Pause, Square } from "lucide-react";

export default function ExercisePage() {
  const { type } = useParams();
  const [, setLocation] = useLocation();
  const { user } = useAuth();
  const videoRef = useRef<HTMLVideoElement>(null);
  
  // State for exercise tracking
  const [isStarted, setIsStarted] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [exerciseState, setExerciseState] = useState<PushupState | PullupState | SitupState>({
    isUp: false,
    isDown: false,
    count: 0,
    formScore: 0,
    feedback: "Position yourself in the frame"
  });
  
  // Analysis state
  const [formAnalysis, setFormAnalysis] = useState<{
    arms: "good" | "warning" | "bad";
    position: "good" | "warning" | "bad";
    depth: "good" | "warning" | "bad";
  }>({
    arms: "good",
    position: "warning",
    depth: "bad"
  });

  // Get exercise details
  const { data: exercises } = useQuery({
    queryKey: ["/api/exercises"],
    enabled: !!user
  });
  
  const exercise = exercises?.find(e => e.type === type);
  
  // Camera setup and pose detection
  useEffect(() => {
    let animationFrameId: number;
    let stream: MediaStream | null = null;
    
    const setupCamera = async () => {
      if (!videoRef.current) return;
      
      try {
        stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: "user" },
          audio: false
        });
        
        videoRef.current.srcObject = stream;
      } catch (error) {
        console.error("Camera access error:", error);
      }
    };
    
    setupCamera();
    
    // Clean up function
    return () => {
      cancelAnimationFrame(animationFrameId);
      if (stream) {
        stream.getTracks().forEach(track => track.stop());
      }
    };
  }, []);
  
  // Pose detection loop
  useEffect(() => {
    let animationFrameId: number;
    const detectPoseLoop = async () => {
      if (!videoRef.current || !isStarted || isPaused) return;
      
      try {
        const pose = await detectPose(videoRef.current);
        
        if (pose) {
          let newState;
          
          // Use the appropriate detection function based on exercise type
          switch (type) {
            case "pushup":
              newState = detectPushup(pose, exerciseState as PushupState);
              break;
            case "pullup":
              newState = detectPullup(pose, exerciseState as PullupState);
              break;
            case "situp":
              newState = detectSitup(pose, exerciseState as SitupState);
              break;
          }
          
          if (newState) {
            setExerciseState(newState);
            
            // Update form analysis based on form score
            const score = newState.formScore;
            setFormAnalysis({
              arms: score >= 80 ? "good" : score >= 60 ? "warning" : "bad",
              position: score >= 70 ? "good" : score >= 50 ? "warning" : "bad",
              depth: score >= 60 ? "good" : score >= 40 ? "warning" : "bad"
            });
          }
        }
      } catch (error) {
        console.error("Pose detection error:", error);
      }
      
      animationFrameId = requestAnimationFrame(detectPoseLoop);
    };
    
    detectPoseLoop();
    
    return () => {
      cancelAnimationFrame(animationFrameId);
    };
  }, [isStarted, isPaused, exerciseState, type]);
  
  // Complete exercise mutation
  const completeMutation = useMutation({
    mutationFn: async () => {
      if (!exercise) throw new Error("Exercise not found");
      
      // Calculate grade based on exercise type and performance
      let grade = 0;
      switch (type) {
        case "pushup":
          grade = calculatePushupGrade(exerciseState.count);
          break;
        case "pullup":
          grade = calculatePullupGrade(exerciseState.count);
          break;
        case "situp":
          grade = calculateSitupGrade(exerciseState.count);
          break;
      }
      
      const data = {
        exerciseId: exercise.id,
        repetitions: exerciseState.count,
        formScore: exerciseState.formScore,
        grade, // Add calculated grade
        completed: true
      };
      
      const res = await apiRequest("POST", "/api/user-exercises", data);
      return await res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/user-exercises/latest/all"] });
      queryClient.invalidateQueries({ queryKey: ["/api/leaderboard/global"] });
      setLocation("/");
    }
  });
  
  // Handle control buttons
  const handleStart = () => {
    setIsStarted(true);
    setIsPaused(false);
  };
  
  const handlePause = () => {
    setIsPaused(true);
  };
  
  const handleStop = () => {
    setIsStarted(false);
    setIsPaused(false);
    // Save exercise results
    completeMutation.mutate();
  };
  
  // Get the title for display
  const getTitle = () => {
    switch (type) {
      case "pushup": return "Push-ups";
      case "pullup": return "Pull-ups";
      case "situp": return "Sit-ups";
      default: return "Exercise";
    }
  };

  return (
    <div className="min-h-screen flex flex-col bg-slate-50">
      {/* Header */}
      <header className="bg-white border-b border-slate-200">
        <div className="container px-4 py-3 mx-auto flex items-center justify-between">
          <div>
            <button className="flex items-center text-accent" onClick={() => setLocation("/")}>
              <ArrowLeft className="h-5 w-5 mr-1" />
              Back
            </button>
          </div>
          <h2 className="text-2xl font-bold">{getTitle()}</h2>
          <div></div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1">
        <section className="py-6 px-4 lg:px-8">
          <div className="container mx-auto max-w-5xl">
            {/* Camera View */}
            <div className="bg-white rounded-xl shadow-sm p-4 mb-6">
              <CameraView 
                videoRef={videoRef}
                exerciseState={exerciseState}
                isStarted={isStarted}
              />
            </div>
            
            {/* Exercise Controls */}
            <div className="flex justify-center space-x-6 mb-8">
              <button 
                className="flex flex-col items-center justify-center p-2"
                onClick={handleStart}
                disabled={isStarted && !isPaused}
              >
                <div className={`w-14 h-14 rounded-full ${isStarted && !isPaused ? 'bg-slate-300' : 'bg-accent'} text-white flex items-center justify-center mb-1`}>
                  <Play className="h-6 w-6" />
                </div>
                <span className="text-xs font-medium">Start</span>
              </button>
              
              <button 
                className="flex flex-col items-center justify-center p-2"
                onClick={handlePause}
                disabled={!isStarted || isPaused}
              >
                <div className={`w-14 h-14 rounded-full ${!isStarted || isPaused ? 'bg-white border-2 border-slate-300 text-slate-400' : 'bg-white border-2 border-slate-300 text-slate-700'} flex items-center justify-center mb-1`}>
                  <Pause className="h-6 w-6" />
                </div>
                <span className="text-xs font-medium">Pause</span>
              </button>
              
              <button 
                className="flex flex-col items-center justify-center p-2"
                onClick={handleStop}
                disabled={!isStarted}
              >
                <div className={`w-14 h-14 rounded-full ${!isStarted ? 'bg-white border-2 border-slate-300 text-slate-400' : 'bg-white border-2 border-red-500 text-red-500'} flex items-center justify-center mb-1`}>
                  <Square className="h-6 w-6" />
                </div>
                <span className="text-xs font-medium">Stop</span>
              </button>
            </div>
            
            {/* Form Analysis */}
            <div className="bg-white rounded-xl shadow-sm p-4 mb-6">
              <h3 className="text-lg font-semibold mb-3">Form Analysis</h3>
              <div className="space-y-3">
                <div className="flex items-center">
                  <div className={`w-8 h-8 rounded-full ${formAnalysis.arms === 'good' ? 'bg-green-500' : formAnalysis.arms === 'warning' ? 'bg-amber-500' : 'bg-red-500'} text-white flex items-center justify-center mr-3`}>
                    {formAnalysis.arms === 'good' ? <CheckCircle className="h-5 w-5" /> : 
                     formAnalysis.arms === 'warning' ? <AlertTriangle className="h-5 w-5" /> : 
                     <XCircle className="h-5 w-5" />}
                  </div>
                  <div>
                    <div className="font-medium">Arm Alignment</div>
                    <div className="text-sm text-slate-500">
                      {formAnalysis.arms === 'good' ? 'Good elbow positioning' : 
                       formAnalysis.arms === 'warning' ? 'Slightly uneven arm position' : 
                       'Poor arm alignment'}
                    </div>
                  </div>
                </div>
                
                <div className="flex items-center">
                  <div className={`w-8 h-8 rounded-full ${formAnalysis.position === 'good' ? 'bg-green-500' : formAnalysis.position === 'warning' ? 'bg-amber-500' : 'bg-red-500'} text-white flex items-center justify-center mr-3`}>
                    {formAnalysis.position === 'good' ? <CheckCircle className="h-5 w-5" /> : 
                     formAnalysis.position === 'warning' ? <AlertTriangle className="h-5 w-5" /> : 
                     <XCircle className="h-5 w-5" />}
                  </div>
                  <div>
                    <div className="font-medium">Body Position</div>
                    <div className="text-sm text-slate-500">
                      {formAnalysis.position === 'good' ? 'Good body alignment' : 
                       formAnalysis.position === 'warning' ? 'Hip position slightly too high' : 
                       'Poor body alignment'}
                    </div>
                  </div>
                </div>
                
                <div className="flex items-center">
                  <div className={`w-8 h-8 rounded-full ${formAnalysis.depth === 'good' ? 'bg-green-500' : formAnalysis.depth === 'warning' ? 'bg-amber-500' : 'bg-red-500'} text-white flex items-center justify-center mr-3`}>
                    {formAnalysis.depth === 'good' ? <CheckCircle className="h-5 w-5" /> : 
                     formAnalysis.depth === 'warning' ? <AlertTriangle className="h-5 w-5" /> : 
                     <XCircle className="h-5 w-5" />}
                  </div>
                  <div>
                    <div className="font-medium">Depth</div>
                    <div className="text-sm text-slate-500">
                      {formAnalysis.depth === 'good' ? 'Good depth on movements' : 
                       formAnalysis.depth === 'warning' ? 'Moderate depth on movements' : 
                       'Not going deep enough'}
                    </div>
                  </div>
                </div>
              </div>
            </div>
            
            {/* Improvement Tips */}
            <div className="bg-white rounded-xl shadow-sm p-4">
              <h3 className="text-lg font-semibold mb-3">Improvement Tips</h3>
              <ul className="space-y-2">
                {type === 'pushup' && (
                  <>
                    <li className="flex">
                      <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                      <span>Lower your body until your chest is approximately 3-4 inches from the ground.</span>
                    </li>
                    <li className="flex">
                      <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                      <span>Keep your back straight by tightening your core and glutes.</span>
                    </li>
                    <li className="flex">
                      <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                      <span>Position your hands directly under your shoulders, not too wide or narrow.</span>
                    </li>
                    <li className="flex">
                      <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                      <span>Maintain an even pace, don't rush through the repetitions.</span>
                    </li>
                  </>
                )}
                
                {type === 'pullup' && (
                  <>
                    <li className="flex">
                      <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                      <span>Pull until your chin is above the bar for a complete repetition.</span>
                    </li>
                    <li className="flex">
                      <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                      <span>Lower yourself with control until arms are fully extended.</span>
                    </li>
                    <li className="flex">
                      <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                      <span>Keep your body straight throughout the movement.</span>
                    </li>
                    <li className="flex">
                      <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                      <span>Avoid swinging or using momentum to complete repetitions.</span>
                    </li>
                  </>
                )}
                
                {type === 'situp' && (
                  <>
                    <li className="flex">
                      <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                      <span>Keep your feet flat on the ground with knees bent.</span>
                    </li>
                    <li className="flex">
                      <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                      <span>Cross your arms over your chest or place hands behind your head.</span>
                    </li>
                    <li className="flex">
                      <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                      <span>Lift your torso until elbows or chest touch your thighs.</span>
                    </li>
                    <li className="flex">
                      <CheckCircle className="h-5 w-5 text-accent mr-2 flex-shrink-0 mt-0.5" />
                      <span>Lower your back completely to the ground between repetitions.</span>
                    </li>
                  </>
                )}
              </ul>
            </div>
          </div>
        </section>
      </main>

      {/* Bottom Navigation */}
      <Navigation active="home" />
    </div>
  );
}
