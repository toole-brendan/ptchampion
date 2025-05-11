import React, { useState } from 'react';
import HolisticCalibration from './HolisticCalibration';
import { CalibrationData } from '../lib/types';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from './ui/select';

const ExerciseCalibrationExample: React.FC = () => {
  const [exerciseType, setExerciseType] = useState<'pushup' | 'situp' | 'pullup' | 'running'>('pushup');
  const [calibrationData, setCalibrationData] = useState<CalibrationData | null>(null);
  const [showCalibration, setShowCalibration] = useState(false);

  const handleExerciseTypeChange = (value: string) => {
    setExerciseType(value as 'pushup' | 'situp' | 'pullup' | 'running');
    setCalibrationData(null);
  };

  const handleCalibrationComplete = (data: CalibrationData) => {
    console.log('Calibration complete:', data);
    setCalibrationData(data);
  };

  const startCalibration = () => {
    setShowCalibration(true);
  };

  return (
    <div className="container mx-auto p-4">
      <Card>
        <CardHeader>
          <CardTitle>Exercise Calibration with MediaPipe Holistic</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            <div className="flex flex-col space-y-2">
              <label htmlFor="exerciseType" className="text-sm font-medium">
                Select Exercise Type
              </label>
              <Select value={exerciseType} onValueChange={handleExerciseTypeChange}>
                <SelectTrigger id="exerciseType">
                  <SelectValue placeholder="Select exercise" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="pushup">Push-up</SelectItem>
                  <SelectItem value="situp">Sit-up</SelectItem>
                  <SelectItem value="pullup">Pull-up</SelectItem>
                  <SelectItem value="running">Running</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {!showCalibration ? (
              <div className="flex justify-center">
                <button
                  onClick={startCalibration}
                  className="px-4 py-2 bg-blue-600 text-white rounded-md font-medium"
                >
                  Start {exerciseType.charAt(0).toUpperCase() + exerciseType.slice(1)} Calibration
                </button>
              </div>
            ) : (
              <HolisticCalibration
                exerciseType={exerciseType}
                onCalibrationComplete={handleCalibrationComplete}
              />
            )}

            {calibrationData && (
              <div className="mt-6 p-4 bg-gray-100 rounded-md">
                <h3 className="text-lg font-semibold mb-2">Calibration Data</h3>
                <pre className="bg-black text-green-400 p-3 rounded text-xs overflow-auto max-h-60">
                  {JSON.stringify({
                    exerciseType: calibrationData.exerciseType,
                    timestamp: new Date(calibrationData.timestamp).toLocaleString(),
                    landmarks: calibrationData.poseLandmarks.length,
                  }, null, 2)}
                </pre>
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default ExerciseCalibrationExample; 