import React from 'react';
import { formatDistanceToNow } from 'date-fns';
import { Card, CardContent } from '@/components/ui/card';
import { AreaChart, Flame, Clock, Award } from 'lucide-react';
import { cn } from '@/lib/utils';
import { formatTime as formatDuration, formatDistance } from '@/lib/utils';

// Activity type definition

// Activity type definition
type ActivityType = 'PUSHUP' | 'PULLUP' | 'SITUP' | 'RUNNING';

// Format exercise type for display
const formatExerciseType = (type: string): string => {
  switch (type.toUpperCase()) {
    case 'PUSHUP': return 'Push-ups';
    case 'PULLUP': return 'Pull-ups';
    case 'SITUP': return 'Sit-ups';
    case 'RUNNING': return 'Running';
    default: return type;
  }
};

type WorkoutCardProps = {
  id: string;
  exerciseType: ActivityType;
  count?: number;
  distance?: number;
  duration: number;
  date: Date;
  score?: number;
  onClick?: (id: string) => void;
  className?: string;
};

export function WorkoutCard({
  id,
  exerciseType,
  count,
  distance,
  duration,
  date,
  score,
  onClick,
  className
}: WorkoutCardProps) {
  // Format the time ago in a readable format (e.g., "2 days ago")
  const timeAgo = formatDistanceToNow(date, { addSuffix: true });
  
  return (
    <Card 
      variant="interactive"
      className={cn("overflow-hidden", className)}
      onClick={() => onClick?.(id)}
    >
      <CardContent className="p-0">
        <div className="bg-deep-ops p-3 text-cream">
          <div className="flex items-center justify-between">
            <h3 className="font-heading text-lg uppercase tracking-wider">{formatExerciseType(exerciseType)}</h3>
            {score !== undefined && (
              <div className="flex items-center text-brass-gold">
                <Award className="mr-1 size-4" />
                <span className="font-heading">{score}</span>
              </div>
            )}
          </div>
          <p className="text-xs text-army-tan">{timeAgo}</p>
        </div>
        
        <div className="grid grid-cols-3 gap-2 p-4 text-center">
          {exerciseType !== 'RUNNING' && count !== undefined && (
            <div className="flex flex-col items-center">
              <div className="flex size-8 items-center justify-center rounded-full bg-brass-gold bg-opacity-10">
                <Flame className="size-4 text-brass-gold" />
              </div>
              <span className="mt-1 font-heading text-heading4 text-command-black">{count}</span>
              <span className="text-xs text-tactical-gray">Reps</span>
            </div>
          )}
          
          {exerciseType === 'RUNNING' && distance !== undefined && (
            <div className="flex flex-col items-center">
              <div className="flex size-8 items-center justify-center rounded-full bg-brass-gold bg-opacity-10">
                <AreaChart className="size-4 text-brass-gold" />
              </div>
              <span className="mt-1 font-heading text-heading4 text-command-black">
                {formatDistance(distance).split(' ')[0]}
              </span>
              <span className="text-xs text-tactical-gray">km</span>
            </div>
          )}
          
          <div className="flex flex-col items-center">
            <div className="flex size-8 items-center justify-center rounded-full bg-brass-gold bg-opacity-10">
              <Clock className="size-4 text-brass-gold" />
            </div>
            <span className="mt-1 font-heading text-heading4 text-command-black">
              {formatDuration(duration)}
            </span>
            <span className="text-xs text-tactical-gray">Time</span>
          </div>
          
          {score !== undefined && (
            <div className="flex flex-col items-center">
              <div className="flex size-8 items-center justify-center rounded-full bg-brass-gold bg-opacity-10">
                <Award className="size-4 text-brass-gold" />
              </div>
              <span className="mt-1 font-heading text-heading4 text-command-black">{score}</span>
              <span className="text-xs text-tactical-gray">Score</span>
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

// Export as default to maintain backward compatibility
export default WorkoutCard; 