import React from 'react';
import { format } from 'date-fns';
import { Link } from 'react-router-dom';
import { ExerciseResponse } from '@/lib/types';
import { formatTime, formatDistance } from '@/lib/utils';
import { Dumbbell, TrendingUp, Calendar } from 'lucide-react';



// Helper to determine icon and metrics for an exercise
const getExerciseInfo = (exerciseType: string): { 
  icon: React.ReactNode,
  metricLabel: string,
  metricValue: (workout: ExerciseResponse) => string | number
} => {
  const typeLower = exerciseType.toLowerCase();
  const isRunning = typeLower.includes('run');

  if (isRunning) {
    return {
      icon: <TrendingUp className="size-5 text-brass-gold" />,
      metricLabel: 'Distance',
      metricValue: (workout) => formatDistance(workout.distance ?? 0)
    };
  }
  
  // Default for all rep-based exercises
  return {
    icon: <Dumbbell className="size-5 text-brass-gold" />,
    metricLabel: 'Reps',
    metricValue: (workout) => workout.reps ?? 0
  };
};

// Grade badge with appropriate color
const GradeBadge: React.FC<{ grade: number }> = ({ grade }) => {
  let color = 'bg-red-500';
  
  if (grade >= 90) {
    color = 'bg-green-600';
  } else if (grade >= 80) {
    color = 'bg-green-500';
  } else if (grade >= 70) {
    color = 'bg-yellow-500';
  } else if (grade >= 60) {
    color = 'bg-yellow-600';
  }
  
  return (
    <div className={`${color} rounded-md px-2 py-0.5 font-semibold text-xs uppercase text-white`}>
      {grade}%
    </div>
  );
};

interface WorkoutCardProps {
  workout: ExerciseResponse;
  onClick?: (event: React.MouseEvent<HTMLAnchorElement>) => void;
}

export const WorkoutCard: React.FC<WorkoutCardProps> = ({ workout, onClick }) => {
  const { icon, metricLabel, metricValue } = getExerciseInfo(workout.exercise_type);
  const exerciseDate = new Date(workout.created_at);
  const formattedDate = format(exerciseDate, 'MMM dd, yyyy');
  
  return (
    <Link 
      to={`/history/${workout.id}`} 
      className="block transition-all hover:translate-y-[-2px]"
      aria-label={`View ${workout.exercise_type} workout from ${formattedDate}`}
      onClick={onClick}
    >
      <div className="bg-card-background relative overflow-hidden rounded-card border-l-4 border-brass-gold shadow-medium hover:bg-brass-gold/5">
        <div className="p-content">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="shrink-0">
                {icon}
              </div>
              <div>
                <h3 className="font-heading text-sm uppercase text-command-black">{workout.exercise_type}</h3>
                <div className="flex items-center space-x-1 text-xs text-tactical-gray">
                  <Calendar className="size-3" />
                  <span>{formattedDate}</span>
                </div>
              </div>
            </div>
            
            <div className="flex items-center space-x-4">
              <div className="text-right">
                <div className="text-xs uppercase text-tactical-gray">{metricLabel}</div>
                <div className="font-heading text-xl text-brass-gold">{metricValue(workout)}</div>
              </div>
              
              {workout.grade !== undefined && (
                <GradeBadge grade={workout.grade} />
              )}
            </div>
          </div>
          
          {workout.time_in_seconds && (
            <div className="mt-2 text-right text-xs text-tactical-gray">
              Duration: {formatTime(workout.time_in_seconds)}
            </div>
          )}
        </div>
      </div>
    </Link>
  );
};

export default WorkoutCard; 