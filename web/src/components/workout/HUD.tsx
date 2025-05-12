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
      <div className="pointer-events-none absolute left-2 top-2 grid gap-2">
        <span className="rounded bg-black/60 px-3 py-1 text-xs text-white">
          Distance: {distance?.toFixed(2) || '0.00'} mi
        </span>
        <span className="flex items-center rounded bg-black/60 px-3 py-1 text-xs text-white">
          <Timer className="mr-1 size-3" /> {formattedTime}
        </span>
        {pace && (
          <span className="flex items-center rounded bg-black/60 px-3 py-1 text-xs text-white">
            <Gauge className="mr-1 size-3" /> Pace: {pace}
          </span>
        )}
      </div>
    );
  }

  // Original HUD for rep-based exercises
  return (
    <div className="pointer-events-none absolute inset-0 z-20 flex flex-col items-center justify-center text-white">
      {/* Rep Count - Large centered display */}
      <div className={`mb-2 font-bold text-7xl lg:text-8xl ${exerciseColor} animate-pop`}>
        {repCount}
      </div>
      
      {/* Timer */}
      <div className="mb-4 flex items-center justify-center text-xl font-medium opacity-90">
        <Timer className="mr-1.5 size-5" />
        {formattedTime}
      </div>
      
      {/* Form Feedback - Floating pill at bottom */}
      {formFeedback && (
        <div className="absolute bottom-16 mx-auto rounded-md bg-destructive/80 px-4 py-2 font-semibold text-sm">
          {formFeedback}
        </div>
      )}
    </div>
  );
};

export default HUD; 