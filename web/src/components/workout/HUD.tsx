import React from 'react';
import { Timer, Gauge } from 'lucide-react';

export interface HUDProps {
  repCount: number;
  formattedTime: string;
  formFeedback: string | null;
  exerciseColor?: string;
  pace?: string;
  distance?: number;
  isRunning?: boolean;
}

const HUD: React.FC<HUDProps> = ({ 
  repCount, 
  formattedTime, 
  formFeedback,
  exerciseColor = 'text-primary',
  pace,
  distance,
  isRunning = false
}) => {
  // Render for running workout (distance, time, pace)
  if (isRunning) {
    return (
      <div className="absolute top-2 left-2 grid gap-2 pointer-events-none">
        <span className="rounded bg-black/60 px-3 py-1 text-xs text-white">
          Distance: {distance?.toFixed(2) || '0.00'} mi
        </span>
        <span className="rounded bg-black/60 px-3 py-1 text-xs text-white flex items-center">
          <Timer className="mr-1 size-3" /> {formattedTime}
        </span>
        {pace && (
          <span className="rounded bg-black/60 px-3 py-1 text-xs text-white flex items-center">
            <Gauge className="mr-1 size-3" /> Pace: {pace}
          </span>
        )}
      </div>
    );
  }

  // Original HUD for rep-based exercises
  return (
    <div className="absolute inset-0 z-20 flex flex-col items-center justify-center pointer-events-none text-white">
      {/* Rep Count - Large centered display */}
      <div className={`text-7xl lg:text-8xl font-bold mb-2 ${exerciseColor} animate-pop`}>
        {repCount}
      </div>
      
      {/* Timer */}
      <div className="flex items-center justify-center text-xl font-medium opacity-90 mb-4">
        <Timer className="mr-1.5 size-5" />
        {formattedTime}
      </div>
      
      {/* Form Feedback - Floating pill at bottom */}
      {formFeedback && (
        <div className="absolute bottom-16 px-4 py-2 bg-destructive/80 rounded-md text-sm font-semibold mx-auto">
          {formFeedback}
        </div>
      )}
    </div>
  );
};

export default HUD; 