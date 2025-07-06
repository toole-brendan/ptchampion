import React, { useMemo, useState, useEffect } from 'react';
import { format } from "date-fns";
import { Calendar as CalendarIcon, Clock, Repeat, TrendingUp, Dumbbell, Award, ChevronLeft, ChevronRight, Loader2, History as HistoryIcon, Flame, AreaChart } from "lucide-react";
import { useQuery } from '@tanstack/react-query';
import { keepPreviousData } from '@tanstack/react-query';
import { DayPickerRangeProps } from "react-day-picker";
import { useNavigate } from 'react-router-dom';
import { DateRange as RDDateRange } from "react-day-picker";

import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Card, CardDivider, SectionCard } from "@/components/ui/card";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import { getUserExercises } from '../lib/apiClient';
import { ExerciseResponse } from '../lib/types';
import { useAuth } from '../lib/authContext';
import { formatTime, formatDistance } from '../lib/utils';
import { logger } from '@/lib/logger';

// Import the exercise PNG images 
import pushupImage from '../assets/pushup.png';
import pullupImage from '../assets/pullup.png';
import situpImage from '../assets/situp.png';
import runningImage from '../assets/running.png';

// Create exercise filter buttons similar to iOS ExerciseFilterBarView
interface FilterButtonProps {
  label: string;
  icon?: React.ComponentType<{ className?: string }>;
  active: boolean;
  onClick: () => void;
}

const FilterButton: React.FC<FilterButtonProps> = ({ label, icon: Icon, active, onClick }) => (
  <Button 
    variant={active ? "default" : "outline"} 
    className={cn(
      "rounded-full transition-all",
      active 
        ? "bg-brass-gold text-white" 
        : "bg-cream text-command-black border-olive-mist/30"
    )}
    onClick={onClick}
  >
    {Icon && <Icon className="mr-1 size-4" />}
    {label}
  </Button>
);

// Helper to determine metric and unit for an exercise
const getExerciseMetric = (exercise: string): { metric: 'reps' | 'distance' | null, unit: string } => {
  switch (exercise.toLowerCase()) {
    case 'push-ups':
    case 'pushup':
      return { metric: 'reps', unit: 'Reps' };
    case 'sit-ups':
    case 'situp':  
      return { metric: 'reps', unit: 'Reps' };
    case 'pull-ups':
    case 'pullup':
      return { metric: 'reps', unit: 'Reps' };
    case 'running':
    case 'run':
    case '2-mile run':
      return { metric: 'distance', unit: 'km' };
    // Add more cases for other exercises if needed
    default:
      return { metric: null, unit: '' };
  }
};

const DEFAULT_PAGE_SIZE = 15;

// Define the PaginatedExercisesResponse type if it's not imported
interface PaginatedExercisesResponse {
  items: ExerciseResponse[];
  total_count: number;
  page: number;
  page_size: number;
}

