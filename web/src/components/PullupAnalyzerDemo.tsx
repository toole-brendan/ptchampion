import React, { useState, useEffect, useRef } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import MediaPipeHolisticSetup from './MediaPipeHolisticSetup';
import { PullupAnalyzer, PullupFormAnalysis, PullupAnalyzerConfig } from '../grading/PullupAnalyzer';
import PullupFormVisualizer from './PullupFormVisualizer';
import { NormalizedLandmark } from '../lib/types';

/**
 * Demo component to showcase pull-up form analysis with MediaPipe Holistic
 */
const PullupAnalyzerDemo: React.FC = () => {
  const [calibrationComplete, setCalibrationComplete] = useState(false);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [repCount, setRepCount] = useState(0);
  const [lastValidRepTime, setLastValidRepTime] = useState(0);
  const [formAnalysis, setFormAnalysis] = useState<PullupFormAnalysis | null>(null);
  const [landmarks, setLandmarks] = useState<NormalizedLandmark[]>([]);
  
  // State machine for rep counting
  const [inUpPosition, setInUpPosition] = useState(false);
  const [inDownPosition, setInDownPosition] = useState(true); // Start in down position (dead hang)
  
  // Refs for persistent data across renders
  const pullupAnalyzerRef = useRef<PullupAnalyzer | null>(null);
  const lastRepTimeRef = useRef<number>(0);
  
  // Initialize the pullup analyzer
  useEffect(() => {
    const config: Partial<PullupAnalyzerConfig> = {
      minElbowLockoutAngle: 160,
      maxElbowTopAngle: 90,
      chinAboveBarThreshold: 0.05,
      maxHorizontalDisplacement: 0.07,
      maxKneeAngleChange: 20,
      pauseThresholdMs: 2000,
      validRepTimeoutMs: 10000,
    };
    
    pullupAnalyzerRef.current = new PullupAnalyzer(config);
    
    return () => {
      pullupAnalyzerRef.current = null;
    };
  }, []);

  // Handle calibration completion
  const handleCalibrationComplete = (calibrationData: any) => {
    console.log('Calibration complete:', calibrationData);
    
    // Set the calibration data
    if (pullupAnalyzerRef.current && calibrationData.poseLandmarks) {
      pullupAnalyzerRef.current.setCalibrationData(calibrationData.poseLandmarks);
    }
    
    setCalibrationComplete(true);
  };

  // Process MediaPipe results with the pullup analyzer
  const handleMediaPipeResults = (results: any) => {
    if (!results.poseLandmarks || !pullupAnalyzerRef.current) return;
    
    // Store landmarks for visualization
    setLandmarks(results.poseLandmarks);
    
    // Only analyze when actively tracking pullups
    if (!isAnalyzing) return;
    
    // Run the form analysis
    const timestamp = Date.now();
    const analysis = pullupAnalyzerRef.current.analyzePullupForm(results.poseLandmarks, timestamp);
    setFormAnalysis(analysis);
    
    // Rep counting state machine with complete cycle validation
    if (!inUpPosition && analysis.isUpPosition) {
      // Entered up position (chin above bar)
      setInUpPosition(true);
    } else if (inUpPosition && !analysis.isUpPosition) {
      // Exited up position - moving down
      setInUpPosition(false);
    } else if (!inDownPosition && analysis.isDownPosition) {
      // Returned to down position (dead hang)
      setInDownPosition(true);
      
      // If we were previously in up position, this completes a rep
      if (inUpPosition) {
        // Only count if the rep meets all criteria
        if (analysis.isValidRep) {
          setRepCount(prevCount => prevCount + 1);
          setLastValidRepTime(timestamp);
          lastRepTimeRef.current = timestamp;
        } else {
          console.log('Invalid rep detected - form issues detected');
        }
      }
    } else if (inDownPosition && !analysis.isDownPosition) {
      // Started moving up from down position
      setInDownPosition(false);
    }
  };

  // Start/stop analyzing pullups
  const toggleAnalysis = () => {
    if (isAnalyzing) {
      setIsAnalyzing(false);
    } else {
      // Reset state before starting
      setRepCount(0);
      setInUpPosition(false);
      setInDownPosition(true);
      setLastValidRepTime(0);
      lastRepTimeRef.current = 0;
      
      if (pullupAnalyzerRef.current) {
        pullupAnalyzerRef.current.reset();
      }
      
      setIsAnalyzing(true);
    }
  };

  // Reset all state
  const resetAnalysis = () => {
    setRepCount(0);
    setInUpPosition(false);
    setInDownPosition(true);
    setLastValidRepTime(0);
    lastRepTimeRef.current = 0;
    setIsAnalyzing(false);
    
    if (pullupAnalyzerRef.current) {
      pullupAnalyzerRef.current.reset();
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
          <CardTitle>Pull-Up Form Analyzer</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col space-y-4">
            <p className="text-sm text-gray-600">
              This demo uses MediaPipe Holistic to track your pull-up form in real-time.
              Position your device to capture your form from the front or side.
              Start in the DEAD HANG position with arms fully extended.
            </p>
            
            {!calibrationComplete ? (
              <div>
                <p className="mb-2 font-medium">First, let's calibrate the system:</p>
                <p className="mb-2 text-sm text-gray-600">
                  Hang from the bar with arms fully extended in the starting position.
                  Make sure your device can see your full body.
                </p>
                <div className="relative aspect-video w-full rounded-lg overflow-hidden border border-gray-200">
                  <MediaPipeHolisticSetup
                    onCalibrationComplete={handleCalibrationComplete}
                    onResults={handleMediaPipeResults}
                  />
                </div>
              </div>
            ) : (
              <div className="space-y-6">
                <div className="relative aspect-video w-full rounded-lg overflow-hidden border border-gray-200">
                  {/* Display the MediaPipe feed with visualization overlay */}
                  <MediaPipeHolisticSetup
                    onResults={handleMediaPipeResults}
                  />
                  
                  {/* Visualization layer */}
                  {formAnalysis && landmarks.length > 0 && (
                    <div className="absolute inset-0">
                      <PullupFormVisualizer
                        landmarks={landmarks}
                        formAnalysis={formAnalysis}
                        width={800}
                        height={450}
                      />
                    </div>
                  )}
                </div>
                
                {/* Controls and statistics */}
                <div className="flex justify-between items-center">
                  <div className="flex flex-col space-y-2">
                    <div className="text-2xl font-bold">
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
                      className={`px-4 py-2 rounded-md font-medium ${
                        isAnalyzing
                          ? 'bg-red-600 text-white'
                          : 'bg-green-600 text-white'
                      }`}
                    >
                      {isAnalyzing ? 'Stop' : 'Start'} Analysis
                    </button>
                    
                    <button
                      onClick={resetAnalysis}
                      className="px-4 py-2 bg-gray-200 text-gray-800 rounded-md font-medium"
                      disabled={isAnalyzing}
                    >
                      Reset
                    </button>
                  </div>
                </div>
                
                {/* Form feedback section */}
                {formAnalysis && (
                  <div className="border border-gray-200 rounded-lg p-4">
                    <h3 className="text-lg font-semibold mb-2">Form Analysis</h3>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <p className="text-sm font-medium">Elbow Angles:</p>
                        <p className="text-sm">
                          Left: {Math.round(formAnalysis.leftElbowAngle)}° | 
                          Right: {Math.round(formAnalysis.rightElbowAngle)}°
                        </p>
                      </div>
                      <div>
                        <p className="text-sm font-medium">Current Position:</p>
                        <p className="text-sm">
                          {formAnalysis.isUpPosition ? 'Chin Above Bar' : 
                           formAnalysis.isDownPosition ? 'Dead Hang' : 'Transitioning'}
                        </p>
                      </div>
                      <div>
                        <p className="text-sm font-medium">Movement Stability:</p>
                        <p className="text-sm">
                          Swing: {Math.round(formAnalysis.maxHorizontalDisplacement * 100)}% | 
                          Kipping: {Math.round(formAnalysis.maxKneeAngleChange)}°
                        </p>
                      </div>
                      <div>
                        <p className="text-sm font-medium">Rep Progress:</p>
                        <p className="text-sm">{Math.round(formAnalysis.repProgress * 100)}%</p>
                      </div>
                    </div>
                    
                    {/* Form issues */}
                    {(!formAnalysis.isElbowLocked && formAnalysis.isDownPosition || 
                      formAnalysis.isSwinging || 
                      formAnalysis.isKipping || 
                      formAnalysis.isPaused) && (
                      <div className="mt-4">
                        <p className="text-sm font-medium text-red-600">Form Issues:</p>
                        <ul className="list-disc list-inside text-sm text-red-600">
                          {!formAnalysis.isElbowLocked && formAnalysis.isDownPosition && 
                            <li>Elbows not fully locked out in dead hang position</li>}
                          {formAnalysis.isSwinging && 
                            <li>Excessive swinging detected</li>}
                          {formAnalysis.isKipping && 
                            <li>Kipping/kicking motion detected</li>}
                          {formAnalysis.isPaused && 
                            <li>Paused too long in position</li>}
                        </ul>
                      </div>
                    )}
                    
                    {/* Requirements for valid rep */}
                    <div className="mt-4 p-3 bg-gray-50 rounded-md">
                      <p className="text-xs font-medium text-gray-700">For a valid rep:</p>
                      <ul className="list-disc list-inside text-xs text-gray-600 mt-1">
                        <li className={formAnalysis.isElbowLocked ? 'text-green-600' : ''}>
                          Start with elbows fully locked (dead hang)
                        </li>
                        <li className={formAnalysis.chinClearsBar ? 'text-green-600' : ''}>
                          Pull up until chin clears the bar
                        </li>
                        <li className={!formAnalysis.isSwinging ? 'text-green-600' : ''}>
                          Maintain control without excessive swinging
                        </li>
                        <li className={!formAnalysis.isKipping ? 'text-green-600' : ''}>
                          No kipping or kicking to generate momentum
                        </li>
                        <li className={!formAnalysis.isPaused ? 'text-green-600' : ''}>
                          Complete rep without excessive pausing
                        </li>
                      </ul>
                    </div>
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

export default PullupAnalyzerDemo; 