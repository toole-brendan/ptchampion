import React from 'react';
import { cn } from '@/lib/utils';
import { 
  Trophy, 
  Dumbbell, 
  Activity, 
  Target, 
  Timer 
} from 'lucide-react';

interface ExerciseButtonProps {
  exercise: {
    id: string;
    name: string;
    displayName: string;
  };
  isSelected: boolean;
  onClick: () => void;
}

const exerciseIcons = {
  overall: Trophy,
  pushup: Dumbbell,
  situp: Activity,
  pullup: Target,
  running: Timer,
} as const;

const ExerciseButton: React.FC<ExerciseButtonProps> = ({
  exercise,
  isSelected,
  onClick
}) => {
  const IconComponent = exerciseIcons[exercise.id as keyof typeof exerciseIcons] || Trophy;

  return (
    <button
      className={cn(
        "flex items-center space-x-2 px-4 py-2.5 rounded-lg transition-all duration-300 ease-spring",
        "border whitespace-nowrap focus:outline-none focus:ring-2 focus:ring-brass-gold focus:ring-offset-2",
        "active:scale-95 transform",
        isSelected
          ? "bg-deep-ops text-brass-gold border-deep-ops shadow-md"
          : "bg-white text-deep-ops border-deep-ops/30 hover:bg-gray-50 hover:border-deep-ops/50"
      )}
      onClick={onClick}
      aria-pressed={isSelected}
      aria-label={`Filter by ${exercise.displayName}`}
    >
      <IconComponent 
        className={cn(
          "w-4 h-4 transition-colors",
          isSelected ? "text-brass-gold" : "text-deep-ops"
        )} 
      />
      <span className="text-xs font-mono uppercase tracking-wide font-medium">
        {exercise.displayName}
      </span>
    </button>
  );
};

export default ExerciseButton; 