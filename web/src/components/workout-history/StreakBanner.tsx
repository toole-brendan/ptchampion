import React from 'react';
import { Flame } from 'lucide-react';
import { Alert, AlertTitle, AlertDescription } from '@/components/ui/alert';

interface StreakBannerProps {
  streakCount: number;
  filtersActive: boolean;
}

const StreakBanner: React.FC<StreakBannerProps> = ({ streakCount, filtersActive }) => {
  // Only show streak if we have one and no filters are active
  if (streakCount === 0 || filtersActive) {
    return null;
  }

  return (
    <Alert className="rounded-card border-olive-mist bg-olive-mist/10">
      <Flame className="size-5 text-brass-gold" />
      <AlertTitle className="font-heading text-sm">Current Streak: {streakCount} {streakCount === 1 ? 'day' : 'days'}</AlertTitle>
      <AlertDescription>
        Keep your workout streak going for better results!
      </AlertDescription>
    </Alert>
  );
};

export default StreakBanner; 