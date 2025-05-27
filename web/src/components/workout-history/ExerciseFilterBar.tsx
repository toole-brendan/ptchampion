import React from 'react';
import { cn } from '@/lib/utils';

// Import exercise PNG images 
import pushupImage from '../../assets/pushup.png';
import pullupImage from '../../assets/pullup.png';
import situpImage from '../../assets/situp.png';
import runningImage from '../../assets/running.png';

interface ExerciseFilterBarProps {
  filter: string;
  onFilterChange: (filter: string) => void;
}

interface FilterOption {
  id: string;
  label: string;
  value: string;
  icon?: string;
  systemIcon?: string;
}

const filterOptions: FilterOption[] = [
  {
    id: 'all',
    label: 'All Exercises',
    value: 'All',
    systemIcon: 'figure.run.circle.fill'
  },
  {
    id: 'pushup',
    label: 'Push-ups',
    value: 'pushup',
    icon: pushupImage
  },
  {
    id: 'situp',
    label: 'Sit-ups', 
    value: 'situp',
    icon: situpImage
  },
  {
    id: 'pullup',
    label: 'Pull-ups',
    value: 'pullup',
    icon: pullupImage
  },
  {
    id: 'run',
    label: 'Run',
    value: 'run',
    icon: runningImage
  }
];

export const ExerciseFilterBar: React.FC<ExerciseFilterBarProps> = ({
  filter,
  onFilterChange
}) => {
  return (
    <div className="overflow-x-auto pb-4 -mx-1 px-1">
      <div className="flex items-center space-x-2 min-w-max px-4">
        {filterOptions.map((option) => {
          const isActive = filter === option.value;
          
          return (
            <button
              key={option.id}
              onClick={() => onFilterChange(option.value)}
              className={cn(
                "flex items-center space-x-2 px-3 py-2 rounded-full text-sm font-semibold transition-all duration-300 whitespace-nowrap",
                "transform hover:scale-105 active:scale-95",
                "shadow-sm",
                isActive
                  ? "bg-brass-gold text-deep-ops shadow-md"
                  : "bg-white text-command-black hover:bg-brass-gold/10"
              )}
            >
              {option.icon ? (
                <img 
                  src={option.icon} 
                  alt={option.label}
                  className="w-4 h-4"
                />
              ) : (
                <div className="w-4 h-4 flex items-center justify-center">
                  <svg 
                    className="w-3 h-3" 
                    fill="currentColor" 
                    viewBox="0 0 20 20"
                  >
                    <circle cx="10" cy="10" r="8" />
                  </svg>
                </div>
              )}
              <span>{option.label}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
};

export default ExerciseFilterBar; 