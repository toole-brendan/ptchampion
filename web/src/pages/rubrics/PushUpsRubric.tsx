import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';

const PushUpsRubric: React.FC = () => {
  const navigate = useNavigate();

  // Comprehensive scoring rubric: reps -> points (matching iOS exactly)
  const scoring: Record<number, number> = {
    68: 100, 67: 99, 66: 97, 65: 96, 64: 94, 63: 93, 62: 91, 61: 90, 60: 88, 59: 87,
    58: 85, 57: 84, 56: 82, 55: 81, 54: 79, 53: 78, 52: 76, 51: 75, 50: 74, 49: 72,
    48: 71, 47: 69, 46: 68, 45: 66, 44: 65, 43: 63, 42: 62, 41: 60, 40: 59, 39: 57,
    38: 56, 37: 54, 36: 53, 35: 51, 34: 50, 33: 48, 32: 47, 31: 46, 30: 44, 29: 43,
    28: 41, 27: 40, 26: 38, 25: 37, 24: 35, 23: 34, 22: 32, 21: 31, 20: 29, 19: 28,
    18: 26, 17: 25, 16: 24, 15: 22, 14: 21, 13: 19, 12: 18, 11: 16, 10: 15, 9: 13,
    8: 12, 7: 10, 6: 9, 5: 7, 4: 6, 3: 4, 2: 3, 1: 1, 0: 0
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
              PUSH-UP SCORE TABLE
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

export default PushUpsRubric; 