import React from 'react';
import { cn } from '@/lib/utils';

interface LeaderboardRowSkeletonProps {
  className?: string;
}

const LeaderboardRowSkeleton: React.FC<LeaderboardRowSkeletonProps> = React.memo(({ className }) => {
  return (
    <div className={cn(
      "flex items-center space-x-4 p-4 animate-pulse",
      className
    )}>
      {/* Rank badge skeleton */}
      <div className="w-11 h-11 bg-gray-200 rounded-full flex-shrink-0" />
      
      {/* User info skeleton */}
      <div className="flex-1 min-w-0 space-y-2">
        <div className="h-4 bg-gray-200 rounded w-32" />
        <div className="h-3 bg-gray-200 rounded w-20" />
      </div>
      
      {/* Score skeleton */}
      <div className="text-right space-y-1">
        <div className="h-6 bg-gray-200 rounded w-16" />
        <div className="h-3 bg-gray-200 rounded w-12" />
      </div>
    </div>
  );
});

LeaderboardRowSkeleton.displayName = 'LeaderboardRowSkeleton';

export default LeaderboardRowSkeleton; 