import React, { useState, useEffect, useRef } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import MediaPipeHolisticSetup from './MediaPipeHolisticSetup';
import { PushupAnalyzer, PushupAnalyzerConfig } from '../grading/PushupAnalyzer';
import PushupFormVisualizer from './PushupFormVisualizer';

/**
 * Demo component to showcase push-up form analysis with MediaPipe Holistic
 */
const PushupAnalyzerDemo: React.FC = () => {
  const [calibrationComplete, setCalibrationComplete] = useState(false);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [repCount, setRepCount] = useState(0);
  const [lastValidRepTime, setLastValidRepTime] = useState(0);
  const [formAnalysis, setFormAnalysis] = useState<PushupFormAnalysis | null>(null);
  const [landmarks, setLandmarks] = useState<NormalizedLandmark[]>([]);
  
  // State machine for rep counting
  const [inUpPosition, setInUpPosition] = useState(false);
  const [inDownPosition, setInDownPosition] = useState(false);
  
  // Refs for persistent data across renders
  const pushupAnalyzerRef = useRef<PushupAnalyzer | null>(null);
  const lastRepTimeRef = useRef<number>(0);
  
  // Initialize the pushup analyzer
  useEffect(() => {
    const config: Partial<PushupAnalyzerConfig> = {
      minElbowExtensionAngle: 160,
      maxElbowFlexionAngle: 90,
      maxPikingAngle: 165,
      minSaggingAngle: 195,
      wormingThreshold: 0.03,
      groundTouchThreshold: 0.02,
      pauseThresholdMs: 2000,
    };
    
    pushupAnalyzerRef.current = new PushupAnalyzer(config);
    
    return () => {
      pushupAnalyzerRef.current = null;
    };
  }, []);

  // Handle calibration completion
  const handleCalibrationComplete = (calibrationData: unknown) => {
    console.log('Calibration complete:', calibrationData);
    setCalibrationComplete(true);
  };

  // Process MediaPipe results with the pushup analyzer
  const handleMediaPipeResults = (results: unknown) => {
    if (!results.poseLandmarks || !pushupAnalyzerRef.current) return;
    
    // Store landmarks for visualization
    setLandmarks(results.poseLandmarks);
    
    // Only analyze when actively tracking pushups
    if (!isAnalyzing) return;
    
    // Run the form analysis
    const timestamp = Date.now();
    const analysis = pushupAnalyzerRef.current.analyzePushupForm(results.poseLandmarks, timestamp);
    setFormAnalysis(analysis);
    
    // Rep counting state machine
    if (!inUpPosition && analysis.isUpPosition) {
      // Entered up position
      setInUpPosition(true);
      setInDownPosition(false);
      
      // If we were in down position before, count as completed rep
      if (inDownPosition) {
        // Allow increasing rep count only if rep is valid
        if (analysis.isValidRep) {
          setRepCount(prevCount => prevCount + 1);
          setLastValidRepTime(timestamp);
          lastRepTimeRef.current = timestamp;
          
          // Reset min elbow angle for next rep
          pushupAnalyzerRef.current?.resetMinElbowAngle();
        }
      }
    } else if (!inDownPosition && analysis.isDownPosition) {
      // Entered down position
      setInDownPosition(true);
      setInUpPosition(false);
    }
  };

  // Start/stop analyzing pushups
  const toggleAnalysis = () => {
    if (isAnalyzing) {
      setIsAnalyzing(false);
    } else {
      // Reset state before starting
      setRepCount(0);
      setInUpPosition(false);
      setInDownPosition(false);
      setLastValidRepTime(0);
      lastRepTimeRef.current = 0;
      
      if (pushupAnalyzerRef.current) {
        pushupAnalyzerRef.current.reset();
      }
      
      setIsAnalyzing(true);
    }
  };

  // Reset all state
  const resetAnalysis = () => {
    setRepCount(0);
    setInUpPosition(false);
    setInDownPosition(false);
    setLastValidRepTime(0);
    lastRepTimeRef.current = 0;
    setIsAnalyzing(false);
    
    if (pushupAnalyzerRef.current) {
      pushupAnalyzerRef.current.reset();
    }
  };

  // Calculate elapsed time since last rep
  const getSecondsSinceLastRep = () => {
    if (lastRepTimeRef.current === 0) return 0;
    const now = Date.now();
    return Math.floor((now - lastRepTimeRef.current) / 1000);
  };

  return (
    <div className="container mx-auto p-4">
      <Card className="mb-6">
        <CardHeader>
          <CardTitle>Push-up Form Analyzer</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col space-y-4">
            <p className="text-sm text-gray-600">
              This demo uses MediaPipe Holistic to track your push-up form in real-time.
              Position your device to capture a side view of your push-ups for best results.
            </p>
            
            {!calibrationComplete ? (
              <div>
                <p className="mb-2 font-medium">First, let's calibrate the system:</p>
                <div className="relative aspect-video w-full overflow-hidden rounded-lg border border-gray-200">
                  <MediaPipeHolisticSetup
                    onCalibrationComplete={handleCalibrationComplete}
                    onResults={handleMediaPipeResults}
                  />
                </div>
              </div>
            ) : (
              <div className="space-y-6">
                <div className="relative aspect-video w-full overflow-hidden rounded-lg border border-gray-200">
                  {/* Display the MediaPipe feed with visualization overlay */}
                  <MediaPipeHolisticSetup
                    onResults={handleMediaPipeResults}
                  />
                  
                  {/* Visualization layer */}
                  {formAnalysis && landmarks.length > 0 && (
                    <div className="absolute inset-0">
                      <PushupFormVisualizer
                        landmarks={landmarks}
                        formAnalysis={formAnalysis}
                        width={800}
                        height={450}
                      />
                    </div>
                  )}
                </div>
                
                {/* Controls and statistics */}
                <div className="flex items-center justify-between">
                  <div className="flex flex-col space-y-2">
                    <div className="font-bold text-2xl">
                      {repCount} <span className="text-lg font-normal text-gray-600">reps</span>
                    </div>
                    {lastValidRepTime > 0 && (
                      <div className="text-sm text-gray-600">
                        {getSecondsSinceLastRep()}s since last rep
                      </div>
                    )}
                  </div>
                  
                  <div className="flex space-x-3">
                    <button
                      onClick={toggleAnalysis}
                      className={`rounded-md px-4 py-2 font-medium ${
                        isAnalyzing
                          ? 'bg-red-600 text-white'
                          : 'bg-green-600 text-white'
                      }`}
                    >
                      {isAnalyzing ? 'Stop' : 'Start'} Analysis
                    </button>
                    
                    <button
                      onClick={resetAnalysis}
                      className="rounded-md bg-gray-200 px-4 py-2 font-medium text-gray-800"
                      disabled={isAnalyzing}
                    >
                      Reset
                    </button>
                  </div>
                </div>
                
                {/* Form feedback section */}
                {formAnalysis && (
                  <div className="rounded-lg border border-gray-200 p-4">
                    <h3 className="mb-2 font-semibold text-lg">Form Analysis</h3>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <p className="text-sm font-medium">Elbow Angles:</p>
                        <p className="text-sm">
                          Left: {Math.round(formAnalysis.leftElbowAngle)}° | 
                          Right: {Math.round(formAnalysis.rightElbowAngle)}°
                        </p>
                      </div>
                      <div>
                        <p className="text-sm font-medium">Body Alignment:</p>
                        <p className="text-sm">
                          {Math.round(formAnalysis.bodyAlignmentAngle)}°
                          {formAnalysis.isBodySagging && ' (Sagging)'}
                          {formAnalysis.isBodyPiking && ' (Piking)'}
                        </p>
                      </div>
                      <div>
                        <p className="text-sm font-medium">Current Position:</p>
                        <p className="text-sm">
                          {formAnalysis.isUpPosition ? 'Up Position' : 
                           formAnalysis.isDownPosition ? 'Down Position' : 'Transitioning'}
                        </p>
                      </div>
                      <div>
                        <p className="text-sm font-medium">Minimum Elbow Angle:</p>
                        <p className="text-sm">{Math.round(formAnalysis.minElbowAngleDuringRep)}°</p>
                      </div>
                    </div>
                    
                    {/* Form issues */}
                    {(formAnalysis.isBodySagging || 
                      formAnalysis.isBodyPiking || 
                      formAnalysis.isWorming ||
                      formAnalysis.handsLiftedOff ||
                      formAnalysis.feetLiftedOff ||
                      formAnalysis.kneesTouchingGround ||
                      formAnalysis.bodyTouchingGround ||
                      formAnalysis.isPaused) && (
                      <div className="mt-4">
                        <p className="text-sm font-medium text-red-600">Form Issues:</p>
                        <ul className="list-inside list-disc text-sm text-red-600">
                          {formAnalysis.isBodySagging && <li>Body sagging (hips too low)</li>}
                          {formAnalysis.isBodyPiking && <li>Body piking (hips too high)</li>}
                          {formAnalysis.isWorming && <li>Worming (shoulders and hips not moving together)</li>}
                          {formAnalysis.handsLiftedOff && <li>Hands lifted off ground</li>}
                          {formAnalysis.feetLiftedOff && <li>Feet lifted off ground</li>}
                          {formAnalysis.kneesTouchingGround && <li>Knees touching ground</li>}
                          {formAnalysis.bodyTouchingGround && <li>Body touching ground</li>}
                          {formAnalysis.isPaused && <li>Paused too long in position</li>}
                        </ul>
                      </div>
                    )}
                  </div>
                )}
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default PushupAnalyzerDemo; 