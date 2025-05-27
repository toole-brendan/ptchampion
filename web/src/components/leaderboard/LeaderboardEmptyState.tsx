import React from 'react';
import { cn } from '@/lib/utils';
import { Trophy } from 'lucide-react';

interface LeaderboardEmptyStateProps {
  exerciseType: string;
  boardType: 'Global' | 'Local';
  className?: string;
}

const LeaderboardEmptyState: React.FC<LeaderboardEmptyStateProps> = ({
  exerciseType,
  boardType,
  className
}) => {
  const getMessage = () => {
    if (boardType === 'Local') {
      return "Be the first to post a score in this area";
    }
    return "Complete a workout to appear here";
  };

  return (
    <div className={cn(
      "flex flex-col items-center justify-center py-12 space-y-4",
      className
    )}>
      <div className="w-16 h-16 bg-brass-gold/10 rounded-full flex items-center justify-center">
        <Trophy className="w-8 h-8 text-brass-gold" />
      </div>
      
      <h3 className="font-mono text-sm font-medium text-tactical-gray uppercase tracking-wide">
        No Rankings Yet
      </h3>
      
      <p className="text-xs text-tactical-gray text-center max-w-xs uppercase tracking-wide">
        {getMessage()}
      </p>
    </div>
  );
};

export default LeaderboardEmptyState; 