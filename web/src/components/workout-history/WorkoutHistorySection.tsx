import React from 'react';
import { Dumbbell } from 'lucide-react';

interface WorkoutHistorySectionProps {
  children: React.ReactNode;
  isEmpty: boolean;
  filter: string;
}

export const WorkoutHistorySection: React.FC<WorkoutHistorySectionProps> = ({
  children,
  isEmpty,
  filter
}) => {
  return (
    <div className="shadow-md rounded-lg overflow-hidden">
      {/* Dark header with brass gold title */}
      <div className="bg-deep-ops px-4 py-4">
        <div className="space-y-1">
          <h2 className="text-2xl font-bold text-brass-gold">
            TRAINING RECORD
          </h2>
          <div className="h-px bg-brass-gold/30"></div>
        </div>
      </div>
      
      {/* White content area */}
      <div className="bg-white">
        {isEmpty ? (
          <div className="py-10 px-4">
            <div className="flex flex-col items-center justify-center space-y-5">
              <div className="w-20 h-20 rounded-full bg-brass-gold/10 flex items-center justify-center">
                <Dumbbell className="w-9 h-9 text-brass-gold" />
              </div>
              
              <div className="text-center space-y-2">
                <h3 className="font-mono text-sm font-medium text-gray-600 uppercase tracking-wider">
                  No Workouts Yet
                </h3>
                <p className="font-mono text-xs text-gray-500 max-w-sm">
                  Complete a workout to see your history here
                </p>
                {filter !== 'All' && (
                  <p className="font-mono text-xs text-gray-500 pt-1">
                    Try changing your filter to see more results
                  </p>
                )}
              </div>
            </div>
          </div>
        ) : (
          <div className="py-2">
            {children}
          </div>
        )}
      </div>
    </div>
  );
};

export default WorkoutHistorySection; 