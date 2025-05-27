import React from 'react';
import { TrendingUp } from 'lucide-react';

interface ChartDataPoint {
  date: Date;
  value: number;
}

interface WorkoutChartSectionProps {
  filter: string;
  chartData: ChartDataPoint[];
  yAxisLabel: string;
}

export const WorkoutChartSection: React.FC<WorkoutChartSectionProps> = ({
  filter,
  chartData,
  yAxisLabel
}) => {
  // Only show chart when filter is not "All"
  if (filter === 'All') {
    return null;
  }

  const hasData = chartData && chartData.length > 0;

  return (
    <div className="space-y-4">
      <h2 className="text-base font-normal tracking-wider text-deep-ops uppercase">
        Progress Chart
      </h2>
      
      <div className="bg-white rounded-lg shadow-md overflow-hidden">
        {hasData ? (
          // Chart with data
          <div className="p-4">
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-mono text-sm text-command-black">
                {filter}
              </h3>
              <span className="text-sm font-medium text-brass-gold">
                {yAxisLabel}
              </span>
            </div>
            
            {/* Placeholder for actual chart - would integrate with chart library */}
            <div className="h-48 bg-gray-50 rounded-lg flex items-center justify-center">
              <div className="text-center text-gray-500">
                <TrendingUp className="w-8 h-8 mx-auto mb-2" />
                <p className="text-sm">Chart visualization would go here</p>
                <p className="text-xs">({chartData.length} data points)</p>
              </div>
            </div>
          </div>
        ) : (
          // Empty state
          <div className="p-6">
            <div className="flex flex-col items-center justify-center space-y-4 min-h-[180px]">
              <TrendingUp className="w-9 h-9 text-gray-400" />
              
              <div className="text-center space-y-2">
                <h4 className="font-mono text-sm font-medium text-gray-600 uppercase tracking-wider">
                  Not Enough Data to Display Chart
                </h4>
                <p className="font-mono text-xs text-gray-500 max-w-xs">
                  Complete more {filter.toUpperCase()} workouts to see progress
                </p>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default WorkoutChartSection; 