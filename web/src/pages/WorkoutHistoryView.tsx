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
  Loader2 
} from 'lucide-react';

import { cn, formatTime } from '@/lib/utils';
import { useAuth } from '@/lib/authContext';
import useInfiniteHistory from '@/lib/hooks/useInfiniteHistory';
import { Button } from '@/components/ui/button';
import WorkoutCard from '@/components/workout-history/WorkoutCard';
import HistoryFilterBar, { DateRange } from '@/components/workout-history/HistoryFilterBar';
import StreakBanner from '@/components/workout-history/StreakBanner';
import InfiniteScrollSentinel from '@/components/workout-history/InfiniteScrollSentinel';

// Header divider component
const HeaderDivider: React.FC = () => (
  <div className="mx-auto my-2 h-px w-16 bg-brass-gold"></div>
);

const WorkoutHistoryView: React.FC = () => {
  const { user, isLoading: isAuthLoading } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const mainRef = useRef<HTMLDivElement>(null);
  
  // State for filters
  const [exerciseFilter, setExerciseFilter] = useState<string>('All');
  const [dateRange, setDateRange] = useState<DateRange | undefined>(undefined);
  
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
    dateRange
  });

  // Extract exercise types from history items
  const exerciseTypes = useMemo(() => {
    const types = new Set(historyItems.map(item => item.exercise_type));
    return ['All', ...Array.from(types).sort()];
  }, [historyItems]);

  // Restore scroll position when returning from detail view
  useEffect(() => {
    // Check for the state containing the scrollY position
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

  const handleClearFilters = () => {
    setDateRange(undefined);
    setExerciseFilter('All');
  };

  // Status states
  const isLoading = isAuthLoading || status === 'pending';
  const isError = status === 'error';
  const isEmpty = status === 'success' && historyItems.length === 0;
  const filtersActive = exerciseFilter !== 'All' || !!dateRange;

  if (isLoading && !historyItems.length) {
    return (
      <div className="flex min-h-[calc(100vh-200px)] items-center justify-center">
        <div className="text-center">
          <Loader2 className="mx-auto mb-4 size-10 animate-spin text-brass-gold"/>
          <p className="font-heading text-lg uppercase">Loading history...</p>
        </div>
      </div>
    );
  }

  if (isError) {
    return (
      <div className="flex min-h-[calc(100vh-200px)] items-center justify-center">
        <div className="bg-card-background relative w-full max-w-md overflow-hidden rounded-card shadow-medium">
          <div className="p-content">
            <div className="mb-4 text-center">
              <h2 className="font-heading text-heading3 uppercase tracking-wider text-error">
                Error Loading History
              </h2>
              <HeaderDivider />
            </div>
            <div className="space-y-4 text-center">
              <p className="text-sm text-tactical-gray">{error instanceof Error ? error.message : 'An unknown error occurred'}</p>
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

  if (isEmpty) {
    return (
      <div className="space-y-section">
        <div className="bg-card-background relative overflow-hidden rounded-card p-content shadow-medium">
          <div className="mb-4 text-center">
            <h2 className="font-heading text-heading3 uppercase tracking-wider text-command-black">
              Training History
            </h2>
            <HeaderDivider />
            <p className="mt-2 text-sm uppercase tracking-wide text-tactical-gray">Track your progress over time</p>
          </div>
        </div>
        
        <div className="bg-card-background relative overflow-hidden rounded-card text-center shadow-medium">
          <div className="p-content">
            <h3 className="mb-4 font-heading text-heading4 uppercase tracking-wider">No Workouts Found</h3>
            <p className="text-tactical-gray">You haven't logged any exercises yet.</p>
            <p className="mt-2 text-tactical-gray">Start tracking your workouts to see your progress here!</p>
          </div>
        </div>
      </div>
    );
  }
  
  return (
    <div 
      ref={mainRef}
      className={cn("space-y-section", isFetchingNextPage && "opacity-75 transition-opacity duration-300")}
    >
      <div className="bg-card-background relative overflow-hidden rounded-card p-content shadow-medium">
        <div className="mb-4 text-center">
          <h2 className="font-heading text-heading3 uppercase tracking-wider text-command-black">
            Training History
          </h2>
          <HeaderDivider />
          <p className="mt-2 text-sm uppercase tracking-wide text-tactical-gray">Track your progress over time</p>
        </div>
      </div>
      
      {/* Streak banner */}
      <StreakBanner streakCount={streakCount} filtersActive={filtersActive} />

      {/* Filters */}
      <div className="bg-card-background relative overflow-hidden rounded-card shadow-medium">
        <div className="rounded-t-card bg-deep-ops p-content">
          <div className="flex items-center">
            <HistoryIcon className="mr-2 size-5 text-brass-gold" />
            <h2 className="font-heading text-heading4 uppercase tracking-wider text-cream">
              Filter Workouts
            </h2>
          </div>
        </div>
        <div className="p-content">
          <HistoryFilterBar
            exerciseFilter={exerciseFilter}
            dateRange={dateRange}
            exerciseTypes={exerciseTypes}
            onExerciseFilterChange={setExerciseFilter}
            onDateRangeChange={setDateRange}
            onClearFilters={handleClearFilters}
          />
        </div>
      </div>

      {/* Summary stats */}
      <div className="grid gap-card-gap md:grid-cols-2 lg:grid-cols-4">
        {[
          { title: 'TOTAL WORKOUTS', value: summaryStats.totalWorkouts, icon: Dumbbell, unit: '' },
          { title: 'TOTAL TIME', value: formatTime(summaryStats.totalSeconds), icon: Clock, unit: '' },
          { title: 'TOTAL REPS', value: summaryStats.totalReps, icon: Repeat, unit: '' },
          { title: 'TOTAL DISTANCE', value: summaryStats.totalDistance, icon: TrendingUp, unit: 'km' },
        ].map((stat, index) => (
          <div key={index} className="bg-card-background relative overflow-hidden rounded-card shadow-medium">
            <div className="p-content">
              <div className="flex flex-row items-center justify-between space-y-0 pb-2">
                <div className="font-semibold text-xs uppercase tracking-wider text-tactical-gray">{stat.title}</div>
                <stat.icon className="size-5 text-brass-gold" />
              </div>
              <div className="font-heading text-heading3 text-command-black">
                {stat.value} {stat.unit && <span className="font-semibold text-sm text-tactical-gray">{stat.unit}</span>}
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Personal records */}
      <div className="bg-card-background relative overflow-hidden rounded-card shadow-medium">
        <div className="rounded-t-card bg-deep-ops p-content">
          <div className="flex items-center">
            <Award className="mr-2 size-5 text-brass-gold" />
            <h2 className="font-heading text-heading4 uppercase tracking-wider text-cream">
              Personal Records
            </h2>
          </div>
          <p className="text-sm text-army-tan">
            Your top performance records based on current filters.
          </p>
        </div>
        <div className="p-content">
          {personalBests.length > 0 ? (
            <ul className="space-y-3">
              {personalBests.map((pb, index) => {
                const isRunning = pb.exercise_type.toLowerCase().includes('run');
                const metric = isRunning ? 'Distance' : 'Max Reps';
                const value = isRunning && pb.distance 
                  ? `${(pb.distance / 1000).toFixed(2)} km` 
                  : `${pb.reps} reps`;
                const date = format(new Date(pb.created_at), 'MMM dd, yyyy');
                
                return (
                  <li key={index} className="relative overflow-hidden rounded-card border-l-4 border-brass-gold bg-cream/30 p-3 shadow-small">
                    <div className="absolute -left-1 top-1/2 h-8 w-1 -translate-y-1/2 rounded bg-brass-gold/40"></div>
                    <div className="flex items-center justify-between">
                      <div className="flex flex-col">
                        <span className="font-heading text-sm uppercase text-command-black">{pb.exercise_type}</span>
                        <span className="font-semibold text-xs text-tactical-gray">{metric}</span>
                      </div>
                      <div className="text-right">
                        <p className="font-heading text-xl text-brass-gold">{value}</p>
                        <p className="text-xs text-tactical-gray">on {date}</p>
                      </div>
                    </div>
                  </li>
                );
              })}
            </ul>
          ) : (
            <p className="py-4 text-center font-semibold text-sm text-tactical-gray">
              No personal bests found for the selected filters.
            </p>
          )}
        </div>
      </div>

      {/* Workout history cards */}
      <div className="bg-card-background relative overflow-hidden rounded-card shadow-medium">
        <div className="rounded-t-card bg-deep-ops p-content">
          <div className="flex items-center">
            <HistoryIcon className="mr-2 size-5 text-brass-gold" />
            <h2 className="font-heading text-heading4 uppercase tracking-wider text-cream">
              Workout History
            </h2>
          </div>
          <p className="text-sm text-army-tan">
            {filtersActive 
              ? 'Filtered workout history matching your criteria.' 
              : 'Complete history of your workouts.'}
          </p>
        </div>
        <div className="p-content">
          {historyItems.length > 0 ? (
            <div className="space-y-4">
              {historyItems.map((workout) => (
                <div key={workout.id}>
                  <WorkoutCard 
                    workout={workout} 
                    onClick={(e) => {
                      e.preventDefault();
                      handleCardClick(workout.id);
                    }}
                  />
                </div>
              ))}
              
              {/* Infinite scroll sentinel */}
              <InfiniteScrollSentinel
                onLoadMore={() => fetchNextPage()}
                isFetchingNextPage={isFetchingNextPage}
                hasNextPage={hasNextPage}
              />
            </div>
          ) : (
            <div className="py-8 text-center font-semibold text-sm text-tactical-gray">
              No workouts match your current filters.
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default WorkoutHistoryView; 