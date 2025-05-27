import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';

const PullUpsRubric: React.FC = () => {
  const navigate = useNavigate();

  // Comprehensive scoring rubric: reps -> points (matching iOS exactly)
  const scoring: Record<number, number> = {
    25: 100, 24: 96, 23: 92, 22: 88, 21: 84, 20: 80, 19: 76, 18: 72, 17: 68, 16: 64,
    15: 60, 14: 56, 13: 52, 12: 48, 11: 44, 10: 40, 9: 36, 8: 32, 7: 28, 6: 24,
    5: 20, 4: 16, 3: 12, 2: 8, 1: 4, 0: 0
  };

  const sortedReps = Object.keys(scoring).map(Number).sort((a, b) => b - a);

  return (
    <div className="bg-cream min-h-screen relative">
      {/* Scrollable content area */}
      <div className="min-h-screen">
        {/* Spacer to push content below the header - matching iOS 60px */}
        <div className="h-15"></div>
        
        {/* Table container with horizontal padding */}
        <div className="px-4 pb-4">
          <div className="max-w-xs mx-auto">
            {/* Table with no outer border */}
            <div>
              {/* Header row - matching iOS 120px width, 44px height */}
              <div className="flex">
                <div className="w-30 h-11 flex items-center justify-center bg-gray-100 border border-gray-300">
                  <span className="font-mono text-base font-medium text-brass-gold">REPS</span>
                </div>
                <div className="w-30 h-11 flex items-center justify-center bg-gray-100 border-l-0 border border-gray-300">
                  <span className="font-mono text-base font-medium text-brass-gold">POINTS</span>
                </div>
              </div>

              {/* Data rows - matching iOS 120px width, 40px height */}
              {sortedReps.map((rep) => (
                <div key={rep} className="flex">
                  <div className={`w-30 h-10 flex items-center justify-center border-l border-r border-b border-gray-300 ${
                    rep % 2 === 0 ? 'bg-white' : 'bg-gray-50'
                  }`}>
                    <span className="font-mono text-base text-deep-ops">{rep}</span>
                  </div>
                  <div className={`w-30 h-10 flex items-center justify-center border-r border-b border-gray-300 ${
                    rep % 2 === 0 ? 'bg-white' : 'bg-gray-50'
                  }`}>
                    <span className="font-mono text-base text-deep-ops">{scoring[rep]}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Fixed header that stays at the top - matching iOS styling */}
      <div className="fixed top-0 left-0 right-0 z-10">
        <div className="bg-cream bg-opacity-95">
          <div className="flex items-center justify-between px-4 py-4">
            <div className="flex-1"></div>
            <h1 className="font-mono text-base font-medium text-deep-ops text-center flex-1">
              PULL-UP SCORE TABLE
            </h1>
            <div className="flex-1 flex justify-end">
              <Button
                variant="ghost"
                onClick={() => navigate(-1)}
                className="text-brass-gold hover:text-brass-gold hover:bg-brass-gold hover:bg-opacity-10 px-3 py-1 text-base font-medium"
              >
                Done
              </Button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PullUpsRubric; 