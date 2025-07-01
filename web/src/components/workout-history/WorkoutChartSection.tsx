import React from 'react';
import { TrendingUp } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { format } from 'date-fns';

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
  // Debug logging
  console.log('[WorkoutChartSection] Rendering with:', {
    filter,
    chartDataLength: chartData?.length || 0,
    yAxisLabel,
    version: 'v9-HISTORY-FIXES'
  });

  // Only show chart when filter is not "All"
  if (filter === 'All') {
    return null;
  }

  const hasData = chartData && chartData.length > 0;

  return (
    <div className="shadow-md rounded-lg overflow-hidden">
      {/* Dark header with brass gold title */}
      <div className="bg-deep-ops px-4 py-4">
        <div className="space-y-1">
          <h2 className="text-2xl font-bold text-brass-gold">
            PROGRESS CHART
          </h2>
          <div className="h-px bg-brass-gold/30"></div>
        </div>
      </div>
      
      {/* White content area */}
      <div className="bg-white">
        {hasData ? (
          // Chart with data
          <div className="p-4">
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-mono text-sm text-command-black uppercase">
                {filter === 'pushup' ? 'Push-ups' :
                 filter === 'situp' ? 'Sit-ups' :
                 filter === 'pullup' ? 'Pull-ups' :
                 filter === 'run' ? 'Two-Mile Run' : filter} Progress
              </h3>
              <span className="text-sm font-medium text-brass-gold">
                {yAxisLabel}
              </span>
            </div>
            
            {/* Actual chart using Recharts */}
            <div className="h-48">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart
                  data={chartData}
                  margin={{ top: 5, right: 5, left: 5, bottom: 5 }}
                >
                  <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                  <XAxis 
                    dataKey="date"
                    tickFormatter={(date) => format(new Date(date), 'MMM d')}
                    stroke="#6B7280"
                    style={{ fontSize: '12px' }}
                  />
                  <YAxis 
                    stroke="#6B7280"
                    style={{ fontSize: '12px' }}
                    tickFormatter={(value) => {
                      if (filter === 'run' && value >= 60) {
                        const minutes = Math.floor(value / 60);
                        const seconds = value % 60;
                        return `${minutes}:${seconds.toString().padStart(2, '0')}`;
                      }
                      return value.toString();
                    }}
                  />
                  <Tooltip 
                    labelFormatter={(date) => format(new Date(date), 'MMM d, yyyy')}
                    formatter={(value: number) => {
                      if (filter === 'run') {
                        const minutes = Math.floor(value / 60);
                        const seconds = value % 60;
                        return [`${minutes}:${seconds.toString().padStart(2, '0')}`, yAxisLabel];
                      }
                      return [value, yAxisLabel];
                    }}
                    contentStyle={{
                      backgroundColor: 'rgba(255, 255, 255, 0.95)',
                      border: '1px solid #e5e7eb',
                      borderRadius: '8px',
                      fontSize: '12px'
                    }}
                  />
                  <Line 
                    type="monotone" 
                    dataKey="value" 
                    stroke="#D4AF37" 
                    strokeWidth={2}
                    dot={{ fill: '#D4AF37', r: 4 }}
                    activeDot={{ r: 6 }}
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>
        ) : (
          // Empty state
          <div className="py-10 px-4">
            <div className="flex flex-col items-center justify-center space-y-5">
              <div className="w-20 h-20 rounded-full bg-brass-gold/10 flex items-center justify-center">
                <TrendingUp className="w-9 h-9 text-brass-gold" />
              </div>
              
              <div className="text-center space-y-2">
                <h3 className="font-mono text-sm font-medium text-gray-600 uppercase tracking-wider">
                  Not Enough Data to Display Chart
                </h3>
                <p className="font-mono text-xs text-gray-500 max-w-xs">
                  Complete more {
                    filter === 'pushup' ? 'PUSH-UP' :
                    filter === 'situp' ? 'SIT-UP' :
                    filter === 'pullup' ? 'PULL-UP' :
                    filter === 'run' ? 'RUNNING' : filter.toUpperCase()
                  } workouts to see progress
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