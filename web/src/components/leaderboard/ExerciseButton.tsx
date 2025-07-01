import React from 'react';
import { cn } from '@/lib/utils';
import { Trophy } from 'lucide-react';

// Import exercise PNG images matching Workout History page
import pushupImage from '../../assets/pushup.png';
import pullupImage from '../../assets/pullup.png';
import situpImage from '../../assets/situp.png';
import runningImage from '../../assets/running.png';

// Import white variants for selected state
import pushupWhiteImage from '../../../assets/pushup_white.png';
import pullupWhiteImage from '../../../assets/pullup_white.png';
import situpWhiteImage from '../../../assets/situp_white.png';
import runWhiteImage from '../../../assets/run_white.png';

interface ExerciseButtonProps {
  exercise: {
    id: string;
    name: string;
    displayName: string;
  };
  isSelected: boolean;
  onClick: () => void;
}

const exerciseAssets = {
  overall: { normal: null, white: null }, // Will use Trophy icon for overall
  pushup: { normal: pushupImage, white: pushupWhiteImage },
  situp: { normal: situpImage, white: situpWhiteImage },
  pullup: { normal: pullupImage, white: pullupWhiteImage },
  running: { normal: runningImage, white: runWhiteImage },
} as const;

const ExerciseButton: React.FC<ExerciseButtonProps> = ({
  exercise,
  isSelected,
  onClick
}) => {
  const assetImages = exerciseAssets[exercise.id as keyof typeof exerciseAssets];
  const currentImage = isSelected && assetImages?.white ? assetImages.white : assetImages?.normal;

  return (
    <button
      className={cn(
        "flex items-center space-x-2 px-4 py-2.5 rounded-lg transition-all duration-300 ease-spring",
        "whitespace-nowrap focus:outline-none",
        "active:scale-95 transform",
        isSelected
          ? "bg-deep-ops text-brass-gold shadow-md ring-2 ring-brass-gold ring-offset-2"
          : "bg-white text-deep-ops border border-deep-ops/30 hover:bg-gray-50 hover:border-deep-ops/50"
      )}
      onClick={onClick}
      aria-pressed={isSelected}
      aria-label={`Filter by ${exercise.displayName}`}
    >
      {currentImage ? (
        <img 
          src={currentImage} 
          alt={exercise.displayName}
          className="w-4 h-4 transition-opacity"
        />
      ) : (
        <Trophy 
          className={cn(
            "w-4 h-4 transition-colors",
            isSelected ? "text-brass-gold" : "text-deep-ops"
          )} 
        />
      )}
      <span className="text-xs font-mono uppercase tracking-wide font-medium">
        {exercise.displayName}
      </span>
    </button>
  );
};

export default ExerciseButton; 