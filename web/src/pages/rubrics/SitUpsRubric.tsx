import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';

const SitUpsRubric: React.FC = () => {
  const navigate = useNavigate();

  // Comprehensive scoring rubric: reps -> points (matching iOS exactly)
  const scoring: Record<number, number> = {
    0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7, 8: 8, 9: 9, 10: 10,
    11: 11, 12: 12, 13: 13, 14: 14, 15: 15, 16: 16, 17: 17, 18: 18, 19: 19, 20: 20,
    21: 21, 22: 22, 23: 23, 24: 24, 25: 25, 26: 26, 27: 27, 28: 28, 29: 29, 30: 30,
    31: 31, 32: 32, 33: 33, 34: 34, 35: 35, 36: 36, 37: 37, 38: 38, 39: 39, 40: 40,
    41: 41, 42: 42, 43: 43, 44: 44, 45: 45, 46: 46, 47: 47, 48: 48, 49: 49, 50: 50,
    51: 52, 52: 58, 53: 60, 54: 62, 55: 64, 56: 66, 57: 68, 58: 70, 59: 72, 60: 74,
    61: 76, 62: 78, 63: 80, 64: 82, 65: 84, 66: 86, 67: 88, 68: 90, 69: 91, 70: 92,
    71: 93, 72: 94, 73: 95, 74: 96, 75: 97, 76: 98, 77: 99, 78: 100
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
              SIT-UP SCORE TABLE
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

export default SitUpsRubric; 