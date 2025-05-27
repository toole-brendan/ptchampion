import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';

const TwoMileRunRubric: React.FC = () => {
  const navigate = useNavigate();

  // Comprehensive scoring rubric: time in seconds -> points (matching iOS exactly)
  const scoring: Record<number, number> = {
    660: 100, 666: 99, 672: 98, 678: 96, 684: 95, 690: 94, 696: 93, 702: 92, 708: 91, 714: 89,
    720: 88, 726: 87, 732: 86, 738: 85, 744: 84, 750: 82, 756: 81, 762: 80, 768: 79, 774: 78,
    780: 76, 786: 75, 792: 74, 798: 73, 804: 72, 810: 71, 816: 69, 822: 68, 828: 67, 834: 66,
    840: 64, 846: 63, 852: 62, 858: 61, 864: 60, 870: 59, 876: 57, 882: 56, 888: 55, 894: 54,
    900: 53, 906: 51, 912: 50, 918: 49, 924: 48, 930: 47, 936: 45, 942: 44, 948: 43, 954: 42,
    960: 41, 966: 39, 972: 38, 978: 37, 984: 36, 990: 35, 996: 33, 1002: 32, 1008: 31, 1014: 30,
    1020: 29, 1026: 28, 1032: 27, 1038: 26, 1044: 24, 1050: 23, 1056: 22, 1062: 21, 1068: 20, 1074: 19,
    1080: 18, 1086: 16, 1092: 15, 1098: 14, 1104: 13, 1110: 12, 1116: 11, 1122: 10, 1128: 9, 1134: 8,
    1140: 6, 1146: 5, 1152: 4, 1158: 3, 1164: 2, 1170: 0
  };

  const sortedTimes = Object.keys(scoring).map(Number).sort((a, b) => a - b);

  const formatTime = (seconds: number): string => {
    const minutes = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${minutes}:${secs.toString().padStart(2, '0')}`;
  };

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
                  <span className="font-mono text-base font-medium text-brass-gold">TIME</span>
                </div>
                <div className="w-30 h-11 flex items-center justify-center bg-gray-100 border-l-0 border border-gray-300">
                  <span className="font-mono text-base font-medium text-brass-gold">POINTS</span>
                </div>
              </div>

              {/* Data rows - matching iOS 120px width, 40px height */}
              {sortedTimes.map((timeInSeconds, index) => (
                <div key={timeInSeconds} className="flex">
                  <div className={`w-30 h-10 flex items-center justify-center border-l border-r border-b border-gray-300 ${
                    index % 2 === 0 ? 'bg-white' : 'bg-gray-50'
                  }`}>
                    <span className="font-mono text-base text-deep-ops">{formatTime(timeInSeconds)}</span>
                  </div>
                  <div className={`w-30 h-10 flex items-center justify-center border-r border-b border-gray-300 ${
                    index % 2 === 0 ? 'bg-white' : 'bg-gray-50'
                  }`}>
                    <span className="font-mono text-base text-deep-ops">{scoring[timeInSeconds]}</span>
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
              TWO-MILE RUN SCORE TABLE
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

export default TwoMileRunRubric; 