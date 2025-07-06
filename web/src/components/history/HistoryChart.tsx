import React from 'react';
import { format } from "date-fns";
import { AreaChart } from "lucide-react";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { SectionCard } from "@/components/ui/card";

interface ChartDataPoint {
  date: string;
  value: number;
}

interface HistoryChartProps {
  exerciseFilter: string;
  chartData: ChartDataPoint[];
  metricName: string;
  yAxisLabel: string;
}

export const HistoryChart: React.FC<HistoryChartProps> = ({
  exerciseFilter,
  chartData,
  metricName,
  yAxisLabel,
}) => {
  if (exerciseFilter === 'All') {
    return null;
  }

  return (
    <div className="animate-fade-in">
      <SectionCard
        title="Progress Chart"
        description={`${exerciseFilter} performance over time`}
        icon={<AreaChart className="size-5" />}
      >
        {chartData.length > 1 ? (
          <div>
            <div className="flex justify-between items-center mb-4">
              <h3 className="font-heading text-md uppercase">{exerciseFilter}</h3>
              <span className="text-brass-gold font-medium">{exerciseFilter}</span>
            </div>
            
            <ResponsiveContainer width="100%" height={200}>
              <LineChart data={chartData} margin={{ top: 5, right: 10, left: 10, bottom: 5 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="var(--color-olive-mist)" opacity={0.3} />
                <XAxis 
                  dataKey="date" 
                  stroke="var(--color-tactical-gray)" 
                  fontSize={11} 
                  tickLine={false} 
                  axisLine={false}
                  tickFormatter={(date) => format(new Date(date), "MMM d")}
                />
                <YAxis
                  stroke="var(--color-tactical-gray)" 
                  fontSize={11} 
                  tickLine={false} 
                  axisLine={false}
                  allowDecimals={yAxisLabel.includes('km')}
                  width={40}
                />
                <Tooltip
                  contentStyle={{ 
                    backgroundColor: 'var(--color-cream)', 
                    border: '1px solid var(--color-army-tan)', 
                    borderRadius: 'var(--radius-card)', 
                    fontSize: '12px' 
                  }}
                  cursor={{ stroke: 'var(--color-brass-gold)', strokeWidth: 1, strokeDasharray: '3 3' }}
                  formatter={(value: number) => [
                    `${value} ${yAxisLabel.includes('km') ? 'km' : (yAxisLabel || '')}`, 
                    metricName.replace(exerciseFilter + ' ', '')
                  ]}
                  labelFormatter={(label: string) => `Date: ${format(new Date(label), 'PP')}`}
                />
                <Line
                  type="monotone" 
                  dataKey="value" 
                  name={metricName}
                  stroke="var(--color-brass-gold)" 
                  strokeWidth={2}
                  activeDot={{ r: 6, fill: 'var(--color-brass-gold)', stroke: 'var(--color-cream)', strokeWidth: 2 }}
                  dot={{ r: 3, fill: 'var(--color-brass-gold)', strokeWidth: 0 }}
                  connectNulls
                />
              </LineChart>
            </ResponsiveContainer>
            
            <div className="text-right mt-2">
              <span className="text-xs text-tactical-gray flex items-center justify-end">
                Y-Axis: <span className="font-mono ml-1">{yAxisLabel}</span>
              </span>
            </div>
          </div>
        ) : (
          <div className="flex flex-col items-center justify-center py-8 text-center">
            <div className="text-tactical-gray/60 mb-4">
              <AreaChart className="size-10" />
            </div>
            <h3 className="font-heading text-sm uppercase tracking-wider mb-2">
              Not enough data to display chart
            </h3>
            <p className="text-xs text-tactical-gray max-w-md">
              Complete more {exerciseFilter.toLowerCase()} workouts to see your progress chart.
            </p>
          </div>
        )}
      </SectionCard>
    </div>
  );
};