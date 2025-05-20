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
import { WorkoutCard } from '@/components/workout-history/WorkoutCard';
import HistoryFilterBar, { DateRange } from '@/components/workout-history/HistoryFilterBar';
import StreakBanner from '@/components/workout-history/StreakBanner';
import InfiniteScrollSentinel from '@/components/workout-history/InfiniteScrollSentinel';
import { SectionCard, CardDivider } from "@/components/ui/card";
import { MetricCard } from "@/components/ui/metric-card";
import { Alert, AlertTitle, AlertDescription } from "@/components/ui/alert";
import { Player } from '@lottiefiles/react-lottie-player';
import emptyHistoryAnimation from '@/assets/empty-leaderboard.json'; // Reusing leaderboard animation for now

// Import exercise PNG images 
import pushupImage from '../assets/pushup.png';
import pullupImage from '../assets/pullup.png';
import situpImage from '../assets/situp.png';
import runningImage from '../assets/running.png';

const WorkoutHistoryView: React.FC = () => {
  const { isLoading: isAuthLoading } = useAuth();
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
      <div className="bg-cream min-h-screen px-4 py-section md:py-12 lg:px-8">
        <div className="flex flex-col space-y-section max-w-7xl mx-auto">
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
      <div className="bg-cream min-h-screen px-4 py-section md:py-12 lg:px-8">
        <div className="flex flex-col space-y-section max-w-7xl mx-auto">
          <header className="text-left mb-section animate-fade-in px-content">
            <h1 className="font-heading text-heading3 md:text-heading2 uppercase tracking-wider text-deep-ops">
              Training History
            </h1>
            <div className="my-4 h-px w-24 bg-brass-gold" />
            <p className="text-sm md:text-base font-semibold tracking-wide text-deep-ops">
              Track your progress over time
            </p>
          </header>
          
          <Alert variant="destructive" className="rounded-card">
            <AlertCircle className="size-5" />
            <AlertTitle className="font-heading text-sm">Error Loading History</AlertTitle>
            <AlertDescription>
              {error instanceof Error ? error.message : 'An unknown error occurred'}
              <Button 
                variant="outline" 
                size="sm" 
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

  if (isEmpty) {
    return (
      <div className="bg-cream min-h-screen px-4 py-section md:py-12 lg:px-8">
        <div className="flex flex-col space-y-section max-w-7xl mx-auto">
          <header className="text-left mb-section animate-fade-in px-content">
            <h1 className="font-heading text-heading3 md:text-heading2 uppercase tracking-wider text-deep-ops">
              Training History
            </h1>
            <div className="my-4 h-px w-24 bg-brass-gold" />
            <p className="text-sm md:text-base font-semibold tracking-wide text-deep-ops">
              Track your progress over time
            </p>
          </header>
          
          <SectionCard
            title="No Workouts Found"
            className="animate-fade-in animation-delay-100 text-center"
            showDivider
          >
            <div className="flex flex-col items-center justify-center py-8">
              <Player
                autoplay
                loop
                src={emptyHistoryAnimation}
                style={{ height: '200px', width: '200px' }}
                className="text-brass-gold"
              />
              <p className="mt-4 text-center font-semibold text-tactical-gray">
                You haven't logged any exercises yet.
              </p>
              <p className="text-center text-sm text-tactical-gray">
                Start tracking your workouts to see your progress here!
              </p>
              <Button
                variant="default"
                className="mt-4 bg-brass-gold text-deep-ops"
                onClick={() => navigate('/exercises')}
              >
                Start Workout
              </Button>
            </div>
          </SectionCard>
        </div>
      </div>
    );
  }
  
  return (
    <div className="bg-cream min-h-screen px-4 py-section md:py-12 lg:px-8">
      <div className="flex flex-col space-y-section max-w-7xl mx-auto" ref={mainRef}>
        {/* Page Header - full-width, no card, left aligned */}
        <header className="text-left mb-section animate-fade-in px-content">
          <h1 className="font-heading text-heading3 md:text-heading2 uppercase tracking-wider text-deep-ops">
            Training History
          </h1>
          <div className="my-4 h-px w-24 bg-brass-gold" />
          <p className="text-sm md:text-base font-semibold tracking-wide text-deep-ops">
            Track your progress over time
          </p>
        </header>
        
        {/* Streak banner */}
        <StreakBanner streakCount={streakCount} filtersActive={filtersActive} />

        {/* Filters */}
        <SectionCard
          title="Filter Workouts"
          icon={<HistoryIcon className="size-5" />}
          className="animate-fade-in animation-delay-100"
          showDivider
        >
          <HistoryFilterBar
            exerciseFilter={exerciseFilter}
            dateRange={dateRange}
            exerciseTypes={exerciseTypes}
            onExerciseFilterChange={setExerciseFilter}
            onDateRangeChange={setDateRange}
            onClearFilters={handleClearFilters}
          />
        </SectionCard>

        {/* Summary stats */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-card-gap animate-fade-in animation-delay-200">
          <MetricCard
            title="TOTAL WORKOUTS"
            value={summaryStats.totalWorkouts}
            icon={Dumbbell}
            iconClassName="text-brass-gold"
            valueClassName="font-heading text-heading2 text-command-black"
            index={0}
            className="bg-white"
          />
          <MetricCard
            title="TOTAL TIME"
            value={formatTime(summaryStats.totalSeconds)}
            icon={Clock}
            iconClassName="text-brass-gold"
            valueClassName="font-heading text-heading2 text-command-black"
            index={1}
            className="bg-white"
          />
          <MetricCard
            title="TOTAL REPS"
            value={summaryStats.totalReps}
            icon={Repeat}
            iconClassName="text-brass-gold"
            valueClassName="font-heading text-heading2 text-command-black"
            index={2}
            className="bg-white"
          />
          <MetricCard
            title="TOTAL DISTANCE"
            value={summaryStats.totalDistance}
            unit="km"
            icon={TrendingUp}
            iconClassName="text-brass-gold"
            valueClassName="font-heading text-heading2 text-command-black"
            index={3}
            className="bg-white"
          />
        </div>

        {/* Personal records */}
        <SectionCard
          title="Personal Records"
          icon={<Award className="size-5" />}
          description="Your top performance records based on current filters."
          className="animate-fade-in animation-delay-300"
          showDivider
        >
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
                  <li 
                    key={index} 
                    className="border-b border-olive-mist/10 transition-colors hover:bg-brass-gold/5 rounded-card p-3 bg-white"
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <div className="mr-4 flex size-10 items-center justify-center rounded-full border border-brass-gold border-opacity-30 bg-brass-gold bg-opacity-10">
                          {pb.exercise_type.toLowerCase().includes('push') ? 
                            <img src={pushupImage} alt="Push-ups" className="size-6" /> :
                          pb.exercise_type.toLowerCase().includes('pull') ? 
                            <img src={pullupImage} alt="Pull-ups" className="size-6" /> :
                          pb.exercise_type.toLowerCase().includes('sit') ? 
                            <img src={situpImage} alt="Sit-ups" className="size-6" /> :
                          pb.exercise_type.toLowerCase().includes('run') ? 
                            <img src={runningImage} alt="Running" className="size-6" /> :
                            <Dumbbell className="size-5 text-brass-gold" />
                          }
                        </div>
                        <div className="flex flex-col">
                          <h3 className="mb-0.5 font-heading text-sm uppercase text-command-black">
                            {pb.exercise_type.toLowerCase().includes('push') ? 'Push-ups' :
                             pb.exercise_type.toLowerCase().includes('pull') ? 'Pull-ups' :
                             pb.exercise_type.toLowerCase().includes('sit') ? 'Sit-ups' :
                             pb.exercise_type.toLowerCase().includes('run') ? 'Running' :
                             pb.exercise_type}
                          </h3>
                          <span className="font-semibold text-xs text-tactical-gray">{metric}</span>
                        </div>
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
            <div className="py-4 text-center font-semibold text-sm text-tactical-gray">
              No personal bests found for the selected filters.
            </div>
          )}
        </SectionCard>

        {/* Workout history cards */}
        <SectionCard
          title="Workout History"
          icon={<HistoryIcon className="size-5" />}
          description={filtersActive 
            ? 'Filtered workout history matching your criteria.' 
            : 'Complete history of your workouts.'}
          className={cn("animate-fade-in animation-delay-400", isFetchingNextPage && "opacity-75 transition-opacity duration-300")}
          showDivider
        >
          {historyItems.length > 0 ? (
            <div className="space-y-4">
              {historyItems.map((workout) => (
                <div key={workout.id} className="animate-fade-in">
                  <WorkoutCard 
                    id={`${workout.id}`}
                    exerciseType={workout.exercise_type as 'PUSHUP' | 'PULLUP' | 'SITUP' | 'RUNNING'}
                    count={workout.reps}
                    distance={workout.distance}
                    duration={workout.time_in_seconds ?? 0}
                    date={new Date(workout.created_at)}
                    score={workout.grade}
                    onClick={(id: string) => handleCardClick(Number(id))}
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
            <div className="flex flex-col items-center justify-center py-8">
              <Player
                autoplay
                loop
                src={emptyHistoryAnimation}
                style={{ height: '200px', width: '200px' }}
                className="text-brass-gold"
              />
              <p className="mt-4 text-center font-semibold text-tactical-gray">
                No workouts match your current filters.
              </p>
              <p className="text-center text-sm text-tactical-gray">
                Try changing your filter settings or complete more workouts.
              </p>
            </div>
          )}
        </SectionCard>
      </div>
    </div>
  );
};

export default WorkoutHistoryView; 