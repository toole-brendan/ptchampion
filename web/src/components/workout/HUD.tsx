import React from 'react';
import { Timer } from 'lucide-react';

export interface HUDProps {
  repCount: number;
  formattedTime: string;
  formFeedback: string | null;
  exerciseColor?: string;
}

const HUD: React.FC<HUDProps> = ({ 
  repCount, 
  formattedTime, 
  formFeedback,
  exerciseColor = 'text-primary' 
}) => {
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