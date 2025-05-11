import React, { useState, useEffect, useCallback } from 'react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { Card, CardContent, CardHeader, CardTitle } from './ui/card';
import { format, subDays, isWithinInterval } from 'date-fns';

// Types for our workout data
interface WorkoutDataPoint {
  date: string; // ISO date string
  count: number;
  duration?: number; // in seconds
  calories?: number;
}

interface WorkoutChartProps {
  data: WorkoutDataPoint[];
  type: 'pushups' | 'pullups' | 'situps' | 'running';
  title?: string;
  timeframe?: 'week' | 'month' | 'year';
  className?: string;
}

export default function WorkoutChart({
  data,
  type,
  title = 'Workout Progress',
  timeframe = 'week',
  className
}: WorkoutChartProps) {
  const [chartData, setChartData] = useState<Array<Record<string, string | number>>>([]);
  const [activeTimeframe, setActiveTimeframe] = useState(timeframe);
  
  // Generate chart colors based on workout type (matching iOS)
  const getChartColors = () => {
    switch (type) {
      case 'pushups':
        return {
          primary: '#BFA24D', // brass-gold
          secondary: 'rgba(191, 162, 77, 0.2)', // brass-gold with transparency
        };
      case 'pullups':
        return {
          primary: '#4E5A48', // tactical-gray
          secondary: 'rgba(78, 90, 72, 0.2)', // tactical-gray with transparency
        };
      case 'situps':
        return {
          primary: '#C9CCA6', // olive-mist
          secondary: 'rgba(201, 204, 166, 0.2)', // olive-mist with transparency
        };
      case 'running':
        return {
          primary: '#E0D4A6', // army-tan
          secondary: 'rgba(224, 212, 166, 0.2)', // army-tan with transparency
        };
      default:
        return {
          primary: '#BFA24D', // brass-gold
          secondary: 'rgba(191, 162, 77, 0.2)', // brass-gold with transparency
        };
    }
  };
  
  const colors = getChartColors();
  
  // Format data for the chart based on timeframe
  useEffect(() => {
    if (!data || data.length === 0) {
      // Generate empty data for the selected timeframe
      const emptyData = generateEmptyData(activeTimeframe);
      setChartData(emptyData);
      return;
    }
    
    // Format actual data
    const formattedData = formatDataForTimeframe(data, activeTimeframe);
    setChartData(formattedData);
  }, [data, activeTimeframe, formatDataForTimeframe, generateEmptyData]);
  
  // Generate empty placeholder data for the chart
  const generateEmptyData = useCallback((timeframe: string) => {
    const today = new Date();
    const result = [];
    
    if (timeframe === 'week') {
      // Generate 7 days of empty data
      for (let i = 6; i >= 0; i--) {
        const date = subDays(today, i);
        result.push({
          date: format(date, 'yyyy-MM-dd'),
          display: format(date, 'EEE'),
          count: 0
        });
      }
    } else if (timeframe === 'month') {
      // Generate 30 days of empty data
      for (let i = 29; i >= 0; i--) {
        const date = subDays(today, i);
        result.push({
          date: format(date, 'yyyy-MM-dd'),
          display: format(date, 'MMM d'),
          count: 0
        });
      }
    } else {
      // Generate 12 months of empty data
      for (let i = 11; i >= 0; i--) {
        const date = new Date(today.getFullYear(), today.getMonth() - i, 1);
        result.push({
          date: format(date, 'yyyy-MM'),
          display: format(date, 'MMM'),
          count: 0
        });
      }
    }
    
    return result;
  }, []);
  
  // Format data based on the selected timeframe
  const formatDataForTimeframe = useCallback((data: WorkoutDataPoint[], timeframe: string) => {
    const today = new Date();
    let startDate: Date;
    let formatString: string;
    let displayFormat: string;
    
    // Configure date range and format based on timeframe
    if (timeframe === 'week') {
      startDate = subDays(today, 6);
      formatString = 'yyyy-MM-dd';
      displayFormat = 'EEE';
    } else if (timeframe === 'month') {
      startDate = subDays(today, 29);
      formatString = 'yyyy-MM-dd';
      displayFormat = 'MMM d';
    } else {
      // Year
      startDate = new Date(today.getFullYear() - 1, today.getMonth(), 1);
      formatString = 'yyyy-MM';
      displayFormat = 'MMM';
    }
    
    // Filter data to only include items within the timeframe
    const filteredData = data.filter(item => {
      const itemDate = new Date(item.date);
      return isWithinInterval(itemDate, { start: startDate, end: today });
    });
    
    // Create a map to aggregate data by date
    const dateMap = new Map();
    
    // Initialize with empty dates
    const emptyDates = generateEmptyData(timeframe);
    emptyDates.forEach(item => {
      dateMap.set(item.date, { date: item.date, display: item.display, count: 0 });
    });
    
    // Add actual data
    filteredData.forEach(item => {
      const itemDate = new Date(item.date);
      const formattedDate = format(itemDate, formatString);
      
      if (dateMap.has(formattedDate)) {
        const existing = dateMap.get(formattedDate);
        dateMap.set(formattedDate, {
          ...existing,
          count: existing.count + item.count,
          duration: (existing.duration || 0) + (item.duration || 0),
          calories: (existing.calories || 0) + (item.calories || 0),
        });
      } else {
        // Should not happen with our initialization, but just in case
        const display = format(itemDate, displayFormat);
        dateMap.set(formattedDate, {
          date: formattedDate,
          display,
          count: item.count,
          duration: item.duration || 0,
          calories: item.calories || 0,
        });
      }
    });
    
    // Convert map back to array and sort by date
    return Array.from(dateMap.values()).sort((a, b) => a.date.localeCompare(b.date));
  }, [generateEmptyData]);
  
  // Custom tooltip that matches iOS design
  const CustomTooltip = ({ active, payload }: unknown) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload;
      
      return (
        <div className="rounded-md bg-deep-ops p-2 text-cream shadow-medium">
          <p className="font-semibold">{data.display}</p>
          <p>{`${type.charAt(0).toUpperCase() + type.slice(1)}: ${data.count}`}</p>
          {data.duration && <p>{`Duration: ${Math.floor(data.duration / 60)}:${(data.duration % 60).toString().padStart(2, '0')}`}</p>}
          {data.calories && <p>{`Calories: ${data.calories}`}</p>}
        </div>
      );
    }
    
    return null;
  };
  
  return (
    <Card className={`overflow-hidden ${className}`}>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle>{title}</CardTitle>
        <div className="flex space-x-2">
          <button
            onClick={() => setActiveTimeframe('week')}
            className={`rounded-button px-2 py-1 font-semibold text-xs ${
              activeTimeframe === 'week' 
                ? 'bg-brass-gold text-cream' 
                : 'bg-cream-dark text-tactical-gray'
            }`}
          >
            Week
          </button>
          <button
            onClick={() => setActiveTimeframe('month')}
            className={`rounded-button px-2 py-1 font-semibold text-xs ${
              activeTimeframe === 'month' 
                ? 'bg-brass-gold text-cream' 
                : 'bg-cream-dark text-tactical-gray'
            }`}
          >
            Month
          </button>
          <button
            onClick={() => setActiveTimeframe('year')}
            className={`rounded-button px-2 py-1 font-semibold text-xs ${
              activeTimeframe === 'year' 
                ? 'bg-brass-gold text-cream' 
                : 'bg-cream-dark text-tactical-gray'
            }`}
          >
            Year
          </button>
        </div>
      </CardHeader>
      <CardContent>
        <div className="h-[300px] w-full">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart
              data={chartData}
              margin={{ top: 10, right: 10, left: 0, bottom: 20 }}
            >
              <defs>
                <linearGradient id={`color${type}`} x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor={colors.primary} stopOpacity={0.8} />
                  <stop offset="95%" stopColor={colors.primary} stopOpacity={0.1} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#E0D4A6" strokeOpacity={0.3} />
              <XAxis 
                dataKey="display" 
                tick={{ fill: '#4E5A48', fontSize: 12 }}
                tickMargin={10}
              />
              <YAxis 
                hide={false}
                tick={{ fill: '#4E5A48', fontSize: 12 }}
                tickMargin={10}
              />
              <Tooltip content={<CustomTooltip />} />
              <Area
                type="monotone"
                dataKey="count"
                stroke={colors.primary}
                fillOpacity={1}
                fill={`url(#color${type})`}
                strokeWidth={2}
                activeDot={{ r: 6, stroke: colors.primary, strokeWidth: 1, fill: '#fff' }}
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
} 