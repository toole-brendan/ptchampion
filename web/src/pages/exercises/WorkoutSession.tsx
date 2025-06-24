import React, { useState, useRef, useEffect, useCallback } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { ArrowLeft, Camera, Play, Pause, RotateCw, Check, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Card, CardContent } from '@/components/ui/card';
import HUD from '@/components/HUD';
import SessionControls from '@/components/SessionControls';
import ExerciseTimer from '@/components/ExerciseTimer';
import PoseVisualizer from '@/components/PoseVisualizer';
import { usePushupTrackerViewModel } from '@/viewmodels/PushupTrackerViewModel';
import { useSitupTrackerViewModel } from '@/viewmodels/SitupTrackerViewModel';
import { usePullupTrackerViewModel } from '@/viewmodels/PullupTrackerViewModel';
import { useRunningTrackerViewModel } from '@/viewmodels/RunningTrackerViewModel';
import { SessionStatus } from '@/viewmodels/TrackerViewModel';
import { calculateAPFTScore } from '@/grading/APFTScoring';
import { ExerciseType } from '@/grading';
import { cn } from '@/lib/utils';

const USE_BLAZEPOSE_DETECTOR = true;

interface WorkoutSessionProps {
  className?: string;
}

export default function WorkoutSession({ className }: WorkoutSessionProps) {
  const navigate = useNavigate();
  const { exerciseType } = useParams<{ exerciseType: string }>();
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  
  // State for user profile (would come from auth context in real app)
  const [userAge] = useState(25);
  const [userGender] = useState<'male' | 'female'>('male');
  
  // Get the appropriate view model based on exercise type
  const getViewModel = () => {
    switch (exerciseType?.toLowerCase()) {
      case 'pushup':
      case 'push-up':
      case 'pushups':
        return usePushupTrackerViewModel(USE_BLAZEPOSE_DETECTOR);
      case 'situp':
      case 'sit-up':
      case 'situps':
        return useSitupTrackerViewModel(USE_BLAZEPOSE_DETECTOR);
      case 'pullup':
      case 'pull-up':
      case 'pullups':
        return usePullupTrackerViewModel(USE_BLAZEPOSE_DETECTOR);
      case 'run':
      case 'running':
        return useRunningTrackerViewModel();
      default:
        return null;
    }
  };
  
  const viewModel = getViewModel();
  
  // Destructure common properties from view model
  const {
    repCount = 0,
    timer = 0,
    status = SessionStatus.INITIALIZING,
    formScore = 100,
    formFeedback = null,
    error = null,
    result = null,
    formattedTime = '00:00',
    distance = 0,
    pace = '00:00',
    initialize,
    startSession,
    pauseSession,
    finishSession,
    resetSession,
    saveResults,
    flipCamera
  } = viewModel || {};
  
  const [apftScore, setApftScore] = useState(0);
  const [showProblemJoints, setShowProblemJoints] = useState(true);
  
  // Initialize the tracker when component mounts
  useEffect(() => {
    if (!viewModel || !initialize) return;
    
    const initializeTracker = async () => {
      if (exerciseType?.toLowerCase().includes('run')) {
        await initialize();
      } else {
        await initialize(videoRef, canvasRef);
      }
    };
    
    initializeTracker();
  }, [viewModel, initialize, exerciseType]);
  
  // Calculate APFT score when rep count changes
  useEffect(() => {
    if (!exerciseType || exerciseType.toLowerCase().includes('run')) return;
    
    const score = calculateAPFTScore(
      exerciseType as ExerciseType,
      repCount,
      userAge,
      userGender
    );
    setApftScore(score);
  }, [repCount, exerciseType, userAge, userGender]);
  
  const handleStart = useCallback(() => {
    if (startSession) {
      startSession();
    }
  }, [startSession]);
  
  const handlePause = useCallback(() => {
    if (pauseSession) {
      pauseSession();
    }
  }, [pauseSession]);
  
  const handleReset = useCallback(() => {
    if (resetSession) {
      resetSession();
    }
  }, [resetSession]);
  
  const handleFinish = useCallback(async () => {
    if (!finishSession) return;
    
    const result = await finishSession();
    if (result && saveResults) {
      const saved = await saveResults();
      if (saved) {
        navigate(`/exercises/${exerciseType}/complete`, {
          state: { result }
        });
      }
    }
  }, [finishSession, saveResults, navigate, exerciseType]);
  
  const handleFlipCamera = useCallback(() => {
    if (flipCamera) {
      flipCamera();
    }
  }, [flipCamera]);
  
  if (!viewModel) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <Alert>
          <AlertDescription>
            Invalid exercise type: {exerciseType}
          </AlertDescription>
        </Alert>
      </div>
    );
  }
  
  const isRunning = exerciseType?.toLowerCase().includes('run');
  const displayName = exerciseType ? 
    exerciseType.charAt(0).toUpperCase() + exerciseType.slice(1).replace('-', ' ') : 
    'Exercise';
  
  return (
    <div className={cn("min-h-screen bg-background", className)}>
      {/* Header */}
      <div className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container flex h-14 items-center">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => navigate('/exercises')}
            className="mr-4"
          >
            <ArrowLeft className="h-4 w-4" />
          </Button>
          <h1 className="text-lg font-semibold">{displayName} Tracker</h1>
          <div className="ml-auto flex items-center gap-2">
            {!isRunning && (
              <Button
                variant="ghost"
                size="icon"
                onClick={handleFlipCamera}
                disabled={status !== SessionStatus.READY && status !== SessionStatus.ACTIVE}
              >
                <Camera className="h-4 w-4" />
              </Button>
            )}
          </div>
        </div>
      </div>
      
      {/* Main Content */}
      <div className="container py-4">
        {error && (
          <Alert variant="destructive" className="mb-4">
            <AlertDescription>{error.message}</AlertDescription>
          </Alert>
        )}
        
        <div className="grid gap-4 lg:grid-cols-3">
          {/* Video/Canvas Section */}
          {!isRunning && (
            <div className="lg:col-span-2">
              <Card>
                <CardContent className="p-0">
                  <div className="relative aspect-video bg-black rounded-lg overflow-hidden">
                    <video
                      ref={videoRef}
                      className="absolute inset-0 w-full h-full object-cover"
                      autoPlay
                      playsInline
                      muted
                    />
                    <canvas
                      ref={canvasRef}
                      className="absolute inset-0 w-full h-full"
                    />
                    {status === SessionStatus.ACTIVE && (
                      <HUD
                        repCount={repCount}
                        timer={formattedTime}
                        formScore={formScore}
                        feedback={formFeedback}
                        className="absolute top-4 left-4"
                      />
                    )}
                  </div>
                </CardContent>
              </Card>
            </div>
          )}
          
          {/* Stats Section */}
          <div className={cn(
            "space-y-4",
            isRunning ? "lg:col-span-3" : "lg:col-span-1"
          )}>
            {/* Timer Card */}
            <Card>
              <CardContent className="p-6">
                <ExerciseTimer duration={timer} />
              </CardContent>
            </Card>
            
            {/* Stats Card */}
            <Card>
              <CardContent className="p-6 space-y-4">
                {!isRunning ? (
                  <>
                    <div>
                      <p className="text-sm text-muted-foreground">Reps</p>
                      <p className="text-3xl font-bold">{repCount}</p>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">APFT Score</p>
                      <p className="text-2xl font-semibold">{apftScore}</p>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">Form Score</p>
                      <p className="text-2xl font-semibold">{formScore}%</p>
                    </div>
                  </>
                ) : (
                  <>
                    <div>
                      <p className="text-sm text-muted-foreground">Distance</p>
                      <p className="text-3xl font-bold">
                        {(distance / 1609.34).toFixed(2)} mi
                      </p>
                    </div>
                    <div>
                      <p className="text-sm text-muted-foreground">Pace</p>
                      <p className="text-2xl font-semibold">{pace} /mi</p>
                    </div>
                  </>
                )}
              </CardContent>
            </Card>
            
            {/* Form Feedback Card */}
            {formFeedback && (
              <Card className="border-orange-200 bg-orange-50">
                <CardContent className="p-4">
                  <p className="text-sm font-medium text-orange-800">
                    {formFeedback}
                  </p>
                </CardContent>
              </Card>
            )}
            
            {/* Controls Card */}
            <Card>
              <CardContent className="p-6">
                <SessionControls
                  status={status}
                  onStart={handleStart}
                  onPause={handlePause}
                  onReset={handleReset}
                  onFinish={handleFinish}
                />
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
}