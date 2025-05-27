import React from 'react';
import { Flame, TrendingUp } from 'lucide-react';

interface WorkoutStreakCardsProps {
  currentStreak: number;
  longestStreak: number;
}

export const WorkoutStreakCards: React.FC<WorkoutStreakCardsProps> = ({
  currentStreak,
  longestStreak
}) => {
  return (
    <div className="grid grid-cols-2 gap-4">
      {/* Current Streak Card */}
      <div className="bg-white rounded-xl p-4 shadow-sm">
        <div className="flex flex-col items-center space-y-3">
          {/* Title */}
          <h3 className="text-xs font-mono font-medium text-deep-ops/80 uppercase tracking-wider text-center">
            Current Streak
          </h3>
          
          {/* Icon in circular container */}
          <div className="w-15 h-15 rounded-full bg-olive-mist/30 flex items-center justify-center">
            <Flame className="w-6 h-6 text-deep-ops" />
          </div>
          
          {/* Streak value and label */}
          <div className="text-center">
            <div className="text-xl font-bold text-deep-ops">
              {currentStreak}
            </div>
            <div className="text-xs text-gray-500">
              days
            </div>
          </div>
        </div>
      </div>

      {/* Longest Streak Card */}
      <div className="bg-white rounded-xl p-4 shadow-sm">
        <div className="flex flex-col items-center space-y-3">
          {/* Title */}
          <h3 className="text-xs font-mono font-medium text-deep-ops/80 uppercase tracking-wider text-center">
            Longest Streak
          </h3>
          
          {/* Icon in circular container */}
          <div className="w-15 h-15 rounded-full bg-olive-mist/30 flex items-center justify-center">
            <TrendingUp className="w-6 h-6 text-deep-ops" />
          </div>
          
          {/* Streak value and label */}
          <div className="text-center">
            <div className="text-xl font-bold text-deep-ops">
              {longestStreak}
            </div>
            <div className="text-xs text-gray-500">
              days
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default WorkoutStreakCards; 