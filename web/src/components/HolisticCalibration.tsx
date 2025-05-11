import React, { useState, useRef } from 'react';
import MediaPipeHolisticSetup from './MediaPipeHolisticSetup';
import { CalibrationData } from '../lib/types';
import { Card } from './ui/card';

interface HolisticCalibrationProps {
  exerciseType: 'pushup' | 'situp' | 'pullup' | 'running';
  onCalibrationComplete: (calibrationData: CalibrationData) => void;
}

const HolisticCalibration: React.FC<HolisticCalibrationProps> = ({
  exerciseType,
  onCalibrationComplete,
}) => {
  const [isCalibrating, setIsCalibrating] = useState(false);
  const [calibrationInstructions, setCalibrationInstructions] = useState('');
  const calibrationDataRef = useRef<any>(null);

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
  const handleCalibrationComplete = (results: any) => {
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
    setIsCalibrating(false);
    
    onCalibrationComplete(calibrationData);
  };

  // Start the calibration process
  const startCalibration = () => {
    setIsCalibrating(true);
  };

  return (
    <div className="flex flex-col items-center w-full">
      <Card className="p-4 mb-4">
        <div className="text-center mb-4">
          <h3 className="text-xl font-semibold">Calibration for {exerciseType.toUpperCase()}</h3>
          <p className="text-gray-600 mt-1">{calibrationInstructions}</p>
        </div>
      </Card>
      
      <div className="w-full max-w-3xl relative aspect-video">
        <MediaPipeHolisticSetup
          onCalibrationComplete={handleCalibrationComplete}
        />
      </div>
      
      {calibrationDataRef.current && (
        <div className="mt-6 p-4 bg-green-100 border border-green-400 rounded-md w-full max-w-3xl">
          <p className="text-green-800 font-medium">Calibration complete! You can now proceed with your exercise.</p>
          <p className="text-sm text-green-700 mt-1">Captured {calibrationDataRef.current.poseLandmarks.length} landmarks at {new Date(calibrationDataRef.current.timestamp).toLocaleTimeString()}</p>
        </div>
      )}
    </div>
  );
};

export default HolisticCalibration; 