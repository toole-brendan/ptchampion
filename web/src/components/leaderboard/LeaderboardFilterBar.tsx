import React from 'react';
import { cn } from '@/lib/utils';
import ExerciseButton from './ExerciseButton';
import FilterDropdown from './FilterDropdown';

interface LeaderboardFilterBarProps {
  selectedExercise: string;
  selectedCategory: string;
  selectedRadius: string;
  showRadiusSelector: boolean;
  onExerciseChange: (exercise: string) => void;
  onCategoryChange: (category: string) => void;
  onRadiusChange: (radius: string) => void;
  className?: string;
}

const exercises = [
  { id: 'overall', name: 'overall', displayName: 'Overall' },
  { id: 'pushup', name: 'pushup', displayName: 'Push-ups' },
  { id: 'situp', name: 'situp', displayName: 'Sit-ups' },
  { id: 'pullup', name: 'pullup', displayName: 'Pull-ups' },
  { id: 'running', name: 'running', displayName: 'Two-Mile Run' },
];

const categoryOptions = [
  { value: 'weekly', label: 'Weekly' },
  { value: 'monthly', label: 'Monthly' },
  { value: 'all-time', label: 'All Time' },
];

const radiusOptions = [
  { value: '5', label: '5 Miles' },
  { value: '10', label: '10 Miles' },
  { value: '25', label: '25 Miles' },
  { value: '50', label: '50 Miles' },
];

const LeaderboardFilterBar: React.FC<LeaderboardFilterBarProps> = ({
  selectedExercise,
  selectedCategory,
  selectedRadius,
  showRadiusSelector,
  onExerciseChange,
  onCategoryChange,
  onRadiusChange,
  className
}) => {
  return (
    <div className={cn("space-y-4", className)}>
      {/* Horizontal scrolling exercise buttons */}
      <div className="overflow-x-auto pt-3 pb-4 -mx-1 px-1">
        <div className="flex space-x-2 min-w-max px-4 py-2">
          {exercises.map((exercise) => (
            <ExerciseButton
              key={exercise.id}
              exercise={exercise}
              isSelected={selectedExercise === exercise.id}
              onClick={() => onExerciseChange(exercise.id)}
            />
          ))}
        </div>
      </div>

      {/* Time period and radius filters */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <FilterDropdown
          label="TIME PERIOD"
          value={selectedCategory}
          options={categoryOptions}
          onChange={onCategoryChange}
        />
        {showRadiusSelector && (
          <FilterDropdown
            label="RADIUS"
            value={selectedRadius}
            options={radiusOptions}
            onChange={onRadiusChange}
          />
        )}
      </div>
    </div>
  );
};

export default LeaderboardFilterBar; 