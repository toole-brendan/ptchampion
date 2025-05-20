import React from 'react';
import { format } from 'date-fns';
import { cn } from '@/lib/utils';
import { formatTime, formatDistance } from '@/lib/utils';

// Import exercise icons (assuming these are the same ones used in the Dashboard)
import pushupImage from '../../assets/pushup.png';
import pullupImage from '../../assets/pullup.png';
import situpImage from '../../assets/situp.png';
import runningImage from '../../assets/running.png';

interface WorkoutCardProps {
  id: string;
  exerciseType: string;
  count?: number;
  distance?: number;
  duration: number;
  date: Date;
  score?: number;
  onClick: (id: string) => void;
}

export function WorkoutCard({
  id,
  exerciseType,
  count,
  distance,
  duration,
  date,
  score,
  onClick
}: WorkoutCardProps) {
  // Get the appropriate icon and display name based on exercise type
  const getExerciseDetails = () => {
    const type = exerciseType.toUpperCase();
    
    if (type.includes('PUSH')) {
      return { 
        name: 'Push-ups',
        icon: pushupImage,
        metric: count ? `${count} reps` : '-'
      };
    } else if (type.includes('PULL')) {
      return { 
        name: 'Pull-ups',
        icon: pullupImage,
        metric: count ? `${count} reps` : '-'
      };
    } else if (type.includes('SIT')) {
      return { 
        name: 'Sit-ups',
        icon: situpImage,
        metric: count ? `${count} reps` : '-'
      };
    } else if (type.includes('RUN')) {
      return { 
        name: 'Running',
        icon: runningImage,
        metric: distance ? formatDistance(distance) : '-'
      };
    } else {
      return { 
        name: exerciseType,
        icon: null,
        metric: count ? `${count} reps` : '-'
      };
    }
  };

  const { name, icon, metric } = getExerciseDetails();
  const formattedDate = format(date, 'MMM dd, yyyy');
  const formattedTime = format(date, 'hh:mm a');
  
  return (
    <div 
      className="animate-slide-up flex items-center justify-between rounded-card px-4 py-3 transition-colors border border-olive-mist/20 hover:bg-brass-gold/5 focus-visible:outline-none focus-visible:ring-[var(--ring-focus)] cursor-pointer bg-white"
      onClick={() => onClick(id)}
      tabIndex={0}
      role="button"
      aria-label={`View details for ${name} workout on ${formattedDate}`}
    >
      <div className="flex items-center">
        <div className="mr-4 flex size-10 items-center justify-center rounded-full border border-brass-gold border-opacity-30 bg-brass-gold bg-opacity-10">
          {icon && <img src={icon} alt={name} className="size-6" />}
        </div>
        <div>
          <h3 className="mb-0.5 font-heading text-sm uppercase text-command-black">
            {name}
          </h3>
          <div className="flex items-center space-x-2">
            <p className="text-xs text-tactical-gray">
              {formattedDate} at {formattedTime}
            </p>
            {score !== undefined && (
              <span className={cn(
                "text-xs px-1.5 py-0.5 rounded font-medium",
                score >= 90 ? "bg-emerald-100 text-emerald-800" :
                score >= 70 ? "bg-amber-100 text-amber-800" :
                "bg-red-100 text-red-800"
              )}>
                {score}%
              </span>
            )}
          </div>
        </div>
      </div>
      <div className="flex flex-col items-end">
        <div className="flex-shrink-0 font-heading text-heading4 text-brass-gold tabular-nums">
          {metric}
        </div>
        <p className="text-xs text-tactical-gray">
          {formatTime(duration)}
        </p>
      </div>
    </div>
  );
}

// Export as default to maintain backward compatibility
export default WorkoutCard; 