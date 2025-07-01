import React from 'react';
import { cn } from '@/lib/utils';

// Import exercise PNG images 
import pushupImage from '../../assets/pushup.png';
import pullupImage from '../../assets/pullup.png';
import situpImage from '../../assets/situp.png';
import runningImage from '../../assets/running.png';

// Import white variants for selected state
import pushupWhiteImage from '../../assets/pushup_white.png';
import pullupWhiteImage from '../../assets/pullup_white.png';
import situpWhiteImage from '../../assets/situp_white.png';
import runWhiteImage from '../../assets/run_white.png';

interface ExerciseFilterBarProps {
  filter: string;
  onFilterChange: (filter: string) => void;
}

interface FilterOption {
  id: string;
  label: string;
  value: string;
  icon?: string;
  iconWhite?: string;
  systemIcon?: string;
}

const filterOptions: FilterOption[] = [
  {
    id: 'all',
    label: 'All Exercises',
    value: 'All'
  },
  {
    id: 'pushup',
    label: 'Push-ups',
    value: 'pushup',
    icon: pushupImage,
    iconWhite: pushupWhiteImage
  },
  {
    id: 'situp',
    label: 'Sit-ups', 
    value: 'situp',
    icon: situpImage,
    iconWhite: situpWhiteImage
  },
  {
    id: 'pullup',
    label: 'Pull-ups',
    value: 'pullup',
    icon: pullupImage,
    iconWhite: pullupWhiteImage
  },
  {
    id: 'run',
    label: 'Two-Mile Run',
    value: 'run',
    icon: runningImage,
    iconWhite: runWhiteImage
  }
];

export const ExerciseFilterBar: React.FC<ExerciseFilterBarProps> = ({
  filter,
  onFilterChange
}) => {
  return (
    <div className="overflow-x-auto pb-4 pt-3 -mx-1 px-1">
      <div className="flex items-center space-x-2 min-w-max px-4 py-2">
        {filterOptions.map((option) => {
          const isActive = filter === option.value;
          
          return (
            <button
              key={option.id}
              onClick={() => onFilterChange(option.value)}
              className={cn(
                "flex items-center space-x-2 px-4 py-2.5 rounded-lg transition-all duration-300 ease-spring",
                "whitespace-nowrap focus:outline-none",
                "active:scale-95 transform",
                isActive
                  ? "bg-deep-ops text-brass-gold shadow-md ring-2 ring-brass-gold ring-offset-2"
                  : "bg-white text-deep-ops border border-deep-ops/30 hover:bg-gray-50 hover:border-deep-ops/50"
              )}
              aria-pressed={isActive}
              aria-label={`Filter by ${option.label}`}
            >
              {option.icon && (
                <img 
                  src={isActive && option.iconWhite ? option.iconWhite : option.icon} 
                  alt={option.label}
                  className="w-4 h-4 transition-opacity"
                />
              )}
              <span className="text-xs font-mono uppercase tracking-wide font-medium">
                {option.label}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
};

export default ExerciseFilterBar; 