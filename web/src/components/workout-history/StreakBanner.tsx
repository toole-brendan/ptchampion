import React from 'react';
import { Flame } from 'lucide-react';

interface StreakBannerProps {
  streakCount: number;
  filtersActive: boolean;
}

export const StreakBanner: React.FC<StreakBannerProps> = ({ streakCount, filtersActive }) => {
  if (filtersActive || streakCount === 0) {
    return null;
  }
  
  return (
    <div className="bg-card-background relative overflow-hidden rounded-card shadow-medium">
      <div className="flex items-center justify-center bg-brass-gold/10 p-3">
        <div className="flex items-center space-x-2">
          <Flame className="size-6 text-red-500" />
          <p className="font-heading text-lg text-command-black">
            <span className="font-bold text-brass-gold">{streakCount}-day</span> streak!
          </p>
          {streakCount >= 7 && (
            <span className="rounded bg-brass-gold px-2 py-0.5 font-bold text-xs uppercase text-white">
              {streakCount >= 30 ? 'Elite' : streakCount >= 14 ? 'Pro' : 'Solid'}
            </span>
          )}
        </div>
      </div>
    </div>
  );
};

export default StreakBanner; 