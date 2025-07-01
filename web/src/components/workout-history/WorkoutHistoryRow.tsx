import React from 'react';
import { format } from 'date-fns';
import { cn, formatTime } from '@/lib/utils';

// Import exercise PNG images 
import pushupImage from '../../assets/pushup.png';
import pullupImage from '../../assets/pullup.png';
import situpImage from '../../assets/situp.png';
import runningImage from '../../assets/running.png';

interface WorkoutHistoryRowProps {
  id: string;
  exerciseType: string;
  count?: number;
  distance?: number;
  duration: number;
  date: Date;
  score?: number;
  onClick: (id: string) => void;
  showDivider?: boolean;
}

export const WorkoutHistoryRow: React.FC<WorkoutHistoryRowProps> = ({
  id,
  exerciseType,
  count,
  distance,
  duration,
  date,
  score,
  onClick,
  showDivider = true
}) => {
  // Get exercise icon and display name
  const getExerciseIcon = (type: string) => {
    const lowerType = type.toLowerCase();
    switch (lowerType) {
      case 'pushup':
      case 'push-up':
        return pushupImage;
      case 'situp':
      case 'sit-up':
        return situpImage;
      case 'pullup':
      case 'pull-up':
        return pullupImage;
      case 'run':
      case 'running':
        return runningImage;
      default:
        return pushupImage;
    }
  };

  const getExerciseName = (type: string) => {
    const lowerType = type.toLowerCase();
    switch (lowerType) {
      case 'pushup':
      case 'push-up':
        return 'Push-ups';
      case 'situp':
      case 'sit-up':
        return 'Sit-ups';
      case 'pullup':
      case 'pull-up':
        return 'Pull-ups';
      case 'run':
      case 'running':
        return 'Two-Mile Run';
      default:
        return type;
    }
  };

  // Get performance metric
  const getPerformanceMetric = () => {
    const lowerType = exerciseType.toLowerCase();
    
    // For runs, show duration instead of reps
    if (lowerType === 'run' || lowerType === 'running') {
      if (duration > 0) {
        const minutes = Math.floor(duration / 60);
        const seconds = duration % 60;
        return { value: `${minutes}:${String(seconds).padStart(2, '0')}`, label: '' };
      }
      return { value: '--', label: '' };
    }
    
    // For other exercises, show reps
    if (count !== undefined && count > 0) {
      return { value: count.toString(), label: 'reps' };
    } else if (distance !== undefined && distance > 0) {
      const distanceMiles = distance * 0.000621371;
      return { value: distanceMiles.toFixed(2), label: 'mi' };
    } else if (score !== undefined) {
      return { value: `${Math.round(score)}%`, label: 'score' };
    } else {
      return { value: '--', label: '' };
    }
  };

  const exerciseIcon = getExerciseIcon(exerciseType);
  const exerciseName = getExerciseName(exerciseType);
  const performanceMetric = getPerformanceMetric();
  
  // Format date as DDMONYYYY to match Dashboard
  const day = date.getDate();
  const month = date.toLocaleDateString('en-US', { month: 'short' }).toUpperCase();
  const year = date.getFullYear();
  const formattedDate = `${day}${month}${year}`;

  return (
    <div>
      <div 
        className="flex items-center space-x-4 px-4 py-3 hover:bg-gray-50 cursor-pointer transition-colors"
        onClick={() => onClick(id)}
        role="button"
        tabIndex={0}
        aria-label={`View details for ${exerciseName} workout on ${formattedDate}`}
      >
        {/* Exercise icon in circular background */}
        <div className="flex-shrink-0">
          <div className="w-11 h-11 rounded-full bg-brass-gold/10 flex items-center justify-center">
            <img 
              src={exerciseIcon} 
              alt={exerciseName}
              className="w-6 h-6"
            />
          </div>
        </div>

        {/* Workout details */}
        <div className="flex-1 min-w-0">
          <div className="space-y-1">
            <h3 className="text-base font-semibold text-command-black">
              {exerciseName}
            </h3>
            <p className="text-sm text-gray-600">
              {formattedDate}
            </p>
          </div>
        </div>

        {/* Performance metrics */}
        <div className="flex items-baseline space-x-1 flex-shrink-0">
          <span className="text-xl font-bold text-command-black font-mono">
            {performanceMetric.value}
          </span>
          {performanceMetric.label && (
            <span className="text-sm text-gray-600 pl-1">
              {performanceMetric.label}
            </span>
          )}
        </div>

        {/* Duration badge - commented out as run times are shown in main metric */}
        {/* <div className="flex-shrink-0">
          <div className="text-center">
            <div className="text-xs text-gray-500 mb-1">
              Duration
            </div>
            <div className="px-2 py-1 bg-gray-100 rounded-full">
              <span className="text-sm font-medium font-mono text-gray-700">
                {formatTime(duration)}
              </span>
            </div>
          </div>
        </div> */}
      </div>
      
      {/* Divider */}
      {showDivider && (
        <div className="mx-4 h-px bg-gray-200"></div>
      )}
    </div>
  );
};

export default WorkoutHistoryRow; 