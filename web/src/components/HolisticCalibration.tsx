import React, { useState, useRef } from 'react';
import MediaPipeHolisticSetup from './MediaPipeHolisticSetup';
import { CalibrationData } from '../lib/types';
import { Card } from './ui/card';

interface HolisticCalibrationProps {
  exerciseType: 'pushup' | 'situp' | 'pullup' | 'running';
  onCalibrationComplete: (calibrationData: CalibrationData) => void;
}

interface CalibrationResults {
  poseLandmarks: unknown[];
  poseWorldLandmarks?: unknown[];
}

const HolisticCalibration: React.FC<HolisticCalibrationProps> = ({
  exerciseType,
  onCalibrationComplete,
}) => {
  const [calibrationInstructions, setCalibrationInstructions] = useState('');
  const calibrationDataRef = useRef<CalibrationData | null>(null);

  // Set the appropriate instructions based on exercise type
  React.useEffect(() => {
    switch (exerciseType) {
      case 'pushup':
        setCalibrationInstructions('Start in the UP position with arms fully extended, back straight, and elbows locked.');
        break;
      case 'situp':
        setCalibrationInstructions('Start in the DOWN position with your back on the ground, knees bent, and fingers interlocked behind your head.');
        break;
      case 'pullup':
        setCalibrationInstructions('Start in the DOWN position with arms fully extended, hanging from the bar.');
        break;
      case 'running':
        setCalibrationInstructions('Stand straight facing the camera to calibrate your standing position.');
        break;
      default:
        setCalibrationInstructions('Please assume the starting position for calibration.');
    }
  }, [exerciseType]);

  // Handle calibration completion
  const handleCalibrationComplete = (results: CalibrationResults) => {
    if (!results.poseLandmarks) {
      console.error('No pose landmarks detected during calibration');
      return;
    }
    
    const calibrationData: CalibrationData = {
      poseLandmarks: results.poseLandmarks,
      poseWorldLandmarks: results.poseWorldLandmarks || [],
      timestamp: Date.now(),
      exerciseType,
    };
    
    calibrationDataRef.current = calibrationData;
    
    onCalibrationComplete(calibrationData);
  };

  return (
    <div className="flex w-full flex-col items-center">
      <Card className="mb-4 p-4">
        <div className="mb-4 text-center">
          <h3 className="font-semibold text-xl">Calibration for {exerciseType.toUpperCase()}</h3>
          <p className="mt-1 text-gray-600">{calibrationInstructions}</p>
        </div>
      </Card>
      
      <div className="relative aspect-video w-full max-w-3xl">
        <MediaPipeHolisticSetup
          onCalibrationComplete={handleCalibrationComplete}
        />
      </div>
      
      {calibrationDataRef.current && (
        <div className="mt-6 w-full max-w-3xl rounded-md border border-green-400 bg-green-100 p-4">
          <p className="font-medium text-green-800">Calibration complete! You can now proceed with your exercise.</p>
          <p className="mt-1 text-sm text-green-700">Captured {calibrationDataRef.current.poseLandmarks.length} landmarks at {new Date(calibrationDataRef.current.timestamp).toLocaleTimeString()}</p>
        </div>
      )}
    </div>
  );
};

export default HolisticCalibration; 