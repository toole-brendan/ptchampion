import React, { useState, useEffect, useRef } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import MediaPipeHolisticSetup from './MediaPipeHolisticSetup';
import { SitupAnalyzer, SitupFormAnalysis, SitupAnalyzerConfig } from '../grading/SitupAnalyzer';
import SitupFormVisualizer from './SitupFormVisualizer';
import { NormalizedLandmark } from '../lib/types';

/**
 * Demo component to showcase sit-up form analysis with MediaPipe Holistic
 */
const SitupAnalyzerDemo: React.FC = () => {
  const [calibrationComplete, setCalibrationComplete] = useState(false);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [repCount, setRepCount] = useState(0);
  const [lastValidRepTime, setLastValidRepTime] = useState(0);
  const [formAnalysis, setFormAnalysis] = useState<SitupFormAnalysis | null>(null);
  const [landmarks, setLandmarks] = useState<NormalizedLandmark[]>([]);
  
  // State machine for rep counting
  const [inUpPosition, setInUpPosition] = useState(false);
  const [inDownPosition, setInDownPosition] = useState(true); // Start in down position
  
  // Refs for persistent data across renders
  const situpAnalyzerRef = useRef<SitupAnalyzer | null>(null);
  const lastRepTimeRef = useRef<number>(0);
  
  // Initialize the situp analyzer
  useEffect(() => {
    const config: Partial<SitupAnalyzerConfig> = {
      minTrunkAngle: 60,
      maxTrunkAngle: 95,
      minKneeAngle: 70,
      maxKneeAngle: 110,
      wristToHeadMaxDistance: 0.15,
      wristsMaxDistance: 0.12,
      shoulderGroundThreshold: 0.03,
      hipLiftThreshold: 0.03,
      pauseThresholdMs: 2000,
      validRepTimeoutMs: 10000,
    };
    
    situpAnalyzerRef.current = new SitupAnalyzer(config);
    
    return () => {
      situpAnalyzerRef.current = null;
    };
  }, []);

  // Handle calibration completion
  const handleCalibrationComplete = (calibrationData: any) => {
    console.log('Calibration complete:', calibrationData);
    
    // Set the calibration data
    if (situpAnalyzerRef.current && calibrationData.poseLandmarks) {
      situpAnalyzerRef.current.setCalibrationData(calibrationData.poseLandmarks);
    }
    
    setCalibrationComplete(true);
  };

  // Process MediaPipe results with the situp analyzer
  const handleMediaPipeResults = (results: any) => {
    if (!results.poseLandmarks || !situpAnalyzerRef.current) return;
    
    // Store landmarks for visualization
    setLandmarks(results.poseLandmarks);
    
    // Only analyze when actively tracking situps
    if (!isAnalyzing) return;
    
    // Run the form analysis
    const timestamp = Date.now();
    const analysis = situpAnalyzerRef.current.analyzeSitupForm(results.poseLandmarks, timestamp);
    setFormAnalysis(analysis);
    
    // Rep counting state machine
    if (!inUpPosition && analysis.isUpPosition) {
      // Entered up position
      setInUpPosition(true);
      
      // If we were in down position, count as a valid rep
      if (inDownPosition) {
        // Allow increasing rep count only if rep is valid
        if (analysis.isValidRep) {
          setRepCount(prevCount => prevCount + 1);
          setLastValidRepTime(timestamp);
          lastRepTimeRef.current = timestamp;
        }
      }
    } else if (!inDownPosition && analysis.isDownPosition) {
      // Entered down position
      setInDownPosition(true);
      setInUpPosition(false);
    } else if (inUpPosition && !analysis.isUpPosition) {
      // Exited up position
      setInUpPosition(false);
    } else if (inDownPosition && !analysis.isDownPosition) {
      // Exited down position
      setInDownPosition(false);
    }
  };

  // Start/stop analyzing situps
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
      
      if (situpAnalyzerRef.current) {
        situpAnalyzerRef.current.reset();
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
    
    if (situpAnalyzerRef.current) {
      situpAnalyzerRef.current.reset();
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
          <CardTitle>Sit-up Form Analyzer</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-col space-y-4">
            <p className="text-sm text-gray-600">
              This demo uses MediaPipe Holistic to track your sit-up form in real-time.
              Position your device to capture a side view of your sit-ups for best results.
              Start in the DOWN position with your back on the ground.
            </p>
            
            {!calibrationComplete ? (
              <div>
                <p className="mb-2 font-medium">First, let's calibrate the system:</p>
                <p className="mb-2 text-sm text-gray-600">
                  Lie on your back with knees bent and feet flat on the ground.
                  Place your hands behind your head with fingers interlocked.
                  Make sure your device can see your full body from the side.
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
                      <SitupFormVisualizer
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
                        <p className="text-sm font-medium">Trunk Angle:</p>
                        <p className="text-sm">
                          {Math.round(formAnalysis.trunkAngle)}°
                          {formAnalysis.trunkAngle < 60 && ' (Not vertical enough)'}
                          {formAnalysis.trunkAngle > 95 && ' (Too far back)'}
                        </p>
                      </div>
                      <div>
                        <p className="text-sm font-medium">Knee Angles:</p>
                        <p className="text-sm">
                          Left: {Math.round(formAnalysis.leftKneeAngle)}° | 
                          Right: {Math.round(formAnalysis.rightKneeAngle)}°
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
                        <p className="text-sm font-medium">Rep Progress:</p>
                        <p className="text-sm">{Math.round(formAnalysis.repProgress * 100)}%</p>
                      </div>
                    </div>
                    
                    {/* Form issues */}
                    {(!formAnalysis.isHandPositionCorrect || 
                      !formAnalysis.isKneeAngleCorrect || 
                      (!formAnalysis.isShoulderBladeGrounded && formAnalysis.isDownPosition) ||
                      !formAnalysis.isHipStable ||
                      formAnalysis.isPaused) && (
                      <div className="mt-4">
                        <p className="text-sm font-medium text-red-600">Form Issues:</p>
                        <ul className="list-disc list-inside text-sm text-red-600">
                          {!formAnalysis.isHandPositionCorrect && <li>Hands not properly positioned behind head</li>}
                          {!formAnalysis.isKneeAngleCorrect && <li>Incorrect knee angle (should be 70-110°)</li>}
                          {!formAnalysis.isShoulderBladeGrounded && formAnalysis.isDownPosition && <li>Shoulders not touching ground in down position</li>}
                          {!formAnalysis.isHipStable && <li>Hips lifting off ground</li>}
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

export default SitupAnalyzerDemo; 