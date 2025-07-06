import React, { useMemo, useState, useEffect } from 'react';
import { Clock, Repeat, TrendingUp, Dumbbell, Award, Loader2, Flame, AreaChart } from "lucide-react";
import { useQuery } from '@tanstack/react-query';
import { keepPreviousData } from '@tanstack/react-query';
import { DateRange as RDDateRange } from "react-day-picker";

import { cn } from "@/lib/utils";
import { Card } from "@/components/ui/card";
import { getUserExercises } from '../lib/apiClient';
import { ExerciseResponse } from '../lib/types';
import { useAuth } from '../lib/authContext';
import { formatTime, formatDistance } from '../lib/utils';
import { logger } from '@/lib/logger';

// Import the new split components
import { HistoryFilter } from '@/components/history/HistoryFilter';
import { HistoryChart } from '@/components/history/HistoryChart';
import { HistoryTable } from '@/components/history/HistoryTable';
import { SectionCard } from "@/components/ui/card";

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
      
      if (metric === 'reps' && session.reps) {
        currentValue = session.reps;
        formattedValue = `${session.reps} ${unit}`;
      } else if (metric === 'distance' && session.distance) {
        currentValue = session.distance;
        formattedValue = formatDistance(session.distance / 1000);
      }
      
      if (currentValue !== undefined && (!bests[session.exercise_type] || 
        (metric === 'reps' && currentValue > (bests[session.exercise_type].value as number)) || 
        (metric === 'distance' && currentValue < (bests[session.exercise_type].value as number)))) {
        bests[session.exercise_type] = {
          exercise: session.exercise_type.toUpperCase(),
          metric: unit,
          value: currentValue,
          date: new Date(session.created_at).toLocaleDateString(),
        };
      }
    });
    
    return Object.values(bests).map((pb, index) => ({
      ...pb,
      value: typeof pb.value === 'number' && pb.metric === 'km' 
        ? formatDistance(pb.value / 1000)
        : pb.value,
    }));
  }, [dateFilteredHistory]);
  
  if (isLoading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <Loader2 className="size-8 animate-spin text-brass-gold" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center h-full">
        <Card className="bg-white p-6 shadow-large max-w-md text-center">
          <h2 className="font-heading text-heading3 uppercase text-command-black mb-4">
            Error Loading History
          </h2>
          <p className="text-tactical-gray mb-4">
            {error.message || 'An unexpected error occurred.'}
          </p>
          <button 
            onClick={() => refetch()}
            className="bg-brass-gold text-white rounded-md px-4 py-2"
          >
            TRY AGAIN
          </button>
        </Card>
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

        {/* Filter Section */}
        <HistoryFilter
          exerciseTypes={exerciseTypes}
          exerciseFilter={exerciseFilter}
          setExerciseFilter={setExerciseFilter}
          dateRange={dateRange}
          setDateRange={setDateRange}
        />
        
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

        {/* Progress Chart */}
        <HistoryChart
          exerciseFilter={exerciseFilter}
          chartData={chartData}
          metricName={metricName}
          yAxisLabel={yAxisLabel}
        />

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

        {/* Personal Records Section */}
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

        {/* Training Record Table */}
        <HistoryTable
          filteredHistory={filteredHistory}
          exercises={exercises}
          page={page}
          totalPages={totalPages}
          totalCount={totalCount}
          isFetching={isFetching}
          setPage={setPage}
        />
      </div>
    </div>
  );
};

export default History;