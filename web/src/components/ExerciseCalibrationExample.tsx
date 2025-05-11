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
                  className="rounded-md bg-blue-600 px-4 py-2 font-medium text-white"
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
              <div className="mt-6 rounded-md bg-gray-100 p-4">
                <h3 className="mb-2 font-semibold text-lg">Calibration Data</h3>
                <pre className="max-h-60 overflow-auto rounded bg-black p-3 text-xs text-green-400">
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