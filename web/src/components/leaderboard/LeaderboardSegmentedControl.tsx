import React from 'react';
import { cn } from '@/lib/utils';

interface LeaderboardSegmentedControlProps {
  selectedBoard: 'Global' | 'Local';
  onBoardChange: (board: 'Global' | 'Local') => void;
  className?: string;
}

const LeaderboardSegmentedControl: React.FC<LeaderboardSegmentedControlProps> = ({
  selectedBoard,
  onBoardChange,
  className
}) => {
  const boards = ['Global', 'Local'] as const;

  return (
    <div className={cn(
      "flex p-1 bg-white rounded-xl shadow-sm border border-olive-mist/20",
      className
    )}>
      {boards.map((board) => {
        const isSelected = selectedBoard === board;
        
        return (
          <button
            key={board}
            className={cn(
              "flex-1 px-6 py-3 text-sm font-mono uppercase tracking-wide rounded-lg transition-all duration-300 ease-spring relative",
              "focus:outline-none focus:ring-2 focus:ring-brass-gold focus:ring-offset-2",
              isSelected 
                ? "bg-deep-ops text-cream shadow-sm transform scale-[0.98]" 
                : "text-deep-ops hover:bg-gray-50 active:scale-[0.96]"
            )}
            onClick={() => onBoardChange(board)}
            aria-pressed={isSelected}
            aria-label={`${board} leaderboard`}
          >
            {board}
          </button>
        );
      })}
    </div>
  );
};

export default LeaderboardSegmentedControl; 