import React, { useState, useRef, useEffect, useMemo } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { format } from 'date-fns';
import { 
  Clock, 
  Repeat, 
  TrendingUp, 
  Dumbbell, 
  Award, 
  History as HistoryIcon, 
  Loader2,
  AlertCircle
} from 'lucide-react';

import { cn, formatTime } from '@/lib/utils';
import { useAuth } from '@/lib/authContext';
import useInfiniteHistory from '@/lib/hooks/useInfiniteHistory';
import { Button } from '@/components/ui/button';
import { Alert, AlertTitle, AlertDescription } from "@/components/ui/alert";
import InfiniteScrollSentinel from '@/components/workout-history/InfiniteScrollSentinel';

// New iOS-style components
import ExerciseFilterBar from '@/components/workout-history/ExerciseFilterBar';
import WorkoutStreakCards from '@/components/workout-history/WorkoutStreakCards';
import WorkoutChartSection from '@/components/workout-history/WorkoutChartSection';
import WorkoutHistorySection from '@/components/workout-history/WorkoutHistorySection';
import WorkoutHistoryRow from '@/components/workout-history/WorkoutHistoryRow';

const WorkoutHistoryView: React.FC = () => {
  const { isLoading: isAuthLoading } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const mainRef = useRef<HTMLDivElement>(null);
  
  // State for filters
  const [exerciseFilter, setExerciseFilter] = useState<string>('All');
  
  // Remember scroll position when navigating to detail
  const scrollY = useRef<number>(0);

  // Query data with the hook
  const {
    historyItems,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    status,
    error,
    refetch,
    summaryStats,
    streakCount,
    personalBests
  } = useInfiniteHistory({
    pageSize: 20,
    exerciseFilter,
    dateRange: undefined
  });

  // Calculate longest streak (mock for now - would come from backend)
  const longestStreak = useMemo(() => {
    return Math.max(streakCount, 5); // Mock calculation
  }, [streakCount]);

  // Generate chart data from filtered history
  const chartData = useMemo(() => {
    if (exerciseFilter === 'All' || historyItems.length === 0) return [];
    
    // Group workouts by date and calculate daily maximums/averages
    const dailyData = new Map<string, { date: Date; maxReps?: number; totalTime?: number; count: number }>();
    
    historyItems.forEach(workout => {
      const date = new Date(workout.created_at);
      const dateKey = date.toISOString().split('T')[0]; // YYYY-MM-DD
      
      if (!dailyData.has(dateKey)) {
        dailyData.set(dateKey, { date, count: 0 });
      }
      
      const dayData = dailyData.get(dateKey)!;
      dayData.count++;
      
      // For rep-based exercises, track max reps
      if (workout.reps) {
        dayData.maxReps = Math.max(dayData.maxReps || 0, workout.reps);
      }
      
      // For time-based exercises (running), track total time
      const duration = workout.duration_seconds || workout.time_in_seconds || 0;
      if (duration > 0) {
        dayData.totalTime = (dayData.totalTime || 0) + duration;
      }
    });
    
    // Convert to chart data format
    const sortedData = Array.from(dailyData.values())
      .sort((a, b) => a.date.getTime() - b.date.getTime())
      .map(dayData => {
        // Determine the value based on exercise type
        let value = 0;
        if (exerciseFilter === 'run') {
          // For running, use average time per workout that day
          value = dayData.totalTime ? Math.round(dayData.totalTime / dayData.count) : 0;
        } else {
          // For other exercises, use max reps
          value = dayData.maxReps || 0;
        }
        
        return {
          date: dayData.date,
          value
        };
      })
      .filter(point => point.value > 0); // Only include days with valid data
    
    return sortedData;
  }, [exerciseFilter, historyItems]);

  // Restore scroll position when returning from detail view
  useEffect(() => {
    if (location.state?.fromY && mainRef.current) {
      setTimeout(() => {
        window.scrollTo(0, location.state.fromY);
      }, 0);
    }
  }, [location.state]);

  // Save scroll position before navigating to detail view
  const handleCardClick = (id: number) => {
    scrollY.current = window.scrollY;
    navigate(`/history/${id}`, { state: { fromY: scrollY.current } });
  };

  // Status states
  const isLoading = isAuthLoading || status === 'pending';
  const isError = status === 'error';
  const isEmpty = status === 'success' && historyItems.length === 0;

  if (isLoading && !historyItems.length) {
    return (
      <div className="bg-cream min-h-screen">
        {/* Radial gradient background */}
        <div 
          className="fixed inset-0 pointer-events-none"
          style={{
            background: `radial-gradient(circle at center, rgba(244, 241, 230, 0.9) 0%, rgba(244, 241, 230, 1) 60%)`
          }}
        />
        
        <div className="relative z-10 px-4 py-8 max-w-7xl mx-auto">
          <div className="flex min-h-[calc(100vh-200px)] items-center justify-center">
            <div className="text-center">
              <Loader2 className="mx-auto mb-4 size-10 animate-spin text-brass-gold"/>
              <p className="font-heading text-lg uppercase">Loading history...</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="bg-cream min-h-screen">
        {/* Radial gradient background */}
        <div 
          className="fixed inset-0 pointer-events-none"
          style={{
            background: `radial-gradient(circle at center, rgba(244, 241, 230, 0.9) 0%, rgba(244, 241, 230, 1) 60%)`
          }}
        />
        
        <div className="relative z-10 px-4 py-8 max-w-7xl mx-auto space-y-8">
          {/* iOS-style header */}
          <header className="space-y-4">
            <h1 className="text-3xl md:text-4xl font-bold tracking-wider text-deep-ops uppercase">
              Workout History
            </h1>
            <div className="w-30 h-0.5 bg-brass-gold"></div>
            <p className="text-base font-normal tracking-wider text-deep-ops uppercase">
              Track your exercise progress
            </p>
          </header>
          
          <Alert variant="destructive" className="rounded-card">
            <AlertCircle className="size-5" />
            <AlertTitle className="font-heading text-sm">Error Loading History</AlertTitle>
            <AlertDescription>
              {error instanceof Error ? error.message : 'An unknown error occurred'}
              <Button 
                variant="outline" 
                size="small" 
                className="mt-2 border-brass-gold text-brass-gold" 
                onClick={() => refetch()}
              >
                TRY AGAIN
              </Button>
            </AlertDescription>
          </Alert>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-cream min-h-screen">
      {/* Radial gradient background */}
      <div 
        className="fixed inset-0 pointer-events-none"
        style={{
          background: `radial-gradient(circle at center, rgba(244, 241, 230, 0.9) 0%, rgba(244, 241, 230, 1) 60%)`
        }}
      />
      
      <div className="relative z-10 px-4 py-8 max-w-7xl mx-auto space-y-6" ref={mainRef}>
        {/* iOS-style header */}
        <header className="space-y-4">
          <h1 className="text-3xl md:text-4xl font-bold tracking-wider text-deep-ops uppercase">
            Workout History
          </h1>
          <div className="w-30 h-0.5 bg-brass-gold"></div>
          <p className="text-base font-normal tracking-wider text-deep-ops uppercase">
            Track your exercise progress
          </p>
        </header>

        {/* Filter bar and streak cards grouped together */}
        <div className="space-y-4">
          {/* Exercise filter bar */}
          <ExerciseFilterBar 
            filter={exerciseFilter}
            onFilterChange={setExerciseFilter}
          />
          
          {/* Streak cards */}
          <WorkoutStreakCards 
            currentStreak={streakCount}
            longestStreak={longestStreak}
          />
        </div>

        {/* Progress chart (conditional) */}
        <WorkoutChartSection 
          filter={exerciseFilter}
          chartData={chartData}
          yAxisLabel={exerciseFilter === 'run' ? 'Time (seconds)' : 'Repetitions'}
        />

        {/* Workout history section */}
        <WorkoutHistorySection 
          isEmpty={isEmpty}
          filter={exerciseFilter}
        >
          {historyItems.length > 0 && (
            <div className="space-y-0">
              {historyItems.map((workout, index) => (
                <WorkoutHistoryRow
                  key={workout.id}
                  id={`${workout.id}`}
                  exerciseType={workout.exercise_name || workout.exercise_type}
                  count={workout.reps}
                  distance={workout.distance}
                  duration={workout.duration_seconds || workout.time_in_seconds || 0}
                  date={new Date(workout.created_at)}
                  score={workout.grade}
                  onClick={(id: string) => handleCardClick(Number(id))}
                  showDivider={index < historyItems.length - 1}
                />
              ))}
              
              {/* Infinite scroll sentinel */}
              <div className="px-4 py-4">
                <InfiniteScrollSentinel
                  onLoadMore={() => fetchNextPage()}
                  isFetchingNextPage={isFetchingNextPage}
                  hasNextPage={hasNextPage}
                />
              </div>
            </div>
          )}
        </WorkoutHistorySection>
      </div>
    </div>
  );
};

export default WorkoutHistoryView; 