const History: React.FC = () => {
  const { user, isLoading: isAuthLoading } = useAuth();
  const [page, setPage] = useState(1);
  const [pageSize] = useState(DEFAULT_PAGE_SIZE);
  const [exerciseFilter, setExerciseFilter] = useState<string>('All');
  const [dateRange, setDateRange] = useState<RDDateRange | undefined>(undefined);
  const navigate = useNavigate();

  // Create a properly typed handler for Calendar's onSelect
  const handleDateRangeSelect: DayPickerRangeProps['onSelect'] = (range) => {
    setDateRange(range);
  };

  const { 
    data: paginatedData, 
    isLoading: isLoadingHistory, 
    error: historyError, 
    isFetching,
    refetch
  } = useQuery<PaginatedExercisesResponse, Error>({
    queryKey: ['exerciseHistory', user?.id, page, pageSize, exerciseFilter, dateRange],
    queryFn: () => getUserExercises(page, pageSize, {
      exerciseType: exerciseFilter === 'All' ? undefined : exerciseFilter,
      startDate: dateRange?.from,
      endDate: dateRange?.to
    }),
    enabled: !!user,
    placeholderData: keepPreviousData,
    staleTime: 1000 * 60,
  });

  const exercises: ExerciseResponse[] = useMemo(() => paginatedData?.items || [], [paginatedData]);
  const totalCount = useMemo(() => paginatedData?.total_count || 0, [paginatedData]);
  const totalPages = useMemo(() => Math.ceil(totalCount / pageSize), [totalCount, pageSize]);

  const isLoading = isAuthLoading || isLoadingHistory;
  const error = historyError;

  useEffect(() => {
    setPage(1);
  }, [exerciseFilter, dateRange]);

  // No need for client-side date filtering anymore - it's done server-side
  const dateFilteredHistory = exercises;

  // Calculate streak stats like in iOS WorkoutHistoryViewModel
  const streakStats = useMemo(() => {
    // Sort workouts by date
    const sortedWorkouts = [...dateFilteredHistory].sort(
      (a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
    );
    
    if (sortedWorkouts.length === 0) {
      return { currentStreak: 0, longestStreak: 0 };
    }
    
    // Calculate streaks
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const streakDates = new Set<string>();
    
    // Add all workout dates to a set
    sortedWorkouts.forEach(workout => {
      const date = new Date(workout.created_at);
      date.setHours(0, 0, 0, 0);
      streakDates.add(date.toISOString().split('T')[0]);
    });
    
    // Check if there's a workout today or yesterday to start the current streak
    const todayFormatted = today.toISOString().split('T')[0];
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayFormatted = yesterday.toISOString().split('T')[0];
    
    let currentStreak = 0;
    let hasWorkoutTodayOrYesterday = streakDates.has(todayFormatted) || streakDates.has(yesterdayFormatted);
    
    if (hasWorkoutTodayOrYesterday) {
      // Start counting the current streak
      let checkDate = streakDates.has(todayFormatted) ? today : yesterday;
      
      while (true) {
        const checkDateFormatted = checkDate.toISOString().split('T')[0];
        
        if (streakDates.has(checkDateFormatted)) {
          currentStreak++;
          checkDate.setDate(checkDate.getDate() - 1);
        } else {
          break;
        }
      }
    }
    
    // Calculate longest streak
    let longestStreak = 0;
    let tempStreak = 0;
    
    // Convert dates to timestamps and sort
    const sortedDates = Array.from(streakDates)
      .map(date => new Date(date).getTime())
      .sort((a, b) => a - b);
    
    for (let i = 0; i < sortedDates.length; i++) {
      if (i === 0) {
        tempStreak = 1;
      } else {
        const prevDate = new Date(sortedDates[i - 1]);
        const currDate = new Date(sortedDates[i]);
        
        // Check if dates are consecutive
        prevDate.setDate(prevDate.getDate() + 1);
        
        if (
          prevDate.getFullYear() === currDate.getFullYear() &&
          prevDate.getMonth() === currDate.getMonth() &&
          prevDate.getDate() === currDate.getDate()
        ) {
          tempStreak++;
        } else {
          tempStreak = 1;
        }
      }
      
      longestStreak = Math.max(longestStreak, tempStreak);
    }
    
    return { currentStreak, longestStreak };
  }, [dateFilteredHistory]);

  const summaryStats = useMemo(() => {
    const totalWorkouts = dateFilteredHistory.length;
    let totalSeconds = 0;
    let totalReps = 0;
    let totalDistance = 0;

    dateFilteredHistory.forEach((session: ExerciseResponse) => {
      if (session.time_in_seconds) {
        totalSeconds += session.time_in_seconds;
      }
      
      if (session.reps) {
        totalReps += session.reps;
      }
      
      if (session.distance) {
        totalDistance += session.distance / 1000;
      }
    });

    return {
      totalWorkouts,
      totalTime: formatTime(totalSeconds),
      totalReps,
      totalDistance: totalDistance.toFixed(1),
    };
  }, [dateFilteredHistory]);

  const exerciseTypes = useMemo(() => {
    const types = new Set(dateFilteredHistory.map((session: ExerciseResponse) => session.exercise_type));
    return ['All', ...Array.from(types).sort()];
  }, [dateFilteredHistory]);

  useEffect(() => {
    if (!exerciseTypes.includes(exerciseFilter)) {
      setExerciseFilter('All');
    }
  }, [exerciseTypes, exerciseFilter]);

  // No need for client-side exercise filtering anymore - it's done server-side
  const filteredHistory = dateFilteredHistory;

  const { chartData, metricName, yAxisLabel } = useMemo(() => {
    if (exerciseFilter === 'All') {
      return { chartData: [], metricName: '', yAxisLabel: '' };
    }
    const { metric, unit } = getExerciseMetric(exerciseFilter);
    if (!metric) {
      return { chartData: [], metricName: '', yAxisLabel: '' };
    }
    const data = dateFilteredHistory
      .filter((session: ExerciseResponse) => session.exercise_type === exerciseFilter)
      .map(session => {
        let value;
        if (metric === 'reps') {
          value = session.reps;
        } else if (metric === 'distance' && session.distance) {
          value = session.distance / 1000;
        }
        return { date: session.created_at.split('T')[0], value };
      })
      .filter(item => item.value !== null && item.value !== undefined)
      .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
    const name = `${exerciseFilter} ${unit}`;
    const yLabel = unit === 'km' ? `Distance (${unit})` : unit;
    return { chartData: data, metricName: name, yAxisLabel: yLabel };
  }, [dateFilteredHistory, exerciseFilter]);

  const personalBests = useMemo(() => {
    const bests: { [key: string]: { exercise: string, metric: string, value: number | string, date: string } } = {};
    dateFilteredHistory.forEach((session: ExerciseResponse) => {
      const { metric, unit } = getExerciseMetric(session.exercise_type);
      if (!metric) return;
      
      let currentValue: number | undefined;
      let formattedValue: string | number;
      
      if (metric === 'reps') {
        currentValue = session.reps;
        formattedValue = currentValue || 0;
      } else if (metric === 'distance' && session.distance) {
        currentValue = session.distance / 1000;
        formattedValue = `${currentValue.toFixed(2)} ${unit}`;
      } else {
        return;
      }
      
      if (currentValue === undefined) return;
      
      if (!bests[session.exercise_type] ||
          (typeof currentValue === 'number' && 
           typeof bests[session.exercise_type].value === 'number' && 
           currentValue > (bests[session.exercise_type].value as number)) ||
          (typeof currentValue === 'number' && 
           typeof bests[session.exercise_type].value === 'string' && 
           currentValue > parseFloat(bests[session.exercise_type].value as string))
         ) {
        bests[session.exercise_type] = {
          exercise: session.exercise_type,
          metric: metric === 'reps' ? 'Max Reps' : 'Max Distance',
          value: formattedValue,
          date: session.created_at.split('T')[0],
        };
      }
    });
    return Object.values(bests).sort((a,b) => a.exercise.localeCompare(b.exercise));
  }, [dateFilteredHistory]);

  if (isLoading && !paginatedData) {
    return (
      <div className="flex min-h-[calc(100vh-200px)] items-center justify-center">
        <div className="text-center">
          <Loader2 className="mx-auto mb-4 size-10 animate-spin text-brass-gold"/>
          <p className="font-heading text-lg uppercase">Loading history...</p>
        </div>
      </div>
    );
  }

  if (error && !isFetching) {
    return (
      <div className="flex min-h-[calc(100vh-200px)] items-center justify-center">
        <div className="bg-card-background relative w-full max-w-md overflow-hidden rounded-card shadow-medium">
          <div className="p-content">
            <div className="mb-4 text-center">
              <h2 className="font-heading text-heading3 uppercase tracking-wider text-error">
                Error Loading History
              </h2>
              <div className="mx-auto h-px w-16 bg-brass-gold my-2"></div>
            </div>
            <div className="space-y-4 text-center">
              <p className="text-sm text-tactical-gray">{error instanceof Error ? error.message : String(error)}</p>
              <Button 
                onClick={() => refetch()} 
                variant="outline"
                className="border-brass-gold text-brass-gold hover:bg-brass-gold/10"
              >
                TRY AGAIN
              </Button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!isLoading && totalCount === 0) {
    return (
      <div className="bg-cream min-h-screen px-4 py-6 md:py-8 lg:px-8">
        <div className="flex flex-col space-y-6 max-w-7xl mx-auto">
          <div className="text-left mb-4 animate-fade-in">
            <h1 className="font-heading text-3xl md:text-4xl tracking-wide uppercase text-deep-ops">
              Workout History
            </h1>
            <div className="w-32 h-0.5 bg-brass-gold my-4"></div>
            <p className="text-sm uppercase tracking-wide text-tactical-gray">
              Track your exercise progress
            </p>
          </div>
          
          <Card className="overflow-hidden shadow-card text-center">
            <div className="p-content">
              <div className="py-16 flex flex-col items-center">
                <div className="mb-4 rounded-full bg-brass-gold bg-opacity-10 p-4">
                  <HistoryIcon className="size-8 text-brass-gold" />
                </div>
                <h3 className="mb-2 font-heading text-heading4">No Workouts Yet</h3>
                <p className="text-tactical-gray max-w-md mx-auto">
                  You haven't logged any exercises yet. Start tracking your workouts to see your progress here!
                </p>
                <Button
                  className="mt-6 bg-brass-gold text-deep-ops"
                  onClick={() => window.location.href = '/exercises'}
                >
                  Start First Workout
                </Button>
              </div>
            </div>
          </Card>
        </div>
      </div>
    );
  }
  
  return (
    <div className={cn(
      "bg-cream min-h-screen px-4 py-6 md:py-8 lg:px-8", 
      isFetching && "opacity-75 transition-opacity duration-300"
    )}>
      <div className="flex flex-col space-y-6 max-w-7xl mx-auto">
        {/* Title Header - Similar to iOS WorkoutHistoryView */}
        <div className="text-left mb-4 animate-fade-in">
          <h1 className="font-heading text-3xl md:text-4xl tracking-wide uppercase text-deep-ops">
            Workout History
          </h1>
          <div className="w-32 h-0.5 bg-brass-gold my-4"></div>
          <p className="text-sm uppercase tracking-wide text-tactical-gray">
            Track your exercise progress
          </p>
        </div>

        {/* Filter Section with SectionCard */}
        <SectionCard
          title="Filter Workouts"
          description="Choose an exercise type or date range"
          className="animate-fade-in"
        >
          {/* Exercise Filter Bar */}
          <div className="overflow-x-auto pb-4 -mx-1 px-1">
            <div className="flex items-center space-x-2 mb-4">
              {exerciseTypes.map(type => (
                <FilterButton
                  key={type}
                  label={
                    type === 'All' ? 'All Exercises' :
                    type === 'pushup' ? 'PUSH-UPS' :
                    type === 'pullup' ? 'PULL-UPS' :
                    type === 'situp' ? 'SIT-UPS' :
                    type === 'run' ? 'TWO-MILE RUN' :
                    type.toUpperCase()
                  }
                  icon={type === 'All' ? Dumbbell : undefined}
                  active={exerciseFilter === type}
                  onClick={() => setExerciseFilter(type)}
                />
              ))}
            </div>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-4">
            {/* Date Range Field */}
            <div className="space-y-2">
              <label className="font-semibold text-sm uppercase tracking-wide text-tactical-gray">Date Range</label>
              <Popover>
                <PopoverTrigger asChild>
                  <Button
                    id="date"
                    variant={"outline"}
                    className={cn(
                      "w-full justify-start text-left font-normal bg-cream border-army-tan/30",
                      !dateRange && "text-tactical-gray"
                    )}
                  >
                    <CalendarIcon className="mr-2 size-4" />
                    {dateRange?.from ? (
                      dateRange.to ? (
                        <>
                          {format(dateRange.from, "LLL dd, y")}
                          {" - "}
                          {format(dateRange.to, "LLL dd, y")}
                        </>
                      ) : (
                        format(dateRange.from, "LLL dd, y")
                      )
                    ) : (
                      <span>Pick a date range</span>
                    )}
                  </Button>
                </PopoverTrigger>
                <PopoverContent className="w-auto p-0" align="start">
                  <Calendar
                    initialFocus
                    mode="range"
                    defaultMonth={dateRange?.from}
                    selected={dateRange}
                    onSelect={(range) => {
                      // @ts-ignore - Type compatibility issue between the DateRange types
                      setDateRange(range);
                    }}
                    numberOfMonths={2}
                  />
                </PopoverContent>
              </Popover>
            </div>
            
            <div className="space-y-2">
              <label className="font-semibold text-sm uppercase tracking-wide text-tactical-gray">Exercise Type</label>
              <Select value={exerciseFilter} onValueChange={setExerciseFilter}>
                <SelectTrigger className="w-full border-army-tan/30 bg-cream">
                  <SelectValue placeholder="Filter by exercise..." />
                </SelectTrigger>
                <SelectContent>
                  {exerciseTypes.map(type => (
                    <SelectItem key={type} value={type}>
                      {type === 'All' ? 'All Exercises' : type}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          
          {(dateRange || exerciseFilter !== 'All') && (
            <Button 
              variant="outline" 
              onClick={() => { setDateRange(undefined); setExerciseFilter('All'); }} 
              className="w-full border-brass-gold text-brass-gold hover:bg-brass-gold/10"
            >
              CLEAR ALL FILTERS
            </Button>
          )}
        </SectionCard>
        
        {/* Streak cards in a row */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 animate-fade-in">
          {/* Current Streak Card */}
          <Card className="bg-white p-4 shadow-card">
            <div className="flex flex-col items-center">
              <p className="text-xs uppercase tracking-wider text-tactical-gray mb-2">
                CURRENT STREAK
              </p>
              <div className="flex size-16 items-center justify-center rounded-full bg-brass-gold bg-opacity-10 mb-2">
                <Flame className="size-8 text-brass-gold" />
              </div>
              <p className="font-heading text-2xl text-deep-ops">
                {streakStats.currentStreak}
              </p>
              <p className="text-xs text-tactical-gray">days</p>
            </div>
          </Card>
          
          {/* Longest Streak Card */}
          <Card className="bg-white p-4 shadow-card">
            <div className="flex flex-col items-center">
              <p className="text-xs uppercase tracking-wider text-tactical-gray mb-2">
                LONGEST STREAK
              </p>
              <div className="flex size-16 items-center justify-center rounded-full bg-brass-gold bg-opacity-10 mb-2">
                <AreaChart className="size-8 text-brass-gold" />
              </div>
              <p className="font-heading text-2xl text-deep-ops">
                {streakStats.longestStreak}
              </p>
              <p className="text-xs text-tactical-gray">days</p>
            </div>
          </Card>
        </div>

        {/* Progress Chart with SectionCard */}
        {exerciseFilter !== 'All' && (
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
        )}

        {/* Summary Stats matching the dashboard screenshot */}
        <div className="bg-cream-dark p-6 rounded-card animate-fade-in">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
            {[
              { title: 'TOTAL WORKOUTS', value: summaryStats.totalWorkouts, icon: Dumbbell },
              { title: 'TOTAL TIME', value: summaryStats.totalTime, icon: Clock },
              { title: 'TOTAL REPS', value: summaryStats.totalReps, icon: Repeat },
              { title: 'TOTAL DISTANCE', value: summaryStats.totalDistance + ' km', icon: TrendingUp },
            ].map((stat, index) => (
              <div key={index} className="flex items-center justify-between">
                <div className="flex flex-col space-y-1">
                  <div className="text-xs text-olive-mist uppercase tracking-wider">{stat.title}</div>
                  <div className="font-heading text-2xl text-deep-ops">{stat.value}</div>
                </div>
                <stat.icon className="size-8 text-brass-gold" />
              </div>
            ))}
          </div>
        </div>

        {/* Personal Records Section with SectionCard */}
        {personalBests.length > 0 && (
          <SectionCard
            title="Personal Records"
            description="Your top performance records"
            icon={<Award className="size-5" />}
            contentClassName="bg-white"
          >
            <ul className="space-y-3">
              {personalBests.map((pb, index) => (
                <li key={index} className="relative overflow-hidden rounded-card border-l-4 border-brass-gold bg-white p-3 shadow-small">
                  <div className="absolute -left-1 top-1/2 h-8 w-1 -translate-y-1/2 rounded bg-brass-gold/40"></div>
                  <div className="flex items-center justify-between">
                    <div className="flex flex-col">
                      <span className="font-heading text-sm uppercase text-command-black">{pb.exercise}</span>
                      <span className="font-semibold text-xs text-tactical-gray">{pb.metric}</span>
                    </div>
                    <div className="text-right">
                      <p className="font-heading text-xl text-brass-gold">{pb.value}</p>
                      <p className="text-xs text-tactical-gray">on {pb.date}</p>
                    </div>
                  </div>
                </li>
              ))}
            </ul>
          </SectionCard>
        )}

        {/* Training Record Section with SectionCard */}
        <SectionCard
          title="Training Record"
          description="Detailed log of workouts matching your filters"
          icon={<HistoryIcon className="size-5" />}
          contentClassName="bg-white"
        >
          {filteredHistory.length > 0 ? (
            <div className="space-y-2">
              {filteredHistory.map((session) => (
                <div 
                  key={session.id} 
                  className="flex items-center justify-between p-4 bg-white hover:bg-brass-gold hover:bg-opacity-5 cursor-pointer rounded-md"
                  onClick={() => navigate ? navigate(`/history/${session.id}`) : window.location.href = `/history/${session.id}`}
                >
                  <div className="flex items-center">
                    <div className="mr-4 flex size-10 items-center justify-center rounded-full border border-brass-gold border-opacity-30 bg-brass-gold bg-opacity-10">
                      {session.exercise_type === 'pushup' ? 
                        <img src={pushupImage} alt="Push-ups" className="size-6" /> :
                      session.exercise_type === 'pullup' ? 
                        <img src={pullupImage} alt="Pull-ups" className="size-6" /> :
                      session.exercise_type === 'situp' ? 
                        <img src={situpImage} alt="Sit-ups" className="size-6" /> :
                      session.exercise_type === 'run' ? 
                        <img src={runningImage} alt="Two-Mile Run" className="size-6" /> :
                        <Dumbbell className="size-5 text-brass-gold" />
                      }
                    </div>
                    <div>
                      <h3 className="font-sans text-base font-medium uppercase text-command-black">
                        {session.exercise_type === 'pushup' ? 'PUSH-UPS' :
                         session.exercise_type === 'pullup' ? 'PULL-UPS' :
                         session.exercise_type === 'situp' ? 'SIT-UPS' :
                         session.exercise_type === 'run' ? 'TWO-MILE RUN' :
                         session.exercise_type.toUpperCase()}
                      </h3>
                      <p className="text-xs text-tactical-gray">
                        {(() => {
                          const date = new Date(session.created_at);
                          const day = date.getDate();
                          const month = date.toLocaleDateString('en-US', { month: 'short' }).toUpperCase();
                          const year = date.getFullYear();
                          const hours = date.getHours();
                          const minutes = date.getMinutes();
                          const militaryTime = `${hours.toString().padStart(2, '0')}${minutes.toString().padStart(2, '0')}`;
                          return `${day}${month}${year} · ${militaryTime}`;
                        })()}
                        {session.exercise_type === 'run' && session.time_in_seconds ? ` · ${formatTime(session.time_in_seconds)}` : ''}
                      </p>
                    </div>
                  </div>
                  <div className="font-heading text-xl text-brass-gold">
                    {session.exercise_type === 'run' && session.time_in_seconds
                      ? `${Math.floor(session.time_in_seconds / 60)}:${(session.time_in_seconds % 60).toString().padStart(2, '0')}`
                      : session.reps !== undefined && session.reps !== null
                        ? `${session.reps} reps`
                        : '-'}
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="rounded-card overflow-hidden bg-white p-8 text-center">
              <p className="font-semibold text-sm text-tactical-gray">
                {exercises.length > 0 
                  ? "No sessions found matching your current filters."
                  : "Loading sessions..."}
              </p>
            </div>
          )}
          
          {filteredHistory.length > 0 && (
            <div className="mt-4 flex items-center justify-between">
              <div className="text-sm text-tactical-gray">
                Page {page} of {totalPages} ({totalCount} total records)
              </div>
              <div className="space-x-2">
                <Button
                  variant="outline"
                  size="small"
                  onClick={() => setPage(prev => Math.max(prev - 1, 1))}
                  disabled={page <= 1 || isFetching}
                  className="border-brass-gold text-brass-gold hover:bg-brass-gold/10"
                >
                  <ChevronLeft className="mr-1 size-4" /> PREV
                </Button>
                <Button
                  variant="outline"
                  size="small"
                  onClick={() => setPage(prev => Math.min(prev + 1, totalPages))}
                  disabled={page >= totalPages || isFetching}
                  className="border-brass-gold text-brass-gold hover:bg-brass-gold/10"
                >
                  NEXT <ChevronRight className="ml-1 size-4" />
                </Button>
              </div>
            </div>
          )}
        </SectionCard>
      </div>
    </div>
  );
};

export default History; 